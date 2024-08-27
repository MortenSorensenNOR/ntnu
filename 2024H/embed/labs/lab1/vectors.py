import numpy as np

# Define the matrices
rotation_matrix = np.array([
    [1.0, 0.0, 0.0, 0.0],
    [0.0, 1.0, 0.0, 0.0],
    [0.0, 0.0, 1.0, 0.0],
    [0.0, 0.0, 0.0, 1.0]
])

translation_matrix = np.array([
    [1.0, 0.0, 0.0, 0.0],
    [0.0, 1.0, 0.0, 0.0],
    [0.0, 0.0, 1.0, 0.0],
    [0.0, 0.0, 0.0, 1.0]
])

view_matrix = np.array([
    [ 0.707107, -0.408248,  0.577350, 0.000000],
    [ 0.000000,  0.816497,  0.577350, 0.000000],
    [-0.707107, -0.408248,  0.577350, 0.000000],
    [-0.000000, -0.000000, -5.196152, 1.000000]
])

projection_matrix = np.array([
    [1.810660, 0.000000,  0.000000,  0.000000],
    [0.000000, 2.414213,  0.000000,  0.000000],
    [0.000000, 0.000000, -1.002002, -1.000000],
    [0.000000, 0.000000, -0.200200,  0.000000]
])

# Combine the matrices
# mvp_matrix = projection_matrix @ view_matrix @ translation_matrix @ rotation_matrix
mvp_matrix = projection_matrix @ view_matrix @ translation_matrix @ rotation_matrix

# Print the resulting matrix
print("MVP Matrix:")
print(mvp_matrix)

# Define the vector
vertex = np.array([1.0, 1.0, 1.0, 1.0])

# Multiply the MVP matrix by the vector
transformed_vertex = mvp_matrix @ vertex

# Print the transformed vertex
print("\nTransformed Vertex:")
print(transformed_vertex)

# Perform perspective divide to get NDC coordinates
ndc_vertex = transformed_vertex[:3] / transformed_vertex[3]

print("\nNDC Coordinates:")
print(ndc_vertex)

