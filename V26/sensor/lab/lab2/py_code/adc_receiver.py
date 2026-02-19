#!/usr/bin/env python3
"""
Live ADC viewer with PyQtGraph
Usage: python3 adc_live.py [port]
"""

import socket
import struct
import numpy as np
import sys
from collections import deque

from PyQt6 import QtWidgets, QtCore
import pyqtgraph as pg

ADCS = 3
BYTES_PER_SAMPLE = ADCS * 2
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 12345
WINDOW_SIZE = 5000  # Samples to show


class PlotPanel:
    """Base class for plot panels — subclass this to add new plot types"""
    
    def __init__(self, layout_widget, row, col=0, rowspan=1, colspan=1, title="", y_range=None):
        self.plot = layout_widget.addPlot(row=row, col=col, rowspan=rowspan, colspan=colspan, title=title)
        if y_range:
            self.plot.setYRange(*y_range)
        self.plot.setLabel('left', 'Value')
    
    def update(self, data):
        """Override this — data is dict with 'raw': [ch0, ch1, ch2] deques"""
        raise NotImplementedError

class RawADCPanel(PlotPanel):
    """Shows raw ADC signal for a single channel"""
    
    def __init__(self, layout_widget, row, channel, col=0, rowspan=1, colspan=1, color='#ff6b6b'):
        super().__init__(layout_widget, row, col, rowspan, colspan, f'ADC {channel + 1}', y_range=(0, 3.3))
        self.channel = channel
        self.curve = self.plot.plot(pen=pg.mkPen(color, width=1))
        self.plot.setLabel('left', 'Voltage (V)')
    
    def update(self, data):
        self.curve.setData(np.array(data['raw'][self.channel]))

class CrossCorrelationPanel(PlotPanel):
    """Shows cross-correlation between two channels"""
    
    def __init__(self, layout_widget, row, ch_a, ch_b, col=0, rowspan=1, colspan=1, color='#a29bfe', fs=31.250e3, d=0.065):
        super().__init__(layout_widget, row, col, rowspan, colspan, f'XCorr ADC {ch_a + 1} × {ch_b + 1}')
        self.ch_a = ch_a
        self.ch_b = ch_b
        self.curve = self.plot.plot(pen=pg.mkPen(color, width=1))
        self.plot.setLabel('bottom', 'Lag (samples)')
        self.c  = 343  # m/s
        self.fs = fs
        self.d  = d
        self.n_max = int(np.ceil(self.fs * self.d / self.c))
        self.n_max = 50 * self.n_max
    
    def update(self, data):
        a = np.array(data['raw'][self.ch_a])
        b = np.array(data['raw'][self.ch_b])
        
        a = a - np.mean(a)
        b = b - np.mean(b)
        
        xcorr = np.correlate(a, b, mode='full')
        xcorr = xcorr / (np.std(a) * np.std(b) * len(a))
        lags = np.arange(-len(a) + 1, len(a))
        
        # Only keep lags within ±n_max
        mask = np.abs(lags) <= self.n_max
        lags = lags[mask]
        xcorr = xcorr[mask]
        
        self.curve.setData(lags, xcorr)

class RadarPanel:
    """Polar radar display for angle estimation using triangular microphone array"""
    
    def __init__(self, layout_widget, row, col=0, rowspan=1, colspan=1, fs=31.250e3, d=0.065):
        self.plot = layout_widget.addPlot(row=row, col=col, rowspan=rowspan, colspan=colspan, title='Angle Estimate')
        self.plot.setAspectLocked(True)
        self.plot.hideAxis('left')
        self.plot.hideAxis('bottom')
        self.plot.setXRange(-1.2, 1.2)
        self.plot.setYRange(-1.2, 1.2)
        
        # Physical parameters
        self.c = 343  # m/s speed of sound
        self.fs = fs
        self.d = d    # side length of triangular array
        self.n_max = int(np.ceil(self.fs * self.d / self.c))
        
        # Draw radar circles
        for r in [0.25, 0.5, 0.75, 1.0]:
            theta = np.linspace(0, 2 * np.pi, 100)
            x = r * np.cos(theta)
            y = r * np.sin(theta)
            self.plot.plot(x, y, pen=pg.mkPen('#444444', width=1))
        
        # Draw crosshairs
        self.plot.plot([-1, 1], [0, 0], pen=pg.mkPen('#444444', width=1))
        self.plot.plot([0, 0], [-1, 1], pen=pg.mkPen('#444444', width=1))
        
        # Draw angle lines every 30 degrees
        for angle_deg in range(0, 360, 30):
            angle = np.radians(angle_deg)
            self.plot.plot([0, np.cos(angle)], [0, np.sin(angle)], pen=pg.mkPen('#333333', width=1))
        
        # Angle indicator line
        self.angle_line = self.plot.plot([0, 0], [0, 1], pen=pg.mkPen('#ff6b6b', width=3))
        
        # Dot at the end
        self.angle_dot = self.plot.plot([0], [1], pen=None, symbol='o', symbolSize=12, symbolBrush='#ff6b6b')
        
        # Angle text
        self.angle_text = pg.TextItem('--°', color='#ffffff', anchor=(0.5, 0.5))
        self.angle_text.setPos(0, -1.1)
        self.plot.addItem(self.angle_text)
        
        # Status text
        self.status_text = pg.TextItem('waiting...', color='#888888', anchor=(0.5, 0.5))
        self.status_text.setPos(0, 0)
        self.plot.addItem(self.status_text)
        
        # State
        self.current_angle = 0
        self.frames_since_detection = 999
        
        # Thresholds
        self.energy_threshold = 0.002
        self.xcorr_peak_ratio = 0.0
        self.hold_frames = 30
    
    def _find_lag(self, a, b):
        """Find lag between two signals using cross-correlation, limited to ±n_max"""
        xcorr = np.correlate(a, b, mode='full')
        lags = np.arange(-len(a) + 1, len(a))
        
        # Mask to only consider lags within ±n_max
        mask = np.abs(lags) <= self.n_max
        xcorr_masked = xcorr[mask]
        lags_masked = lags[mask]
        
        peak_idx = np.argmax(np.abs(xcorr_masked))
        peak_val = np.abs(xcorr_masked[peak_idx])
        mean_val = np.mean(np.abs(xcorr_masked))
        
        return lags_masked[peak_idx], peak_val, mean_val
    
    def update(self, data):
        # Get signals from all 3 microphones
        ch1 = np.array(data['raw'][0])
        ch2 = np.array(data['raw'][1])
        ch3 = np.array(data['raw'][2])
        
        if len(ch1) < 1000:
            return
        
        # Use recent samples
        ch1 = ch1[-1000:]
        ch2 = ch2[-1000:]
        ch3 = ch3[-1000:]
        
        # Remove DC
        ch1 = ch1 - np.mean(ch1)
        ch2 = ch2 - np.mean(ch2)
        ch3 = ch3 - np.mean(ch3)
        
        # Check energy threshold
        if np.var(ch1) < self.energy_threshold or np.var(ch2) < self.energy_threshold or np.var(ch3) < self.energy_threshold:
            print(np.var(ch1), self.energy_threshold)
            self.frames_since_detection += 1
            self._update_display(detected=False)
            return
        
        # Find lags between microphone pairs (n_ji = lag from i to j)
        # Using the convention from the lab: sensor 1 is top, 2 is bottom-left, 3 is bottom-right
        n_21, peak_21, mean_21 = self._find_lag(ch2, ch1)  # lag from mic 1 to mic 2
        n_31, peak_31, mean_31 = self._find_lag(ch3, ch1)  # lag from mic 1 to mic 3
        n_32, peak_32, mean_32 = self._find_lag(ch3, ch2)  # lag from mic 2 to mic 3
        
        # Check if peaks are strong enough
        min_ratio = min(peak_21/mean_21, peak_31/mean_31, peak_32/mean_32)
        if min_ratio < self.xcorr_peak_ratio:
            self.frames_since_detection += 1
            self._update_display(detected=False)
            return
        
        # Calculate angle using equation II.29 from lab doc
        numerator = n_31 + n_21
        denominator = n_31 - n_21 + 2 * n_32
        
        if denominator == 0:
            # Avoid division by zero - signal coming from y-axis direction
            theta = np.pi / 2 if numerator > 0 else -np.pi / 2
        else:
            theta = np.arctan(np.sqrt(3) * numerator / denominator)
        
        # Add π if x < 0 (i.e., if (-n_21 + n_31 + 2*n_32) < 0)
        if (-n_21 + n_31 + 2 * n_32) < 0:
            theta += np.pi
        
        # Normalize to [-π, π]
        while theta > np.pi:
            theta -= 2 * np.pi
        while theta < -np.pi:
            theta += 2 * np.pi
        
        # Smooth angle estimate
        # Handle angle wrapping for smoothing
        angle_diff = theta - self.current_angle
        if angle_diff > np.pi:
            angle_diff -= 2 * np.pi
        elif angle_diff < -np.pi:
            angle_diff += 2 * np.pi
        
        self.current_angle += 0.3 * angle_diff
        self.frames_since_detection = 0
        
        self._update_display(detected=True)
    
    def _update_display(self, detected):
        # Fade out if no recent detection
        if self.frames_since_detection > self.hold_frames:
            alpha = max(0.2, 1.0 - (self.frames_since_detection - self.hold_frames) / 30.0)
            self.status_text.setText('waiting...')
            self.status_text.setColor(pg.mkColor('#888888'))
        else:
            alpha = 1.0
            self.status_text.setText('')
        
        # Update line and dot (θ=0 is along positive x-axis in the lab coordinate system)
        x = np.cos(self.current_angle)
        y = np.sin(self.current_angle)
        
        color = pg.mkColor(255, 107, 107, int(alpha * 255))
        self.angle_line.setPen(pg.mkPen(color, width=3))
        self.angle_line.setData([0, x], [0, y])
        self.angle_dot.setData([x], [y])
        self.angle_dot.setSymbolBrush(color)
        
        # Update text - display angle in degrees
        if self.frames_since_detection <= self.hold_frames:
            display_angle = np.degrees(self.current_angle)
            self.angle_text.setText(f'{display_angle:.1f}°')
            self.angle_text.setColor(pg.mkColor(255, 255, 255, int(alpha * 255)))
        else:
            self.angle_text.setText('--°')
            self.angle_text.setColor(pg.mkColor('#888888'))

class ADCPlotter(QtWidgets.QMainWindow):
    def __init__(self, conn, sample_period_us):
        super().__init__()
        self.conn = conn
        self.sample_period_us = sample_period_us
        self.buffer = b''
        
        # Ring buffers for each channel
        self.data = {
            'raw': [deque(np.zeros(WINDOW_SIZE), maxlen=WINDOW_SIZE) for _ in range(ADCS)]
        }
        
        # Setup window
        self.setWindowTitle('ADC Live View')
        self.resize(1200, 900)
        
        widget = QtWidgets.QWidget()
        self.setCentralWidget(widget)
        layout = QtWidgets.QVBoxLayout(widget)
        
        self.plot_widget = pg.GraphicsLayoutWidget()
        layout.addWidget(self.plot_widget)
        
       # === ADD YOUR PANELS HERE ===
        colors = ['#ff6b6b', '#4ecdc4', '#ffe66d']

        # Top left: Raw ADCs (rows 0-2, col 0)
        self.panels = [
            RawADCPanel(self.plot_widget, row=0, col=0, channel=0, color=colors[0]),
            RawADCPanel(self.plot_widget, row=1, col=0, channel=1, color=colors[1]),
            RawADCPanel(self.plot_widget, row=2, col=0, channel=2, color=colors[2]),
        ]

        # Right column: Radar
        self.panels += [
            RadarPanel(self.plot_widget, row=0, col=1, rowspan=3, colspan=1),
        ]

        # Bottom: Cross-correlations spanning both columns (rows 3-4, col 0, colspan 2)
        self.panels += [
            CrossCorrelationPanel(self.plot_widget, row=3, col=0, colspan=2, ch_a=0, ch_b=1, color='#a29bfe'),
            CrossCorrelationPanel(self.plot_widget, row=4, col=0, colspan=2, ch_a=0, ch_b=2, color='#fd79a8'),
        ]
        # === END PANELS === 

        # Timer for reading data
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.refresh)
        self.timer.start(16)  # ~60 fps
        
        # Make socket non-blocking
        self.conn.setblocking(False)
    
    def refresh(self):
        # Read available data
        try:
            while True:
                chunk = self.conn.recv(4096)
                if not chunk:
                    break
                self.buffer += chunk
        except BlockingIOError:
            pass
        
        # Process complete frames
        usable = len(self.buffer) - (len(self.buffer) % BYTES_PER_SAMPLE)
        if usable > 0:
            samples = np.frombuffer(self.buffer[:usable], dtype=np.uint16).reshape(-1, ADCS)
            self.buffer = self.buffer[usable:]
            
            # Convert to voltage: 12-bit ADC, 3.3V reference
            voltage = samples * (3.3 / 4095)
            
            for i in range(ADCS):
                self.data['raw'][i].extend(voltage[:, i])
        
        # Update all panels
        for panel in self.panels:
            panel.update(self.data)

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', PORT))
    server.listen(1)
    
    print(f"Listening on port {PORT}...")
    
    conn, addr = server.accept()
    print(f"Connected from {addr}")
    
    # Read header
    header = conn.recv(8)
    sample_period_us = struct.unpack('d', header)[0]
    print(f"Sample period: {sample_period_us} µs ({1000/sample_period_us:.2f} kHz)")
    
    app = QtWidgets.QApplication(sys.argv)
    plotter = ADCPlotter(conn, sample_period_us)
    plotter.show()
    
    try:
        app.exec()
    finally:
        conn.close()
        server.close()


if __name__ == "__main__":
    main()
