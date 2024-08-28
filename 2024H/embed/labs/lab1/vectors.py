import numpy as np
import matplotlib.pyplot as plt
import glm

display_width = 320
display_height = 240
near = 0.1
far = 100.0
fov = 45.0

# Define the matrices
model_matrix = glm.mat4(1.0)
model_matrix = glm.translate(model_matrix, glm.vec3(0, 0, -2.0))
model_matrix = glm.rotate(model_matrix, glm.radians(45), glm.vec3(0, 1, 0))

view_matrix = glm.lookAt(glm.vec3(0, 0, 6.5), glm.vec3(0, 0, 0), glm.vec3(0, 1, 0))
projection_matrix = glm.perspective(glm.radians(fov), display_width / display_height, near, far)

model_matrix = np.array(model_matrix)
view_matrix = np.array(view_matrix)
projection_matrix = np.array(projection_matrix)

# Combine the matrices
# mvp_matrix = projection_matrix @ view_matrix @ translation_matrix @ rotation_matrix
mvp_matrix = projection_matrix @ view_matrix @ model_matrix
mvp_matrix = np.array(mvp_matrix)

vertexes = [
    [ 1.0, -1.0, -1.0 ],
    [ 1.0, -1.0,  1.0 ],
    [-1.0, -1.0,  1.0 ],
    [-1.0, -1.0, -1.0 ],
    [ 1.0,  1.0, -1.0 ],
    [ 1.0,  1.0,  1.0 ],
    [-1.0,  1.0,  1.0 ],
    [-1.0,  1.0, -1.0 ],
]

indices = [
    1,3,0, 
    7,5,4, 
    4,1,0, 
    5,2,1, 
    2,7,3,
    0,7,4,
    1,2,3,
    7,6,5,
    4,5,1,
    5,6,2,
    2,6,7,
    0,3,7
]

screen_vertexes = []

for vertex in vertexes:
    # Define the vector
    vertex = np.array([vertex[0], vertex[1], vertex[2], 1])

    # Multiply the MVP matrix by the vector
    transformed_vertex = np.dot(mvp_matrix, vertex)

    print(vertex, transformed_vertex)

    # Perform perspective divide to get NDC coordinates
    ndc_vertex = transformed_vertex[:3] / transformed_vertex[3]

    # Perform viewport transform to get screen coordinates
    screen_dim = (display_width, display_height)
    screen_vertex = (ndc_vertex[:2] + 1) / 2 * screen_dim

    screen_vertexes.append(screen_vertex)

# Plot the lines between the screen coordinates based on the indices
for i in range(0, len(indices), 3):
    v0 = screen_vertexes[indices[i]]
    v1 = screen_vertexes[indices[i + 1]]
    v2 = screen_vertexes[indices[i + 2]]

    plt.plot([v0[0], v1[0]], [v0[1], v1[1]], 'b-')
    plt.plot([v1[0], v2[0]], [v1[1], v2[1]], 'b-')
    plt.plot([v2[0], v0[0]], [v2[1], v0[1]], 'b-') 

# Set min and max to the screen dimensions
plt.xlim([0, display_width])
plt.ylim([0, display_height])

# Write matricies to the same file without brackets and such
separator = np.full((1, model_matrix.shape[1]), np.nan)
combined = np.vstack((model_matrix, separator, view_matrix, separator, projection_matrix, separator, mvp_matrix))
np.savetxt('matrices.txt', combined, fmt='%f')

identity = glm.mat4(1.0)
print(glm.rotate(identity, glm.radians(45), glm.vec3(0, 1, 0)))
