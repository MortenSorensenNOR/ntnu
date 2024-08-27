#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define GLM_ENABLE_EXPERIMENTAL
#include <glm/glm.hpp>
#include <glm/gtx/transform.hpp>

void printMatrix(glm::mat4& matrix) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++)
            printf("%f ", matrix[i][j]);
        printf("\n");
    }
    printf("\n");
}

int main() {
    glm::mat4 identity = glm::mat4(1.0f);
    printMatrix(identity);

    glm::mat4 view = glm::mat4(1.0f); // Identity matrix as a starting point
    view = glm::lookAt(
            glm::vec3(0.0f, 0.0f, -3.0f), // Camera position in world space
            glm::vec3(0.0f, 0.0f, 1.0f), // Looking at the origin
            glm::vec3(0.0f, 1.0f, 0.0f)  // Up vector
    );

    // Define the projection matrix (perspective projection)
    glm::mat4 projection = glm::mat4(1.0f); // Identity matrix as a starting point
    projection = glm::perspective(
            glm::radians(45.0f), // Field of view in radians
            320.0f / 240.0f,         // Aspect ratio
            0.1f,                // Near clipping plane
            100.0f               // Far clipping plane
    );

    printMatrix(view);
    printMatrix(projection);

    return 0;
}
