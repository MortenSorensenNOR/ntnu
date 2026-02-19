from raspi_import import raspi_import
import matplotlib.pyplot as plt
import numpy as np
import sys

# Get filename from command line argument, default to 'foo.bin'
filename = sys.argv[1] if len(sys.argv) > 1 else 'foo.bin'

sample_period, data = raspi_import(filename)  # converting binary file to array

data -= (2**12 - 1) / 2  # subtracting offset
data = data * (3.3 / ((2**12) - 1))  # scaling y-axis to Volt

data_length = data.shape[0]  # getting the length of samples
data_channels = data.shape[1]  # getting amount of channels

n = np.arange(data_length)  # making a list with same length as data
time = n * sample_period  # scaling x-axis to time in seconds

w = np.sin(np.pi * n / data_length) ** 2  # hanning window function

fig, ax = plt.subplots(data_channels, 1)  # setting up figure for time series
fig.tight_layout(pad=0.5)

for i in range(data_channels):  # Plotting data channel i
    ax[i].plot(time, data[:, i])
    ax[i].set_title(f"ADC {i + 1}:")
    ax[i].set_xlim(0, 0.05)
    ax[i].set_ylim(-2, 2)
    ax[i].set_ylabel("Amplitude [V]")
    ax[i].set_xlabel("Tid [s]")
plt.show()

N = 2**15  # setting FFT length to closest 2 power of data_length

Sdb = np.zeros((N, data_channels))  # making empty array for fft values

fs = int(1 / sample_period)  # sampling frequency
df = np.linspace(-0.5, 0.5, N) * fs  # making scaled frequency axis

fig1, ax1 = plt.subplots(data_channels, 1)  # setting up figure for PSD
fig1.tight_layout(pad=0.5)

for i in range(data_channels):
    data[:, i] = w * data[:, i]  # using hanning window on channel i

    fft = abs(np.fft.fft(data[:, i], N))  # taking fft
    fft = abs(np.fft.fftshift(fft))  # shifting spectrum

    Sdb[:, i] = 20 * np.log10(fft / max(fft))  # dB scale and normalising

    ax1[i].plot(df, Sdb[:, i])
    ax1[i].set_title(f"ADC {i + 1}:")
    ax1[i].set_xlim(10, 15000)
    ax1[i].set_ylim(-120,)
    ax1[i].set_ylabel("Effekt [dB]")
    ax1[i].set_xlabel("Frekvens [Hz]")
    # Linear frequency scale (removed log scale)
plt.show()

freq_resolution = fs / N  # Hz per bin

for i in range(data_channels):
    # Find peak in positive frequencies
    f_idx = np.argmax(Sdb[int(N / 2):, i])  # index relative to N/2
    f_hz = f_idx * freq_resolution  # actual frequency in Hz
    print(f"ADC {i+1}: f = {f_hz:.1f} Hz")

    # Hanning window main lobe width is ~4 bins on each side
    # Use the larger of: window main lobe or 10% of signal frequency
    window_bandwidth = 8 * freq_resolution  # ~8 bins for Hanning window main lobe
    B_hz = max(window_bandwidth * 3, f_hz / 5)  # exclude ~24 bins to clear Hanning sidelobes

    signal_power = 0  # normalized to 0 dB

    # Convert frequencies to absolute indices
    def hz_to_idx(freq_hz):
        return int(N / 2 + freq_hz / freq_resolution)

    # Frequency ranges for noise measurement
    low_start = hz_to_idx(10)  # start at 10 Hz
    low_end = hz_to_idx(f_hz - B_hz / 2)  # end before signal
    high_start = hz_to_idx(f_hz + B_hz / 2)  # start after signal
    harmonic_cutoff = hz_to_idx(2 * f_hz - B_hz / 2)  # stop before 2nd harmonic

    # Find max noise in low frequency region
    low_freq_max = np.max(Sdb[low_start:low_end, i])
    low_freq_max_idx = low_start + np.argmax(Sdb[low_start:low_end, i])
    low_freq_max_hz = (low_freq_max_idx - N/2) * freq_resolution

    # Including harmonics: look from high_start to end
    high_freq_with_harmonics = Sdb[high_start:, i]
    high_max_with_harm = np.max(high_freq_with_harmonics)
    high_max_with_harm_idx = high_start + np.argmax(high_freq_with_harmonics)
    high_max_with_harm_hz = (high_max_with_harm_idx - N/2) * freq_resolution

    # Excluding harmonics: look from high_start to harmonic_cutoff
    high_freq_no_harmonics = Sdb[high_start:harmonic_cutoff, i]
    high_max_no_harm = np.max(high_freq_no_harmonics)
    high_max_no_harm_idx = high_start + np.argmax(high_freq_no_harmonics)
    high_max_no_harm_hz = (high_max_no_harm_idx - N/2) * freq_resolution

    # SNR with harmonics
    noise_power_harmonic = max(low_freq_max, high_max_with_harm)
    # SNR without harmonics
    noise_power = max(low_freq_max, high_max_no_harm)

    print(f"  Low freq max: {low_freq_max:.1f} dB at {low_freq_max_hz:.1f} Hz")
    print(f"  High freq max (incl harmonics): {high_max_with_harm:.1f} dB at {high_max_with_harm_hz:.1f} Hz")
    print(f"  High freq max (excl harmonics): {high_max_no_harm:.1f} dB at {high_max_no_harm_hz:.1f} Hz")
    print(f"  SNR including harmonic noise: {signal_power - noise_power_harmonic:.2f} dB")
    print(f"  SNR excluding harmonic noise: {signal_power - noise_power:.2f} dB")
    print()

print("Theoretical SNR max =", 20 * np.log10((np.sqrt(6) / 2) * (2**12) * (3.3 / 3.3)))
