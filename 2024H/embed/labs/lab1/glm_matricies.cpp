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

const int g_scWidth = 320;
const int g_scHeight = 240;

int main() {
    glm::mat4 identity = glm::mat4(1.0f);
    printMatrix(identity);

    glm::mat4 M0 = glm::translate(identity, glm::vec3(0, 0, 2.f));
    M0 = glm::rotate(M0, glm::radians(45.f), glm::vec3(0, 1, 0));
    printMatrix(M0);

    float nearPlane = 0.1f;
    float farPlane = 100.f;
    glm::vec3 eye(0, 3.75, 6.5);
    glm::vec3 lookat(0, 0, 0);
    glm::vec3 up(0, 1, 0);

    glm::mat4 view = glm::lookAt(eye, lookat, up);
    glm::mat4 proj = glm::perspective(glm::radians(60.f), (float)g_scWidth / (float)g_scHeight, nearPlane, farPlane);

    printMatrix(view);
    printMatrix(proj);

    return 0;
}
