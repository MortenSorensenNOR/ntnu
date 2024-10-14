import numpy as np

I_bias = 149.25e-6
V_T = 25.85e-3
h_oe = 60e-6

A = (I_bias / V_T) * 1 / h_oe
print(f"A = {A:.2f}")
