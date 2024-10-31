import numpy as np

A = 0.316
fb = 4.55e3
fc = 3.4125e3

n = np.ceil(0.5 * (np.log(0.316**(-2) - 1))/(np.log(fb/fc)))

zeta_1 = np.cos(np.pi / (2 * n) + (1-1) * np.pi/n)
zeta_2 = np.cos(np.pi / (2 * n) + (2-1) * np.pi/n)

omega_0 = 2*np.pi * fc

R = 10e3
tau_1 = 1/(omega_0 * zeta_1)
tau_2 = 1/(omega_0**2 * tau_1)

C_1 = tau_1 / R
C_2 = tau_2 / R
print("Sallen-Key 1.:")
print(C_1, C_2)

tau_1 = 1/(omega_0 * zeta_2)
tau_2 = 1/(omega_0**2 * tau_1)

C_1 = tau_1 / R
C_2 = tau_2 / R
print("Sallen-Key 2.:")
print(C_1, C_2)
