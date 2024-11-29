import numpy as np
import matplotlib.pyplot as plt

def mat_unit_mul2x2(A):
    res = []
    for i in range(100):
        v = np.array([np.cos(2 * np.pi * i/100), np.sin(2 * np.pi * i/100)])
        res.append(np.dot(A, v))
    return np.array(res)

A = np.array([[1, 0], [0, 1]])
r = mat_unit_mul2x2(A)

plt.scatter(r[:,0], r[:,1])
plt.show()
