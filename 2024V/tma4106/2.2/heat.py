import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

alpha = 0.5

def b_n(n):
    if n % 2 == 0:
        return 0
    return 8/(np.pi*n**3)

def u(x, t):
    global alpha

    s = 0
    for n in range(1, 1000):
        s += b_n(n) * np.exp(-alpha * n**2 * t) * np.sin(n*x)
    return s

def plot_u(t, ax):
    x = np.linspace(0, np.pi, 100)
    T = u(x, t)

    scatter = ax.plot(x, u(x, t), label=f"t = {'{:.2f}'.format(t)}")

fig, ax = plt.subplots()

for t in np.arange(0, 2.2, 0.2):
    plot_u(t, ax)

plt.legend()
# plt.show()

plt.savefig("plot.png", dpi=500)
