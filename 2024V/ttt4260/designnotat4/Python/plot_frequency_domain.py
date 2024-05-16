import numpy as np
import matplotlib.pyplot as plt

def plot_signal_spectrum_from_file(file_path, sampling_frequency):
    # Load voltage samples from file
    voltage_samples = np.loadtxt(file_path)
    
    # Number of samples
    N = len(voltage_samples)
    
    # Compute the FFT
    fft_values = np.fft.fft(voltage_samples)
    
    # Compute the double-sided spectrum
    double_sided_spectrum = np.abs(fft_values) / N
    
    # Compute the single-sided spectrum (for real signals)
    single_sided_spectrum = double_sided_spectrum[:N//2] * 2
    
    # Correct the DC and Nyquist component (if N is even)
    if N % 2 == 0:
        single_sided_spectrum[-1] = double_sided_spectrum[N//2]  # Only the Nyquist freq if N is even
    
    # Frequency axis
    freq = np.fft.fftfreq(N, d=1/sampling_frequency)[:N//2]

    single_sided_spectrum = single_sided_spectrum[:len(single_sided_spectrum)//4]
    freq = freq[:len(freq)//4]

    # Compute power spectrum (power at each frequency)
    power_spectrum = single_sided_spectrum ** 2
    
    # Define frequency bins of 100 Hz each
    bin_width = 2600
    freq_bins = np.arange(-1300, freq[-1], bin_width)
    power_bin_sums, bin_edges = np.histogram(freq, bins=freq_bins, weights=power_spectrum)
    
    # Adjust frequency labels to the center of each bin
    bin_centers = 0.5 * (bin_edges[:-1] + bin_edges[1:])
    
    # Identify the fundamental frequency index
    # Assuming the fundamental frequency is the highest peak in the binned spectrum
    fundamental_index = np.argmax(power_bin_sums)
    fundamental_frequency = bin_centers[fundamental_index]
    fundamental_power = power_bin_sums[fundamental_index]
    
    # Total power excluding the fundamental frequency
    total_power = np.sum(power_bin_sums)
    distortion_power = total_power - fundamental_power
    
    # Calculate Signal to Distortion Ratio (SDR)
    SDR = 10 * np.log10(fundamental_power / distortion_power)
    
    print(f"Fundamental Frequency: {fundamental_frequency} Hz")
    print(f"Fundamental frequency power: {fundamental_power} Total power: {total_power}")
    print(f"Signal to Distortion Ratio (SDR): {SDR:.2f} dB")

    # Plotting
    plt.figure(figsize=(14, 6))
    
    plt.subplot(1, 2, 1)
    plt.bar(bin_centers, 20 * np.log10(power_bin_sums / np.sqrt(2)), width=bin_width)
    plt.title('Spectrum in dBV (Binned)')
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Magnitude (dBV)')
    plt.grid(True)

    plt.xticks(np.arange(0, freq[-1], 2600))
    
    plt.subplot(1, 2, 2)
    plt.bar(bin_centers, power_bin_sums / np.sqrt(2), width=bin_width)
    plt.title('Spectrum in V-RMS (Binned)')
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Magnitude (Vrms)')
    plt.grid(True)

    plt.xticks(np.arange(0, freq[-1], 2600))
    
    plt.tight_layout()
    plt.show()
    
# Specify the file path and sampling frequency
file_path = './output.txt'
sampling_frequency = 500000  # Sampling frequency in Hz

# Call the function
plot_signal_spectrum_from_file(file_path, sampling_frequency)
