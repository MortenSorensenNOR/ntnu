import numpy as np

# v0 = 353.96e-3
# v1 = 334.64e-3
# R_prime = 1.208e3
#
# R_inn = v1 / (v0 - v1) * R_prime
# print(R_inn)

v_ut = 349.2
v_2 = 334.8
R_L = 220

R_ut = 220 * (v_ut / v_2 - 1)
print(R_ut)
