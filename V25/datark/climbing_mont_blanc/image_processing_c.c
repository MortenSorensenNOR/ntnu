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

#define IDX(x, y, width) ((y) * (width) + (x))
void compute_image_integral(AccurateImage* image, int channel, int width, int height, double* integral) {
    #pragma omp parallel for
    for (int y = 0; y < height; y++) {
        double row_sum = 0;
        for (int x = 0; x < width; x++) {
            row_sum += *(&(image->data[IDX(x, y, width)].red) + channel);
            integral[IDX(x, y, width)] = row_sum;
        }
    }

    #pragma omp parallel for
    for (int x = 0; x < width; x++) {
        for (int y = 1; y < height; y++) {
            integral[IDX(x, y, width)] += integral[IDX(x, y - 1, width)];
        }
    }
}

// blur one color channel
void blurIteration(AccurateImage *imageOut, AccurateImage *imageIn, int channel, int size, double* integral_image) {
    int width = imageIn->x;
    int height = imageIn->y;
    compute_image_integral(imageIn, channel, width, height, integral_image);

    #pragma omp parallel for
    for (int y = 0; y < height; y++) {
        int y1 = (y - size < 0) ? 0 : y - size;
        int y2 = (y + size >= height) ? height - 1 : y + size;

        for (int x = 0; x < width; x++) {
            int x1 = (x - size < 0) ? 0 : x - size;
            int x2 = (x + size >= width) ? width - 1 : x + size;

            double A = (x1 > 0 && y1 > 0) ? integral_image[IDX(x1 - 1, y1 - 1, width)] : 0;
            double B = (y1 > 0) ? integral_image[IDX(x2, y1 - 1, width)] : 0;
            double C = (x1 > 0) ? integral_image[IDX(x1 - 1, y2, width)] : 0;
            double D = integral_image[IDX(x2, y2, width)];

            float sum = D - B - C + A;
            int area = (x2 - x1 + 1) * (y2 - y1 + 1);
            *(&(imageOut->data[IDX(x, y, width)].red) + channel) = (float)sum / area;
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
    double* integral_image = (double*)calloc(width * height, sizeof(double));
	
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
//    writePPM("imageAccurate2_tiny.ppm", convertToPPPMImage(imageAccurate2_tiny));
	
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

