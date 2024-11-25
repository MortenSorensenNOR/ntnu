import numpy as np
import matplotlib.pyplot as plt

# Read data from ../Data/total_system.csv
data = np.genfromtxt('../Data/total_system.csv', delimiter=',', skip_header=1)

# Extract time and signal
time = data[:, 0]
signal = data[:, 1]


# T does not start at 0
time = time - time[0]

# Limit t to 0.1s
time = time[time <= 0.04]
signal = signal[:len(time)]

# Plot signal
plt.plot(time, signal, label='y(t)')
plt.xlabel('Time (s)')
plt.ylabel('Spenning (V)')
plt.title('Støysignal')
plt.grid()
plt.legend()
# plt.show()

# Save plot to ../Figures/signal.png
plt.savefig('../Notat/Bilder/total_system_signal.png')
