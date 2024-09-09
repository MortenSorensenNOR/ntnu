import numpy as np

NA = 2.5e17
ND = 1.2e24

phi = 0.5624
Vr = 1.1

Ks = 11.8
epsilon = 8.854e-12
q = 1.602e-19

xn = ((2 * Ks * epsilon * (phi + Vr))/q * (NA)/(ND * (NA + ND))) ** 0.5
xp = ((2 * Ks * epsilon * (phi + Vr))/q * (ND)/(NA * (NA + ND))) ** 0.5

# print(f"x_n: {xn}  x_p: {xp}")

val = 1.602e-19 * 2.7e7 
print(val)
