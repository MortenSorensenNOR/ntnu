#include <math.h>
#include <stdlib.h>
#include <stddef.h>
#include <assert.h>

#include <omp.h>

#include "ppm.h"

// Image from:
// http://7-themes.com/6971875-funny-flowers-pictures.html

typedef struct {
     float red,green,blue;
} AccuratePixel;

typedef struct {
     int x, y;
     AccuratePixel *data;
} AccurateImage;

// Convert ppm to high precision format.
AccurateImage *convertToAccurateImage(PPMImage *image) {
	// Make a copy
	AccurateImage *imageAccurate;
	imageAccurate = (AccurateImage *)malloc(sizeof(AccurateImage));
	imageAccurate->data = (AccuratePixel*)malloc(image->x * image->y * sizeof(AccuratePixel));
	for(int i = 0; i < image->x * image->y; i++) {
		imageAccurate->data[i].red   = (double) image->data[i].red;
		imageAccurate->data[i].green = (double) image->data[i].green;
		imageAccurate->data[i].blue  = (double) image->data[i].blue;
	}
	imageAccurate->x = image->x;
	imageAccurate->y = image->y;
	
	return imageAccurate;
}

PPMImage * convertToPPPMImage(AccurateImage *imageIn) {
    PPMImage *imageOut;
    imageOut = (PPMImage *)malloc(sizeof(PPMImage));
    imageOut->data = (PPMPixel*)malloc(imageIn->x * imageIn->y * sizeof(PPMPixel));

    imageOut->x = imageIn->x;
    imageOut->y = imageIn->y;

    for(int i = 0; i < imageIn->x * imageIn->y; i++) {
        imageOut->data[i].red = imageIn->data[i].red;
        imageOut->data[i].green = imageIn->data[i].green;
        imageOut->data[i].blue = imageIn->data[i].blue;
    }
    return imageOut;
}

// blur one color channel
#define IDX(x, y, width) ((y) * (width) + (x))
void blurIteration(AccurateImage *imageOut, AccurateImage *imageIn, int channel, int size, float* temp) {
    int width = imageIn->x;
    int height = imageIn->y;

    // Horizontal pass
    #pragma omp parallel for
    for (int y = 0; y < height; y++) {
        float sum = 0;
        // Initial sum for the first pixel in the row
        for (int x = -size; x <= size; x++) {
            int clamped_x = (x < 0) ? 0 : ((x >= width) ? width - 1 : x);
            sum += *(&(imageIn->data[IDX(clamped_x, y, width)].red) + channel);
        }
        temp[IDX(0, y, width)] = sum;

        for (int x = 1; x < width; x++) {
            int add_idx = x + size;
            int sub_idx = x - size - 1;

            // Clamp add_idx and sub_idx to valid range
            int clamped_add_idx = (add_idx >= width) ? width - 1 : add_idx;
            int clamped_sub_idx = (sub_idx < 0) ? 0 : sub_idx;

            float add_val = *(&(imageIn->data[IDX(clamped_add_idx, y, width)].red) + channel);
            float sub_val = *(&(imageIn->data[IDX(clamped_sub_idx, y, width)].red) + channel);
            sum += add_val - sub_val;

            temp[IDX(x, y, width)] = sum;
        }
    }

    // Vertical pass
    #pragma omp parallel for
    for (int x = 0; x < width; x++) {
        float sum = 0;
        // Initial sum for the first pixel in the column
        for (int y = -size; y <= size; y++) {
            int clamped_y = (y < 0) ? 0 : ((y >= height) ? height - 1 : y);
            sum += temp[IDX(x, clamped_y, width)];
        }

        int area = (2 * size + 1) * (2 * size + 1);
        *(&(imageOut->data[IDX(x, 0, width)].red) + channel) = sum / area;

        for (int y = 1; y < height; y++) {
            int add_idx = y + size;
            int sub_idx = y - size - 1;

            // Clamp add_idx and sub_idx to valid range
            int clamped_add_idx = (add_idx >= height) ? height - 1 : add_idx;
            int clamped_sub_idx = (sub_idx < 0) ? 0 : sub_idx;

            float add_val = temp[IDX(x, clamped_add_idx, width)];
            float sub_val = temp[IDX(x, clamped_sub_idx, width)];
            sum += add_val - sub_val;

            *(&(imageOut->data[IDX(x, y, width)].red) + channel) = sum / area;
        }
    }
}

// Perform the final step, and return it as ppm.
PPMImage * imageDifference(AccurateImage *imageInSmall, AccurateImage *imageInLarge) {
	PPMImage *imageOut;
	imageOut = (PPMImage *)malloc(sizeof(PPMImage));
	imageOut->data = (PPMPixel*)malloc(imageInSmall->x * imageInSmall->y * sizeof(PPMPixel));
	
	imageOut->x = imageInSmall->x;
	imageOut->y = imageInSmall->y;

    #pragma omp parallel for
    for (int channel = 0; channel < 3; channel++) {
        #pragma omp parallel for
        for(int i = 0; i < imageInSmall->x * imageInSmall->y; i++) {
            float value = (*(&imageInLarge->data[i].red+channel) - *(&imageInSmall->data[i].red + channel));
            if (value < -1.0)
                value = 257.0 + value;
            if (value < 0.0f)
                value = 0.0f;
            if (value > 255.0f)
                value = 255.0f;

            *(&imageOut->data[i].red + channel) = floor(value);
        }
    }

	return imageOut;
}


int main(int argc, char** argv) {
    // read image
    PPMImage *image;
    // select where to read the image from
    if(argc > 1) {
        // from file for debugging (with argument)
        image = readPPM("flower.ppm");
    } else {
        // from stdin for cmb
        image = readStreamPPM(stdin);
    }
	
    int width = image->x;
    int height = image->y;
    float* integral_image = (float*)calloc(width * height, sizeof(float));
	
	AccurateImage *imageAccurate1_tiny = convertToAccurateImage(image);
	AccurateImage *imageAccurate2_tiny = convertToAccurateImage(image);
	
	// Process the tiny case:
	for(int colour = 0; colour < 3; colour++) {
		int size = 2;
        blurIteration(imageAccurate2_tiny, imageAccurate1_tiny, colour, size, integral_image);
        blurIteration(imageAccurate1_tiny, imageAccurate2_tiny, colour, size, integral_image);
        blurIteration(imageAccurate2_tiny, imageAccurate1_tiny, colour, size, integral_image);
        blurIteration(imageAccurate1_tiny, imageAccurate2_tiny, colour, size, integral_image);
        blurIteration(imageAccurate2_tiny, imageAccurate1_tiny, colour, size, integral_image);
	}
	
	
	AccurateImage *imageAccurate1_small = convertToAccurateImage(image);
	AccurateImage *imageAccurate2_small = convertToAccurateImage(image);
	
	// Process the small case:
	for(int colour = 0; colour < 3; colour++) {
		int size = 3;
        blurIteration(imageAccurate2_small, imageAccurate1_small, colour, size, integral_image);
        blurIteration(imageAccurate1_small, imageAccurate2_small, colour, size, integral_image);
        blurIteration(imageAccurate2_small, imageAccurate1_small, colour, size, integral_image);
        blurIteration(imageAccurate1_small, imageAccurate2_small, colour, size, integral_image);
        blurIteration(imageAccurate2_small, imageAccurate1_small, colour, size, integral_image);
	}

    // an intermediate step can be saved for debugging like this
   writePPM("imageAccurate2_tiny.ppm", convertToPPPMImage(imageAccurate2_tiny));
	
	AccurateImage *imageAccurate1_medium = convertToAccurateImage(image);
	AccurateImage *imageAccurate2_medium = convertToAccurateImage(image);
	
	// Process the medium case:
	for(int colour = 0; colour < 3; colour++) {
		int size = 5;
        blurIteration(imageAccurate2_medium, imageAccurate1_medium, colour, size, integral_image);
        blurIteration(imageAccurate1_medium, imageAccurate2_medium, colour, size, integral_image);
        blurIteration(imageAccurate2_medium, imageAccurate1_medium, colour, size, integral_image);
        blurIteration(imageAccurate1_medium, imageAccurate2_medium, colour, size, integral_image);
        blurIteration(imageAccurate2_medium, imageAccurate1_medium, colour, size, integral_image);
	}
	
	AccurateImage *imageAccurate1_large = convertToAccurateImage(image);
	AccurateImage *imageAccurate2_large = convertToAccurateImage(image);
	
	// Do each color channel
	for(int colour = 0; colour < 3; colour++) {
		int size = 8;
        blurIteration(imageAccurate2_large, imageAccurate1_large, colour, size, integral_image);
        blurIteration(imageAccurate1_large, imageAccurate2_large, colour, size, integral_image);
        blurIteration(imageAccurate2_large, imageAccurate1_large, colour, size, integral_image);
        blurIteration(imageAccurate1_large, imageAccurate2_large, colour, size, integral_image);
        blurIteration(imageAccurate2_large, imageAccurate1_large, colour, size, integral_image);
	}

    free(integral_image);

	// calculate difference
	PPMImage *final_tiny = imageDifference(imageAccurate2_tiny, imageAccurate2_small);
    PPMImage *final_small = imageDifference(imageAccurate2_small, imageAccurate2_medium);
    PPMImage *final_medium = imageDifference(imageAccurate2_medium, imageAccurate2_large);
	// Save the images.
    if(argc > 1) {
        writePPM("flower_tiny.ppm", final_tiny);
        writePPM("flower_small.ppm", final_small);
        writePPM("flower_medium.ppm", final_medium);
    } else {
        writeStreamPPM(stdout, final_tiny);
        writeStreamPPM(stdout, final_small);
        writeStreamPPM(stdout, final_medium);
    }
	
}

