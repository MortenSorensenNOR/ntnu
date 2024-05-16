import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import freqz

def get_amplitude_respons(coeff_file):
    coefficients = np.loadtxt(coeff_file)
    fs = 50000
    w, h = freqz(coefficients, worN=16000)
    frequencies = w * fs / (2 * np.pi)
    return frequencies, h

frequencies, h1 = get_amplitude_respons('../Data/coeffs/FIR_matlab_coeffs.txt')

# Plot the magnitude response in decibels
plt.figure(figsize=(12, 6))
plt.plot(frequencies, 20 * np.log10(abs(h1)), color='blue')
plt.title('Frekvensresponsen til FIR filteret')
plt.xlabel('Frekvens (Hz)')
plt.ylabel('Magnitude (dB)')
plt.grid()

# Show the plots
plt.tight_layout()
# plt.savefig("../Notat/Bilder/fir_filter_perf_175.png")
plt.show()
