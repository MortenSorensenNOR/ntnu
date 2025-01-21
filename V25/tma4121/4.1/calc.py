import numpy as np

d = np.array([1, 2, 3]).T
J = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]]).T

print(d)
print()
print(J)
print()

print(np.cross(d.T, J))
print()

print(np.array([2 * 3 - 3 * 2, 3 * 1 - 1 * 3, 1 * 2 - 2 * 1]))
print(np.array([2 * 6 - 3 * 5, 3 * 4 - 1 * 6, 1 * 5 - 2 * 4]))
print()

