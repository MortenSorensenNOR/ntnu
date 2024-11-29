import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import freqz

def get_amplitude_respons(coeff_file, fs):
    coefficients = np.loadtxt(coeff_file)
    w, h = freqz(coefficients, worN=16000)
    frequencies = w * fs / (2 * np.pi)
    return frequencies, h

fs = 96000
frequencies, h1 = get_amplitude_respons('../Data/coeffs/FIR_matlab_coeffs_96kHz.txt', fs)
h1 = 20 * np.log10(abs(h1))

f2600_index = np.argmin(np.abs(np.array([frequencies]) - 2600))
f5200_index = np.argmin(np.abs(np.array([frequencies]) - 5200))
f7800_index = np.argmin(np.abs(np.array([frequencies]) - 7800))

# Plot the magnitude response in decibels
plt.figure(figsize=(12, 6))

plt.scatter(2600, h1[f2600_index], color='brown', label="Frekvenskomponent ved f i $\hat{x}_2(t)$:" + f"  {h1[f2600_index]:.2f}dB", zorder=3)
plt.scatter(5200, h1[f5200_index], color='green', label="Frekvenskomponent ved 2f i $\hat{x}_2(t)$:" + f" {h1[f5200_index]:.2f}dB", zorder=3)   
plt.axvline(x=2600*2, color='r', linestyle='-.', linewidth=1, label='Ideell senterfrekens for filter - 2f', zorder=2)
plt.axvline(x=2600, color='b', linestyle='--', linewidth=2, label='Frekvens til inngangssignal $x_1(t)$ - $f$', zorder=2)
plt.plot(frequencies, h1, color='blue', zorder=1)

plt.xticks(np.arange(0, frequencies[-1], 2600))
plt.title('Amplituderesponsen til FIR filteret')
plt.xlabel('Frekvens (Hz)')
plt.ylabel('Magnitude (dB)')
plt.legend(loc="upper right")
plt.grid()

# Show the plots
plt.tight_layout()
plt.savefig("../Notat/Bilder/fir_filter_perf.png")
plt.show()
