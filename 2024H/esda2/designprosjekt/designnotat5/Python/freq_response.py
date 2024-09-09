import numpy as np
import matplotlib.pyplot as plt

# Load buffer_frekvens_respons.csv
# First column is frequency in Hz, second column is input signal magnitude in dB, third column is output signal magnitude in dB, fourth column is phase shift in degrees
data = np.genfromtxt('../Data/buffer_frekvens_respons.csv', delimiter=',', skip_header=1)

# Plot input and output signal magnitude vs frequency
plt.plot(data[:, 0], data[:, 1], label='$|v_0(f)|$')
plt.plot(data[:, 0], data[:, 2], label='$|v_2(f)|$')

# Find the frequency at which |v_2(f)| is -3dB and plot a vertical line and place a red dot at the intersection
# betwen the line and the curve for |v_2(f)| with a label indicating the frequency
freq_3db = data[np.argmin(np.abs(data[:, 2]+3)), 0]
plt.axvline(freq_3db, color='r', linestyle='--')
plt.plot(freq_3db, -3, 'ro', label=f"$f_0 = {freq_3db:.2f}$ Hz")

# Add labels and title
plt.xlabel('Frekvens (Hz)')
plt.ylabel('Magnitude (dB)')
plt.xscale('log')
plt.legend()

# plt.show()
plt.savefig('../Notat/Bilder/buffer_frekvens_respons.png')

