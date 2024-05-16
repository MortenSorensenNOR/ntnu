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
coeffs = np.loadtxt("../Data/coeffs/FIR_matlab_coeffs_500kHz_1000order.txt")

# Load the audio file
data = pd.read_csv("../Data/ulin_signal_500kHz.csv", skiprows=0)
data_vals = np.array(data["Channel 2 (V)"])
data_t = np.array(data["Time (s)"])
print(data_t)

# Apply the FIR filter a convolve function
filtered_data = fir_convolve(data_vals, coeffs)
# filtered_data = filtered_data[1500:]
#
# filtered_data = np.array(filtered_data * 32767, dtype=np.int16)
# wavfile.write("output.wav", 50000, filtered_data)

# np.savetxt("output.txt", filtered_data[1100:])

plt.plot(data_t[4000:4800], data_vals[4000:4800])
plt.plot(data_t[4000:4800], filtered_data[4000:4800])
plt.show()
