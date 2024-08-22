import numpy as np
import matplotlib.pyplot as plt

# Load the signal data from the file
file_path = 'output.txt'
signal = np.loadtxt(file_path)

# Sampling frequency
fs = 96000  # 96 kHz

# Compute the FFT of the signal
fft_result = np.fft.fft(signal)
fft_magnitude = np.abs(fft_result)

# Generate the frequency axis
n = len(signal)
frequencies = np.fft.fftfreq(n, d=1/fs)

# Plot the frequency spectrum
plt.figure(figsize=(12, 6))
plt.plot(frequencies[:n//2], fft_magnitude[:n//2])  # Plot only the positive frequencies
plt.xlabel('Frequency (Hz)')
plt.ylabel('Magnitude')
plt.title('Frequency Spectrum')
plt.grid(True)
plt.show()
