import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.io import wavfile

def fir_convolve(signal, kernel):
    kernel_size = len(kernel)

    output = np.zeros_like(signal)
    shift = np.zeros(kernel_size) 

    for i in range(len(signal)):
        shift = np.concatenate((np.array([signal[i]]), np.array(shift[0:kernel_size-1])))
        products = shift * kernel
        output[i] = np.sum(products)
    
    return output

# Load filter coefficients
coeffs = np.loadtxt("../Data/coeffs/FIR_matlab_coeffs_96kHz.txt")
# coeffs = np.loadtxt("../Data/coeffs/FIR_matlab_coeffs_500kHz_1000order.txt")

# Load the audio file
data = pd.read_csv("../Data/ulin_signal_96khz.csv", skiprows=0)
# data = pd.read_csv("../Data/ulin_signal_500kHz.csv", skiprows=0)
orig_vals = np.array(data["Channel 1 (V)"])
data_vals = np.array(data["Channel 2 (V)"])
data_t = np.array(data["Time (s)"])
print(data_t)

# Apply the FIR filter a convolve function
filtered_data = fir_convolve(data_vals, coeffs)
filtered_data = filtered_data[1500:]

# filtered_data = np.array(filtered_data * 32767, dtype=np.int16)
# wavfile.write("output.wav", 96000, filtered_data)
#
np.savetxt("output.txt", np.array(filtered_data[1100:]))

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 6))

ax1.plot(data_t[4100:4200], orig_vals[4100:4200], label="Inngangssignal $x_1(t)$")
ax2.plot(data_t[4100:4200], filtered_data[4100:4200], label="Resultat etter FIR filter $\hat{x}_2(t)$", color="orange")

fig.suptitle("Sammenligning av inngangssignal $x_1(t)$ og utgangssignal $\hat{x}_2(t)$")
ax1.legend(loc="upper right")
ax2.legend(loc="upper right")

ax1.set_xlabel("Tid [s]")
ax2.set_xlabel("Tid [s]")
ax1.set_ylabel("Amplitude [V]")
ax2.set_ylabel("Amplitude [V]")

fig.tight_layout()
plt.show()
# plt.savefig("../Notat/Bilder/fir_result_signal.png")
