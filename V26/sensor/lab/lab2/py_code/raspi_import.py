"""
Mandag 12. januar, Morten Sørensen
"""

import os
import glob

import numpy as np
import matplotlib.pyplot as plt
import sys

def raspi_import(path, channels=3):
    with open(path, 'r') as fid:
        sample_period = np.fromfile(fid, count=1, dtype=float)[0]
        data = np.fromfile(fid, dtype='uint16').astype('float64')
        data = data.reshape((-1, channels))
    sample_period *= 1e-6
    return sample_period, data

def plot_spectrum(voltage, sample_period, channel=0, window='hann', zero_pad_factor=1):
    signal = voltage[:, channel]
    n = len(signal)
    fs = 1 / sample_period
    
    # Remove DC offset
    signal = signal - np.mean(signal)
    
    # Apply window
    w = np.ones(n)
    if window == 'hann':
        w = np.hanning(n)
    elif window == 'hamming':
        w = np.hamming(n)
    elif window == 'blackman':
        w = np.blackman(n)
    windowed = signal * w
    
    # Zero-padding
    nfft      = n * zero_pad_factor
    spectrum  = np.fft.rfft(windowed, n=nfft)
    freqs     = np.fft.rfftfreq(nfft, sample_period)
    magnitude = np.abs(spectrum)
    magnitude_db = 20 * np.log10(magnitude / np.max(magnitude) + 1e-12)
    
    return freqs, magnitude_db

if __name__ == "__main__":
    if len(sys.argv) > 1:
        filename = sys.argv[1]
    else:
        files = glob.glob('data/out*')
        filename = max(files, key=os.path.getmtime)
    
    sample_period, data = raspi_import(filename)
    voltage = data * (3.3 / 4095)
    fs = 1 / sample_period
    
    print(f"Sample rate: {fs:.1f} Hz")
    print(f"Frekvensoppløsning: {fs/len(data):.2f} Hz")
    print(f"Ideell 12-bit SNR: {6.02*12 + 1.76:.1f} dB")
    
    # Plotte kode fra Claud.ai:
    # --- Time domain plot ---
    fig, axes = plt.subplots(3, 1, figsize=(10, 6), sharex=True)
    n_samples = min(500, len(voltage))
    time_ms = np.arange(n_samples) * sample_period * 1000
    
    for i, ax in enumerate(axes):
        ax.plot(time_ms, voltage[:n_samples, i])
        ax.set_ylabel(f'Ch {i+1} (V)')
        ax.set_ylim(0, 3.3)
        ax.grid(True, alpha=0.3)
    axes[-1].set_xlabel('Time (ms)')
    fig.suptitle('Time Domain')
    plt.tight_layout()
    
    # --- Frequency domain ---
    fig, axes = plt.subplots(3, 1, figsize=(10, 8), sharex=True)
    for i, ax in enumerate(axes):
        freqs, mag_db = plot_spectrum(voltage, sample_period, channel=i)
        ax.plot(freqs, mag_db, alpha=0.8)
        ax.set_ylabel(f'Ch {i+1} (dB)')
        ax.set_ylim(-100, 5)
        ax.grid(True, alpha=0.3)
        ax.legend(loc='upper right')
    axes[-1].set_xlabel('Frekvens (Hz)')
    fig.suptitle('Spektrum')
    plt.tight_layout()
    plt.show()
