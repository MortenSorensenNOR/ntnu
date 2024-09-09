import numpy as np
import matplotlib.pyplot as plt

# Load buffer_no_load.csv data
# First column is time in seconds, second column is input voltage, third column is output voltage
data = np.genfromtxt('../Data/buffer_load_and_source_res.csv', delimiter=',', skip_header=1)

# Convert time to milliseconds
data[:, 0] *= 1000

# Resenter the data around 0V (subtract 1.0V)
data[:, 1] -= 1.0
# data[:, 2] -= 1.0

# Plot input and output voltage vs time (start at middle of data, and then plot 3000 points)
middle = len(data)//2
plot_end = len(data)
plt.plot(data[middle:plot_end, 0], data[middle:plot_end, 1], label='$v_0(t)$')
plt.plot(data[middle:plot_end, 0], data[middle:plot_end, 2], label='$v_2(t)$')

# Add labels and title
plt.xlabel('Tid (ms)')
plt.ylabel('Spenning (V)')
plt.legend()
# plt.show()
plt.savefig('../Notat/Bilder/buffer_load_source_res.png')

