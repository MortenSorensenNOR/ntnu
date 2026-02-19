from raspi_import import raspi_import
import matplotlib.pyplot as plt
import numpy as np
import sys
import os
import re

# Create images directory if it doesn't exist
os.makedirs("images", exist_ok=True)

# Get filenames from command line arguments
filenames = sys.argv[1:] if len(sys.argv) > 1 else ['foo.bin']
num_files = len(filenames)

def parse_frequency_label(filename):
    """Extract frequency from filename and format nicely (e.g., '100hz' -> '100 Hz', '1khz' -> '1 kHz')"""
    base = os.path.splitext(os.path.basename(filename))[0]
    match = re.search(r'(\d+)(hz|khz)', base.lower())
    if match:
        value = int(match.group(1))
        unit = match.group(2)
        if unit == 'khz':
            return f"{value} kHz"
        else:
            return f"{value} Hz"
    return base

# Store data for combined plots
all_time_data = []
all_freq_data = []
all_labels = []

N = 2**15  # FFT length

# Open results file
with open("results.txt", "w") as results_file:
    results_file.write("Signal Analysis Results\n")
    results_file.write("=" * 50 + "\n\n")

    for filename in filenames:
        base_name = os.path.splitext(os.path.basename(filename))[0]
        freq_label = parse_frequency_label(filename)
        all_labels.append(freq_label)

        results_file.write(f"File: {filename}\n")
        results_file.write("-" * 50 + "\n")
        print(f"\nProcessing: {filename}")

        sample_period, data = raspi_import(filename)

        data = data.copy()
        data -= (2**12 - 1) / 2
        data = data * (3.3 / ((2**12) - 1))

        data_length = data.shape[0]
        data_channels = data.shape[1]

        n = np.arange(data_length)
        time = n * sample_period

        w = np.sin(np.pi * n / data_length) ** 2  # hanning window

        fs = int(1 / sample_period)
        df = np.linspace(-0.5, 0.5, N) * fs

        # Store time-domain data for channel 0 (before windowing)
        all_time_data.append({
            'time': time,
            'signal': data[:, 0].copy(),
            'label': freq_label
        })

        # Compute FFT for all channels
        Sdb = np.zeros((N, data_channels))
        for i in range(data_channels):
            windowed = w * data[:, i]
            fft = abs(np.fft.fft(windowed, N))
            fft = abs(np.fft.fftshift(fft))
            Sdb[:, i] = 20 * np.log10(fft / max(fft))

        # Store frequency-domain data for channel 0
        all_freq_data.append({
            'freq': df,
            'spectrum': Sdb[:, 0],
            'label': freq_label
        })

        freq_resolution = fs / N

        def hz_to_idx(freq_hz):
            return int(N / 2 + freq_hz / freq_resolution)

        # Compute SNR for all channels
        for i in range(data_channels):
            f_idx = np.argmax(Sdb[int(N / 2):, i])
            f_hz = f_idx * freq_resolution

            window_bandwidth = 8 * freq_resolution
            B_hz = max(window_bandwidth * 3, f_hz / 5)

            signal_power = 0

            low_start = hz_to_idx(10)
            low_end = hz_to_idx(f_hz - B_hz / 2)
            high_start = hz_to_idx(f_hz + B_hz / 2)
            harmonic_cutoff = hz_to_idx(2 * f_hz - B_hz / 2)

            low_freq_max = np.max(Sdb[low_start:low_end, i])
            low_freq_max_idx = low_start + np.argmax(Sdb[low_start:low_end, i])
            low_freq_max_hz = (low_freq_max_idx - N/2) * freq_resolution

            high_freq_with_harmonics = Sdb[high_start:, i]
            high_max_with_harm = np.max(high_freq_with_harmonics)
            high_max_with_harm_idx = high_start + np.argmax(high_freq_with_harmonics)
            high_max_with_harm_hz = (high_max_with_harm_idx - N/2) * freq_resolution

            high_freq_no_harmonics = Sdb[high_start:harmonic_cutoff, i]
            high_max_no_harm = np.max(high_freq_no_harmonics)
            high_max_no_harm_idx = high_start + np.argmax(high_freq_no_harmonics)
            high_max_no_harm_hz = (high_max_no_harm_idx - N/2) * freq_resolution

            noise_power_harmonic = max(low_freq_max, high_max_with_harm)
            noise_power = max(low_freq_max, high_max_no_harm)

            result_lines = [
                f"ADC {i+1}: f = {f_hz:.1f} Hz",
                f"  Low freq max: {low_freq_max:.1f} dB at {low_freq_max_hz:.1f} Hz",
                f"  High freq max (incl harmonics): {high_max_with_harm:.1f} dB at {high_max_with_harm_hz:.1f} Hz",
                f"  High freq max (excl harmonics): {high_max_no_harm:.1f} dB at {high_max_no_harm_hz:.1f} Hz",
                f"  SNR including harmonic noise: {signal_power - noise_power_harmonic:.2f} dB",
                f"  SNR excluding harmonic noise: {signal_power - noise_power:.2f} dB",
            ]
            for line in result_lines:
                print(line)
                results_file.write(line + "\n")
            print()
            results_file.write("\n")

        theoretical_snr = 20 * np.log10((np.sqrt(6) / 2) * (2**12) * (3.3 / 3.3))
        theoretical_line = f"Theoretical SNR max = {theoretical_snr}"
        print(theoretical_line)
        results_file.write(theoretical_line + "\n\n")

# Create combined signal plot
fig_signal, axes_signal = plt.subplots(num_files, 1, figsize=(10, 3.5 * num_files))
if num_files == 1:
    axes_signal = [axes_signal]

for idx, data in enumerate(all_time_data):
    ax = axes_signal[idx]
    ax.plot(data['time'], data['signal'])
    ax.set_title(f"Tidsvarierende signal med $f$ = {data['label']}:")
    ax.set_ylabel("Amplitude [V]")
    ax.set_xlabel("Tid [s]")
    ax.set_ylim(-2, 2)
    # Auto-scale x-axis to show ~5 periods
    freq_match = re.search(r'(\d+)\s*(Hz|kHz)', data['label'])
    if freq_match:
        freq_val = int(freq_match.group(1))
        if freq_match.group(2) == 'kHz':
            freq_val *= 1000
        x_max = 5 / freq_val
        ax.set_xlim(0, x_max)

fig_signal.tight_layout()
plt.savefig("images/signals.png", dpi=300, bbox_inches='tight')
plt.close(fig_signal)
print("\nSaved: images/signals.png")

# Create combined frequency plot
fig_freq, axes_freq = plt.subplots(num_files, 1, figsize=(10, 3.5 * num_files))
if num_files == 1:
    axes_freq = [axes_freq]

for idx, data in enumerate(all_freq_data):
    ax = axes_freq[idx]
    ax.plot(data['freq'], data['spectrum'])
    ax.set_title(f"Effekttetthetsspektrum $f$ = {data['label']}:")
    ax.set_ylabel("Effekt [dB]")
    ax.set_xlabel("Frekvens [Hz]")
    ax.set_xlim(10, 15000)
    ax.set_ylim(-120, 0)

fig_freq.tight_layout()
plt.savefig("images/frequency.png", dpi=300, bbox_inches='tight')
plt.close(fig_freq)
print("Saved: images/frequency.png")

print(f"\nResults written to: results.txt")
