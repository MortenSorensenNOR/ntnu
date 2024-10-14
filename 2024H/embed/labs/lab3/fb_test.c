#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <string.h>

static int BPP = 16;
static int LINE_LENGTH = 0;

typedef struct {
	uint16_t r : 5; // 5 bits for red
	uint16_t g : 6; // 6 bits for green
	uint16_t b : 5; // 5 bits for blue
} Color16;

Color16 firePalette[] = {
	{31, 31, 0},  // Bright Yellow
	{31, 16, 0},  // Orange
	{31, 0, 0},   // Red
	{15, 0, 0}    // Dark Red
};

Color16 customPalette[] = {
	{31, 15, 15},   // Purple
	{0, 31, 31},   // Light Blue
	{0, 31, 0},    // Emerald Green
	{31, 0, 31}    // Pink
};

uint16_t color16_to_short(Color16 color) {
	return (color.r << 11) | (color.g << 5) | color.b; // Pack the RGB components into a single short
}

// Interpolate between two 16-bit colors
Color16 interpolate16(Color16 c1, Color16 c2, float t) {
	Color16 result;
	result.r = (uint16_t)(c1.r + t * (c2.r - c1.r));
	result.g = (uint16_t)(c1.g + t * (c2.g - c1.g));
	result.b = (uint16_t)(c1.b + t * (c2.b - c1.b));
	return result;
}

Color16 interpolate_bilinear16(Color16 c00, Color16 c10, Color16 c01, Color16 c11, float u, float v) {
	// Interpolate horizontally along the top and bottom
	Color16 top = interpolate16(c00, c10, u);
	Color16 bottom = interpolate16(c01, c11, u);

	// Interpolate vertically between the results of the top and bottom rows
	return interpolate16(top, bottom, v);
}

static inline void write_pixel(int x, int y, int color, char* fb_ptr) {
	int location = x * BPP + y * LINE_LENGTH;
	*((unsigned int short*)(fb_ptr + location)) = color;
}

int main() {
	int fb_fd = open("/dev/fb1", O_RDWR);
	if (fb_fd == -1) {
		perror("Error: cannot open framebuffer device");
		exit(1);
	}

	struct fb_fix_screeninfo finfo = {0};
	if (ioctl(fb_fd, FBIOGET_FSCREENINFO, &finfo) == -1) {
		perror("Error reading fixed screen information");
		close(fb_fd);
		return 1;
	}

	printf("ID: %s\n", finfo.id);

	struct fb_var_screeninfo vinfo = {0};
	if (ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo) == -1) {
		perror("Error reading varible screen information");
		close(fb_fd);
		return 1;
	}

	int resx = vinfo.xres;
	int resy = vinfo.yres;
	printf("Resolution: (%d, %d)\n", resx, resy);

	BPP = vinfo.bits_per_pixel / 8;
	LINE_LENGTH = finfo.line_length;

	// Map the framebuffer to memory
	long screensize = vinfo.yres_virtual * finfo.line_length;
	char *fb_ptr = (char *)mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fb_fd, 0);
	if (fb_ptr == MAP_FAILED) {
		perror("Error: failed to map framebuffer device to memory");
		close(fb_fd);
		return 1;
	}

	// set the whole screen to black
	// memset(fb_ptr, 0, screensize);
	for (int x = 0; x < resx; x++) {
		for (int y = 0; y < resy; y++) {
			float u = (float)x / resx;
			float v = (float)y / resy;

			
			Color16 gradient = interpolate_bilinear16(customPalette[0], customPalette[1],
								  customPalette[2], customPalette[3], u, v);
			unsigned short color = color16_to_short(gradient);

			write_pixel(x, y, color, fb_ptr);
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
