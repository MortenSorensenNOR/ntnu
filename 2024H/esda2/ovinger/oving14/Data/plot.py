import numpy as np
import matplotlib.pyplot as plt

# Import file: 'kritisk_demping_sprang.csv'
# First column: time, second column: voltage in, third column: voltage out
data = np.loadtxt('Data/oppgave_2_sprang.csv', delimiter=',', skiprows=1)

# Extract time, voltage in and voltage out
index_max = len(data[:, 0]) - 1010
index_min = len(data[:, 0]) - 3500
time = data[index_min:index_max, 0]
voltage_in = data[index_min:index_max, 1]
voltage_out = data[index_min:index_max, 2]

index_start_step = np.argmax(voltage_in)
voltage_out[:index_start_step-1] = voltage_in[:index_start_step-1]

# Plot voltage in and voltage out
plt.title("Sprangrespons til RLC kretsen")
plt.plot(time, voltage_in, label='$v_{in}$')
plt.plot(time, voltage_out, label='$v_{ut}$')
plt.xlabel('Tid [s]')
plt.ylabel('Spenning [V]')
plt.legend()
# plt.show()
plt.savefig("Bilder/oppgave_2_sprang.png", dpi=300)

