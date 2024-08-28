import numpy as np

# The size of the table is defined by the number of values
num_values = 20
x_vals = np.linspace(0, 2*np.pi, num_values)

# Compute cosine
cos_vals = np.cos(x_vals)

# Compute sine
sin_vals = np.sin(x_vals)

# Write values to file
with open('trig_table.txt', 'w') as f:
    for i in range(num_values):
        f.write(f'{cos_vals[i]:.2f}\n')
    f.write('\n')
    for i in range(num_values):
        f.write(f'{sin_vals[i]:.2f}\n')
