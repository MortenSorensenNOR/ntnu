import numpy as np


A = np.array([[2, 1, 1], [1, 2, 1], [1, 1, 2]])

V = [A.T[0]]
for col in A.T[1:]:
    v = col
    for v_k in V:
        v = v - np.dot((np.dot(v_k.T, col))/(np.dot(v_k.T, v_k)), v_k)
    V.append(v)

V = np.array(V).T
print(V)

P = []
for col in V.T:
    P.append(col / np.linalg.norm(col))
P = np.array(P).T

L = np.array([[4, 0, 0], [0, 1, 0], [0, 0, 1]])
print(np.dot(np.dot(P, L), P.T))
