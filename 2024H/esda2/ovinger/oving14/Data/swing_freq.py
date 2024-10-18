import numpy as np
import matplotlib.pyplot as plt

# Import file: 'under_kritisk_demping_sprang.csv'
# First column: time, second column: voltage in, third column: voltage out
data = np.loadtxt('Data/under_kritisk_demping_sprang.csv', delimiter=',', skiprows=1)

# Extract time, voltage in and voltage out
index_max = len(data[:, 0]) - 750
time = data[:index_max, 0]
voltage_in = data[:index_max, 1]
voltage_out = data[:index_max, 2]

index_start_step = np.argmax(voltage_in)

# Extract time and voltage for the swing
time_swing = time[index_start_step:]
voltage_swing = voltage_out[index_start_step:]

# Find the frequency of the swing using fft
N = len(time_swing)
dt = time_swing[1] - time_swing[0]

# Compute the FFT of the signal
X = np.fft.fft(voltage_swing)

# Compute the corresponding frequencies
freqs = np.fft.fftfreq(len(voltage_swing), dt)

# Compute the magnitude of the FFT (frequency spectrum)
X_mag = np.abs(X) / len(voltage_swing)

# Plot only the positive frequencies as well as the first 5 kHz
index_5kHz = np.where(freqs > 1000)[0][0]

# Draw line at second highest peak
index_max = np.argmax(X_mag[1:index_5kHz])
index_max += 1

plt.axvline(freqs[index_max], color='r', linestyle='--', label='Ossileringsfrekvens $f_0 = ${:.2f} Hz'.format(freqs[index_max]))

plt.plot(freqs[:index_5kHz], X_mag[:index_5kHz])
plt.title("Frekvensspekter av svingning")
plt.xlabel("Frekvens [Hz]")
plt.ylabel("Magnitude")
plt.grid()
plt.legend(loc='upper right')
plt.show()
# plt.savefig("Bilder/frekvensspekter_svingning.png", dpi=300)
