#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <string.h>

int main() {
    int fb_fd = open("/dev/fb0", O_RDONLY);
    if (fb_fd == -1) {
        perror("Error: cannot open framebuffer device");
        exit(1);
    }

    struct fb_fix_screeninfo screen_info_fixed = {0};
    if (ioctl(fb_fd, FBIOGET_FSCREENINFO, &screen_info_fixed) == -1) {
        perror("Error reading fixed screen information");
        close(fb_fd);
        return 1;
    }

    struct fb_var_screeninfo screen_info_var = {0};
    if (ioctl(fb_fd, FBIOGET_VSCREENINFO, &screen_info_var) == -1) {
        perror("Error reading varible screen information");
        close(fb_fd);
        return 1;
    }

    // Map the framebuffer to memory
    long screensize = screen_info_var.yres_virtual * screen_info_fixed.line_length;
    char *fb_ptr = (char *)mmap(0, screensize, PROT_READ, MAP_SHARED, fb_fd, 0);
    if (fb_ptr == MAP_FAILED) {
        perror("Error: failed to map framebuffer device to memory");
        close(fb_fd);
        return 1;
    }

    // Color gradient from top left to bottom right
    // 16bpp
    // pink to blue (left to right) and turquiouse to green (top to bottom)
    for (int y = 0; y < screen_info_var.yres_virtual; y++) {
        for (int x = 0; x < screen_info_var.xres_virtual; x++) {
            float u = (float)x / screen_info_var.xres_virtual;
            float v = (float)y / screen_info_var.yres_virtual;

            unsigned short color = 0;
            color |= (unsigned short)(0x1F * (1 - u) + 0x1F * u) << 11; // red
            color |= (unsigned short)(0x1F * (1 - v) + 0x1F * v) << 5; // green
            color |= (unsigned short)(0x1F * (1 - u) + 0x1F * u); // blue

        }
    }



    // Unmap the framebuffer
    if (munmap(fb_ptr, screensize) == -1) {
        perror("Error: failed to unmap framebuffer device from memory");
        close(fb_fd);
        return 1;
    }

    close(fb_fd);

    return 0;
}
