import numpy as np
import matplotlib.pyplot as plt

a = 1.2

def f(q, p):
    return np.array([p, -np.sin(q)])

def f_med_luft(q, p):
    return np.array([p, -np.sin(q) - a * p * np.abs(p)])

x_vals = np.linspace(-1, 1, 10)
y_vals = np.linspace(-1, 1, 10)
X, Y = np.meshgrid(x_vals, y_vals)
U1, V1 = np.zeros(X.shape), np.zeros(Y.shape)
U2, V2 = np.zeros(X.shape), np.zeros(Y.shape)

for i in range(x_vals.size):
    for j in range(y_vals.size):
        vec = f(X[i, j], Y[i, j])
        U1[i, j], V1[i, j] = vec
        vec = f_med_luft(X[i, j], Y[i, j])
        U2[i, j], V2[i, j] = vec

plt.quiver(X, Y, U1, V1, color="blue", angles="xy", scale_units="xy", scale=1)
plt.quiver(X, Y, U2, V2, color="red", angles="xy", scale_units="xy", scale=1)

plt.xlim((-1.75, 1.75))
plt.ylim((-1.75, 1.75))
plt.show()

