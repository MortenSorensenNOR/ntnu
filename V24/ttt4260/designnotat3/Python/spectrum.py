import numpy as np
import matplotlib.pyplot as plt
from scipy.io import wavfile
from scipy.fft import fft

def plot_frequency_spectrum(wav_file):
    sample_rate, data = wavfile.read(wav_file)
    if len(data.shape) > 1:
        data = data[:,0]

    n = len(data)
    audio_fft = fft(data)
    frequencies = np.linspace(0, sample_rate, n)
    magnitude = np.abs(audio_fft)[:n // 2] * 2 / n

    # plt.figure(figsize=(12, 6))
    # plt.plot(frequencies[:n // 16], magnitude[:n//16])  # Plot only the first half of frequencies
    # plt.xlabel('Frequency (Hz)')
    # plt.ylabel('Magnitude')
    # plt.title('Frequency Spectrum')
    # plt.grid(True)
    # plt.savefig("Lydsignal_82.png")

# Replace 'your_audio_file.wav' with the path to your WAV file
plot_frequency_spectrum('Lydsignal_82.wav')
