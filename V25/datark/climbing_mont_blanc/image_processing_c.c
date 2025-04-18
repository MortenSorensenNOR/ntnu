#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <assert.h>

#include <omp.h>
#include "ppm.h"

typedef float v4sf __attribute__((vector_size(16)));  // 4 floats
typedef int v4si __attribute__((vector_size(16))); // for mask

typedef struct {
    int width, height;
    float* data[3];
} Image;


Image *convertToAccurateImage(PPMImage *pp_image) {
    Image* image;
    image = (Image*)malloc(sizeof(Image));
    image->width = pp_image->x;
    image->height = pp_image->y;

    image->data[0] = (float*)malloc(image->width * image->height * sizeof(float));
    image->data[1] = (float*)malloc(image->width * image->height * sizeof(float));
    image->data[2] = (float*)malloc(image->width * image->height * sizeof(float));

    #pragma omp parallel for
    for (int i = 0; i < image->width * image->height; i++) {
        image->data[0][i] = (float)pp_image->data[i].red;
        image->data[1][i] = (float)pp_image->data[i].green;
        image->data[2][i] = (float)pp_image->data[i].blue;
    }
    return image;
}

void fillImageData(Image* image, PPMPixel* data) {
    #pragma omp parallel for
    for (int i = 0; i < image->width * image->height; i++) {
        image->data[0][i] = (float)data[i].red;
        image->data[1][i] = (float)data[i].green;
        image->data[2][i] = (float)data[i].blue;
    }
}

Image* shallowCopyImage(Image* orig) {
    Image* copy = (Image*)malloc(sizeof(Image));
    copy->width = orig->width;
    copy->height = orig->height;

    copy->data[0] = (float*)malloc(copy->width * copy->height * sizeof(float));
    copy->data[1] = (float*)malloc(copy->width * copy->height * sizeof(float));
    copy->data[2] = (float*)malloc(copy->width * copy->height * sizeof(float));

    return copy;
}

PPMImage * convertToPPPMImage(Image *imageIn) {
    PPMImage *imageOut;
    imageOut = (PPMImage *)malloc(sizeof(PPMImage));
    imageOut->data = (PPMPixel*)malloc(imageIn->width * imageIn->height * sizeof(PPMPixel));
    imageOut->x = imageIn->width;
    imageOut->y = imageIn->height;

    for(int i = 0; i < imageIn->width * imageIn->height; i++) {
        imageOut->data[i].red   = imageIn->data[0][i];
        imageOut->data[i].green = imageIn->data[1][i];
        imageOut->data[i].blue  = imageIn->data[2][i];
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
    flip_block_single_channel(in->data[0], out->data[0], width, height);
    flip_block_single_channel(in->data[1], out->data[1], width, height);
    flip_block_single_channel(in->data[2], out->data[2], width, height);
}

inline void blur_horizontal_single_channel(const float* src, float* dst, const int width, const int height, const int size) {
    const float iarr = 1.0f / (size * 2 + 1);

    #pragma omp parallel for
    for (int i = 0; i < height; i++) {
        float inorm;
        const int begin = i * width;
        const int end   = begin + width;

        // current index, left index, right index
        float acc = 0.0f;
        int ti = begin, li = begin-size-1, ri = begin+size;

        // Initial acucmulation
        for(int j=ti; j<ri; j++)
        {
            acc += src[j];
        }

        // Left side out and right side in
        for(; li < begin; ri++, ti++, li++)
        { 
            acc += src[ri];
            inorm = 1.f / (float)(ri+1-begin);
            dst[ti] = acc*inorm;
        }

        // Left side in and right side in
        for(; ri<end; ri++, ti++, li++)
        { 
            acc += src[ri] - src[li];
            dst[ti] = acc*iarr;
        }

        // Left side in and right side out
        for(; ti<end; ti++, li++)
        { 
            acc -= src[li];
            inorm = 1.f / (float)(end-li-1);
            dst[ti] = acc*inorm;
        }
    }
}

void blur_horizontal(Image* src, Image* dst, const int width, const int height, const int size) {
    blur_horizontal_single_channel(src->data[0], dst->data[0], width, height, size);
    blur_horizontal_single_channel(src->data[1], dst->data[1], width, height, size);
    blur_horizontal_single_channel(src->data[2], dst->data[2], width, height, size);

}

void imageBlur(Image* src, Image* dst, int size) {
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
    flip_block(dst, src, height, width);

    // swap the pointers
    float* tmp = src->data[0];    
    src->data[0] = dst->data[0];
    dst->data[0] = tmp;
    tmp = src->data[1];
    src->data[1] = dst->data[1];
    dst->data[1] = tmp;
    tmp = src->data[2];
    src->data[2] = dst->data[2];
    dst->data[2] = tmp;
}

// PPMImage * imageDifference(Image *imageInSmall, Image *imageInLarge) {
// 	PPMImage *imageOut;
// 	imageOut = (PPMImage *)malloc(sizeof(PPMImage));
// 	imageOut->data = (PPMPixel*)malloc(imageInSmall->width * imageInSmall->height * sizeof(PPMPixel));
//
// 	imageOut->x = imageInSmall->width;
// 	imageOut->y = imageInSmall->height;
//
//     const int step = 4;
//     const int total_pixels = imageInSmall->width * imageInSmall->height;
//
//     #pragma omp parallel for
//     for (int i = 0; i < total_pixels; i += 4) {
//         // Load 4 pixels at once for each channel
//         v4sf r_large = *(v4sf*)&imageInLarge->data[0][i];
//         v4sf r_small = *(v4sf*)&imageInSmall->data[0][i];
//         v4sf g_large = *(v4sf*)&imageInLarge->data[1][i];
//         v4sf g_small = *(v4sf*)&imageInSmall->data[1][i];
//         v4sf b_large = *(v4sf*)&imageInLarge->data[2][i];
//         v4sf b_small = *(v4sf*)&imageInSmall->data[2][i];
//
//         // Compute difference
//         v4sf r = r_large - r_small;
//         v4sf g = g_large - g_small;
//         v4sf b = b_large - b_small;
//
//         // Wrap
//         v4sf threshold = {-1.0f, -1.0f, -1.0f, -1.0f};
//         v4sf addval = {-257.0f, -257.0f, -257.0f, -257.0f};
//
//         v4si mask_r = (v4si)(r < threshold);
//         v4si mask_g = (v4si)(g < threshold);
//         v4si mask_b = (v4si)(b < threshold);
//         v4sf mask_r_f = __builtin_convertvector(mask_r, v4sf);
//         v4sf mask_g_f = __builtin_convertvector(mask_g, v4sf);
//         v4sf mask_b_f = __builtin_convertvector(mask_b, v4sf);
//
//         r = r + (mask_r_f * addval);
//         g = g + (mask_g_f * addval);
//         b = b + (mask_b_f * addval);
//
//         // Clamp to [0, 255]
//         v4sf min_val = {0.0f, 0.0f, 0.0f, 0.0f};
//         v4sf max_val = {255.0f, 255.0f, 255.0f, 255.0f};
//
//         r = __builtin_ia32_maxps(__builtin_ia32_minps(r, max_val), min_val);
//         g = __builtin_ia32_maxps(__builtin_ia32_minps(g, max_val), min_val);
//         b = __builtin_ia32_maxps(__builtin_ia32_minps(b, max_val), min_val);
//
//         // Convert to unsigned char (simulating floor)
//         for (int j = 0; j < 4; j++) {
//             imageOut->data[i + j].red   = (unsigned char)(r[j]);
//             imageOut->data[i + j].green = (unsigned char)(g[j]);
//             imageOut->data[i + j].blue  = (unsigned char)(b[j]);
//         }
//     }
//
//     for (int i = total_pixels - (total_pixels % 4); i < total_pixels; i++) {
//         float r = imageInLarge->data[0][i] - imageInSmall->data[0][i];
//         if (r < -1.0f) r += 257.0f;
//         r = fminf(fmaxf(r, 0.0f), 255.0f);
//
//         float g = imageInLarge->data[1][i] - imageInSmall->data[1][i];
//         if (g < -1.0f) g += 257.0f;
//         g = fminf(fmaxf(g, 0.0f), 255.0f);
//
//         float b = imageInLarge->data[2][i] - imageInSmall->data[2][i];
//         if (b < -1.0f) b += 257.0f;
//         b = fminf(fmaxf(b, 0.0f), 255.0f);
//
//         imageOut->data[i].red   = (unsigned char)r;
//         imageOut->data[i].green = (unsigned char)g;
//         imageOut->data[i].blue  = (unsigned char)b;
//     }
//
// 	return imageOut;
// }

PPMImage * imageDifference(Image *imageInSmall, Image *imageInLarge) {
	PPMImage *imageOut;
	imageOut = (PPMImage *)malloc(sizeof(PPMImage));
	imageOut->data = (PPMPixel*)malloc(imageInSmall->width * imageInSmall->height * sizeof(PPMPixel));
	
	imageOut->x = imageInSmall->width;
	imageOut->y = imageInSmall->height;

    #pragma omp parallel for
    for(int i = 0; i < imageInSmall->width * imageInSmall->height; i++) {
        float value = imageInLarge->data[0][i] - imageInSmall->data[0][i];
        if (value < -1.0)
            value = 257.0 + value;
        if (value < 0.0f)
            value = 0.0f;
        if (value > 255.0f)
            value = 255.0f;

        imageOut->data[i].red = floor(value);

        value = imageInLarge->data[1][i] - imageInSmall->data[1][i];
        if (value < -1.0)
            value = 257.0 + value;
        if (value < 0.0f)
            value = 0.0f;
        if (value > 255.0f)
            value = 255.0f;

        imageOut->data[i].green = floor(value);

        value = imageInLarge->data[2][i] - imageInSmall->data[2][i];
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

