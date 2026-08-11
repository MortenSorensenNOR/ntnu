#!/usr/bin/env python3
"""
Live Doppler radar viewer — spectrum + speed over time
ADC 1 = I,  ADC 2 = Q,  carrier = 24 GHz
Usage: python3 live_doppler.py [port]
"""

import socket
import struct
import sys
import numpy as np
from collections import deque
from scipy.signal import welch

from PyQt6 import QtWidgets, QtCore
import pyqtgraph as pg

# --- Constants --------------------------------------------------------------
ADCS             = 3
BYTES_PER_SAMPLE = ADCS * 2
PORT             = int(sys.argv[1]) if len(sys.argv) > 1 else 12345
FC               = 24e9          # carrier frequency (Hz)
C                = 3e8           # speed of light (m/s)
MAX_SPEED_MS     = 10.0          # ignore peaks beyond ±10 m/s (36 km/h)
WINDOW_SIZE      = 8192          # IQ samples kept in ring buffer
SPEED_HISTORY    = 300           # number of speed estimates to show
DC_GUARD_HZ      = 5             # ignore ±5 Hz around DC when finding peak
WELCH_NPERSEG    = 1024


# --- Panels -----------------------------------------------------------------

class DopplerSpectrumPanel:
    """Live Welch PSD of the IQ signal with speed axis."""

    def __init__(self, layout_widget, row, col=0, rowspan=1, colspan=1, fs=31250.0):
        self.fs = fs
        self.plot = layout_widget.addPlot(
            row=row, col=col, rowspan=rowspan, colspan=colspan,
            title="Doppler-spektrum (live)")
        self.plot.setLabel('left', 'Effekt (dB)')
        self.plot.setLabel('bottom', 'Doppler-frekvens (Hz)')
        self.plot.setXRange(-fs / 2, fs / 2)
        self.plot.addLegend()

        self.curve      = self.plot.plot(pen=pg.mkPen('#4ecdc4', width=1), name='PSD')
        self.peak_line  = pg.InfiniteLine(angle=90, pen=pg.mkPen('#ff6b6b', width=2, style=QtCore.Qt.PenStyle.DashLine))
        self.plot.addItem(self.peak_line)

        self.peak_label = pg.TextItem('', color='#ff6b6b', anchor=(0, 1))
        self.plot.addItem(self.peak_label)

        # Secondary x-axis label (speed) via title update — pyqtgraph doesn't
        # support twin axes natively, so we annotate via the peak label instead.

    def update(self, data):
        I = np.array(data['I'])
        Q = np.array(data['Q'])
        if len(I) < WELCH_NPERSEG * 2:
            return

        I = I - I.mean()
        Q = Q - Q.mean()
        iq = I + 1j * Q

        freqs, psd = welch(iq, fs=self.fs, nperseg=WELCH_NPERSEG,
                           noverlap=WELCH_NPERSEG // 2, window='hann',
                           return_onesided=False)
        freqs = np.fft.fftshift(freqs)
        psd   = np.fft.fftshift(psd)
        psd_dB = 10 * np.log10(np.abs(psd) + 1e-12)

        self.curve.setData(freqs, psd_dB)

        # Peak (exclude DC)
        max_doppler_hz = MAX_SPEED_MS * 2 * FC / C
        mask = (np.abs(freqs) < DC_GUARD_HZ) | (np.abs(freqs) > max_doppler_hz)
        psd_nodc = psd_dB.copy()
        psd_nodc[mask] = -np.inf
        idx = np.argmax(psd_nodc)
        peak_f = freqs[idx]
        peak_v = peak_f * C / (2 * FC)

        self.peak_line.setValue(peak_f)
        self.peak_label.setText(
            f"{peak_f:+.1f} Hz  →  {peak_v:+.2f} m/s  ({peak_v*3.6:+.2f} km/h)")
        self.peak_label.setPos(peak_f, psd_dB[idx])


class DopplerSpeedPanel:
    """Rolling speed-over-time plot derived from peak Doppler bin."""

    def __init__(self, layout_widget, row, col=0, rowspan=1, colspan=1, fs=31250.0):
        self.fs = fs
        self.speeds = deque([0.0] * SPEED_HISTORY, maxlen=SPEED_HISTORY)

        self.plot = layout_widget.addPlot(
            row=row, col=col, rowspan=rowspan, colspan=colspan,
            title="Hastighet over tid")
        self.plot.setLabel('left', 'Hastighet (m/s)')
        self.plot.setLabel('bottom', 'Tid (frames)')
        self.plot.addLegend()
        self.plot.setYRange(-3, 3)

        self.curve     = self.plot.plot(pen=pg.mkPen('#ffe66d', width=2), name='v (m/s)')
        self.zero_line = pg.InfiniteLine(angle=0, pos=0,
                                         pen=pg.mkPen('#555555', width=1,
                                                      style=QtCore.Qt.PenStyle.DashLine))
        self.plot.addItem(self.zero_line)

        self.speed_label = pg.TextItem('', color='#ffe66d', anchor=(1, 1))
        self.plot.addItem(self.speed_label)

    def update(self, data):
        I = np.array(data['I'])
        Q = np.array(data['Q'])
        if len(I) < WELCH_NPERSEG * 2:
            return

        I = I - I.mean()
        Q = Q - Q.mean()
        iq = I + 1j * Q

        freqs, psd = welch(iq, fs=self.fs, nperseg=WELCH_NPERSEG,
                           noverlap=WELCH_NPERSEG // 2, window='hann',
                           return_onesided=False)
        freqs = np.fft.fftshift(freqs)
        psd   = np.fft.fftshift(np.abs(psd))

        max_doppler_hz = MAX_SPEED_MS * 2 * FC / C
        mask = (np.abs(freqs) < DC_GUARD_HZ) | (np.abs(freqs) > max_doppler_hz)
        psd[mask] = 0
        peak_v = freqs[np.argmax(psd)] * C / (2 * FC)

        self.speeds.append(peak_v)
        self.curve.setData(np.array(self.speeds))
        self.speed_label.setText(f"{peak_v:+.3f} m/s  ({peak_v*3.6:+.2f} km/h)")
        self.speed_label.setPos(SPEED_HISTORY, peak_v)


# --- Main window ------------------------------------------------------------

class DopplerPlotter(QtWidgets.QMainWindow):
    def __init__(self, conn, sample_period_us):
        super().__init__()
        self.conn = conn
        self.fs   = 1e6 / sample_period_us
        self.buffer = b''
        self.first_sample_skipped = False

        self.data = {
            'I': deque(np.zeros(WINDOW_SIZE), maxlen=WINDOW_SIZE),
            'Q': deque(np.zeros(WINDOW_SIZE), maxlen=WINDOW_SIZE),
        }

        self.setWindowTitle('Doppler Live View  —  24 GHz')
        self.resize(1200, 700)

        widget = QtWidgets.QWidget()
        self.setCentralWidget(widget)
        layout = QtWidgets.QVBoxLayout(widget)

        self.plot_widget = pg.GraphicsLayoutWidget()
        layout.addWidget(self.plot_widget)

        self.panels = [
            DopplerSpectrumPanel(self.plot_widget, row=0, col=0, rowspan=1, colspan=1, fs=self.fs),
            DopplerSpeedPanel   (self.plot_widget, row=1, col=0, rowspan=1, colspan=1, fs=self.fs),
        ]

        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.refresh)
        self.timer.start(50)   # 20 fps — spectrum calc is heavier than raw ADC

        self.conn.setblocking(False)

    def refresh(self):
        try:
            while True:
                chunk = self.conn.recv(4096)
                if not chunk:
                    break
                self.buffer += chunk
        except BlockingIOError:
            pass

        usable = len(self.buffer) - (len(self.buffer) % BYTES_PER_SAMPLE)
        if usable > 0:
            samples = np.frombuffer(self.buffer[:usable], dtype=np.uint16).reshape(-1, ADCS)
            self.buffer = self.buffer[usable:]

            # Skip the very first sample (always corrupted)
            if not self.first_sample_skipped:
                samples = samples[1:]
                self.first_sample_skipped = True

            self.data['I'].extend(samples[:, 0].astype(float))
            self.data['Q'].extend(samples[:, 1].astype(float))

        for panel in self.panels:
            panel.update(self.data)


# --- Entry point ------------------------------------------------------------

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', PORT))
    server.listen(1)

    print(f"Listening on port {PORT}...")
    conn, addr = server.accept()
    print(f"Connected from {addr}")

    header = conn.recv(8)
    sample_period_us = struct.unpack('d', header)[0]
    print(f"Sample period: {sample_period_us} µs  ({1e6/sample_period_us:.0f} Hz)")

    app = QtWidgets.QApplication(sys.argv)
    plotter = DopplerPlotter(conn, sample_period_us)
    plotter.show()

    try:
        app.exec()
    finally:
        conn.close()
        server.close()


if __name__ == "__main__":
    main()
