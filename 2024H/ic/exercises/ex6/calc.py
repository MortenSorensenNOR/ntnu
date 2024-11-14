import numpy as np

VDD = 1.2
Vtn = 0.45
Vtp = 0.45

L = 45e-9
W_n = L
W_p = 4 * W_n

Beta_n = 280 * 1e-3 * (W_n)/L
Beta_p = 70  * 1e-3 * (W_p)/L
print(f"Beta_n = {Beta_n}")
print(f"Beta_p = {Beta_p}")

R_n = 1/(Beta_n * (VDD - Vtn))
R_p = 1/(Beta_p * (VDD - Vtp))

print(f"R_n = {R_n} Ohm")
print(f"R_p = {R_p} Ohm")

t_f = 2.2 * R_n * 5 * 1e-15
t_r = 2.2 * R_p * 5 * 1e-15

print(f"t_f = {t_f} s")
print(f"t_r = {t_r} s")

f_max = 1/(t_f + t_r)
print(f"f_max = {f_max:.2E} Hz")
