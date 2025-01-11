import numpy as np
import matplotlib.pyplot as plt

# Load buffer_no_load.csv data
# First column is time in seconds, second column is input voltage, third column is output voltage
name = "buffer_load_source"
data = np.genfromtxt(f'../Data/{name}.csv', delimiter=',', skip_header=1)

# Convert time to milliseconds
data[:, 0] *= 1000

# Plot input and output voltage vs time (start at middle of data, and then plot 3000 points)
middle = len(data)//2
plot_end = len(data)
plt.plot(data[middle:plot_end, 0], data[middle:plot_end, 2], label='$v_2(t)$')
plt.plot(data[middle:plot_end, 0], data[middle:plot_end, 1], label='$v_0(t)$')

print(np.max(data[:, 1]))
print(np.max(data[:, 2]))

# Add labels and title
plt.title("$v_0(t)$ vs. $v_2(t)$ ved last $R_L = 220 \Omega$ og kilde motstand $R_K = 1.2$k$\Omega$")
plt.xlabel('Tid (ms)')
plt.ylabel('Spenning (V)')
plt.legend()
# plt.show()
plt.savefig(f'../Notat/Bilder/{name}.png')

