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

    # Compute power spectrum (power at each frequency)
    power_spectrum = single_sided_spectrum ** 2
    
    # Identify the fundamental frequency index
    # Assuming the fundamental frequency is the highest peak in the spectrum
    fundamental_index = np.argmax(power_spectrum)
    fundamental_frequency = freq[fundamental_index]
    fundamental_power = power_spectrum[fundamental_index]
    
    # Total power excluding the fundamental frequency
    total_power = np.sum(power_spectrum)
    distortion_power = total_power - fundamental_power
    
    # Calculate Signal to Distortion Ratio (SDR)
    SDR = 10 * np.log10(fundamental_power / distortion_power)
    
    print(f"Fundamental Frequency: {fundamental_frequency} Hz")
    print(f"Signal to Distortion Ratio (SDR): {SDR:.2f} dB")

    single_sided_spectrum = single_sided_spectrum[:int(len(single_sided_spectrum)//4)]
    freq = freq[:int(len(freq)//4)]

    f2600_index = np.argmin(np.abs(np.array([freq]) - 2600))
    f5200_index = np.argmin(np.abs(np.array([freq]) - 5200))

    # Convert to dBV (20*log10(Vrms/1V))
    spectrum_dBV = 20 * np.log10(single_sided_spectrum / np.sqrt(2))
    
    # Convert to Vrms (already in Vrms because we use the single-sided spectrum)
    spectrum_Vrms = single_sided_spectrum / np.sqrt(2)
    
    # Plotting
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 6))
    
    ax1.plot(freq, spectrum_dBV)
    ax1.set_title('Spektrum i dBV')
    ax1.set_xlabel('Frekvens [Hz]')
    ax1.set_ylabel('Magnitude [dBV]')
    ax1.grid(True)
    ax1.scatter(2600, spectrum_dBV[f2600_index], color='brown', label="Frekvenskomponent ved f i $\hat{x}_2(t)$:" + f"  {spectrum_dBV[f2600_index]:.2f}dBV")
    ax1.scatter(5200, spectrum_dBV[f5200_index], color='green', label="Frekvenskomponent ved 2f i $\hat{x}_2(t)$:" + f" {spectrum_dBV[f5200_index]:.2f}dBV")   
    
    ax1.set_xticks(np.arange(0, freq[-1], 2600))
    ax1.legend(loc="upper right")
    
    ax2.plot(freq, spectrum_Vrms)
    ax2.set_title('Spektrum i V-RMS')
    ax2.set_xlabel('Frekvens [Hz]')
    ax2.set_ylabel('Magnitude [Vrms]')
    ax2.grid(True)
    
    ax2.set_xticks(np.arange(0, freq[-1], 2600))
    ax2.legend(loc="upper right")
    
    fig.tight_layout()
    plt.savefig("../Notat/Bilder/fir_result_spectrum.png")
    # plt.show()

# Specify the file path and sampling frequency
file_path = './output.txt'
sampling_frequency = 96000  # Sampling frequency in Hz

# Call the function
plot_signal_spectrum_from_file(file_path, sampling_frequency)
