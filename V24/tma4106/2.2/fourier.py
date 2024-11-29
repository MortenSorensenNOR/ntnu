import numpy as np
import matplotlib.pyplot as plt

# def b_n(n):
#     if n % 2 == 0:
#         return 0
#     return 8/(np.pi * n**3)
#
# def part_sum(x):
#     part = 0
#     for n in range(1, 100):
#         part += b_n(n) * np.sin(n * x)
#     return np.array(part)

def test(x):
    s = 0
    for n in range(1, 1000000):
        s += 1/(2*n-1)**3 * np.sin((2*n-1)*x)
    return 8/np.pi * s

x = np.arange(0, 10, 0.5)
# plt.scatter(x, part_sum(x))
plt.plot(x, test(x))
plt.plot(x, x * (np.pi - x))
plt.show()
