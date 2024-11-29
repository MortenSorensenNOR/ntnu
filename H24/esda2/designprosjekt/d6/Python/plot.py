import numpy as np
import matplotlib.pyplot as plt

# Load buffer_no_load.csv data
# First column is time in seconds, second column is input voltage, third column is output voltage
file = "inverting_100k_signal"
data = np.genfromtxt(f'../Data/{file}.csv', delimiter=',', skip_header=1)

# Convert time to milliseconds
data[:, 0] *= 1000

# Plot input and output voltage vs time (start at middle of data, and then plot 3000 points)
middle = len(data)//2
plot_end = len(data)

t = data[middle:plot_end, 0]
in_data = data[middle:plot_end, 1]
out_data = data[middle:plot_end, 2]

in_data = in_data - np.mean(in_data)
out_data = out_data - np.mean(out_data)

plt.plot(t, in_data, label='$v^{+}(t)$')
plt.plot(t, out_data, label='$v_{out}(t)$')

# Add labels and title
plt.title(f'Inverterende forsterker, $A = 10$, $R_L = 100$k$\Omega$, $v^+ = {int(np.ceil(np.max(in_data)*1000))}$mV')
plt.xlabel('Tid (ms)')
plt.ylabel('Spenning (V)')
plt.legend(loc='upper right')
# plt.show()
plt.savefig(f'../Notat/Bilder/{file}.png')

