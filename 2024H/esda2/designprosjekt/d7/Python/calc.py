import numpy as np

A = 0.316
fb = 4.55e3
fc = 3.4125e3

n = np.ceil(0.5 * (np.log(0.316**(-2) - 1))/(np.log(fb/fc)))
print(n)
