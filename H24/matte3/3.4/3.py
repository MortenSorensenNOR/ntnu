import cupy as cu
import numpy as np
import matplotlib.pyplot as plt

A1 = np.array([[2, 1], [1, 2]])
A2 = np.array([[1, -2], [-2, 1]])
A3 = np.array([[-1, 0], [0, -1]])
A4 = np.array([[0, 1], [-1, 0]])
A5 = np.array([[-1, -1], [1, -1]])
A6 = np.array([[0, 1], [-1, 2]])

A = A3

def f(x):
    return A @ x

x_values = np.linspace(-2, 2, 10)
y_values = np.linspace(-2, 2, 10)
X, Y = np.meshgrid(x_values, y_values)
U = np.zeros(X.shape)
V = np.zeros(Y.shape)

for i in range(len(x_values)):
    for j in range(len(y_values)):
        vector = np.array([X[i, j], Y[i, j]])
        transformed_vector = f(vector)
        U[i, j] = transformed_vector[0]
        V[i, j] = transformed_vector[1]

plt.quiver(X, Y, U, V, color="blue", angles="xy", scale_units="xy", scale=1)

eigenvalues, eigenvectors = np.linalg.eig(A)

for i in range(len(eigenvalues)):
    eig_vec = eigenvectors[:, i]
    
    # Extract real parts of the eigenvector
    eig_vec_real = eig_vec.real
    
    # Plot the real part of the eigenvectors as quivers
    origin = np.array([[0, 0], [0, 0]])  # origin point for the eigenvectors
    plt.quiver(origin[0, 0], origin[1, 0], eig_vec_real[0], eig_vec_real[1], 
               color="red", angles="xy", scale_units="xy", scale=1, width=0.02, 
               label=f'Eigenvector {i+1} (Real)')

plt.xlim((-5, 5))
plt.ylim((-5, 5))
plt.show()
