import numpy as np
import matplotlib.pyplot as plt

def b_n(n):
    return 4/(n**2 * np.pi)

# def part_sum(x):
#     part = 1/2
#     for n in range(1, 10000):
#         part += b_n(n) * np.sin(n * x)
#     return np.array(part)

def test(x, num):
    s = np.pi/2
    for n in range(1, num):
        s += b_n(n) * np.cos(n*x)
    return s

x = np.arange(-np.pi, np.pi, 0.001)
# plt.scatter(x, part_sum(x))
plt.plot(x, test(x,5))
plt.plot(x, test(x,25))
plt.plot(x, test(x,5000))
plt.plot(x, test(x, 50000))
# plt.plot(x, x * (np.pi - x))
plt.show()
