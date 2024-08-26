#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define WIDTH 320
#define HEIGHT 240

// Frame buffer
unsigned char frame_buffer[WIDTH * HEIGHT];

// Write framebuffer to file with newline
void write_frame_buffer(const char *filename) {
    FILE *file = fopen(filename, "w");
    for (int i = 0; i < WIDTH * HEIGHT; i++) {
        fprintf(file, "%d", frame_buffer[i]);
        if (i % WIDTH == WIDTH - 1) {
            fprintf(file, "\n");
        }
    }
}

void bresenham(int x0, int y0, int x1, int y1) {
    int dx = abs(x1 - x0);
    int dy = -abs(y1 - y0);
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;

    int err = dx + dy;
    int e2;

    for (;;) {
        frame_buffer[y0 * WIDTH + x0] = 1;
        if (x0 == x1 && y0 == y1) {
            break;
        }
        e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x0 += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y0 += sy;
        }
    }

}


int main() {
    // Clear frame buffer
    memset(frame_buffer, 0, WIDTH * HEIGHT);

    // Draw line
    int x0 = 0;
    int y0 = 0;
    int x1 = WIDTH - 1;
    int y1 = HEIGHT - 1;

    // Bresenham's line algorithm
    bresenham(x0, y0, x1, y1);

    write_frame_buffer("output");

    return 0;
}
