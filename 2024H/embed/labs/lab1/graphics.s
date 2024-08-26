// VGAmini.s provided with Lab1 in TDT4258 autumn 2024
// 320 (width) x 240 (height) pixels, 
// 2 bytes per pixel RGB format, 1024 bytes is used to store one row
.global _start
.equ VGA_BASE_ADDR, 0xc8000000

_set_pixel: 
    // assumes R1 = x-coord, R2 = y, R3 = colorvalue
    // the color values are rgb 5-6-5 format
    ldr r0, =VGA_BASE_ADDR
    lsl r2, r2, #10 // Y-ADDRESS SHIFT LEFT 10 BITS (1024 BYTES)
    lsl r1, r1, #1  // X-ADRESS  SHIFT LEFT 1 BIT (2 BYTES)
    add r2, r1 // r2 IS NOW CORRECT OFFSET
    strh r3, [r0,r2]  // sTORE HALF-WORD, LOWER 16 BITS AT ADDRESS r0 + OFFSET r2
    bx lr

_clear_screen:
    push {r1, r2, r3, r4, r5, lr}
    ldr r5, =0
        
_clear_screen_loop:
    ldr r4, =0

_clear_screen_line: 
    mov r1, r4
    mov r2, r5
    bl _set_pixel

    add r4, r4, #1
    cmp r4, #320
    blt _clear_screen_line

    // Line cleared, continue loop
    add r5, r5, #1
    cmp r5, #240
    blt _clear_screen_loop

	pop {r1, r2, r3, r4, r5, lr}
    bx lr

abs:
    cmp r0, #0
    movge r0, r0
    rsblt r0, r0, #0
    bx lr

bresenham:
    // r0:      start_x
    // r1:      start_y
    // r2:      end_x
    // r3:      end_y

    // r4:      dx
    // r5:      dy
    // r6:      sx
    // r7:      sy
    // r8:      err
    // r9:      e2
    push {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9}

    // Clip start_x and start_y to screen size
    ldr r4, =VGA_WIDTH
    ldr r5, =VGA_HEIGHT
    sub r4, r4, #1
    sub r5, r5, #1

    cmp r0, #0
    movlt r0, #0
    cmp r0, r4
    movgt r0, r4

    cmp r1, #0
    movlt r1, #0
    cmp r1, r5
    movgt r1, r5

    // Clip end_x and end_y to screen size
    cmp r2, #0
    movlt r2, #0
    cmp r2, r4
    movgt r2, r4 

    cmp r3, #0
    movlt r3, #0
    cmp r3, r5
    movgt r3, r5 
    
    // dx = abs(x1 - x0)
    sub r4, r2, r0
    push {r0, lr}
    mov r0, r4
    bl abs
    mov r4, r0
    pop {r0, lr}

    // dy = -abs(y1 - y0)
    sub r5, r3, r1
    push {r0, lr}
    mov r0, r5
    bl abs
    mov r5, r0
    rsb r5, r5, #0
    pop {r0, lr}

    // sx = x0 < x1 ? 1 : -1
    cmp r0, r2
    ldrlt r6, =1
    ldrge r6, =-1

    // sy = y0 < y1 ? 1 : -1
    cmp r1, r3
    ldrlt r7, =1
    ldrge r7, =-1

    // err = dx + dy
    add r8, r5, r6

_bresenham_loop:
    // Color pixel at (x0, y0)
    push {r0, r1, r2, r3, lr}
    mov r2, r1          // y = y0
    mov r1, r0          // x = x0
    ldr r3, =0xffff     // color = white
    bl _set_pixel
    pop {r0, r1, r2, r3, lr}

    // if (x0 == x1 && y0 == y1) break;
    cmp r0, r2
    beq _bresenham_end
    cmp r1, r3
    beq _bresenham_end

    // e2 = 2 * err
    lsl r9, r8, #1

    // if (e2 >= dy)
    cmp r9, r5
    blt _bresenham_e2_ngeq_dy

    // err += dy
    add r8, r8, r5
    // x0 += sx
    add r0, r0, r6

_bresenham_e2_ngeq_dy:
    // if (e2 <= dx)
    cmp r9, r4
    bgt _bresenham_continue

    // err += dx
    add r8, r8, r4
    // y0 += sy
    add r1, r1, r7

_bresenham_continue:
    b _bresenham_loop

_bresenham_end:
    pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9}
    bx lr

matmul4:
    // r0:  address of matrix A
    // r1:  address of matrix B
    // r3:  address of return matrix C

    // Save the registers
    push {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}

    # Outer loop: i (row of matrixA)
    mov r3, #0                  // i = 0
matmul4_outer_loop:
    cmp r3, #4                  // if (i >= 4) break;
    bge matmul4_done

    # Inner loop: j (column of matrixB)
    mov r4, #0                  // j = 0
matmul4_inner_loop:
    cmp r4, #4                  // if (j >= 4) break;
    bge matmul4_next_row

    # Initialize sum (C[i][j] = 0)
    ldr r6, =.float_zero_val    // Load address of zero_val into R6
    vldr s0, [r6]               // Load zero value from address in R6 into S0

    # Compute the dot product of the i-th row of matrixA and j-th column of matrixB
    mov r5, #0                  // k = 0
matmul4_dot_product:
    cmp r5, #4                  // if (k >= 4) break;
    bge matmul4_store_result

    # Calculate addresses
    mov r7, r3                  // Save row index i into R7
    mov r8, r5                  // Save index k into R8
    mov r9, r4                  // Save column index j into R9

    # Load A[i][k] into S1
    lsl r10, r7, #4             // R10 = i * 16 (size of a row in bytes)
    add r10, r10, r8, lsl #2    // R10 = address of A[i][k]
    mov r11, r0
    add r12, r11, r10           // R12 = &matrixA[i][k]
    vldr s1, [r12]              // Load matrixA[i][k] into S1

    # Load B[k][j] into S2
    lsl r10, r8, #4             // R10 = k * 16 (size of a row in bytes)
    add r10, r10, r9, lsl #2    // R10 = address of B[k][j]
    mov r11, r1
    add r12, r11, r10           // R12 = &matrixB[k][j]
    vldr s2, [r12]              // Load matrixB[k][j] into S2

    # Multiply and accumulate
    vmul.f32 s1, s1, s2         // s1 = s1 * s2
    vadd.f32 s0, s0, s1         // s0 = s0 + s1

    add r5, r5, #1              // K++
    b matmul4_dot_product

matmul4_store_result:
    # Store the result in matrixC[i][j]
    lsl r10, r3, #4             // r10 = i * 16 (size of a row in bytes)
    add r10, r10, r4, lsl #2    // r10 = address of C[i][j]
    mov r11, r2
    add r12, r11, r10           // r12 = &matrixC[i][j]
    vstr s0, [r12]              // Store result in matrixC[i][j]

    add r4, r4, #1              // j++
    b matmul4_inner_loop

matmul4_next_row:
    add r3, r3, #1              // i++
    b matmul4_outer_loop

matmul4_done:
    // Save the link register
    pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, LR}          
    bx LR

mat4xvec4:
    // r0:  address of matrix A
    // r1:  address of vector B
    // r2:  address of return vector C

    // Save the registers
    push {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}

    # Outer loop: i (row of matrixA)
    mov r3, #0                  // i = 0

mat4xvec4_outer_loop:
    cmp r3, #4                  // if (i >= 4) break;
    bge mat4xvec4_done

    # Initialize sum (C[i] = 0)
    ldr r6, =.float_zero_val    // Load address of zero_val into R6
    vldr s0, [r6]               // Load zero value from address in R6 into S0

    # Compute the dot product of the i-th row of matrixA and vectorB
    mov r4, #0                  // j = 0

mat4xvec4_dot_product: 
    cmp r4, #4                  // if (j >= 4) break;
    bge mat4xvec4_store_result

    # Calculate addresses
    mov r7, r3                  // Save row index i into R7
    mov r8, r4                  // Save index j into R8

    # Load A[i][j] into S1
    lsl r10, r7, #4             // R10 = i * 16 (size of a row in bytes)
    add r10, r10, r8, lsl #2    // R10 = address of A[i][j]
    mov r11, r0
    add r12, r11, r10           // R12 = &matrixA[i][j]
    vldr s1, [r12]              // Load matrixA[i][j] into S1

    # Load B[j] into S2
    lsl r10, r8, #2             // R10 = j * 4 (size of a row in bytes)
    add r10, r10, r1            // R10 = address of B[j]
    vldr s2, [r10]              // Load vectorB[j] into S2

    # Multiply and accumulate
    vmul.f32 s1, s1, s2         // s1 = s1 * s2
    vadd.f32 s0, s0, s1         // s0 = s0 + s1

    add r4, r4, #1              // j++
    b mat4xvec4_dot_product

mat4xvec4_store_result:
    # Store the result in vectorC[i]
    lsl r10, r3, #2             // r10 = i * 4 (size of a row in bytes)
    add r10, r10, r2            // r10 = address of C[i]
    vstr s0, [r10]              // Store result in vectorC[i]

    add r3, r3, #1              // i++
    b mat4xvec4_outer_loop

mat4xvec4_done:
    // Save the link register
    pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    bx lr

main_graphics_loop:
    ldr r3, =0x0000
    bl _clear_screen

    // Calculate model matrix
    push {lr}
    ldr r0, =.rotation_matrix
    ldr r1, =.translation_matrix
    ldr r2, =.model_matrix
    bl matmul4
    pop {lr}

    // Calculate model-view matrix
    push {lr}
    ldr r0, =.view_matrix
    ldr r1, =.model_matrix
    ldr r2, =.model_view_matrix
    bl matmul4
    pop {lr}

    // Calculate model-view-projection matrix
    push {lr}
    ldr r0, =.projection_matrix
    ldr r1, =.model_view_matrix
    ldr r2, =.model_view_projection_matrix
    bl matmul4
    pop {lr}

    // Multiply each of the vertices with the model-view-projection matrix
    // The verticies are stored in .vertex_data
    // The indices are stored in .index_data
    // The result is stored in .ndc_vertex_data
    // Loop over all vertices and compute the projected vertex position
    ldr r0, =.vertex_data
    ldr r1, =.ndc_vertex_data
    ldr r2, =.model_view_projection_matrix

    // Loop over all vertices
    ldr r3, =0      // i = 0
    
_main_graphics_vertex_projection_loop:
    ldr r4, =.vertex_data_size
    ldr r4, [r4]
    cmp r3, r4
    bge _main_graphics_vertex_projection_loop_end

    // Get address of vertex_data[i]
    lsl r4, r3, #4  // r4 = i * 16 (4 * 4 bytes)
    add r4, r0, r4  // r4 = &vertex_data[i]
    
    // Get address of ndc_vertex_data[i]
    lsl r5, r3, #4  // r5 = i * 4
    add r5, r1, r5  // r5 = &ndc_vertex_data[i]

    // Multiply the vertex with the model-view-projection matrix
    push {r0, r1, r2, lr}
    mov r0, r2
    mov r1, r4
    mov r2, r5
    bl mat4xvec4
    pop {r0, r1, r2, lr}

    // Convert vertex to ndc coordinates
    // Divide by w
    vldr s0, [r5]       // Load x into S0
    vldr s1, [r5, #4]   // Load y into S1
    vldr s2, [r5, #8]   // Load z into S2
    vldr s3, [r5, #12]  // Load w into S3

    vdiv.f32 s0, s0, s3 // x = x / w
    vdiv.f32 s1, s1, s3 // y = y / w
    vdiv.f32 s2, s2, s3 // z = z / w

    // Write back
    vstr s0, [r5]       // Store x
    vstr s1, [r5, #4]   // Store y
    vstr s2, [r5, #8]   // Store z

    add r3, r3, #1  // i++
    b _main_graphics_vertex_projection_loop

_main_graphics_vertex_projection_loop_end:
    // Convert the ndc coordinates to screen coordinates
    // The result is stored in .screen_space_vertex_data
    // Loop over all vertices and convert to screen coordinates
    ldr r0, =.ndc_vertex_data
    ldr r1, =.screen_space_vertex_data
    ldr r2, =VGA_WIDTH
    ldr r3, =VGA_HEIGHT

    // Loop over all vertices
    ldr r4, =0      // i = 0

_main_graphics_screen_space_loop:
    ldr r3, =.vertex_data_size
    ldr r3, [r3]
    cmp r4, r3
    bge _main_graphics_screen_space_loop_end

    // Get address of ndc_vertex_data[i]
    lsl r5, r4, #4  // r5 = i * 16
    add r5, r0, r5  // r5 = &ndc_vertex_data[i]

    // Get address of screen_space_vertex_data[i]
    lsl r6, r4, #3  // r6 = i * 8
    add r6, r1, r6  // r6 = &screen_space_vertex_data[i]

    // Convert ndc coordinates to screen coordinates
    vldr s0, [r5]       // Load x into S0
    vldr s1, [r5, #4]   // Load y into S1
    vldr s2, [r5, #8]   // Load z into S2

    // int screenX = (ndcPos.x * 0.5f + 0.5f) * screenWidth;
    // int screenY = (ndcPos.y * 0.5f + 0.5f) * screenHeight;

    // Calculate screenX 
    vldr s3, =.float_half
    vmul.f32 s0, s0, s3 // x = x * 0.5
    vadd.f32 s0, s0, s3 // x = x + 0.5
    vmul.f32 s0, s0, s2 // x = x * screenWidth

    // Calculate screenY
    vldr s3, =.float_half
    vmul.f32 s1, s1, s3 // y = y * 0.5
    vadd.f32 s1, s1, s3 // y = y + 0.5
    vmul.f32 s1, s1, s3 // y = y * screenHeight

    // Convert to integer
    vcvt.s32.f32 s0, s0
    vcvt.s32.f32 s1, s1

    // Store screen coordinates
    vstr s0, [r6]
    vstr s1, [r6, #4]

    add r4, r4, #1  // i++
    b _main_graphics_screen_space_loop

_main_graphics_screen_space_loop_end:
    // Draw the cube
    // Iterate over index buffer and draw lines between the vertices
    ldr r0, =.index_data
    ldr r1, =.screen_space_vertex_data
    ldr r2, =VGA_WIDTH
    ldr r3, =VGA_HEIGHT

    // Loop over all indices
    ldr r4, =0      // i = 0

_main_graphics_draw_cube_loop:
    ldr r5, =.index_data_size
    ldr r5, [r5]
    cmp r4, r5
    bge _main_graphics_draw_cube_loop_end

    // Get address of index_data[i]
    lsl r6, r4, #4      // r6 = i * 16 (4 * 4 bytes)
    add r6, r0, r6      // r6 = &index_data[i]

    // Get the indices
    ldr r7, [r6]        // Load index 1
    ldr r8, [r6, #4]    // Load index 2
    ldr r9, [r6, #8]    // Load index 3

    // Get the screen space coordinates
    lsl r10, r7, #3     // r10 = index1 * 8 (2 * 4 bytes)
    add r10, r1, r10    // r10 = &screen_space_vertex_data[index1]

    lsl r11, r8, #3     // r11 = index2 * 8 (2 * 4 bytes)
    add r11, r1, r11    // r11 = &screen_space_vertex_data[index2]

    lsl r12, r9, #3     // r12 = index3 * 8 (2 * 4 bytes)
    add r12, r1, r12    // r12 = &screen_space_vertex_data[index3]

    // Draw the lines
    push {r0, r1, r2, r3, lr}
    mov r0, r10
    mov r1, r11
    ldr r2, =0xffff     // color = white
    bl bresenham
    pop {r0, r1, r2, r3, lr}

    push {r0, r1, r2, r3, lr}
    mov r0, r11
    mov r1, r12
    ldr r2, =0xffff     // color = white
    bl bresenham
    pop {r0, r1, r2, r3, lr}

    push {r0, r1, r2, r3, lr}
    mov r0, r12
    mov r1, r10
    ldr r2, =0xffff     // color = white
    bl bresenham
    pop {r0, r1, r2, r3, lr}

    add r4, r4, #4  // i++
    b _main_graphics_draw_cube_loop

_main_graphics_draw_cube_loop_end:

    b main_graphics_loop

_main_graphics_loop_end:
    bx lr

_start:
    bl main_graphics_loop
    b .

.data
.align
    VGA_WIDTH: .word 320
    VGA_HEIGHT: .word 240

    .float_zero_val: .float 0.0         // Used to null out float registers because fmov.fp32 s0, #0.0 gives "immediate out of range" error
    .float_half:     .float 0.5         // Same as above, but for 0.5

    .rotation_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .translation_matrix:
        .float 0.0, 0.0,  0.0, 0.0                                                                                                                                                  
        .float 0.0, 1.0,  0.0, 0.0                                                                                                                                                  
        .float 0.0, 0.0,  1.0, 0.0                                                                                                                                                  
        .float 0.0, 0.0, -5.0, 1.0

    .view_matrix:
        .float  1.0,  0.0, -0.0, 0.0
        .float -0.0,  1.0, -0.0, 0.0                                                                                                                                                
        .float  0.0,  0.0,  1.0, 0.0                                                                                                                                                  
        .float -0.0, -0.0, -3.0, 1.0

    .projection_matrix:
        .float 1.810660, 0.000000,  0.000000,  0.000000                                                                                                                                                  
        .float 0.000000, 2.414213,  0.000000,  0.000000                                                                                                                                                  
        .float 0.000000, 0.000000, -1.002002, -1.000000                                                                                                                                                
        .float 0.000000, 0.000000, -0.200200,  0.000000

    .model_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .model_view_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .model_view_projection_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .vertex_data_size: .word 8
    .index_data_size: .word 36

    .vertex_data:
        .float -1.0, -1.0, -1.0, 1.0
        .float -1.0, -1.0,  1.0, 1.0
        .float -1.0,  1.0, -1.0, 1.0
        .float -1.0,  1.0,  1.0, 1.0
        .float  1.0, -1.0, -1.0, 1.0
        .float  1.0, -1.0,  1.0, 1.0
        .float  1.0,  1.0, -1.0, 1.0
        .float  1.0,  1.0,  1.0, 1.0

    .ndc_vertex_data:
        .float 1.0, 1.0, 1.0, 1.0
        .float 1.0, 1.0, 1.0, 1.0
        .float 1.0, 1.0, 1.0, 1.0
        .float 1.0, 1.0, 1.0, 1.0
        .float 1.0, 1.0, 1.0, 1.0
        .float 1.0, 1.0, 1.0, 1.0
        .float 1.0, 1.0, 1.0, 1.0
        .float 1.0, 1.0, 1.0, 1.0 

    .screen_space_vertex_data:
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 


    .index_data:
        .word 0, 1, 3, 0        // Last value is for padding to make it memory alligned
        .word 0, 2, 3, 0
        .word 1, 5, 6, 0
        .word 1, 6, 2, 0
        .word 5, 4, 7, 0
        .word 5, 7, 6, 0
        .word 4, 0, 3, 0
        .word 4, 3, 7, 0
        .word 3, 2, 6, 0
        .word 3, 6, 7, 0
        .word 4, 5, 1, 0
        .word 4, 1, 0, 0

.end
