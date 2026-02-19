#!/usr/bin/env python3
"""
Plot ADC capture data from .npy files.
Usage: python3 plot_adc.py [filename.npy] [sample_rate_hz]

If no filename given, uses the most recent adc_capture_*.npy file.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import glob
import os


def load_capture(filename=None):
    """Load capture file. If none given, find most recent."""
    if filename is None:
        files = glob.glob("adc_capture_*.npy")
        if not files:
            print("No adc_capture_*.npy files found")
            sys.exit(1)
        filename = max(files, key=os.path.getmtime)
        print(f"Loading most recent: {filename}")

    return np.load(filename), filename


def plot_capture(data, sample_rate=None, filename=""):
    """Plot the captured ADC data."""
    n_samples, n_channels = data.shape

    # Create time axis
    if sample_rate:
        t = np.arange(n_samples) / sample_rate * 1000  # ms
        xlabel = "Time (ms)"
    else:
        t = np.arange(n_samples)
        xlabel = "Sample number"

    # Create figure with subplots for each channel
    fig, axes = plt.subplots(n_channels, 1, figsize=(12, 3 * n_channels), sharex=True)
    if n_channels == 1:
        axes = [axes]

    channel_names = ["ADC0", "ADC1", "ADC2"]
    colors = ["tab:blue", "tab:orange", "tab:green"]

    for i, ax in enumerate(axes):
        ax.plot(t, data[:, i], color=colors[i], linewidth=0.5)
        ax.set_ylabel(f"{channel_names[i]} (V)")
        ax.grid(True, alpha=0.3)
        ax.set_ylim(-3.3/2, 3.3/2)
        ax.set_xlim(50, 100)

        # Show stats
        mean = np.mean(data[:, i])
        std = np.std(data[:, i])
        ax.axhline(mean, color=colors[i], linestyle='--', alpha=0.5)
        ax.text(0.02, 0.95, f"Mean: {mean:.3f}V, Std: {std:.3f}V",
                transform=ax.transAxes, fontsize=9, verticalalignment='top')

    axes[-1].set_xlabel(xlabel)

    title = f"ADC Capture: {filename}" if filename else "ADC Capture"
    title += f" ({n_samples} samples)"
    if sample_rate:
        title += f" @ {sample_rate/1000:.1f} kHz"
    fig.suptitle(title)

    plt.tight_layout()
    return fig


def plot_fft(data, sample_rate, filename=""):
    """Plot FFT of the captured data."""
    if sample_rate is None:
        print("Sample rate required for FFT plot")
        return None

    n_samples, n_channels = data.shape

    fig, axes = plt.subplots(n_channels, 1, figsize=(12, 3 * n_channels), sharex=True)
    if n_channels == 1:
        axes = [axes]

    channel_names = ["ADC0", "ADC1", "ADC2"]
    colors = ["tab:blue", "tab:orange", "tab:green"]

    freqs = np.fft.rfftfreq(n_samples, 1/sample_rate)

    for i, ax in enumerate(axes):
        fft = np.abs(np.fft.rfft(data[:, i] - np.mean(data[:, i])))
        fft_db = 20 * np.log10(fft + 1e-10)

        ax.plot(freqs / 1000, fft_db, color=colors[i], linewidth=0.5)
        ax.set_ylabel(f"{channel_names[i]} (dB)")
        ax.grid(True, alpha=0.3)
        ax.set_xlim(0, sample_rate / 2000)
        ax.set_ylim(-30, 1.1 * np.max(fft_db))

    axes[-1].set_xlabel("Frequency (kHz)")

    title = f"FFT: {filename}" if filename else "FFT"
    fig.suptitle(title)

    plt.tight_layout()
    return fig


def main():
    # Parse arguments
    filename = sys.argv[1] if len(sys.argv) > 1 else None
    sample_rate = float(sys.argv[2]) if len(sys.argv) > 2 else None

    # Load data
    data, fname = load_capture(filename)
    print(f"Loaded {data.shape[0]} samples, {data.shape[1]} channels")

    for i in range(data.shape[1]):
        data[:, i] = data[:, i] - np.mean(data[:, i])

    # Plot time domain
    plot_capture(data, sample_rate, fname)

    # Plot FFT if sample rate provided
    if sample_rate:
        plot_fft(data, sample_rate, fname)

    plt.show()


if __name__ == "__main__":
    main()
