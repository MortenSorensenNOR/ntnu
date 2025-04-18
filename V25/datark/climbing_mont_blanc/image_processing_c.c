#include <math.h>
#include <stdlib.h>
#include <stddef.h>
#include <assert.h>

#include <omp.h>
#include "ppm.h"

typedef struct {
    int width, height;
    float* r;
    float* g;
    float* b;
} Image;

Image *convertToAccurateImage(PPMImage *pp_image) {
    Image* image;
    image = (Image*)malloc(sizeof(Image));
    image->width = pp_image->x;
    image->height = pp_image->y;

    image->r = (float*)malloc(image->width * image->height * sizeof(float));
    image->g = (float*)malloc(image->width * image->height * sizeof(float));
    image->b = (float*)malloc(image->width * image->height * sizeof(float));

    #pragma omp parallel for
    for (int i = 0; i < image->width * image->height; i++) {
        image->r[i] = (float)pp_image->data[i].red;
        image->g[i] = (float)pp_image->data[i].green;
        image->b[i] = (float)pp_image->data[i].blue;
    }
    return image;
}

void fillImageData(Image* image, PPMPixel* data) {
    #pragma omp parallel for
    for (int i = 0; i < image->width * image->height; i++) {
        image->r[i] = (float)data[i].red;
        image->g[i] = (float)data[i].green;
        image->b[i] = (float)data[i].blue;
    }
}

Image* shallowCopyImage(Image* orig) {
    Image* copy = (Image*)malloc(sizeof(Image));
    copy->width = orig->width;
    copy->height = orig->height;

    copy->r = (float*)malloc(copy->width * copy->height * sizeof(float));
    copy->g = (float*)malloc(copy->width * copy->height * sizeof(float));
    copy->b = (float*)malloc(copy->width * copy->height * sizeof(float));

    return copy;
}

PPMImage * convertToPPPMImage(Image *imageIn) {
    PPMImage *imageOut;
    imageOut = (PPMImage *)malloc(sizeof(PPMImage));
    imageOut->data = (PPMPixel*)malloc(imageIn->width * imageIn->height * sizeof(PPMPixel));
    imageOut->x = imageIn->width;
    imageOut->y = imageIn->height;

    for(int i = 0; i < imageIn->width * imageIn->height; i++) {
        imageOut->data[i].red = imageIn->r[i];
        imageOut->data[i].green = imageIn->g[i];
        imageOut->data[i].blue = imageIn->b[i];
    }
    return imageOut;
}

// Main algorithm
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

inline void flip_block_single_channel(const float* in, float* out, int width, int height) {
    const int block = 256;
    #pragma omp parallel for
    for (int x = 0; x < width; x += block) {
    for (int y = 0; y < height; y += block) {
        const float* p = in + y * width + x;
        float* q = out + y + x * height;
    
        const int block_x = MIN(width,  x + block) - x;
        const int block_y = MIN(height, y + block) - y;
        for (int xx = 0; xx < block_x; xx++) {
            for (int yy = 0; yy < block_y; yy++) {
    
                *q = *p;
                p += width;
                q += 1;
            }
    
            p += -block_y * width + 1;
            q += -block_y + height;
        }
    }
    }
}

void flip_block(Image* in, Image* out, const int width, const int height) {
    // For each color channel, transpose image data using a 2D block to reduce cache misses

    #pragma omp parallel sections
    {
        // Red channel
        #pragma omp section
        {
            flip_block_single_channel(in->r, out->r, width, height);
        } 
    
        // Green channel
        #pragma omp section
        {
            flip_block_single_channel(in->g, out->g, width, height);
        }

        // Blue channel
        #pragma omp section
        {
            flip_block_single_channel(in->b, out->b, width, height);
        }
    }
}

inline void blur_horizontal_single_channel(const float* src, float* dst, const int width, const int height, const int size) {
    const float iarr = 1.0f / (size * 2 + 1);

    #pragma omp parallel for
    for (int i = 0; i < height; i++) {
        const int begin = i * width;
        const int end   = begin + width;

        // current index, left index, right index
        float acc = 0.0f;
        int ti = begin, li = begin-size-1, ri = begin+size;

        // initial acucmulation
        for(int j=ti; j<ri; j++)
        {
            acc += src[j];
        }

        // 1. left side out and right side in
        for(; li < begin; ri++, ti++, li++)
        { 
            acc += src[ri];
            const float inorm = 1.f / (float)(ri+1-begin);
            dst[ti] = acc*inorm;
        }

        // 2. left side in and right side in
        for(; ri<end; ri++, ti++, li++)
        { 
            acc += src[ri] - src[li];
            dst[ti] = acc*iarr;
        }

        // 3. left side in and right side out
        for(; ti<end; ti++, li++)
        { 
            acc -= src[li];
            const float inorm = 1.f / (float)(end-li-1);
            dst[ti] = acc*inorm;
        }
    }
}

void blur_horizontal(Image* src, Image* dst, const int width, const int height, const int size) {
    #pragma omp parallel sections
    {
        // Red channel
        #pragma omp section
        {
            blur_horizontal_single_channel(src->r, dst->r, width, height, size);
        } 
    
        // Green channel
        #pragma omp section
        {
            blur_horizontal_single_channel(src->g, dst->g, width, height, size);
        }

        // Blue channel
        #pragma omp section
        {
            blur_horizontal_single_channel(src->b, dst->b, width, height, size);
        }
    }
}

void imageBlur(Image* src, Image* dst, int size) {
    Image* temp;
    const int width = src->width;
    const int height = src->height;

    blur_horizontal(src, dst, width, height, size);
    blur_horizontal(dst, src, width, height, size);
    blur_horizontal(src, dst, width, height, size);
    blur_horizontal(dst, src, width, height, size);
    blur_horizontal(src, dst, width, height, size);

    // transpose the image
    flip_block(dst, src, width, height);

    blur_horizontal(src, dst, height, width, size);
    blur_horizontal(dst, src, height, width, size);
    blur_horizontal(src, dst, height, width, size);
    blur_horizontal(dst, src, height, width, size);
    blur_horizontal(src, dst, height, width, size);

    // transpose the image
    flip_block(src, dst, height, width);

    temp = src;
    dst = src;
    src = temp;
}

PPMImage * imageDifference(Image *imageInSmall, Image *imageInLarge) {
	PPMImage *imageOut;
	imageOut = (PPMImage *)malloc(sizeof(PPMImage));
	imageOut->data = (PPMPixel*)malloc(imageInSmall->width * imageInSmall->height * sizeof(PPMPixel));
	
	imageOut->x = imageInSmall->width;
	imageOut->y = imageInSmall->height;

    #pragma omp parallel for
    for(int i = 0; i < imageInSmall->width * imageInSmall->height; i++) {
        float value = imageInLarge->r[i] - imageInSmall->r[i];
        if (value < -1.0)
            value = 257.0 + value;
        if (value < 0.0f)
            value = 0.0f;
        if (value > 255.0f)
            value = 255.0f;

        imageOut->data[i].red = floor(value);

        value = imageInLarge->g[i] - imageInSmall->g[i];
        if (value < -1.0)
            value = 257.0 + value;
        if (value < 0.0f)
            value = 0.0f;
        if (value > 255.0f)
            value = 255.0f;

        imageOut->data[i].green = floor(value);

        value = imageInLarge->b[i] - imageInSmall->b[i];
        if (value < -1.0)
            value = 257.0 + value;
        if (value < 0.0f)
            value = 0.0f;
        if (value > 255.0f)
            value = 255.0f;

        imageOut->data[i].blue = floor(value);
    }

	return imageOut;
}


int main(int argc, char** argv) {
    PPMImage *image;
    if(argc > 1) {
        image = readPPM("flower.ppm");
    } else {
        image = readStreamPPM(stdin);
    }
	
    // Shared
    int width = image->x;
    int height = image->y;
    Image* base_image = convertToAccurateImage(image);

    int size;
    Image* image_tiny = shallowCopyImage(base_image);
    Image *image_small = shallowCopyImage(base_image);
    Image *image_medium = shallowCopyImage(base_image);
    Image *image_large = shallowCopyImage(base_image); 

    // Run blur
    size = 2;
    imageBlur(base_image, image_tiny, size);
    
    size = 3;
    fillImageData(base_image, image->data);
    imageBlur(base_image, image_small, size);
    
    
    size = 5;
    fillImageData(base_image, image->data);
    imageBlur(base_image, image_medium, size);
    
    size = 8;
    fillImageData(base_image, image->data);
    imageBlur(base_image, image_large, size);

    writePPM("image_test.ppm", convertToPPPMImage(image_large));

	PPMImage *final_tiny = imageDifference(image_tiny, image_small);
    PPMImage *final_small = imageDifference(image_small, image_medium);
    PPMImage *final_medium = imageDifference(image_medium, image_large);
	
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

