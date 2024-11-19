import numpy as np
import matplotlib.pyplot as plt

# Read in v_vals.txt
# Format: time, val
v_vals = np.loadtxt('v_vals.txt', delimiter=',', skiprows=0)

time = v_vals[:,0]
val = v_vals[:,1]

# Calculate the frequency of the signal
freq = np.fft.fftfreq(len(time), time[1] - time[0])
fft_vals = np.fft.fft(val)

# Plot the frequency spectrum for only the positive frequencies
plt.plot(freq[1:len(freq)//2], np.abs(fft_vals[1:len(freq)//2]))
plt.xlabel('Frequency (Hz)')
plt.ylabel('Magnitude')
plt.title('Frequency Spectrum of Signal')
plt.show()
