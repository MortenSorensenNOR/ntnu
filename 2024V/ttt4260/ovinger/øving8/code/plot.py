import numpy as np
import matplotlib.pyplot as plt

def c_k_x(k, a, V0):
    return a * V0 * np.sinc(a * k)

def c_k_y(k, a, V0):
    return np.abs(a * V0 * np.sinc(a * k)/np.sqrt(1 + k**2))

a = 0.2
V0 = 1

k = np.linspace(0, 10, 11)
c_vals_x = np.abs(c_k_x(k, a, V0))
c_vals_y = np.abs(c_k_y(k, a, V0))

plt.xlabel("k")
plt.ylabel("$|c_k^y|$")
plt.stem(k, c_vals_x, "b", label="$|c_k^x|$")
plt.stem(k, c_vals_y, "g", label="$|c_k^y|$")
plt.legend()
plt.savefig("../Bilder/2a.png")
