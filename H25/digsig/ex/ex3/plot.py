import numpy as np
import matplotlib.pyplot as plt

N = 10
M = 10

omega   = np.linspace(-np.pi, np.pi, 1000)
X_omega = 2 + 2 * np.cos(omega)
Y_omega = np.sin(omega * (M + 0.5))/np.sin(omega/2)

# Plot
plt.figure(figsize=(14,4))

plt.title(r"$X(\omega)$")
plt.plot(omega, Y_omega)
plt.xticks(np.linspace(-np.pi, np.pi, 10))

# plt.subplot(1, 2, 1)
# plt.title(r"$c_k(\omega)$")
# plt.stem(omega, c_k, basefmt=" ")
# plt.xticks(omega)

# plt.subplot(1, 2, 2)
# plt.title(r"$y_2[n]$")
# plt.stem(y2, basefmt=" ")
# plt.xticks(np.arange(0, y2.shape[0]))

# plt.show()
plt.savefig("Bilder/1b.png", dpi=300)
