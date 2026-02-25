#!/usr/bin/env python3
"""
Plot data from np_data/ directory (.npz files).
"""

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path


def load_npz(filepath):
    """Load npz file and return sample_period and data."""
    npz = np.load(filepath)
    sample_period = npz['sample_period']  # in microseconds
    data = npz['data']  # shape (n_samples, n_channels), uint16
    return sample_period, data


def plot_time_domain(data, sample_period, title="", channels=None):
    """Plot time-domain signals."""
    n_samples, n_channels = data.shape
    sample_rate = 1e6 / sample_period  # Hz

    if channels is None:
        channels = list(range(n_channels))

    # Convert to voltage (assuming 12-bit ADC with 3.3V reference)
    voltage = data.astype(float) * 3.3 / 4095

    # Create time axis in ms
    t = np.arange(n_samples) * sample_period / 1000  # ms

    fig, axes = plt.subplots(len(channels), 1, figsize=(12, 3 * len(channels)), sharex=True)
    if len(channels) == 1:
        axes = [axes]

    colors = ['tab:blue', 'tab:orange', 'tab:green']

    for ax, ch in zip(axes, channels):
        ax.plot(t, voltage[:, ch], color=colors[ch % 3], linewidth=0.5)
        ax.set_ylabel(f'Ch {ch} (V)')
        ax.grid(True, alpha=0.3)

        mean = np.mean(voltage[:, ch])
        std = np.std(voltage[:, ch])
        ax.text(0.02, 0.95, f'Mean: {mean:.3f}V, Std: {std:.3f}V',
                transform=ax.transAxes, fontsize=9, verticalalignment='top')

    axes[-1].set_xlabel('Time (ms)')
    fig.suptitle(f'{title} ({n_samples} samples @ {sample_rate/1000:.1f} kHz)')
    plt.tight_layout()
    return fig


def plot_xcorr(data, sample_period, title="", max_lag=30):
    """Plot cross-correlation between channels."""
    n_samples, n_channels = data.shape

    # Convert to voltage and remove mean
    voltage = data.astype(float) * 3.3 / 4095
    for ch in range(n_channels):
        voltage[:, ch] -= np.mean(voltage[:, ch])

    # Channel pairs for cross-correlation
    pairs = [(0, 1), (0, 2), (1, 2)]
    lags = np.arange(-max_lag, max_lag + 1)

    fig, axes = plt.subplots(len(pairs), 1, figsize=(12, 3 * len(pairs)), sharex=True)
    colors = ['tab:blue', 'tab:orange', 'tab:green']

    for ax, (ch1, ch2), color in zip(axes, pairs, colors):
        xcorr = np.correlate(voltage[:, ch1], voltage[:, ch2], mode='full')
        mid = len(xcorr) // 2
        xcorr = xcorr[mid - max_lag:mid + max_lag + 1]
        # Normalize
        xcorr = xcorr / np.max(np.abs(xcorr))

        ax.stem(lags, xcorr, linefmt=color, markerfmt='o', basefmt='k-')
        ax.set_ylabel(f'Ch{ch1} x Ch{ch2}')
        ax.grid(True, alpha=0.3)
        ax.set_ylim(-1.1, 1.1)
        ax.axvline(0, color='red', linestyle='--', alpha=0.5)

        # Find peak lag
        peak_lag = lags[np.argmax(xcorr)]
        ax.text(0.02, 0.95, f'Peak at lag {peak_lag}',
                transform=ax.transAxes, fontsize=9, verticalalignment='top')

    axes[-1].set_xlabel('Lag (samples)')
    fig.suptitle(f'Cross-correlation: {title}')
    plt.tight_layout()
    return fig


def main():
    # Find all npz files in np_data directory
    np_data_dir = Path(__file__).parent.parent / 'np_data'
    npz_files = sorted(np_data_dir.glob('*.npz'))

    if not npz_files:
        print("No .npz files found in np_data/")
        return

    print(f"Found {len(npz_files)} files in np_data/")
    for i, f in enumerate(npz_files):
        print(f"  {i}: {f.name}")

    # Get user selection
    try:
        selection = int(input("\nEnter file number to plot: "))
        if selection < 0 or selection >= len(npz_files):
            print(f"Invalid selection. Choose 0-{len(npz_files)-1}")
            return
    except ValueError:
        print("Invalid input. Enter a number.")
        return

    filepath = npz_files[selection]
    print(f"\nPlotting: {filepath.name}")

    sample_period, data = load_npz(filepath)
    print(f"  Sample period: {sample_period} us")
    print(f"  Data shape: {data.shape}")

    # Plot time domain (full data)
    plot_time_domain(data, sample_period, title=filepath.stem)

    # Plot cross-correlation
    plot_xcorr(data, sample_period, title=filepath.stem, max_lag=30)

    plt.show()


if __name__ == "__main__":
    main()
