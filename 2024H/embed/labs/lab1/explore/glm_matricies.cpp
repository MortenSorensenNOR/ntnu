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
    float scale_factor = 0.004f;
    glm::mat4 scale = glm::scale(glm::vec3(scale_factor, scale_factor, scale_factor));
    glm::mat4 model = scale;

    printMatrix(model);

    float nearPlane = 0.1f;
    float farPlane = 100.f;
    glm::vec3 eye(0, 0, 3);
    glm::vec3 lookat(0, 0, -1);
    glm::vec3 up(0, 1, 0);

    glm::mat4 view = glm::lookAt(eye, lookat, up);

    float fov = 90.f;
    float aspect = 1.777778f;
    float zNear = 0.1f;
    float zFar = 100.f;
    glm::mat4 proj = glm::perspective(glm::radians(fov), aspect, zNear, zFar);

    printMatrix(view);
    printMatrix(proj);

    glm::mat4 mvp = proj * view * model;
    printMatrix(mvp);

    return 0;
}
