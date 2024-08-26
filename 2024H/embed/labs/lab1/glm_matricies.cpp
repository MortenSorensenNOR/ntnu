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

    glm::mat4 projection = glm::perspective(glm::radians(45.0f), // Field of view
                                            320.0f / 240.0f,     // Aspect ratio
                                            0.1f,                // Near plane
                                            100.0f);              // Far plane
    printMatrix(projection);

    return 0;
}
