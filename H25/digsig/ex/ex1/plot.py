import numpy as np
import matplotlib.pyplot as plt

t = np.arange(0, 5)
x = np.where((t>=0)&(t<=2), t+1, 0)

h1 = np.array([1, 1, 1])
h2 = 0.9 ** np.arange(0, 11)

y1 = np.convolve(x, h2, mode="full")
y2 = np.convolve(y1, h1, mode="full")

# Plot
plt.figure(figsize=(14,4))

plt.subplot(1, 2, 1)
plt.title(r"$y_1[n]$")
plt.stem(y1, basefmt=" ")
plt.xticks(np.arange(0, y1.shape[0]))

plt.subplot(1, 2, 2)
plt.title(r"$y_2[n]$")
plt.stem(y2, basefmt=" ")
plt.xticks(np.arange(0, y2.shape[0]))

# plt.show()
plt.savefig("Bilder/5d.png", dpi=300)
