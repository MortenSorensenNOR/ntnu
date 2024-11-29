import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import norm

n = 20
a = 5
r_0 = 12.5

measured = np.array([7.98, 10.82, 15.88, 17.00, 24.22, 12.20, 8.17, 16.53, 7.46, 14.31, 34.55,
19.46, 20.21, 13.58, 10.98, 4.42, 24.92, 30.29, 23.45, 23.36])

print(norm.ppf(1 - 0.2))
