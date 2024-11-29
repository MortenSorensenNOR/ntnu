import numpy as np

# The size of the table is defined by the number of values
num_values = 100
x_vals = np.linspace(0, 2*np.pi, num_values)

# Compute cosine
cos_vals = np.cos(x_vals)

# Compute sine
sin_vals = np.sin(x_vals)

# Write values to file
with open('trig_table.txt', 'w') as f:
    for i in range(0, num_values, 4):
        f.write(f'.float {cos_vals[i]:.2f}, {cos_vals[i+1]:.2f}, {cos_vals[i+2]:.2f}, {cos_vals[i+3]:.2f}\n')
    f.write('\n')
    for i in range(0, num_values, 4):
        f.write(f'.float {sin_vals[i]:.2f}, {sin_vals[i+1]:.2f}, {sin_vals[i+2]:.2f}, {sin_vals[i+3]:.2f}\n')
