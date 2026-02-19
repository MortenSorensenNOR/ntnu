"""
Mandag 12. januar, Morten Sørensen
"""

import numpy as np
import matplotlib.pyplot as plt
import sys

def raspi_import(path, channels=3):
    with open(path, 'r') as fid:
        sample_period = np.fromfile(fid, count=1, dtype=float)[0]
        data = np.fromfile(fid, dtype='uint16').astype('float64')
        data = data.reshape((-1, channels))
    data = data[1:, :]
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

def find_signal_freq(voltage, sample_period, channel=0, min_freq=100):
    """Auto-detect the fundamental signal frequency by finding the peak in the spectrum."""
    signal = voltage[:, channel] - np.mean(voltage[:, channel])
    n = len(signal)

    w = np.hanning(n)
    windowed = signal * w

    spectrum = np.fft.rfft(windowed)
    freqs = np.fft.rfftfreq(n, sample_period)
    magnitude = np.abs(spectrum)

    # Exclude DC and very low frequencies
    min_bin = np.argmin(np.abs(freqs - min_freq))
    magnitude[:min_bin] = 0

    peak_bin = np.argmax(magnitude)
    return freqs[peak_bin]

def get_snr(voltage, sample_period, channel=0, signal_freq=None):
    signal = voltage[:, channel] - np.mean(voltage[:, channel])
    n = len(signal)
    fs = 1 / sample_period

    w = np.hanning(n)
    windowed = signal * w

    spectrum = np.fft.rfft(windowed)
    freqs = np.fft.rfftfreq(n, sample_period)
    power = np.abs(spectrum)**2

    if signal_freq is None:
        signal_freq = find_signal_freq(voltage, sample_period, channel)

    signal_bin = np.argmin(np.abs(freqs - signal_freq))
    signal_power = np.sum(power[max(0, signal_bin-2):signal_bin+3])
    noise_power = np.sum(power) - signal_power
    snr = 10 * np.log10(signal_power / noise_power)
    return snr, signal_freq

def get_sfdr(voltage, sample_period, channel=0, signal_freq=None, bin_width=2):
    """
    SFDR: ratio between signal peak and greatest spurious peak.
    bin_width: number of bins around each peak to exclude when searching for spurs.
    """
    signal = voltage[:, channel] - np.mean(voltage[:, channel])
    n = len(signal)

    w = np.hanning(n)
    windowed = signal * w

    spectrum = np.fft.rfft(windowed)
    freqs = np.fft.rfftfreq(n, sample_period)
    magnitude = np.abs(spectrum)

    if signal_freq is None:
        signal_freq = find_signal_freq(voltage, sample_period, channel)

    signal_bin = np.argmin(np.abs(freqs - signal_freq))
    signal_mag = magnitude[signal_bin]

    # Mask out the signal region
    mask = np.ones(len(magnitude), dtype=bool)
    mask[max(0, signal_bin - bin_width):signal_bin + bin_width + 1] = False

    # Also mask out DC
    mask[:bin_width + 1] = False

    # Find greatest spurious peak
    spur_mag = np.max(magnitude[mask])

    sfdr = 20 * np.log10(signal_mag / spur_mag)
    return sfdr

def get_sfdr_no_harmonics(voltage, sample_period, channel=0, signal_freq=None, bin_width=2, num_harmonics=10):
    """
    SFDR excluding harmonics: ratio between signal peak and greatest spurious peak,
    where harmonics (2f, 3f, 4f, ...) of the signal are also excluded.
    """
    signal = voltage[:, channel] - np.mean(voltage[:, channel])
    n = len(signal)
    fs = 1 / sample_period

    w = np.hanning(n)
    windowed = signal * w

    spectrum = np.fft.rfft(windowed)
    freqs = np.fft.rfftfreq(n, sample_period)
    magnitude = np.abs(spectrum)

    if signal_freq is None:
        signal_freq = find_signal_freq(voltage, sample_period, channel)

    signal_bin = np.argmin(np.abs(freqs - signal_freq))
    signal_mag = magnitude[signal_bin]

    # Mask out the signal region
    mask = np.ones(len(magnitude), dtype=bool)
    mask[max(0, signal_bin - bin_width):signal_bin + bin_width + 1] = False

    # Mask out DC
    mask[:bin_width + 1] = False

    # Mask out harmonics (2f, 3f, 4f, ...)
    nyquist = fs / 2
    for h in range(2, num_harmonics + 1):
        harmonic_freq = h * signal_freq
        if harmonic_freq >= nyquist:
            break
        harmonic_bin = np.argmin(np.abs(freqs - harmonic_freq))
        mask[max(0, harmonic_bin - bin_width):harmonic_bin + bin_width + 1] = False

    # Find greatest spurious peak (excluding signal and harmonics)
    spur_mag = np.max(magnitude[mask])

    sfdr = 20 * np.log10(signal_mag / spur_mag)
    return sfdr

if __name__ == "__main__":
    sample_period, data = raspi_import(sys.argv[1] if len(sys.argv) > 1 else 'foo.bin')
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
        ax.set_ylim(-0.1, 3.6)
        ax.grid(True, alpha=0.3)
    axes[-1].set_xlabel('Time (ms)')
    fig.suptitle('Time Domain')
    plt.tight_layout()
    
    # --- Compare windows ---
    fig, axes = plt.subplots(3, 1, figsize=(10, 8), sharex=True)
    windows = ['none', 'hann', 'blackman']
    
    for i, ax in enumerate(axes):
        for win in windows:
            freqs, mag_db = plot_spectrum(voltage, sample_period, channel=i, window=win)
            ax.plot(freqs, mag_db, label=win, alpha=0.8)
            break
        ax.set_ylabel(f'Ch {i+1} (dB)')
        ax.set_ylim(-100, 5)
        ax.grid(True, alpha=0.3)
        ax.legend(loc='upper right')
    axes[-1].set_xlabel('Frequency (Hz)')
    fig.suptitle('Spektrum - Window Sammenligning')
    plt.tight_layout()
    # plt.savefig("window_functions.png", dpi=300)
    
    # --- Compare zero-padding ---
    fig, axes = plt.subplots(3, 1, figsize=(10, 8), sharex=True)
    pad_factors = [1, 4, 8]
    
    for i, ax in enumerate(axes):
        for pad in pad_factors:
            freqs, mag_db = plot_spectrum(voltage, sample_period, channel=i, 
                                          window='hann', zero_pad_factor=pad)
            ax.plot(freqs, mag_db, label=f'{pad}x', alpha=0.8)
        ax.set_ylabel(f'Ch {i+1} (dB)')
        ax.set_ylim(-100, 5)
        ax.grid(True, alpha=0.3)
        ax.legend(loc='upper right')
    axes[-1].set_xlabel('Frequency (Hz)')
    fig.suptitle('Spektrum - Zero-padding Sammenligning (Hann window)')
    plt.tight_layout()
    # plt.savefig("zero_padding.png", dpi=300)
    
    # --- SNR estimate (auto-detect signal frequency) ---
    detected_freq = find_signal_freq(voltage, sample_period, channel=0)
    print(f"Detected signal frequency: {detected_freq:.1f} Hz")
    for i in range(3):
        snr_db, _ = get_snr(voltage, sample_period, i, detected_freq)
        sfdr_db = get_sfdr(voltage, sample_period, i, detected_freq)
        sfdr_no_harm_db = get_sfdr_no_harmonics(voltage, sample_period, i, detected_freq)
        print(f"ADC {i} SNR: {snr_db:.1f} dB | SFDR: {sfdr_db:.1f} dB | SFDR (no harmonics): {sfdr_no_harm_db:.1f} dB")
    
    plt.show()
