import numpy as np

model_matrix = np.array([
    [ 1.0,  0.0,  0.0, 0.0], 
    [ 0.0,  1.0,  0.0, 0.0], 
    [ 0.0,  0.0,  1.0, 0.0],
    [ 0.0,  0.0,  3.0, 1.0]
])

vector = np.array([-1.0, -1.0, -1.0, 1.0])

result = np.dot(model_matrix, vector)
print(result)
