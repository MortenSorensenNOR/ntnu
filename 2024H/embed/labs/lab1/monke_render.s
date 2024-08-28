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
	
_set_pixel_double:
	ldr r0, =VGA_BASE_ADDR
	lsl r2, r2, #10
	lsl r1, r1, #2
	add r2, r1
	str r3, [r0, r2]
	bx lr
	
_clear_screen:
    push {r1, r2, r3, r4, r5, lr}
    ldr r5, =0
        
_clear_screen_loop:
    ldr r4, =0

_clear_screen_line:
    mov r1, r4
    mov r2, r5
    bl _set_pixel_double

    add r4, r4, #1
    cmp r4, #160
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
    ldr r4, [r4]
    ldr r5, [r5]

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
    add r8, r4, r5

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
    bne .+12
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

cosine_lookup:
    push {r0, r1, lr}
    lsl r0, r0, #2
    ldr r1, =.cosine_table
    add r1, r1, r0
    vldr s0, [r1]

    pop {r0, r1, lr}
    bx lr

sine_lookup:
    push {r0, r1, lr}
    lsl r0, r0, #2
    ldr r1, =.sine_table
    add r1, r1, r0
    vldr s0, [r1]

    pop {r0, r1, lr}
    bx lr

rotation_matrix_y:
    // r0:      Index for trig table lookup
    // r1:      Address of return matrix
    push {r0, r1, r2, r3, r4, lr}

    // First, get the corresponding sine and cosine values into s0 and s1
    bl sine_lookup
    vmov s1, s0
    bl cosine_lookup

    // Get -sinθ into s2
    vmov s2, s1
    vneg.f32 s2, s2

    // s0:      cosθ
    // s1:      sinθ
    // s2:     -sinθ
    // s3:      0.0
    // s4:      1.0
    
    // Load 1.0 into s2 and 0.0 into s3
    ldr r2, =.float_zero_val
    vldr s3, [r2]
    ldr r2, =.float_one
    vldr s4, [r2]
    
    // Fill in the rotation matrix
    // result.m[0] = c;
    // result.m[2] = -s;
    // result.m[8] = s;
    // result.m[10] = c;

    vstr s0, [r1]       // cosθ
    vstr s3, [r1, #4]   // 0
    vstr s2, [r1, #8]   // -sinθ
    vstr s3, [r1, #12]  // 0
    vstr s3, [r1, #16]  // 0
    vstr s4, [r1, #20]  // 1
    vstr s3, [r1, #24]  // 0
    vstr s3, [r1, #28]  // 0
    vstr s1, [r1, #32]  // sinθ
    vstr s3, [r1, #36]  // 0
    vstr s0, [r1, #40]  // cosθ
    vstr s3, [r1, #44]  // 0
    vstr s3, [r1, #48]  // 0
    vstr s3, [r1, #52]  // 0
    vstr s3, [r1, #56]  // 0
    vstr s4, [r1, #60]  // 1

    pop {r0, r1, r2, r3, r4, lr}
    bx lr

main_graphics_start:

main_graphics_loop:
    push {r0, r1, r2, r3, lr}
    ldr r3, =0x0000
    bl _clear_screen
    pop {r0, r1, r2, r3, lr}

    // Rotate the cube
    ldr r4, =.trig_table_size
    ldr r4, [r4]
    ldr r12, =.graphics_loop_count
    ldr r0, [r12]
    cmp r0, r4
    ldrge r0, =0
    strge r0, [r12]

    push {r0, lr}
    mov r0, r0     // Index for trig table lookup
    ldr r1, =.rotation_matrix
    bl rotation_matrix_y
    pop {r0, lr}

    // Scale-rotation matrix
    push {lr}
    ldr r0, =.rotation_matrix
    ldr r1, =.scale_matrix
    ldr r2, =.scale_rotation_matrix
    bl matmul4
    pop {lr}

    // Calculate model matrix
    push {lr}
    ldr r0, =.translation_matrix
    ldr r1, =.scale_rotation_matrix
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
    lsl r5, r3, #4  // r5 = i * 16 (4 * 4 bytes)
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
    ldr r2, [r2]
    ldr r3, [r3]

    // Loop over all vertices
    ldr r4, =0      // i = 0

_main_graphics_screen_space_loop:
    ldr r5, =.vertex_data_size
    ldr r5, [r5]
    cmp r4, r5
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

    vmov s3, r2       // Load screenWidth into S3
    vmov s4, r3       // Load screenHeight into S4
    
    // Convert screen width and height from integer to float
    vcvt.f32.s32 s3, s3
    vcvt.f32.s32 s4, s4

    // int screenX = (ndc.x + 1.0) * in->s_width * 0.5
    // int screenY = (1.0 - ndc.y) * in->s_height * 0.5

    // Calculate screenX 
    ldr r7, =.float_half
    vldr s5, [r7]           // Load 0.5 into S5
    ldr r7, =.float_one
    vldr s6, [r7]           // Load 1.0 into S6

    vadd.f32 s0, s0, s6     // x = x + 1.0
    vmul.f32 s0, s0, s3     // x = x * screenWidth
    vmul.f32 s0, s0, s5     // x = x * 0.5

    // Calculate screenY
    vsub.f32 s1, s6, s1     // y = 1 - y
    vmul.f32 s1, s1, s4     // y = y * screenHeight
    vmul.f32 s1, s1, s5     // y = y + 0.5

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

    // Draw the line from r10 to r11
    push {r0, r1, r2, r3, lr}
    ldr r0, [r10]
    ldr r1, [r10, #4]
    ldr r2, [r11]
    ldr r3, [r11, #4]
    bl bresenham
    pop {r0, r1, r2, r3, lr}

    // Draw line from r11 to r12
    push {r0, r1, r2, r3, lr}
    ldr r0, [r11]
    ldr r1, [r11, #4]
    ldr r2, [r12]
    ldr r3, [r12, #4]
    bl bresenham
    pop {r0, r1, r2, r3, lr}

    // Draw line from r12 to r10
    push {r0, r1, r2, r3, lr}
    ldr r0, [r12]
    ldr r1, [r12, #4]
    ldr r2, [r10]
    ldr r3, [r10, #4]
    bl bresenham
    pop {r0, r1, r2, r3, lr}

    add r4, r4, #1  // i++
    b _main_graphics_draw_cube_loop

_main_graphics_draw_cube_loop_end:
    ldr r12, =.graphics_loop_count
    ldr r0, [r12]
    add r0, r0, #1
    str r0, [r12]
    b main_graphics_loop

_main_graphics_loop_end:
    bx lr

_start:
    push {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    bl main_graphics_start
    pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}

    b .

.data
.align
    VGA_WIDTH: .word 320
    VGA_HEIGHT: .word 240

    .float_zero_val: .float 0.0         // Used to null out float registers because fmov.fp32 s0, #0.0 gives "immediate out of range" error
    .float_half:     .float 0.5         // Same as above, but for 0.5
    .float_one:      .float 1.0         // Same as above, but for 1.0

    .scale_matrix:
        .float 2.0, 0.0, 0.0, 0.0
        .float 0.0, 2.0, 0.0, 0.0
        .float 0.0, 0.0, 2.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .rotation_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .translation_matrix:
        .float  0.707107, -0.000000, 0.707107, 0.000000
        .float  0.000000,  1.000000, 0.000000, 0.000000
        .float -0.707107,  0.000000, 0.707107, -2.000000
        .float  0.000000,  0.000000, 0.000000, 1.000000

    .view_matrix:
        .float  1.000000, -0.000000, 0.000000, -0.000000
        .float  0.000000,  1.000000, 0.000000, -0.000000
        .float -0.000000, -0.000000, 1.000000, -6.500000
        .float  0.000000,  0.000000, 0.000000,  1.000000

    .projection_matrix:
        .float 1.810660, 0.000000,  0.000000,  0.000000
        .float 0.000000, 2.414213,  0.000000,  0.000000
        .float 0.000000, 0.000000, -1.002002, -0.200200
        .float 0.000000, 0.000000, -1.000000,  0.000000

    .scale_rotation_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .model_matrix:
        .float  0.707107, -0.000000, 0.707107, 0.000000
        .float  0.000000,  1.000000, 0.000000, 0.000000
        .float -0.707107,  0.000000, 0.707107, -2.000000
        .float  0.000000,  0.000000, 0.000000, 1.000000

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

    .trig_table_size: .word 100
    .cosine_table: 
        .float 1.00, 1.00, 0.99, 0.98
        .float 0.97, 0.95, 0.93, 0.90
        .float 0.87, 0.84, 0.81, 0.77
        .float 0.72, 0.68, 0.63, 0.58
        .float 0.53, 0.47, 0.42, 0.36
        .float 0.30, 0.24, 0.17, 0.11
        .float 0.05, -0.02, -0.08, -0.14
        .float -0.20, -0.27, -0.33, -0.39
        .float -0.44, -0.50, -0.55, -0.61
        .float -0.65, -0.70, -0.75, -0.79
        .float -0.82, -0.86, -0.89, -0.92
        .float -0.94, -0.96, -0.98, -0.99
        .float -1.00, -1.00, -1.00, -1.00
        .float -0.99, -0.98, -0.96, -0.94
        .float -0.92, -0.89, -0.86, -0.82
        .float -0.79, -0.75, -0.70, -0.65
        .float -0.61, -0.55, -0.50, -0.44
        .float -0.39, -0.33, -0.27, -0.20
        .float -0.14, -0.08, -0.02, 0.05
        .float 0.11, 0.17, 0.24, 0.30
        .float 0.36, 0.42, 0.47, 0.53
        .float 0.58, 0.63, 0.68, 0.72
        .float 0.77, 0.81, 0.84, 0.87
        .float 0.90, 0.93, 0.95, 0.97
        .float 0.98, 0.99, 1.00, 1.00

    .sine_table:
        .float 0.00, 0.06, 0.13, 0.19
        .float 0.25, 0.31, 0.37, 0.43
        .float 0.49, 0.54, 0.59, 0.64
        .float 0.69, 0.73, 0.78, 0.81
        .float 0.85, 0.88, 0.91, 0.93
        .float 0.95, 0.97, 0.98, 0.99
        .float 1.00, 1.00, 1.00, 0.99
        .float 0.98, 0.96, 0.95, 0.92
        .float 0.90, 0.87, 0.83, 0.80
        .float 0.76, 0.71, 0.67, 0.62
        .float 0.57, 0.51, 0.46, 0.40
        .float 0.34, 0.28, 0.22, 0.16
        .float 0.10, 0.03, -0.03, -0.10
        .float -0.16, -0.22, -0.28, -0.34
        .float -0.40, -0.46, -0.51, -0.57
        .float -0.62, -0.67, -0.71, -0.76
        .float -0.80, -0.83, -0.87, -0.90
        .float -0.92, -0.95, -0.96, -0.98
        .float -0.99, -1.00, -1.00, -1.00
        .float -0.99, -0.98, -0.97, -0.95
        .float -0.93, -0.91, -0.88, -0.85
        .float -0.81, -0.78, -0.73, -0.69
        .float -0.64, -0.59, -0.54, -0.49
        .float -0.43, -0.37, -0.31, -0.25
        .float -0.19, -0.13, -0.06, -0.00

    .graphics_loop_count: .word 25

    .vertex_data_size: .word 510
    .index_data_size: .word 967
    .vertex_data:
        .float 0.437500, 0.164063, 0.765625, 1.0
        .float -0.437500, 0.164063, 0.765625, 1.0
        .float 0.500000, 0.093750, 0.687500, 1.0
        .float -0.500000, 0.093750, 0.687500, 1.0
        .float 0.546875, 0.054688, 0.578125, 1.0
        .float -0.546875, 0.054688, 0.578125, 1.0
        .float 0.351563, -0.023438, 0.617188, 1.0
        .float -0.351563, -0.023438, 0.617188, 1.0
        .float 0.351563, 0.031250, 0.718750, 1.0
        .float -0.351563, 0.031250, 0.718750, 1.0
        .float 0.351563, 0.132813, 0.781250, 1.0
        .float -0.351563, 0.132813, 0.781250, 1.0
        .float 0.273438, 0.164063, 0.796875, 1.0
        .float -0.273438, 0.164063, 0.796875, 1.0
        .float 0.203125, 0.093750, 0.742188, 1.0
        .float -0.203125, 0.093750, 0.742188, 1.0
        .float 0.156250, 0.054688, 0.648438, 1.0
        .float -0.156250, 0.054688, 0.648438, 1.0
        .float 0.078125, 0.242188, 0.656250, 1.0
        .float -0.078125, 0.242188, 0.656250, 1.0
        .float 0.140625, 0.242188, 0.742188, 1.0
        .float -0.140625, 0.242188, 0.742188, 1.0
        .float 0.242188, 0.242188, 0.796875, 1.0
        .float -0.242188, 0.242188, 0.796875, 1.0
        .float 0.273438, 0.328125, 0.796875, 1.0
        .float -0.273438, 0.328125, 0.796875, 1.0
        .float 0.203125, 0.390625, 0.742188, 1.0
        .float -0.203125, 0.390625, 0.742188, 1.0
        .float 0.156250, 0.437500, 0.648438, 1.0
        .float -0.156250, 0.437500, 0.648438, 1.0
        .float 0.351563, 0.515625, 0.617188, 1.0
        .float -0.351563, 0.515625, 0.617188, 1.0
        .float 0.351563, 0.453125, 0.718750, 1.0
        .float -0.351563, 0.453125, 0.718750, 1.0
        .float 0.351563, 0.359375, 0.781250, 1.0
        .float -0.351563, 0.359375, 0.781250, 1.0
        .float 0.437500, 0.328125, 0.765625, 1.0
        .float -0.437500, 0.328125, 0.765625, 1.0
        .float 0.500000, 0.390625, 0.687500, 1.0
        .float -0.500000, 0.390625, 0.687500, 1.0
        .float 0.546875, 0.437500, 0.578125, 1.0
        .float -0.546875, 0.437500, 0.578125, 1.0
        .float 0.625000, 0.242188, 0.562500, 1.0
        .float -0.625000, 0.242188, 0.562500, 1.0
        .float 0.562500, 0.242188, 0.671875, 1.0
        .float -0.562500, 0.242188, 0.671875, 1.0
        .float 0.468750, 0.242188, 0.757813, 1.0
        .float -0.468750, 0.242188, 0.757813, 1.0
        .float 0.476563, 0.242188, 0.773438, 1.0
        .float -0.476563, 0.242188, 0.773438, 1.0
        .float 0.445313, 0.335938, 0.781250, 1.0
        .float -0.445313, 0.335938, 0.781250, 1.0
        .float 0.351563, 0.375000, 0.804688, 1.0
        .float -0.351563, 0.375000, 0.804688, 1.0
        .float 0.265625, 0.335938, 0.820313, 1.0
        .float -0.265625, 0.335938, 0.820313, 1.0
        .float 0.226563, 0.242188, 0.820313, 1.0
        .float -0.226563, 0.242188, 0.820313, 1.0
        .float 0.265625, 0.156250, 0.820313, 1.0
        .float -0.265625, 0.156250, 0.820313, 1.0
        .float 0.351563, 0.242188, 0.828125, 1.0
        .float -0.351563, 0.242188, 0.828125, 1.0
        .float 0.351563, 0.117188, 0.804688, 1.0
        .float -0.351563, 0.117188, 0.804688, 1.0
        .float 0.445313, 0.156250, 0.781250, 1.0
        .float -0.445313, 0.156250, 0.781250, 1.0
        .float 0.000000, 0.429688, 0.742188, 1.0
        .float 0.000000, 0.351563, 0.820313, 1.0
        .float 0.000000, -0.679688, 0.734375, 1.0
        .float 0.000000, -0.320313, 0.781250, 1.0
        .float 0.000000, -0.187500, 0.796875, 1.0
        .float 0.000000, -0.773438, 0.718750, 1.0
        .float 0.000000, 0.406250, 0.601563, 1.0
        .float 0.000000, 0.570313, 0.570313, 1.0
        .float 0.000000, 0.898438, -0.546875, 1.0
        .float 0.000000, 0.562500, -0.851563, 1.0
        .float 0.000000, 0.070313, -0.828125, 1.0
        .float 0.000000, -0.382813, -0.351563, 1.0
        .float 0.203125, -0.187500, 0.562500, 1.0
        .float -0.203125, -0.187500, 0.562500, 1.0
        .float 0.312500, -0.437500, 0.570313, 1.0
        .float -0.312500, -0.437500, 0.570313, 1.0
        .float 0.351563, -0.695313, 0.570313, 1.0
        .float -0.351563, -0.695313, 0.570313, 1.0
        .float 0.367188, -0.890625, 0.531250, 1.0
        .float -0.367188, -0.890625, 0.531250, 1.0
        .float 0.328125, -0.945313, 0.523438, 1.0
        .float -0.328125, -0.945313, 0.523438, 1.0
        .float 0.179688, -0.968750, 0.554688, 1.0
        .float -0.179688, -0.968750, 0.554688, 1.0
        .float 0.000000, -0.984375, 0.578125, 1.0
        .float 0.437500, -0.140625, 0.531250, 1.0
        .float -0.437500, -0.140625, 0.531250, 1.0
        .float 0.632813, -0.039063, 0.539063, 1.0
        .float -0.632813, -0.039063, 0.539063, 1.0
        .float 0.828125, 0.148438, 0.445313, 1.0
        .float -0.828125, 0.148438, 0.445313, 1.0
        .float 0.859375, 0.429688, 0.593750, 1.0
        .float -0.859375, 0.429688, 0.593750, 1.0
        .float 0.710938, 0.484375, 0.625000, 1.0
        .float -0.710938, 0.484375, 0.625000, 1.0
        .float 0.492188, 0.601563, 0.687500, 1.0
        .float -0.492188, 0.601563, 0.687500, 1.0
        .float 0.320313, 0.757813, 0.734375, 1.0
        .float -0.320313, 0.757813, 0.734375, 1.0
        .float 0.156250, 0.718750, 0.757813, 1.0
        .float -0.156250, 0.718750, 0.757813, 1.0
        .float 0.062500, 0.492188, 0.750000, 1.0
        .float -0.062500, 0.492188, 0.750000, 1.0
        .float 0.164063, 0.414063, 0.773438, 1.0
        .float -0.164063, 0.414063, 0.773438, 1.0
        .float 0.125000, 0.304688, 0.765625, 1.0
        .float -0.125000, 0.304688, 0.765625, 1.0
        .float 0.203125, 0.093750, 0.742188, 1.0
        .float -0.203125, 0.093750, 0.742188, 1.0
        .float 0.375000, 0.015625, 0.703125, 1.0
        .float -0.375000, 0.015625, 0.703125, 1.0
        .float 0.492188, 0.062500, 0.671875, 1.0
        .float -0.492188, 0.062500, 0.671875, 1.0
        .float 0.625000, 0.187500, 0.648438, 1.0
        .float -0.625000, 0.187500, 0.648438, 1.0
        .float 0.640625, 0.296875, 0.648438, 1.0
        .float -0.640625, 0.296875, 0.648438, 1.0
        .float 0.601563, 0.375000, 0.664063, 1.0
        .float -0.601563, 0.375000, 0.664063, 1.0
        .float 0.429688, 0.437500, 0.718750, 1.0
        .float -0.429688, 0.437500, 0.718750, 1.0
        .float 0.250000, 0.468750, 0.757813, 1.0
        .float -0.250000, 0.468750, 0.757813, 1.0
        .float 0.000000, -0.765625, 0.734375, 1.0
        .float 0.109375, -0.718750, 0.734375, 1.0
        .float -0.109375, -0.718750, 0.734375, 1.0
        .float 0.117188, -0.835938, 0.710938, 1.0
        .float -0.117188, -0.835938, 0.710938, 1.0
        .float 0.062500, -0.882813, 0.695313, 1.0
        .float -0.062500, -0.882813, 0.695313, 1.0
        .float 0.000000, -0.890625, 0.687500, 1.0
        .float 0.000000, -0.195313, 0.750000, 1.0
        .float 0.000000, -0.140625, 0.742188, 1.0
        .float 0.101563, -0.148438, 0.742188, 1.0
        .float -0.101563, -0.148438, 0.742188, 1.0
        .float 0.125000, -0.226563, 0.750000, 1.0
        .float -0.125000, -0.226563, 0.750000, 1.0
        .float 0.085938, -0.289063, 0.742188, 1.0
        .float -0.085938, -0.289063, 0.742188, 1.0
        .float 0.398438, -0.046875, 0.671875, 1.0
        .float -0.398438, -0.046875, 0.671875, 1.0
        .float 0.617188, 0.054688, 0.625000, 1.0
        .float -0.617188, 0.054688, 0.625000, 1.0
        .float 0.726563, 0.203125, 0.601563, 1.0
        .float -0.726563, 0.203125, 0.601563, 1.0
        .float 0.742188, 0.375000, 0.656250, 1.0
        .float -0.742188, 0.375000, 0.656250, 1.0
        .float 0.687500, 0.414063, 0.726563, 1.0
        .float -0.687500, 0.414063, 0.726563, 1.0
        .float 0.437500, 0.546875, 0.796875, 1.0
        .float -0.437500, 0.546875, 0.796875, 1.0
        .float 0.312500, 0.640625, 0.835938, 1.0
        .float -0.312500, 0.640625, 0.835938, 1.0
        .float 0.203125, 0.617188, 0.851563, 1.0
        .float -0.203125, 0.617188, 0.851563, 1.0
        .float 0.101563, 0.429688, 0.843750, 1.0
        .float -0.101563, 0.429688, 0.843750, 1.0
        .float 0.125000, -0.101563, 0.812500, 1.0
        .float -0.125000, -0.101563, 0.812500, 1.0
        .float 0.210938, -0.445313, 0.710938, 1.0
        .float -0.210938, -0.445313, 0.710938, 1.0
        .float 0.250000, -0.703125, 0.687500, 1.0
        .float -0.250000, -0.703125, 0.687500, 1.0
        .float 0.265625, -0.820313, 0.664063, 1.0
        .float -0.265625, -0.820313, 0.664063, 1.0
        .float 0.234375, -0.914063, 0.632813, 1.0
        .float -0.234375, -0.914063, 0.632813, 1.0
        .float 0.164063, -0.929688, 0.632813, 1.0
        .float -0.164063, -0.929688, 0.632813, 1.0
        .float 0.000000, -0.945313, 0.640625, 1.0
        .float 0.000000, 0.046875, 0.726563, 1.0
        .float 0.000000, 0.210938, 0.765625, 1.0
        .float 0.328125, 0.476563, 0.742188, 1.0
        .float -0.328125, 0.476563, 0.742188, 1.0
        .float 0.164063, 0.140625, 0.750000, 1.0
        .float -0.164063, 0.140625, 0.750000, 1.0
        .float 0.132813, 0.210938, 0.757813, 1.0
        .float -0.132813, 0.210938, 0.757813, 1.0
        .float 0.117188, -0.687500, 0.734375, 1.0
        .float -0.117188, -0.687500, 0.734375, 1.0
        .float 0.078125, -0.445313, 0.750000, 1.0
        .float -0.078125, -0.445313, 0.750000, 1.0
        .float 0.000000, -0.445313, 0.750000, 1.0
        .float 0.000000, -0.328125, 0.742188, 1.0
        .float 0.093750, -0.273438, 0.781250, 1.0
        .float -0.093750, -0.273438, 0.781250, 1.0
        .float 0.132813, -0.226563, 0.796875, 1.0
        .float -0.132813, -0.226563, 0.796875, 1.0
        .float 0.109375, -0.132813, 0.781250, 1.0
        .float -0.109375, -0.132813, 0.781250, 1.0
        .float 0.039063, -0.125000, 0.781250, 1.0
        .float -0.039063, -0.125000, 0.781250, 1.0
        .float 0.000000, -0.203125, 0.828125, 1.0
        .float 0.046875, -0.148438, 0.812500, 1.0
        .float -0.046875, -0.148438, 0.812500, 1.0
        .float 0.093750, -0.156250, 0.812500, 1.0
        .float -0.093750, -0.156250, 0.812500, 1.0
        .float 0.109375, -0.226563, 0.828125, 1.0
        .float -0.109375, -0.226563, 0.828125, 1.0
        .float 0.078125, -0.250000, 0.804688, 1.0
        .float -0.078125, -0.250000, 0.804688, 1.0
        .float 0.000000, -0.289063, 0.804688, 1.0
        .float 0.257813, -0.312500, 0.554688, 1.0
        .float -0.257813, -0.312500, 0.554688, 1.0
        .float 0.164063, -0.242188, 0.710938, 1.0
        .float -0.164063, -0.242188, 0.710938, 1.0
        .float 0.179688, -0.312500, 0.710938, 1.0
        .float -0.179688, -0.312500, 0.710938, 1.0
        .float 0.234375, -0.250000, 0.554688, 1.0
        .float -0.234375, -0.250000, 0.554688, 1.0
        .float 0.000000, -0.875000, 0.687500, 1.0
        .float 0.046875, -0.867188, 0.687500, 1.0
        .float -0.046875, -0.867188, 0.687500, 1.0
        .float 0.093750, -0.820313, 0.710938, 1.0
        .float -0.093750, -0.820313, 0.710938, 1.0
        .float 0.093750, -0.742188, 0.726563, 1.0
        .float -0.093750, -0.742188, 0.726563, 1.0
        .float 0.000000, -0.781250, 0.656250, 1.0
        .float 0.093750, -0.750000, 0.664063, 1.0
        .float -0.093750, -0.750000, 0.664063, 1.0
        .float 0.093750, -0.812500, 0.640625, 1.0
        .float -0.093750, -0.812500, 0.640625, 1.0
        .float 0.046875, -0.851563, 0.632813, 1.0
        .float -0.046875, -0.851563, 0.632813, 1.0
        .float 0.000000, -0.859375, 0.632813, 1.0
        .float 0.171875, 0.218750, 0.781250, 1.0
        .float -0.171875, 0.218750, 0.781250, 1.0
        .float 0.187500, 0.156250, 0.773438, 1.0
        .float -0.187500, 0.156250, 0.773438, 1.0
        .float 0.335938, 0.429688, 0.757813, 1.0
        .float -0.335938, 0.429688, 0.757813, 1.0
        .float 0.273438, 0.421875, 0.773438, 1.0
        .float -0.273438, 0.421875, 0.773438, 1.0
        .float 0.421875, 0.398438, 0.773438, 1.0
        .float -0.421875, 0.398438, 0.773438, 1.0
        .float 0.562500, 0.351563, 0.695313, 1.0
        .float -0.562500, 0.351563, 0.695313, 1.0
        .float 0.585938, 0.289063, 0.687500, 1.0
        .float -0.585938, 0.289063, 0.687500, 1.0
        .float 0.578125, 0.195313, 0.679688, 1.0
        .float -0.578125, 0.195313, 0.679688, 1.0
        .float 0.476563, 0.101563, 0.718750, 1.0
        .float -0.476563, 0.101563, 0.718750, 1.0
        .float 0.375000, 0.062500, 0.742188, 1.0
        .float -0.375000, 0.062500, 0.742188, 1.0
        .float 0.226563, 0.109375, 0.781250, 1.0
        .float -0.226563, 0.109375, 0.781250, 1.0
        .float 0.179688, 0.296875, 0.781250, 1.0
        .float -0.179688, 0.296875, 0.781250, 1.0
        .float 0.210938, 0.375000, 0.781250, 1.0
        .float -0.210938, 0.375000, 0.781250, 1.0
        .float 0.234375, 0.359375, 0.757813, 1.0
        .float -0.234375, 0.359375, 0.757813, 1.0
        .float 0.195313, 0.296875, 0.757813, 1.0
        .float -0.195313, 0.296875, 0.757813, 1.0
        .float 0.242188, 0.125000, 0.757813, 1.0
        .float -0.242188, 0.125000, 0.757813, 1.0
        .float 0.375000, 0.085938, 0.726563, 1.0
        .float -0.375000, 0.085938, 0.726563, 1.0
        .float 0.460938, 0.117188, 0.703125, 1.0
        .float -0.460938, 0.117188, 0.703125, 1.0
        .float 0.546875, 0.210938, 0.671875, 1.0
        .float -0.546875, 0.210938, 0.671875, 1.0
        .float 0.554688, 0.281250, 0.671875, 1.0
        .float -0.554688, 0.281250, 0.671875, 1.0
        .float 0.531250, 0.335938, 0.679688, 1.0
        .float -0.531250, 0.335938, 0.679688, 1.0
        .float 0.414063, 0.390625, 0.750000, 1.0
        .float -0.414063, 0.390625, 0.750000, 1.0
        .float 0.281250, 0.398438, 0.765625, 1.0
        .float -0.281250, 0.398438, 0.765625, 1.0
        .float 0.335938, 0.406250, 0.750000, 1.0
        .float -0.335938, 0.406250, 0.750000, 1.0
        .float 0.203125, 0.171875, 0.750000, 1.0
        .float -0.203125, 0.171875, 0.750000, 1.0
        .float 0.195313, 0.226563, 0.750000, 1.0
        .float -0.195313, 0.226563, 0.750000, 1.0
        .float 0.109375, 0.460938, 0.609375, 1.0
        .float -0.109375, 0.460938, 0.609375, 1.0
        .float 0.195313, 0.664063, 0.617188, 1.0
        .float -0.195313, 0.664063, 0.617188, 1.0
        .float 0.335938, 0.687500, 0.593750, 1.0
        .float -0.335938, 0.687500, 0.593750, 1.0
        .float 0.484375, 0.554688, 0.554688, 1.0
        .float -0.484375, 0.554688, 0.554688, 1.0
        .float 0.679688, 0.453125, 0.492188, 1.0
        .float -0.679688, 0.453125, 0.492188, 1.0
        .float 0.796875, 0.406250, 0.460938, 1.0
        .float -0.796875, 0.406250, 0.460938, 1.0
        .float 0.773438, 0.164063, 0.375000, 1.0
        .float -0.773438, 0.164063, 0.375000, 1.0
        .float 0.601563, 0.000000, 0.414063, 1.0
        .float -0.601563, 0.000000, 0.414063, 1.0
        .float 0.437500, -0.093750, 0.468750, 1.0
        .float -0.437500, -0.093750, 0.468750, 1.0
        .float 0.000000, 0.898438, 0.289063, 1.0
        .float 0.000000, 0.984375, -0.078125, 1.0
        .float 0.000000, -0.195313, -0.671875, 1.0
        .float 0.000000, -0.460938, 0.187500, 1.0
        .float 0.000000, -0.976563, 0.460938, 1.0
        .float 0.000000, -0.804688, 0.343750, 1.0
        .float 0.000000, -0.570313, 0.320313, 1.0
        .float 0.000000, -0.484375, 0.281250, 1.0
        .float 0.851563, 0.234375, 0.054688, 1.0
        .float -0.851563, 0.234375, 0.054688, 1.0
        .float 0.859375, 0.320313, -0.046875, 1.0
        .float -0.859375, 0.320313, -0.046875, 1.0
        .float 0.773438, 0.265625, -0.437500, 1.0
        .float -0.773438, 0.265625, -0.437500, 1.0
        .float 0.460938, 0.437500, -0.703125, 1.0
        .float -0.460938, 0.437500, -0.703125, 1.0
        .float 0.734375, -0.046875, 0.070313, 1.0
        .float -0.734375, -0.046875, 0.070313, 1.0
        .float 0.593750, -0.125000, -0.164063, 1.0
        .float -0.593750, -0.125000, -0.164063, 1.0
        .float 0.640625, -0.007813, -0.429688, 1.0
        .float -0.640625, -0.007813, -0.429688, 1.0
        .float 0.335938, 0.054688, -0.664063, 1.0
        .float -0.335938, 0.054688, -0.664063, 1.0
        .float 0.234375, -0.351563, 0.406250, 1.0
        .float -0.234375, -0.351563, 0.406250, 1.0
        .float 0.179688, -0.414063, 0.257813, 1.0
        .float -0.179688, -0.414063, 0.257813, 1.0
        .float 0.289063, -0.710938, 0.382813, 1.0
        .float -0.289063, -0.710938, 0.382813, 1.0
        .float 0.250000, -0.500000, 0.390625, 1.0
        .float -0.250000, -0.500000, 0.390625, 1.0
        .float 0.328125, -0.914063, 0.398438, 1.0
        .float -0.328125, -0.914063, 0.398438, 1.0
        .float 0.140625, -0.757813, 0.367188, 1.0
        .float -0.140625, -0.757813, 0.367188, 1.0
        .float 0.125000, -0.539063, 0.359375, 1.0
        .float -0.125000, -0.539063, 0.359375, 1.0
        .float 0.164063, -0.945313, 0.437500, 1.0
        .float -0.164063, -0.945313, 0.437500, 1.0
        .float 0.218750, -0.281250, 0.429688, 1.0
        .float -0.218750, -0.281250, 0.429688, 1.0
        .float 0.210938, -0.226563, 0.468750, 1.0
        .float -0.210938, -0.226563, 0.468750, 1.0
        .float 0.203125, -0.171875, 0.500000, 1.0
        .float -0.203125, -0.171875, 0.500000, 1.0
        .float 0.210938, -0.390625, 0.164063, 1.0
        .float -0.210938, -0.390625, 0.164063, 1.0
        .float 0.296875, -0.312500, -0.265625, 1.0
        .float -0.296875, -0.312500, -0.265625, 1.0
        .float 0.343750, -0.148438, -0.539063, 1.0
        .float -0.343750, -0.148438, -0.539063, 1.0
        .float 0.453125, 0.867188, -0.382813, 1.0
        .float -0.453125, 0.867188, -0.382813, 1.0
        .float 0.453125, 0.929688, -0.070313, 1.0
        .float -0.453125, 0.929688, -0.070313, 1.0
        .float 0.453125, 0.851563, 0.234375, 1.0
        .float -0.453125, 0.851563, 0.234375, 1.0
        .float 0.460938, 0.523438, 0.429688, 1.0
        .float -0.460938, 0.523438, 0.429688, 1.0
        .float 0.726563, 0.406250, 0.335938, 1.0
        .float -0.726563, 0.406250, 0.335938, 1.0
        .float 0.632813, 0.453125, 0.281250, 1.0
        .float -0.632813, 0.453125, 0.281250, 1.0
        .float 0.640625, 0.703125, 0.054688, 1.0
        .float -0.640625, 0.703125, 0.054688, 1.0
        .float 0.796875, 0.562500, 0.125000, 1.0
        .float -0.796875, 0.562500, 0.125000, 1.0
        .float 0.796875, 0.617188, -0.117188, 1.0
        .float -0.796875, 0.617188, -0.117188, 1.0
        .float 0.640625, 0.750000, -0.195313, 1.0
        .float -0.640625, 0.750000, -0.195313, 1.0
        .float 0.640625, 0.679688, -0.445313, 1.0
        .float -0.640625, 0.679688, -0.445313, 1.0
        .float 0.796875, 0.539063, -0.359375, 1.0
        .float -0.796875, 0.539063, -0.359375, 1.0
        .float 0.617188, 0.328125, -0.585938, 1.0
        .float -0.617188, 0.328125, -0.585938, 1.0
        .float 0.484375, 0.023438, -0.546875, 1.0
        .float -0.484375, 0.023438, -0.546875, 1.0
        .float 0.820313, 0.328125, -0.203125, 1.0
        .float -0.820313, 0.328125, -0.203125, 1.0
        .float 0.406250, -0.171875, 0.148438, 1.0
        .float -0.406250, -0.171875, 0.148438, 1.0
        .float 0.429688, -0.195313, -0.210938, 1.0
        .float -0.429688, -0.195313, -0.210938, 1.0
        .float 0.890625, 0.406250, -0.234375, 1.0
        .float -0.890625, 0.406250, -0.234375, 1.0
        .float 0.773438, -0.140625, -0.125000, 1.0
        .float -0.773438, -0.140625, -0.125000, 1.0
        .float 1.039063, -0.101563, -0.328125, 1.0
        .float -1.039063, -0.101563, -0.328125, 1.0
        .float 1.281250, 0.054688, -0.429688, 1.0
        .float -1.281250, 0.054688, -0.429688, 1.0
        .float 1.351563, 0.320313, -0.421875, 1.0
        .float -1.351563, 0.320313, -0.421875, 1.0
        .float 1.234375, 0.507813, -0.421875, 1.0
        .float -1.234375, 0.507813, -0.421875, 1.0
        .float 1.023438, 0.476563, -0.312500, 1.0
        .float -1.023438, 0.476563, -0.312500, 1.0
        .float 1.015625, 0.414063, -0.289063, 1.0
        .float -1.015625, 0.414063, -0.289063, 1.0
        .float 1.187500, 0.437500, -0.390625, 1.0
        .float -1.187500, 0.437500, -0.390625, 1.0
        .float 1.265625, 0.289063, -0.406250, 1.0
        .float -1.265625, 0.289063, -0.406250, 1.0
        .float 1.210938, 0.078125, -0.406250, 1.0
        .float -1.210938, 0.078125, -0.406250, 1.0
        .float 1.031250, -0.039063, -0.304688, 1.0
        .float -1.031250, -0.039063, -0.304688, 1.0
        .float 0.828125, -0.070313, -0.132813, 1.0
        .float -0.828125, -0.070313, -0.132813, 1.0
        .float 0.921875, 0.359375, -0.218750, 1.0
        .float -0.921875, 0.359375, -0.218750, 1.0
        .float 0.945313, 0.304688, -0.289063, 1.0
        .float -0.945313, 0.304688, -0.289063, 1.0
        .float 0.882813, -0.023438, -0.210938, 1.0
        .float -0.882813, -0.023438, -0.210938, 1.0
        .float 1.039063, 0.000000, -0.367188, 1.0
        .float -1.039063, 0.000000, -0.367188, 1.0
        .float 1.187500, 0.093750, -0.445313, 1.0
        .float -1.187500, 0.093750, -0.445313, 1.0
        .float 1.234375, 0.250000, -0.445313, 1.0
        .float -1.234375, 0.250000, -0.445313, 1.0
        .float 1.171875, 0.359375, -0.437500, 1.0
        .float -1.171875, 0.359375, -0.437500, 1.0
        .float 1.023438, 0.343750, -0.359375, 1.0
        .float -1.023438, 0.343750, -0.359375, 1.0
        .float 0.843750, 0.289063, -0.210938, 1.0
        .float -0.843750, 0.289063, -0.210938, 1.0
        .float 0.835938, 0.171875, -0.273438, 1.0
        .float -0.835938, 0.171875, -0.273438, 1.0
        .float 0.757813, 0.093750, -0.273438, 1.0
        .float -0.757813, 0.093750, -0.273438, 1.0
        .float 0.820313, 0.085938, -0.273438, 1.0
        .float -0.820313, 0.085938, -0.273438, 1.0
        .float 0.843750, 0.015625, -0.273438, 1.0
        .float -0.843750, 0.015625, -0.273438, 1.0
        .float 0.812500, -0.015625, -0.273438, 1.0
        .float -0.812500, -0.015625, -0.273438, 1.0
        .float 0.726563, 0.000000, -0.070313, 1.0
        .float -0.726563, 0.000000, -0.070313, 1.0
        .float 0.718750, -0.023438, -0.171875, 1.0
        .float -0.718750, -0.023438, -0.171875, 1.0
        .float 0.718750, 0.039063, -0.187500, 1.0
        .float -0.718750, 0.039063, -0.187500, 1.0
        .float 0.796875, 0.203125, -0.210938, 1.0
        .float -0.796875, 0.203125, -0.210938, 1.0
        .float 0.890625, 0.242188, -0.265625, 1.0
        .float -0.890625, 0.242188, -0.265625, 1.0
        .float 0.890625, 0.234375, -0.320313, 1.0
        .float -0.890625, 0.234375, -0.320313, 1.0
        .float 0.812500, -0.015625, -0.320313, 1.0
        .float -0.812500, -0.015625, -0.320313, 1.0
        .float 0.851563, 0.015625, -0.320313, 1.0
        .float -0.851563, 0.015625, -0.320313, 1.0
        .float 0.828125, 0.078125, -0.320313, 1.0
        .float -0.828125, 0.078125, -0.320313, 1.0
        .float 0.765625, 0.093750, -0.320313, 1.0
        .float -0.765625, 0.093750, -0.320313, 1.0
        .float 0.843750, 0.171875, -0.320313, 1.0
        .float -0.843750, 0.171875, -0.320313, 1.0
        .float 1.039063, 0.328125, -0.414063, 1.0
        .float -1.039063, 0.328125, -0.414063, 1.0
        .float 1.187500, 0.343750, -0.484375, 1.0
        .float -1.187500, 0.343750, -0.484375, 1.0
        .float 1.257813, 0.242188, -0.492188, 1.0
        .float -1.257813, 0.242188, -0.492188, 1.0
        .float 1.210938, 0.085938, -0.484375, 1.0
        .float -1.210938, 0.085938, -0.484375, 1.0
        .float 1.046875, 0.000000, -0.421875, 1.0
        .float -1.046875, 0.000000, -0.421875, 1.0
        .float 0.882813, -0.015625, -0.265625, 1.0
        .float -0.882813, -0.015625, -0.265625, 1.0
        .float 0.953125, 0.289063, -0.343750, 1.0
        .float -0.953125, 0.289063, -0.343750, 1.0
        .float 0.890625, 0.109375, -0.328125, 1.0
        .float -0.890625, 0.109375, -0.328125, 1.0
        .float 0.937500, 0.062500, -0.335938, 1.0
        .float -0.937500, 0.062500, -0.335938, 1.0
        .float 1.000000, 0.125000, -0.367188, 1.0
        .float -1.000000, 0.125000, -0.367188, 1.0
        .float 0.960938, 0.171875, -0.351563, 1.0
        .float -0.960938, 0.171875, -0.351563, 1.0
        .float 1.015625, 0.234375, -0.375000, 1.0
        .float -1.015625, 0.234375, -0.375000, 1.0
        .float 1.054688, 0.187500, -0.382813, 1.0
        .float -1.054688, 0.187500, -0.382813, 1.0
        .float 1.109375, 0.210938, -0.390625, 1.0
        .float -1.109375, 0.210938, -0.390625, 1.0
        .float 1.085938, 0.273438, -0.390625, 1.0
        .float -1.085938, 0.273438, -0.390625, 1.0
        .float 1.023438, 0.437500, -0.484375, 1.0
        .float -1.023438, 0.437500, -0.484375, 1.0
        .float 1.250000, 0.468750, -0.546875, 1.0
        .float -1.250000, 0.468750, -0.546875, 1.0
        .float 1.367188, 0.296875, -0.500000, 1.0
        .float -1.367188, 0.296875, -0.500000, 1.0
        .float 1.312500, 0.054688, -0.531250, 1.0
        .float -1.312500, 0.054688, -0.531250, 1.0
        .float 1.039063, -0.085938, -0.492188, 1.0
        .float -1.039063, -0.085938, -0.492188, 1.0
        .float 0.789063, -0.125000, -0.328125, 1.0
        .float -0.789063, -0.125000, -0.328125, 1.0
        .float 0.859375, 0.382813, -0.382813, 1.0
        .float -0.859375, 0.382813, -0.382813, 1.0
        .float -1.023438, 0.476563, -0.312500, 1.0
        .float -1.234375, 0.507813, -0.421875, 1.0
        .float -0.890625, 0.406250, -0.234375, 1.0
        .float -0.820313, 0.328125, -0.203125, 1.0


    .ndc_vertex_data:
        .float 0.437500, 0.164063, 0.765625, 1.0
        .float -0.437500, 0.164063, 0.765625, 1.0
        .float 0.500000, 0.093750, 0.687500, 1.0
        .float -0.500000, 0.093750, 0.687500, 1.0
        .float 0.546875, 0.054688, 0.578125, 1.0
        .float -0.546875, 0.054688, 0.578125, 1.0
        .float 0.351563, -0.023438, 0.617188, 1.0
        .float -0.351563, -0.023438, 0.617188, 1.0
        .float 0.351563, 0.031250, 0.718750, 1.0
        .float -0.351563, 0.031250, 0.718750, 1.0
        .float 0.351563, 0.132813, 0.781250, 1.0
        .float -0.351563, 0.132813, 0.781250, 1.0
        .float 0.273438, 0.164063, 0.796875, 1.0
        .float -0.273438, 0.164063, 0.796875, 1.0
        .float 0.203125, 0.093750, 0.742188, 1.0
        .float -0.203125, 0.093750, 0.742188, 1.0
        .float 0.156250, 0.054688, 0.648438, 1.0
        .float -0.156250, 0.054688, 0.648438, 1.0
        .float 0.078125, 0.242188, 0.656250, 1.0
        .float -0.078125, 0.242188, 0.656250, 1.0
        .float 0.140625, 0.242188, 0.742188, 1.0
        .float -0.140625, 0.242188, 0.742188, 1.0
        .float 0.242188, 0.242188, 0.796875, 1.0
        .float -0.242188, 0.242188, 0.796875, 1.0
        .float 0.273438, 0.328125, 0.796875, 1.0
        .float -0.273438, 0.328125, 0.796875, 1.0
        .float 0.203125, 0.390625, 0.742188, 1.0
        .float -0.203125, 0.390625, 0.742188, 1.0
        .float 0.156250, 0.437500, 0.648438, 1.0
        .float -0.156250, 0.437500, 0.648438, 1.0
        .float 0.351563, 0.515625, 0.617188, 1.0
        .float -0.351563, 0.515625, 0.617188, 1.0
        .float 0.351563, 0.453125, 0.718750, 1.0
        .float -0.351563, 0.453125, 0.718750, 1.0
        .float 0.351563, 0.359375, 0.781250, 1.0
        .float -0.351563, 0.359375, 0.781250, 1.0
        .float 0.437500, 0.328125, 0.765625, 1.0
        .float -0.437500, 0.328125, 0.765625, 1.0
        .float 0.500000, 0.390625, 0.687500, 1.0
        .float -0.500000, 0.390625, 0.687500, 1.0
        .float 0.546875, 0.437500, 0.578125, 1.0
        .float -0.546875, 0.437500, 0.578125, 1.0
        .float 0.625000, 0.242188, 0.562500, 1.0
        .float -0.625000, 0.242188, 0.562500, 1.0
        .float 0.562500, 0.242188, 0.671875, 1.0
        .float -0.562500, 0.242188, 0.671875, 1.0
        .float 0.468750, 0.242188, 0.757813, 1.0
        .float -0.468750, 0.242188, 0.757813, 1.0
        .float 0.476563, 0.242188, 0.773438, 1.0
        .float -0.476563, 0.242188, 0.773438, 1.0
        .float 0.445313, 0.335938, 0.781250, 1.0
        .float -0.445313, 0.335938, 0.781250, 1.0
        .float 0.351563, 0.375000, 0.804688, 1.0
        .float -0.351563, 0.375000, 0.804688, 1.0
        .float 0.265625, 0.335938, 0.820313, 1.0
        .float -0.265625, 0.335938, 0.820313, 1.0
        .float 0.226563, 0.242188, 0.820313, 1.0
        .float -0.226563, 0.242188, 0.820313, 1.0
        .float 0.265625, 0.156250, 0.820313, 1.0
        .float -0.265625, 0.156250, 0.820313, 1.0
        .float 0.351563, 0.242188, 0.828125, 1.0
        .float -0.351563, 0.242188, 0.828125, 1.0
        .float 0.351563, 0.117188, 0.804688, 1.0
        .float -0.351563, 0.117188, 0.804688, 1.0
        .float 0.445313, 0.156250, 0.781250, 1.0
        .float -0.445313, 0.156250, 0.781250, 1.0
        .float 0.000000, 0.429688, 0.742188, 1.0
        .float 0.000000, 0.351563, 0.820313, 1.0
        .float 0.000000, -0.679688, 0.734375, 1.0
        .float 0.000000, -0.320313, 0.781250, 1.0
        .float 0.000000, -0.187500, 0.796875, 1.0
        .float 0.000000, -0.773438, 0.718750, 1.0
        .float 0.000000, 0.406250, 0.601563, 1.0
        .float 0.000000, 0.570313, 0.570313, 1.0
        .float 0.000000, 0.898438, -0.546875, 1.0
        .float 0.000000, 0.562500, -0.851563, 1.0
        .float 0.000000, 0.070313, -0.828125, 1.0
        .float 0.000000, -0.382813, -0.351563, 1.0
        .float 0.203125, -0.187500, 0.562500, 1.0
        .float -0.203125, -0.187500, 0.562500, 1.0
        .float 0.312500, -0.437500, 0.570313, 1.0
        .float -0.312500, -0.437500, 0.570313, 1.0
        .float 0.351563, -0.695313, 0.570313, 1.0
        .float -0.351563, -0.695313, 0.570313, 1.0
        .float 0.367188, -0.890625, 0.531250, 1.0
        .float -0.367188, -0.890625, 0.531250, 1.0
        .float 0.328125, -0.945313, 0.523438, 1.0
        .float -0.328125, -0.945313, 0.523438, 1.0
        .float 0.179688, -0.968750, 0.554688, 1.0
        .float -0.179688, -0.968750, 0.554688, 1.0
        .float 0.000000, -0.984375, 0.578125, 1.0
        .float 0.437500, -0.140625, 0.531250, 1.0
        .float -0.437500, -0.140625, 0.531250, 1.0
        .float 0.632813, -0.039063, 0.539063, 1.0
        .float -0.632813, -0.039063, 0.539063, 1.0
        .float 0.828125, 0.148438, 0.445313, 1.0
        .float -0.828125, 0.148438, 0.445313, 1.0
        .float 0.859375, 0.429688, 0.593750, 1.0
        .float -0.859375, 0.429688, 0.593750, 1.0
        .float 0.710938, 0.484375, 0.625000, 1.0
        .float -0.710938, 0.484375, 0.625000, 1.0
        .float 0.492188, 0.601563, 0.687500, 1.0
        .float -0.492188, 0.601563, 0.687500, 1.0
        .float 0.320313, 0.757813, 0.734375, 1.0
        .float -0.320313, 0.757813, 0.734375, 1.0
        .float 0.156250, 0.718750, 0.757813, 1.0
        .float -0.156250, 0.718750, 0.757813, 1.0
        .float 0.062500, 0.492188, 0.750000, 1.0
        .float -0.062500, 0.492188, 0.750000, 1.0
        .float 0.164063, 0.414063, 0.773438, 1.0
        .float -0.164063, 0.414063, 0.773438, 1.0
        .float 0.125000, 0.304688, 0.765625, 1.0
        .float -0.125000, 0.304688, 0.765625, 1.0
        .float 0.203125, 0.093750, 0.742188, 1.0
        .float -0.203125, 0.093750, 0.742188, 1.0
        .float 0.375000, 0.015625, 0.703125, 1.0
        .float -0.375000, 0.015625, 0.703125, 1.0
        .float 0.492188, 0.062500, 0.671875, 1.0
        .float -0.492188, 0.062500, 0.671875, 1.0
        .float 0.625000, 0.187500, 0.648438, 1.0
        .float -0.625000, 0.187500, 0.648438, 1.0
        .float 0.640625, 0.296875, 0.648438, 1.0
        .float -0.640625, 0.296875, 0.648438, 1.0
        .float 0.601563, 0.375000, 0.664063, 1.0
        .float -0.601563, 0.375000, 0.664063, 1.0
        .float 0.429688, 0.437500, 0.718750, 1.0
        .float -0.429688, 0.437500, 0.718750, 1.0
        .float 0.250000, 0.468750, 0.757813, 1.0
        .float -0.250000, 0.468750, 0.757813, 1.0
        .float 0.000000, -0.765625, 0.734375, 1.0
        .float 0.109375, -0.718750, 0.734375, 1.0
        .float -0.109375, -0.718750, 0.734375, 1.0
        .float 0.117188, -0.835938, 0.710938, 1.0
        .float -0.117188, -0.835938, 0.710938, 1.0
        .float 0.062500, -0.882813, 0.695313, 1.0
        .float -0.062500, -0.882813, 0.695313, 1.0
        .float 0.000000, -0.890625, 0.687500, 1.0
        .float 0.000000, -0.195313, 0.750000, 1.0
        .float 0.000000, -0.140625, 0.742188, 1.0
        .float 0.101563, -0.148438, 0.742188, 1.0
        .float -0.101563, -0.148438, 0.742188, 1.0
        .float 0.125000, -0.226563, 0.750000, 1.0
        .float -0.125000, -0.226563, 0.750000, 1.0
        .float 0.085938, -0.289063, 0.742188, 1.0
        .float -0.085938, -0.289063, 0.742188, 1.0
        .float 0.398438, -0.046875, 0.671875, 1.0
        .float -0.398438, -0.046875, 0.671875, 1.0
        .float 0.617188, 0.054688, 0.625000, 1.0
        .float -0.617188, 0.054688, 0.625000, 1.0
        .float 0.726563, 0.203125, 0.601563, 1.0
        .float -0.726563, 0.203125, 0.601563, 1.0
        .float 0.742188, 0.375000, 0.656250, 1.0
        .float -0.742188, 0.375000, 0.656250, 1.0
        .float 0.687500, 0.414063, 0.726563, 1.0
        .float -0.687500, 0.414063, 0.726563, 1.0
        .float 0.437500, 0.546875, 0.796875, 1.0
        .float -0.437500, 0.546875, 0.796875, 1.0
        .float 0.312500, 0.640625, 0.835938, 1.0
        .float -0.312500, 0.640625, 0.835938, 1.0
        .float 0.203125, 0.617188, 0.851563, 1.0
        .float -0.203125, 0.617188, 0.851563, 1.0
        .float 0.101563, 0.429688, 0.843750, 1.0
        .float -0.101563, 0.429688, 0.843750, 1.0
        .float 0.125000, -0.101563, 0.812500, 1.0
        .float -0.125000, -0.101563, 0.812500, 1.0
        .float 0.210938, -0.445313, 0.710938, 1.0
        .float -0.210938, -0.445313, 0.710938, 1.0
        .float 0.250000, -0.703125, 0.687500, 1.0
        .float -0.250000, -0.703125, 0.687500, 1.0
        .float 0.265625, -0.820313, 0.664063, 1.0
        .float -0.265625, -0.820313, 0.664063, 1.0
        .float 0.234375, -0.914063, 0.632813, 1.0
        .float -0.234375, -0.914063, 0.632813, 1.0
        .float 0.164063, -0.929688, 0.632813, 1.0
        .float -0.164063, -0.929688, 0.632813, 1.0
        .float 0.000000, -0.945313, 0.640625, 1.0
        .float 0.000000, 0.046875, 0.726563, 1.0
        .float 0.000000, 0.210938, 0.765625, 1.0
        .float 0.328125, 0.476563, 0.742188, 1.0
        .float -0.328125, 0.476563, 0.742188, 1.0
        .float 0.164063, 0.140625, 0.750000, 1.0
        .float -0.164063, 0.140625, 0.750000, 1.0
        .float 0.132813, 0.210938, 0.757813, 1.0
        .float -0.132813, 0.210938, 0.757813, 1.0
        .float 0.117188, -0.687500, 0.734375, 1.0
        .float -0.117188, -0.687500, 0.734375, 1.0
        .float 0.078125, -0.445313, 0.750000, 1.0
        .float -0.078125, -0.445313, 0.750000, 1.0
        .float 0.000000, -0.445313, 0.750000, 1.0
        .float 0.000000, -0.328125, 0.742188, 1.0
        .float 0.093750, -0.273438, 0.781250, 1.0
        .float -0.093750, -0.273438, 0.781250, 1.0
        .float 0.132813, -0.226563, 0.796875, 1.0
        .float -0.132813, -0.226563, 0.796875, 1.0
        .float 0.109375, -0.132813, 0.781250, 1.0
        .float -0.109375, -0.132813, 0.781250, 1.0
        .float 0.039063, -0.125000, 0.781250, 1.0
        .float -0.039063, -0.125000, 0.781250, 1.0
        .float 0.000000, -0.203125, 0.828125, 1.0
        .float 0.046875, -0.148438, 0.812500, 1.0
        .float -0.046875, -0.148438, 0.812500, 1.0
        .float 0.093750, -0.156250, 0.812500, 1.0
        .float -0.093750, -0.156250, 0.812500, 1.0
        .float 0.109375, -0.226563, 0.828125, 1.0
        .float -0.109375, -0.226563, 0.828125, 1.0
        .float 0.078125, -0.250000, 0.804688, 1.0
        .float -0.078125, -0.250000, 0.804688, 1.0
        .float 0.000000, -0.289063, 0.804688, 1.0
        .float 0.257813, -0.312500, 0.554688, 1.0
        .float -0.257813, -0.312500, 0.554688, 1.0
        .float 0.164063, -0.242188, 0.710938, 1.0
        .float -0.164063, -0.242188, 0.710938, 1.0
        .float 0.179688, -0.312500, 0.710938, 1.0
        .float -0.179688, -0.312500, 0.710938, 1.0
        .float 0.234375, -0.250000, 0.554688, 1.0
        .float -0.234375, -0.250000, 0.554688, 1.0
        .float 0.000000, -0.875000, 0.687500, 1.0
        .float 0.046875, -0.867188, 0.687500, 1.0
        .float -0.046875, -0.867188, 0.687500, 1.0
        .float 0.093750, -0.820313, 0.710938, 1.0
        .float -0.093750, -0.820313, 0.710938, 1.0
        .float 0.093750, -0.742188, 0.726563, 1.0
        .float -0.093750, -0.742188, 0.726563, 1.0
        .float 0.000000, -0.781250, 0.656250, 1.0
        .float 0.093750, -0.750000, 0.664063, 1.0
        .float -0.093750, -0.750000, 0.664063, 1.0
        .float 0.093750, -0.812500, 0.640625, 1.0
        .float -0.093750, -0.812500, 0.640625, 1.0
        .float 0.046875, -0.851563, 0.632813, 1.0
        .float -0.046875, -0.851563, 0.632813, 1.0
        .float 0.000000, -0.859375, 0.632813, 1.0
        .float 0.171875, 0.218750, 0.781250, 1.0
        .float -0.171875, 0.218750, 0.781250, 1.0
        .float 0.187500, 0.156250, 0.773438, 1.0
        .float -0.187500, 0.156250, 0.773438, 1.0
        .float 0.335938, 0.429688, 0.757813, 1.0
        .float -0.335938, 0.429688, 0.757813, 1.0
        .float 0.273438, 0.421875, 0.773438, 1.0
        .float -0.273438, 0.421875, 0.773438, 1.0
        .float 0.421875, 0.398438, 0.773438, 1.0
        .float -0.421875, 0.398438, 0.773438, 1.0
        .float 0.562500, 0.351563, 0.695313, 1.0
        .float -0.562500, 0.351563, 0.695313, 1.0
        .float 0.585938, 0.289063, 0.687500, 1.0
        .float -0.585938, 0.289063, 0.687500, 1.0
        .float 0.578125, 0.195313, 0.679688, 1.0
        .float -0.578125, 0.195313, 0.679688, 1.0
        .float 0.476563, 0.101563, 0.718750, 1.0
        .float -0.476563, 0.101563, 0.718750, 1.0
        .float 0.375000, 0.062500, 0.742188, 1.0
        .float -0.375000, 0.062500, 0.742188, 1.0
        .float 0.226563, 0.109375, 0.781250, 1.0
        .float -0.226563, 0.109375, 0.781250, 1.0
        .float 0.179688, 0.296875, 0.781250, 1.0
        .float -0.179688, 0.296875, 0.781250, 1.0
        .float 0.210938, 0.375000, 0.781250, 1.0
        .float -0.210938, 0.375000, 0.781250, 1.0
        .float 0.234375, 0.359375, 0.757813, 1.0
        .float -0.234375, 0.359375, 0.757813, 1.0
        .float 0.195313, 0.296875, 0.757813, 1.0
        .float -0.195313, 0.296875, 0.757813, 1.0
        .float 0.242188, 0.125000, 0.757813, 1.0
        .float -0.242188, 0.125000, 0.757813, 1.0
        .float 0.375000, 0.085938, 0.726563, 1.0
        .float -0.375000, 0.085938, 0.726563, 1.0
        .float 0.460938, 0.117188, 0.703125, 1.0
        .float -0.460938, 0.117188, 0.703125, 1.0
        .float 0.546875, 0.210938, 0.671875, 1.0
        .float -0.546875, 0.210938, 0.671875, 1.0
        .float 0.554688, 0.281250, 0.671875, 1.0
        .float -0.554688, 0.281250, 0.671875, 1.0
        .float 0.531250, 0.335938, 0.679688, 1.0
        .float -0.531250, 0.335938, 0.679688, 1.0
        .float 0.414063, 0.390625, 0.750000, 1.0
        .float -0.414063, 0.390625, 0.750000, 1.0
        .float 0.281250, 0.398438, 0.765625, 1.0
        .float -0.281250, 0.398438, 0.765625, 1.0
        .float 0.335938, 0.406250, 0.750000, 1.0
        .float -0.335938, 0.406250, 0.750000, 1.0
        .float 0.203125, 0.171875, 0.750000, 1.0
        .float -0.203125, 0.171875, 0.750000, 1.0
        .float 0.195313, 0.226563, 0.750000, 1.0
        .float -0.195313, 0.226563, 0.750000, 1.0
        .float 0.109375, 0.460938, 0.609375, 1.0
        .float -0.109375, 0.460938, 0.609375, 1.0
        .float 0.195313, 0.664063, 0.617188, 1.0
        .float -0.195313, 0.664063, 0.617188, 1.0
        .float 0.335938, 0.687500, 0.593750, 1.0
        .float -0.335938, 0.687500, 0.593750, 1.0
        .float 0.484375, 0.554688, 0.554688, 1.0
        .float -0.484375, 0.554688, 0.554688, 1.0
        .float 0.679688, 0.453125, 0.492188, 1.0
        .float -0.679688, 0.453125, 0.492188, 1.0
        .float 0.796875, 0.406250, 0.460938, 1.0
        .float -0.796875, 0.406250, 0.460938, 1.0
        .float 0.773438, 0.164063, 0.375000, 1.0
        .float -0.773438, 0.164063, 0.375000, 1.0
        .float 0.601563, 0.000000, 0.414063, 1.0
        .float -0.601563, 0.000000, 0.414063, 1.0
        .float 0.437500, -0.093750, 0.468750, 1.0
        .float -0.437500, -0.093750, 0.468750, 1.0
        .float 0.000000, 0.898438, 0.289063, 1.0
        .float 0.000000, 0.984375, -0.078125, 1.0
        .float 0.000000, -0.195313, -0.671875, 1.0
        .float 0.000000, -0.460938, 0.187500, 1.0
        .float 0.000000, -0.976563, 0.460938, 1.0
        .float 0.000000, -0.804688, 0.343750, 1.0
        .float 0.000000, -0.570313, 0.320313, 1.0
        .float 0.000000, -0.484375, 0.281250, 1.0
        .float 0.851563, 0.234375, 0.054688, 1.0
        .float -0.851563, 0.234375, 0.054688, 1.0
        .float 0.859375, 0.320313, -0.046875, 1.0
        .float -0.859375, 0.320313, -0.046875, 1.0
        .float 0.773438, 0.265625, -0.437500, 1.0
        .float -0.773438, 0.265625, -0.437500, 1.0
        .float 0.460938, 0.437500, -0.703125, 1.0
        .float -0.460938, 0.437500, -0.703125, 1.0
        .float 0.734375, -0.046875, 0.070313, 1.0
        .float -0.734375, -0.046875, 0.070313, 1.0
        .float 0.593750, -0.125000, -0.164063, 1.0
        .float -0.593750, -0.125000, -0.164063, 1.0
        .float 0.640625, -0.007813, -0.429688, 1.0
        .float -0.640625, -0.007813, -0.429688, 1.0
        .float 0.335938, 0.054688, -0.664063, 1.0
        .float -0.335938, 0.054688, -0.664063, 1.0
        .float 0.234375, -0.351563, 0.406250, 1.0
        .float -0.234375, -0.351563, 0.406250, 1.0
        .float 0.179688, -0.414063, 0.257813, 1.0
        .float -0.179688, -0.414063, 0.257813, 1.0
        .float 0.289063, -0.710938, 0.382813, 1.0
        .float -0.289063, -0.710938, 0.382813, 1.0
        .float 0.250000, -0.500000, 0.390625, 1.0
        .float -0.250000, -0.500000, 0.390625, 1.0
        .float 0.328125, -0.914063, 0.398438, 1.0
        .float -0.328125, -0.914063, 0.398438, 1.0
        .float 0.140625, -0.757813, 0.367188, 1.0
        .float -0.140625, -0.757813, 0.367188, 1.0
        .float 0.125000, -0.539063, 0.359375, 1.0
        .float -0.125000, -0.539063, 0.359375, 1.0
        .float 0.164063, -0.945313, 0.437500, 1.0
        .float -0.164063, -0.945313, 0.437500, 1.0
        .float 0.218750, -0.281250, 0.429688, 1.0
        .float -0.218750, -0.281250, 0.429688, 1.0
        .float 0.210938, -0.226563, 0.468750, 1.0
        .float -0.210938, -0.226563, 0.468750, 1.0
        .float 0.203125, -0.171875, 0.500000, 1.0
        .float -0.203125, -0.171875, 0.500000, 1.0
        .float 0.210938, -0.390625, 0.164063, 1.0
        .float -0.210938, -0.390625, 0.164063, 1.0
        .float 0.296875, -0.312500, -0.265625, 1.0
        .float -0.296875, -0.312500, -0.265625, 1.0
        .float 0.343750, -0.148438, -0.539063, 1.0
        .float -0.343750, -0.148438, -0.539063, 1.0
        .float 0.453125, 0.867188, -0.382813, 1.0
        .float -0.453125, 0.867188, -0.382813, 1.0
        .float 0.453125, 0.929688, -0.070313, 1.0
        .float -0.453125, 0.929688, -0.070313, 1.0
        .float 0.453125, 0.851563, 0.234375, 1.0
        .float -0.453125, 0.851563, 0.234375, 1.0
        .float 0.460938, 0.523438, 0.429688, 1.0
        .float -0.460938, 0.523438, 0.429688, 1.0
        .float 0.726563, 0.406250, 0.335938, 1.0
        .float -0.726563, 0.406250, 0.335938, 1.0
        .float 0.632813, 0.453125, 0.281250, 1.0
        .float -0.632813, 0.453125, 0.281250, 1.0
        .float 0.640625, 0.703125, 0.054688, 1.0
        .float -0.640625, 0.703125, 0.054688, 1.0
        .float 0.796875, 0.562500, 0.125000, 1.0
        .float -0.796875, 0.562500, 0.125000, 1.0
        .float 0.796875, 0.617188, -0.117188, 1.0
        .float -0.796875, 0.617188, -0.117188, 1.0
        .float 0.640625, 0.750000, -0.195313, 1.0
        .float -0.640625, 0.750000, -0.195313, 1.0
        .float 0.640625, 0.679688, -0.445313, 1.0
        .float -0.640625, 0.679688, -0.445313, 1.0
        .float 0.796875, 0.539063, -0.359375, 1.0
        .float -0.796875, 0.539063, -0.359375, 1.0
        .float 0.617188, 0.328125, -0.585938, 1.0
        .float -0.617188, 0.328125, -0.585938, 1.0
        .float 0.484375, 0.023438, -0.546875, 1.0
        .float -0.484375, 0.023438, -0.546875, 1.0
        .float 0.820313, 0.328125, -0.203125, 1.0
        .float -0.820313, 0.328125, -0.203125, 1.0
        .float 0.406250, -0.171875, 0.148438, 1.0
        .float -0.406250, -0.171875, 0.148438, 1.0
        .float 0.429688, -0.195313, -0.210938, 1.0
        .float -0.429688, -0.195313, -0.210938, 1.0
        .float 0.890625, 0.406250, -0.234375, 1.0
        .float -0.890625, 0.406250, -0.234375, 1.0
        .float 0.773438, -0.140625, -0.125000, 1.0
        .float -0.773438, -0.140625, -0.125000, 1.0
        .float 1.039063, -0.101563, -0.328125, 1.0
        .float -1.039063, -0.101563, -0.328125, 1.0
        .float 1.281250, 0.054688, -0.429688, 1.0
        .float -1.281250, 0.054688, -0.429688, 1.0
        .float 1.351563, 0.320313, -0.421875, 1.0
        .float -1.351563, 0.320313, -0.421875, 1.0
        .float 1.234375, 0.507813, -0.421875, 1.0
        .float -1.234375, 0.507813, -0.421875, 1.0
        .float 1.023438, 0.476563, -0.312500, 1.0
        .float -1.023438, 0.476563, -0.312500, 1.0
        .float 1.015625, 0.414063, -0.289063, 1.0
        .float -1.015625, 0.414063, -0.289063, 1.0
        .float 1.187500, 0.437500, -0.390625, 1.0
        .float -1.187500, 0.437500, -0.390625, 1.0
        .float 1.265625, 0.289063, -0.406250, 1.0
        .float -1.265625, 0.289063, -0.406250, 1.0
        .float 1.210938, 0.078125, -0.406250, 1.0
        .float -1.210938, 0.078125, -0.406250, 1.0
        .float 1.031250, -0.039063, -0.304688, 1.0
        .float -1.031250, -0.039063, -0.304688, 1.0
        .float 0.828125, -0.070313, -0.132813, 1.0
        .float -0.828125, -0.070313, -0.132813, 1.0
        .float 0.921875, 0.359375, -0.218750, 1.0
        .float -0.921875, 0.359375, -0.218750, 1.0
        .float 0.945313, 0.304688, -0.289063, 1.0
        .float -0.945313, 0.304688, -0.289063, 1.0
        .float 0.882813, -0.023438, -0.210938, 1.0
        .float -0.882813, -0.023438, -0.210938, 1.0
        .float 1.039063, 0.000000, -0.367188, 1.0
        .float -1.039063, 0.000000, -0.367188, 1.0
        .float 1.187500, 0.093750, -0.445313, 1.0
        .float -1.187500, 0.093750, -0.445313, 1.0
        .float 1.234375, 0.250000, -0.445313, 1.0
        .float -1.234375, 0.250000, -0.445313, 1.0
        .float 1.171875, 0.359375, -0.437500, 1.0
        .float -1.171875, 0.359375, -0.437500, 1.0
        .float 1.023438, 0.343750, -0.359375, 1.0
        .float -1.023438, 0.343750, -0.359375, 1.0
        .float 0.843750, 0.289063, -0.210938, 1.0
        .float -0.843750, 0.289063, -0.210938, 1.0
        .float 0.835938, 0.171875, -0.273438, 1.0
        .float -0.835938, 0.171875, -0.273438, 1.0
        .float 0.757813, 0.093750, -0.273438, 1.0
        .float -0.757813, 0.093750, -0.273438, 1.0
        .float 0.820313, 0.085938, -0.273438, 1.0
        .float -0.820313, 0.085938, -0.273438, 1.0
        .float 0.843750, 0.015625, -0.273438, 1.0
        .float -0.843750, 0.015625, -0.273438, 1.0
        .float 0.812500, -0.015625, -0.273438, 1.0
        .float -0.812500, -0.015625, -0.273438, 1.0
        .float 0.726563, 0.000000, -0.070313, 1.0
        .float -0.726563, 0.000000, -0.070313, 1.0
        .float 0.718750, -0.023438, -0.171875, 1.0
        .float -0.718750, -0.023438, -0.171875, 1.0
        .float 0.718750, 0.039063, -0.187500, 1.0
        .float -0.718750, 0.039063, -0.187500, 1.0
        .float 0.796875, 0.203125, -0.210938, 1.0
        .float -0.796875, 0.203125, -0.210938, 1.0
        .float 0.890625, 0.242188, -0.265625, 1.0
        .float -0.890625, 0.242188, -0.265625, 1.0
        .float 0.890625, 0.234375, -0.320313, 1.0
        .float -0.890625, 0.234375, -0.320313, 1.0
        .float 0.812500, -0.015625, -0.320313, 1.0
        .float -0.812500, -0.015625, -0.320313, 1.0
        .float 0.851563, 0.015625, -0.320313, 1.0
        .float -0.851563, 0.015625, -0.320313, 1.0
        .float 0.828125, 0.078125, -0.320313, 1.0
        .float -0.828125, 0.078125, -0.320313, 1.0
        .float 0.765625, 0.093750, -0.320313, 1.0
        .float -0.765625, 0.093750, -0.320313, 1.0
        .float 0.843750, 0.171875, -0.320313, 1.0
        .float -0.843750, 0.171875, -0.320313, 1.0
        .float 1.039063, 0.328125, -0.414063, 1.0
        .float -1.039063, 0.328125, -0.414063, 1.0
        .float 1.187500, 0.343750, -0.484375, 1.0
        .float -1.187500, 0.343750, -0.484375, 1.0
        .float 1.257813, 0.242188, -0.492188, 1.0
        .float -1.257813, 0.242188, -0.492188, 1.0
        .float 1.210938, 0.085938, -0.484375, 1.0
        .float -1.210938, 0.085938, -0.484375, 1.0
        .float 1.046875, 0.000000, -0.421875, 1.0
        .float -1.046875, 0.000000, -0.421875, 1.0
        .float 0.882813, -0.015625, -0.265625, 1.0
        .float -0.882813, -0.015625, -0.265625, 1.0
        .float 0.953125, 0.289063, -0.343750, 1.0
        .float -0.953125, 0.289063, -0.343750, 1.0
        .float 0.890625, 0.109375, -0.328125, 1.0
        .float -0.890625, 0.109375, -0.328125, 1.0
        .float 0.937500, 0.062500, -0.335938, 1.0
        .float -0.937500, 0.062500, -0.335938, 1.0
        .float 1.000000, 0.125000, -0.367188, 1.0
        .float -1.000000, 0.125000, -0.367188, 1.0
        .float 0.960938, 0.171875, -0.351563, 1.0
        .float -0.960938, 0.171875, -0.351563, 1.0
        .float 1.015625, 0.234375, -0.375000, 1.0
        .float -1.015625, 0.234375, -0.375000, 1.0
        .float 1.054688, 0.187500, -0.382813, 1.0
        .float -1.054688, 0.187500, -0.382813, 1.0
        .float 1.109375, 0.210938, -0.390625, 1.0
        .float -1.109375, 0.210938, -0.390625, 1.0
        .float 1.085938, 0.273438, -0.390625, 1.0
        .float -1.085938, 0.273438, -0.390625, 1.0
        .float 1.023438, 0.437500, -0.484375, 1.0
        .float -1.023438, 0.437500, -0.484375, 1.0
        .float 1.250000, 0.468750, -0.546875, 1.0
        .float -1.250000, 0.468750, -0.546875, 1.0
        .float 1.367188, 0.296875, -0.500000, 1.0
        .float -1.367188, 0.296875, -0.500000, 1.0
        .float 1.312500, 0.054688, -0.531250, 1.0
        .float -1.312500, 0.054688, -0.531250, 1.0
        .float 1.039063, -0.085938, -0.492188, 1.0
        .float -1.039063, -0.085938, -0.492188, 1.0
        .float 0.789063, -0.125000, -0.328125, 1.0
        .float -0.789063, -0.125000, -0.328125, 1.0
        .float 0.859375, 0.382813, -0.382813, 1.0
        .float -0.859375, 0.382813, -0.382813, 1.0
        .float -1.023438, 0.476563, -0.312500, 1.0
        .float -1.234375, 0.507813, -0.421875, 1.0
        .float -0.890625, 0.406250, -0.234375, 1.0
        .float -0.820313, 0.328125, -0.203125, 1.0

    .screen_space_vertex_data:
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 

    .index_data:
        .word 60, 64, 48, 0
        .word 49, 65, 61, 0
        .word 62, 64, 60, 0
        .word 61, 65, 63, 0
        .word 60, 58, 62, 0
        .word 63, 59, 61, 0
        .word 60, 56, 58, 0
        .word 59, 57, 61, 0
        .word 60, 54, 56, 0
        .word 57, 55, 61, 0
        .word 60, 52, 54, 0
        .word 55, 53, 61, 0
        .word 60, 50, 52, 0
        .word 53, 51, 61, 0
        .word 60, 48, 50, 0
        .word 51, 49, 61, 0
        .word 224, 228, 226, 0
        .word 227, 229, 225, 0
        .word 72, 283, 73, 0
        .word 73, 284, 72, 0
        .word 341, 347, 383, 0
        .word 384, 348, 342, 0
        .word 299, 345, 343, 0
        .word 344, 346, 300, 0
        .word 323, 379, 351, 0
        .word 352, 380, 324, 0
        .word 441, 443, 445, 0
        .word 446, 444, 442, 0
        .word 463, 491, 465, 0
        .word 466, 492, 464, 0
        .word 495, 497, 499, 0
        .word 500, 498, 496, 0
        .word 504, 322, 320, 0
        .word 504, 320, 390, 0
        .word 319, 321, 503, 0
        .word 319, 503, 389, 0
        .word 504, 506, 314, 0
        .word 504, 314, 322, 0
        .word 313, 505, 503, 0
        .word 313, 503, 321, 0
        .word 388, 382, 506, 0
        .word 382, 314, 506, 0
        .word 313, 381, 505, 0
        .word 381, 387, 505, 0
        .word 500, 496, 494, 0
        .word 500, 494, 502, 0
        .word 493, 495, 499, 0
        .word 493, 499, 501, 0
        .word 504, 502, 506, 0
        .word 502, 494, 506, 0
        .word 493, 501, 505, 0
        .word 501, 503, 505, 0
        .word 494, 400, 506, 0
        .word 400, 388, 506, 0
        .word 387, 399, 505, 0
        .word 399, 493, 505, 0
        .word 496, 398, 494, 0
        .word 398, 400, 494, 0
        .word 399, 397, 493, 0
        .word 397, 495, 493, 0
        .word 498, 396, 496, 0
        .word 396, 398, 496, 0
        .word 397, 395, 495, 0
        .word 395, 497, 495, 0
        .word 500, 394, 498, 0
        .word 394, 396, 498, 0
        .word 395, 393, 497, 0
        .word 393, 499, 497, 0
        .word 502, 392, 394, 0
        .word 502, 394, 500, 0
        .word 393, 391, 501, 0
        .word 393, 501, 499, 0
        .word 504, 390, 392, 0
        .word 504, 392, 502, 0
        .word 391, 389, 503, 0
        .word 391, 503, 501, 0
        .word 490, 492, 466, 0
        .word 490, 466, 468, 0
        .word 465, 491, 489, 0
        .word 465, 489, 467, 0
        .word 488, 490, 470, 0
        .word 490, 468, 470, 0
        .word 467, 489, 469, 0
        .word 489, 487, 469, 0
        .word 482, 488, 472, 0
        .word 488, 470, 472, 0
        .word 469, 487, 471, 0
        .word 487, 481, 471, 0
        .word 480, 482, 472, 0
        .word 480, 472, 474, 0
        .word 471, 481, 479, 0
        .word 471, 479, 473, 0
        .word 480, 474, 456, 0
        .word 474, 454, 456, 0
        .word 453, 473, 455, 0
        .word 473, 479, 455, 0
        .word 462, 478, 458, 0
        .word 462, 458, 460, 0
        .word 457, 477, 461, 0
        .word 457, 461, 459, 0
        .word 478, 462, 484, 0
        .word 462, 452, 484, 0
        .word 451, 461, 483, 0
        .word 461, 477, 483, 0
        .word 486, 484, 476, 0
        .word 484, 452, 476, 0
        .word 451, 483, 475, 0
        .word 483, 485, 475, 0
        .word 486, 476, 464, 0
        .word 486, 464, 492, 0
        .word 463, 475, 485, 0
        .word 463, 485, 491, 0
        .word 490, 488, 492, 0
        .word 488, 486, 492, 0
        .word 485, 487, 491, 0
        .word 487, 489, 491, 0
        .word 488, 482, 484, 0
        .word 488, 484, 486, 0
        .word 483, 481, 487, 0
        .word 483, 487, 485, 0
        .word 482, 480, 484, 0
        .word 480, 478, 484, 0
        .word 477, 479, 483, 0
        .word 479, 481, 483, 0
        .word 480, 456, 478, 0
        .word 456, 458, 478, 0
        .word 457, 455, 477, 0
        .word 455, 479, 477, 0
        .word 472, 420, 474, 0
        .word 420, 418, 474, 0
        .word 417, 419, 473, 0
        .word 419, 471, 473, 0
        .word 470, 422, 472, 0
        .word 422, 420, 472, 0
        .word 419, 421, 471, 0
        .word 421, 469, 471, 0
        .word 468, 424, 470, 0
        .word 424, 422, 470, 0
        .word 421, 423, 469, 0
        .word 423, 467, 469, 0
        .word 466, 426, 424, 0
        .word 466, 424, 468, 0
        .word 423, 425, 465, 0
        .word 423, 465, 467, 0
        .word 464, 428, 426, 0
        .word 464, 426, 466, 0
        .word 425, 427, 463, 0
        .word 425, 463, 465, 0
        .word 476, 416, 428, 0
        .word 476, 428, 464, 0
        .word 427, 415, 475, 0
        .word 427, 475, 463, 0
        .word 474, 418, 440, 0
        .word 474, 440, 454, 0
        .word 439, 417, 473, 0
        .word 439, 473, 453, 0
        .word 454, 440, 438, 0
        .word 454, 438, 456, 0
        .word 437, 439, 453, 0
        .word 437, 453, 455, 0
        .word 456, 438, 458, 0
        .word 438, 436, 458, 0
        .word 435, 437, 457, 0
        .word 437, 455, 457, 0
        .word 458, 436, 460, 0
        .word 436, 434, 460, 0
        .word 433, 435, 459, 0
        .word 435, 457, 459, 0
        .word 460, 434, 432, 0
        .word 460, 432, 462, 0
        .word 431, 433, 459, 0
        .word 431, 459, 461, 0
        .word 462, 432, 452, 0
        .word 432, 450, 452, 0
        .word 449, 431, 451, 0
        .word 431, 461, 451, 0
        .word 452, 450, 416, 0
        .word 452, 416, 476, 0
        .word 415, 449, 451, 0
        .word 415, 451, 475, 0
        .word 446, 442, 448, 0
        .word 442, 312, 448, 0
        .word 311, 441, 447, 0
        .word 441, 445, 447, 0
        .word 430, 448, 382, 0
        .word 448, 312, 382, 0
        .word 311, 447, 381, 0
        .word 447, 429, 381, 0
        .word 450, 430, 416, 0
        .word 430, 414, 416, 0
        .word 413, 429, 415, 0
        .word 429, 449, 415, 0
        .word 432, 448, 450, 0
        .word 448, 430, 450, 0
        .word 429, 447, 449, 0
        .word 447, 431, 449, 0
        .word 446, 448, 434, 0
        .word 448, 432, 434, 0
        .word 431, 447, 433, 0
        .word 447, 445, 433, 0
        .word 438, 446, 434, 0
        .word 438, 434, 436, 0
        .word 433, 445, 437, 0
        .word 433, 437, 435, 0
        .word 444, 446, 440, 0
        .word 446, 438, 440, 0
        .word 437, 445, 439, 0
        .word 445, 443, 439, 0
        .word 440, 418, 412, 0
        .word 440, 412, 444, 0
        .word 411, 417, 439, 0
        .word 411, 439, 443, 0
        .word 414, 430, 382, 0
        .word 414, 382, 388, 0
        .word 381, 429, 413, 0
        .word 381, 413, 387, 0
        .word 442, 318, 310, 0
        .word 442, 310, 312, 0
        .word 309, 317, 441, 0
        .word 309, 441, 311, 0
        .word 412, 390, 444, 0
        .word 390, 320, 444, 0
        .word 319, 389, 443, 0
        .word 389, 411, 443, 0
        .word 444, 320, 442, 0
        .word 320, 318, 442, 0
        .word 317, 319, 441, 0
        .word 319, 443, 441, 0
        .word 416, 414, 402, 0
        .word 416, 402, 428, 0
        .word 401, 413, 415, 0
        .word 401, 415, 427, 0
        .word 426, 428, 404, 0
        .word 428, 402, 404, 0
        .word 401, 427, 403, 0
        .word 427, 425, 403, 0
        .word 424, 426, 406, 0
        .word 426, 404, 406, 0
        .word 403, 425, 405, 0
        .word 425, 423, 405, 0
        .word 422, 424, 408, 0
        .word 424, 406, 408, 0
        .word 405, 423, 407, 0
        .word 423, 421, 407, 0
        .word 420, 422, 408, 0
        .word 420, 408, 410, 0
        .word 407, 421, 419, 0
        .word 407, 419, 409, 0
        .word 418, 420, 410, 0
        .word 418, 410, 412, 0
        .word 409, 419, 417, 0
        .word 409, 417, 411, 0
        .word 412, 410, 392, 0
        .word 412, 392, 390, 0
        .word 391, 409, 411, 0
        .word 391, 411, 389, 0
        .word 410, 408, 392, 0
        .word 408, 394, 392, 0
        .word 393, 407, 391, 0
        .word 407, 409, 391, 0
        .word 408, 406, 394, 0
        .word 406, 396, 394, 0
        .word 395, 405, 393, 0
        .word 405, 407, 393, 0
        .word 406, 404, 396, 0
        .word 404, 398, 396, 0
        .word 397, 403, 395, 0
        .word 403, 405, 395, 0
        .word 404, 402, 400, 0
        .word 404, 400, 398, 0
        .word 399, 401, 403, 0
        .word 399, 403, 397, 0
        .word 414, 388, 402, 0
        .word 388, 400, 402, 0
        .word 399, 387, 401, 0
        .word 387, 413, 401, 0
        .word 380, 352, 386, 0
        .word 352, 350, 386, 0
        .word 349, 351, 385, 0
        .word 351, 379, 385, 0
        .word 380, 386, 322, 0
        .word 386, 320, 322, 0
        .word 319, 385, 321, 0
        .word 385, 379, 321, 0
        .word 380, 378, 324, 0
        .word 378, 316, 324, 0
        .word 315, 377, 323, 0
        .word 377, 379, 323, 0
        .word 380, 322, 378, 0
        .word 322, 314, 378, 0
        .word 313, 321, 377, 0
        .word 321, 379, 377, 0
        .word 342, 344, 300, 0
        .word 342, 300, 384, 0
        .word 299, 343, 341, 0
        .word 299, 341, 383, 0
        .word 384, 300, 298, 0
        .word 384, 298, 318, 0
        .word 297, 299, 383, 0
        .word 297, 383, 317, 0
        .word 386, 384, 320, 0
        .word 384, 318, 320, 0
        .word 317, 383, 319, 0
        .word 383, 385, 319, 0
        .word 386, 350, 384, 0
        .word 350, 348, 384, 0
        .word 347, 349, 383, 0
        .word 349, 385, 383, 0
        .word 370, 376, 382, 0
        .word 376, 314, 382, 0
        .word 313, 375, 381, 0
        .word 375, 369, 381, 0
        .word 370, 382, 312, 0
        .word 370, 312, 368, 0
        .word 311, 381, 369, 0
        .word 311, 369, 367, 0
        .word 368, 312, 310, 0
        .word 368, 310, 362, 0
        .word 309, 311, 367, 0
        .word 309, 367, 361, 0
        .word 310, 296, 362, 0
        .word 296, 294, 362, 0
        .word 293, 295, 361, 0
        .word 295, 309, 361, 0
        .word 360, 290, 284, 0
        .word 360, 284, 73, 0
        .word 283, 289, 359, 0
        .word 283, 359, 73, 0
        .word 288, 286, 290, 0
        .word 286, 284, 290, 0
        .word 283, 285, 289, 0
        .word 285, 287, 289, 0
        .word 358, 360, 301, 0
        .word 360, 73, 301, 0
        .word 73, 359, 301, 0
        .word 359, 357, 301, 0
        .word 364, 292, 360, 0
        .word 292, 290, 360, 0
        .word 289, 291, 359, 0
        .word 291, 363, 359, 0
        .word 364, 360, 358, 0
        .word 364, 358, 366, 0
        .word 357, 359, 363, 0
        .word 357, 363, 365, 0
        .word 366, 358, 356, 0
        .word 366, 356, 372, 0
        .word 355, 357, 365, 0
        .word 355, 365, 371, 0
        .word 372, 356, 354, 0
        .word 372, 354, 374, 0
        .word 353, 355, 371, 0
        .word 353, 371, 373, 0
        .word 374, 354, 316, 0
        .word 374, 316, 378, 0
        .word 315, 353, 373, 0
        .word 315, 373, 377, 0
        .word 374, 378, 376, 0
        .word 378, 314, 376, 0
        .word 313, 377, 375, 0
        .word 377, 373, 375, 0
        .word 376, 370, 372, 0
        .word 376, 372, 374, 0
        .word 371, 369, 375, 0
        .word 371, 375, 373, 0
        .word 370, 368, 366, 0
        .word 370, 366, 372, 0
        .word 365, 367, 369, 0
        .word 365, 369, 371, 0
        .word 368, 362, 364, 0
        .word 368, 364, 366, 0
        .word 363, 361, 367, 0
        .word 363, 367, 365, 0
        .word 362, 294, 292, 0
        .word 362, 292, 364, 0
        .word 291, 293, 361, 0
        .word 291, 361, 363, 0
        .word 316, 354, 74, 0
        .word 316, 74, 75, 0
        .word 74, 353, 315, 0
        .word 74, 315, 75, 0
        .word 354, 356, 302, 0
        .word 354, 302, 74, 0
        .word 302, 355, 353, 0
        .word 302, 353, 74, 0
        .word 356, 358, 302, 0
        .word 358, 301, 302, 0
        .word 301, 357, 302, 0
        .word 357, 355, 302, 0
        .word 324, 316, 76, 0
        .word 316, 75, 76, 0
        .word 75, 315, 76, 0
        .word 315, 323, 76, 0
        .word 318, 298, 296, 0
        .word 318, 296, 310, 0
        .word 295, 297, 317, 0
        .word 295, 317, 309, 0
        .word 348, 328, 342, 0
        .word 328, 326, 342, 0
        .word 325, 327, 341, 0
        .word 327, 347, 341, 0
        .word 328, 348, 304, 0
        .word 328, 304, 308, 0
        .word 304, 347, 327, 0
        .word 304, 327, 308, 0
        .word 348, 350, 77, 0
        .word 348, 77, 304, 0
        .word 77, 349, 347, 0
        .word 77, 347, 304, 0
        .word 350, 352, 77, 0
        .word 352, 303, 77, 0
        .word 303, 351, 77, 0
        .word 351, 349, 77, 0
        .word 352, 324, 303, 0
        .word 324, 76, 303, 0
        .word 76, 323, 303, 0
        .word 323, 351, 303, 0
        .word 300, 346, 92, 0
        .word 346, 79, 92, 0
        .word 78, 345, 91, 0
        .word 345, 299, 91, 0
        .word 344, 215, 346, 0
        .word 215, 79, 346, 0
        .word 78, 214, 345, 0
        .word 214, 343, 345, 0
        .word 342, 326, 209, 0
        .word 326, 81, 209, 0
        .word 80, 325, 208, 0
        .word 325, 341, 208, 0
        .word 344, 342, 215, 0
        .word 342, 209, 215, 0
        .word 208, 341, 214, 0
        .word 341, 343, 214, 0
        .word 332, 83, 81, 0
        .word 332, 81, 326, 0
        .word 80, 82, 331, 0
        .word 80, 331, 325, 0
        .word 338, 332, 328, 0
        .word 332, 326, 328, 0
        .word 325, 331, 327, 0
        .word 331, 337, 327, 0
        .word 340, 334, 336, 0
        .word 334, 330, 336, 0
        .word 329, 333, 335, 0
        .word 333, 339, 335, 0
        .word 338, 336, 330, 0
        .word 338, 330, 332, 0
        .word 329, 335, 337, 0
        .word 329, 337, 331, 0
        .word 330, 85, 83, 0
        .word 330, 83, 332, 0
        .word 82, 84, 329, 0
        .word 82, 329, 331, 0
        .word 334, 87, 85, 0
        .word 334, 85, 330, 0
        .word 84, 86, 333, 0
        .word 84, 333, 329, 0
        .word 340, 89, 87, 0
        .word 340, 87, 334, 0
        .word 86, 88, 339, 0
        .word 86, 339, 333, 0
        .word 305, 90, 89, 0
        .word 305, 89, 340, 0
        .word 88, 90, 305, 0
        .word 88, 305, 339, 0
        .word 336, 306, 340, 0
        .word 306, 305, 340, 0
        .word 305, 306, 339, 0
        .word 306, 335, 339, 0
        .word 338, 307, 336, 0
        .word 307, 306, 336, 0
        .word 306, 307, 335, 0
        .word 307, 337, 335, 0
        .word 328, 308, 338, 0
        .word 308, 307, 338, 0
        .word 307, 308, 337, 0
        .word 308, 327, 337, 0
        .word 300, 92, 94, 0
        .word 300, 94, 298, 0
        .word 93, 91, 299, 0
        .word 93, 299, 297, 0
        .word 298, 94, 96, 0
        .word 298, 96, 296, 0
        .word 95, 93, 297, 0
        .word 95, 297, 295, 0
        .word 296, 96, 294, 0
        .word 96, 98, 294, 0
        .word 97, 95, 293, 0
        .word 95, 295, 293, 0
        .word 294, 98, 100, 0
        .word 294, 100, 292, 0
        .word 99, 97, 293, 0
        .word 99, 293, 291, 0
        .word 292, 100, 290, 0
        .word 100, 102, 290, 0
        .word 101, 99, 289, 0
        .word 99, 291, 289, 0
        .word 290, 102, 288, 0
        .word 102, 104, 288, 0
        .word 103, 101, 287, 0
        .word 101, 289, 287, 0
        .word 288, 104, 286, 0
        .word 104, 106, 286, 0
        .word 105, 103, 285, 0
        .word 103, 287, 285, 0
        .word 286, 106, 108, 0
        .word 286, 108, 284, 0
        .word 107, 105, 285, 0
        .word 107, 285, 283, 0
        .word 284, 108, 66, 0
        .word 284, 66, 72, 0
        .word 66, 107, 283, 0
        .word 66, 283, 72, 0
        .word 280, 234, 232, 0
        .word 280, 232, 282, 0
        .word 231, 233, 279, 0
        .word 231, 279, 281, 0
        .word 282, 232, 254, 0
        .word 282, 254, 260, 0
        .word 253, 231, 281, 0
        .word 253, 281, 259, 0
        .word 260, 254, 256, 0
        .word 260, 256, 258, 0
        .word 255, 253, 259, 0
        .word 255, 259, 257, 0
        .word 262, 252, 234, 0
        .word 262, 234, 280, 0
        .word 233, 251, 261, 0
        .word 233, 261, 279, 0
        .word 264, 250, 262, 0
        .word 250, 252, 262, 0
        .word 251, 249, 261, 0
        .word 249, 263, 261, 0
        .word 266, 248, 264, 0
        .word 248, 250, 264, 0
        .word 249, 247, 263, 0
        .word 247, 265, 263, 0
        .word 268, 246, 248, 0
        .word 268, 248, 266, 0
        .word 247, 245, 267, 0
        .word 247, 267, 265, 0
        .word 270, 244, 268, 0
        .word 244, 246, 268, 0
        .word 245, 243, 267, 0
        .word 243, 269, 267, 0
        .word 272, 242, 244, 0
        .word 272, 244, 270, 0
        .word 243, 241, 271, 0
        .word 243, 271, 269, 0
        .word 274, 240, 272, 0
        .word 240, 242, 272, 0
        .word 241, 239, 271, 0
        .word 239, 273, 271, 0
        .word 278, 236, 274, 0
        .word 236, 240, 274, 0
        .word 239, 235, 273, 0
        .word 235, 277, 273, 0
        .word 276, 238, 236, 0
        .word 276, 236, 278, 0
        .word 235, 237, 275, 0
        .word 235, 275, 277, 0
        .word 258, 256, 238, 0
        .word 258, 238, 276, 0
        .word 237, 255, 257, 0
        .word 237, 257, 275, 0
        .word 256, 110, 128, 0
        .word 256, 128, 238, 0
        .word 127, 109, 255, 0
        .word 127, 255, 237, 0
        .word 238, 128, 179, 0
        .word 238, 179, 236, 0
        .word 178, 127, 237, 0
        .word 178, 237, 235, 0
        .word 236, 179, 126, 0
        .word 236, 126, 240, 0
        .word 125, 178, 235, 0
        .word 125, 235, 239, 0
        .word 240, 126, 242, 0
        .word 126, 124, 242, 0
        .word 123, 125, 241, 0
        .word 125, 239, 241, 0
        .word 242, 124, 244, 0
        .word 124, 122, 244, 0
        .word 121, 123, 243, 0
        .word 123, 241, 243, 0
        .word 244, 122, 120, 0
        .word 244, 120, 246, 0
        .word 119, 121, 243, 0
        .word 119, 243, 245, 0
        .word 246, 120, 118, 0
        .word 246, 118, 248, 0
        .word 117, 119, 245, 0
        .word 117, 245, 247, 0
        .word 248, 118, 116, 0
        .word 248, 116, 250, 0
        .word 115, 117, 247, 0
        .word 115, 247, 249, 0
        .word 250, 116, 114, 0
        .word 250, 114, 252, 0
        .word 113, 115, 249, 0
        .word 113, 249, 251, 0
        .word 252, 114, 234, 0
        .word 114, 181, 234, 0
        .word 180, 113, 233, 0
        .word 113, 251, 233, 0
        .word 254, 112, 256, 0
        .word 112, 110, 256, 0
        .word 109, 111, 255, 0
        .word 111, 253, 255, 0
        .word 232, 183, 112, 0
        .word 232, 112, 254, 0
        .word 111, 182, 231, 0
        .word 111, 231, 253, 0
        .word 234, 181, 183, 0
        .word 234, 183, 232, 0
        .word 182, 180, 233, 0
        .word 182, 233, 231, 0
        .word 229, 230, 223, 0
        .word 229, 223, 225, 0
        .word 223, 230, 228, 0
        .word 223, 228, 224, 0
        .word 223, 71, 225, 0
        .word 71, 222, 225, 0
        .word 221, 71, 224, 0
        .word 71, 223, 224, 0
        .word 225, 222, 220, 0
        .word 225, 220, 227, 0
        .word 219, 221, 224, 0
        .word 219, 224, 226, 0
        .word 227, 220, 218, 0
        .word 227, 218, 229, 0
        .word 217, 219, 226, 0
        .word 217, 226, 228, 0
        .word 229, 218, 230, 0
        .word 218, 216, 230, 0
        .word 216, 217, 230, 0
        .word 217, 228, 230, 0
        .word 218, 135, 136, 0
        .word 218, 136, 216, 0
        .word 136, 134, 217, 0
        .word 136, 217, 216, 0
        .word 220, 133, 135, 0
        .word 220, 135, 218, 0
        .word 134, 132, 219, 0
        .word 134, 219, 217, 0
        .word 222, 131, 133, 0
        .word 222, 133, 220, 0
        .word 132, 130, 221, 0
        .word 132, 221, 219, 0
        .word 71, 129, 222, 0
        .word 129, 131, 222, 0
        .word 130, 129, 221, 0
        .word 129, 71, 221, 0
        .word 211, 164, 79, 0
        .word 211, 79, 215, 0
        .word 78, 163, 210, 0
        .word 78, 210, 214, 0
        .word 211, 215, 213, 0
        .word 215, 209, 213, 0
        .word 208, 214, 212, 0
        .word 214, 210, 212, 0
        .word 213, 209, 166, 0
        .word 209, 81, 166, 0
        .word 80, 208, 165, 0
        .word 208, 212, 165, 0
        .word 166, 187, 213, 0
        .word 187, 144, 213, 0
        .word 143, 186, 212, 0
        .word 186, 165, 212, 0
        .word 213, 144, 211, 0
        .word 144, 142, 211, 0
        .word 141, 143, 210, 0
        .word 143, 212, 210, 0
        .word 211, 142, 140, 0
        .word 211, 140, 164, 0
        .word 139, 141, 210, 0
        .word 139, 210, 163, 0
        .word 164, 140, 138, 0
        .word 164, 138, 176, 0
        .word 138, 139, 163, 0
        .word 138, 163, 176, 0
        .word 206, 207, 198, 0
        .word 206, 198, 204, 0
        .word 198, 207, 205, 0
        .word 198, 205, 203, 0
        .word 202, 204, 200, 0
        .word 204, 198, 200, 0
        .word 198, 203, 199, 0
        .word 203, 201, 199, 0
        .word 206, 204, 193, 0
        .word 206, 193, 191, 0
        .word 192, 203, 205, 0
        .word 192, 205, 190, 0
        .word 204, 202, 193, 0
        .word 202, 195, 193, 0
        .word 194, 201, 192, 0
        .word 201, 203, 192, 0
        .word 202, 200, 197, 0
        .word 202, 197, 195, 0
        .word 196, 199, 201, 0
        .word 196, 201, 194, 0
        .word 200, 198, 70, 0
        .word 200, 70, 197, 0
        .word 70, 198, 199, 0
        .word 70, 199, 196, 0
        .word 206, 191, 207, 0
        .word 191, 69, 207, 0
        .word 69, 190, 207, 0
        .word 190, 205, 207, 0
        .word 191, 144, 69, 0
        .word 144, 189, 69, 0
        .word 189, 143, 69, 0
        .word 143, 190, 69, 0
        .word 197, 70, 138, 0
        .word 70, 137, 138, 0
        .word 137, 70, 138, 0
        .word 70, 196, 138, 0
        .word 195, 197, 140, 0
        .word 197, 138, 140, 0
        .word 138, 196, 139, 0
        .word 196, 194, 139, 0
        .word 193, 195, 142, 0
        .word 195, 140, 142, 0
        .word 139, 194, 141, 0
        .word 194, 192, 141, 0
        .word 191, 193, 142, 0
        .word 191, 142, 144, 0
        .word 141, 192, 190, 0
        .word 141, 190, 143, 0
        .word 185, 131, 68, 0
        .word 131, 129, 68, 0
        .word 129, 130, 68, 0
        .word 130, 184, 68, 0
        .word 188, 187, 68, 0
        .word 187, 185, 68, 0
        .word 184, 186, 68, 0
        .word 186, 188, 68, 0
        .word 188, 189, 187, 0
        .word 189, 144, 187, 0
        .word 143, 189, 186, 0
        .word 189, 188, 186, 0
        .word 168, 170, 131, 0
        .word 168, 131, 185, 0
        .word 130, 169, 167, 0
        .word 130, 167, 184, 0
        .word 185, 187, 166, 0
        .word 185, 166, 168, 0
        .word 165, 186, 184, 0
        .word 165, 184, 167, 0
        .word 172, 133, 170, 0
        .word 133, 131, 170, 0
        .word 130, 132, 169, 0
        .word 132, 171, 169, 0
        .word 174, 135, 133, 0
        .word 174, 133, 172, 0
        .word 132, 134, 173, 0
        .word 132, 173, 171, 0
        .word 175, 136, 135, 0
        .word 175, 135, 174, 0
        .word 134, 136, 175, 0
        .word 134, 175, 173, 0
        .word 183, 181, 177, 0
        .word 181, 176, 177, 0
        .word 176, 180, 177, 0
        .word 180, 182, 177, 0
        .word 177, 67, 112, 0
        .word 177, 112, 183, 0
        .word 111, 67, 177, 0
        .word 111, 177, 182, 0
        .word 67, 162, 112, 0
        .word 162, 110, 112, 0
        .word 109, 161, 111, 0
        .word 161, 67, 111, 0
        .word 176, 181, 114, 0
        .word 176, 114, 164, 0
        .word 113, 180, 176, 0
        .word 113, 176, 163, 0
        .word 146, 164, 114, 0
        .word 146, 114, 116, 0
        .word 113, 163, 145, 0
        .word 113, 145, 115, 0
        .word 148, 146, 118, 0
        .word 146, 116, 118, 0
        .word 115, 145, 117, 0
        .word 145, 147, 117, 0
        .word 150, 148, 120, 0
        .word 148, 118, 120, 0
        .word 117, 147, 119, 0
        .word 147, 149, 119, 0
        .word 152, 150, 122, 0
        .word 150, 120, 122, 0
        .word 119, 149, 121, 0
        .word 149, 151, 121, 0
        .word 154, 152, 124, 0
        .word 152, 122, 124, 0
        .word 121, 151, 123, 0
        .word 151, 153, 123, 0
        .word 156, 154, 126, 0
        .word 154, 124, 126, 0
        .word 123, 153, 125, 0
        .word 153, 155, 125, 0
        .word 158, 156, 179, 0
        .word 156, 126, 179, 0
        .word 125, 155, 178, 0
        .word 155, 157, 178, 0
        .word 158, 179, 128, 0
        .word 158, 128, 160, 0
        .word 127, 178, 157, 0
        .word 127, 157, 159, 0
        .word 160, 128, 162, 0
        .word 128, 110, 162, 0
        .word 109, 127, 161, 0
        .word 127, 159, 161, 0
        .word 67, 66, 162, 0
        .word 66, 108, 162, 0
        .word 107, 66, 161, 0
        .word 66, 67, 161, 0
        .word 162, 108, 160, 0
        .word 108, 106, 160, 0
        .word 105, 107, 159, 0
        .word 107, 161, 159, 0
        .word 160, 106, 158, 0
        .word 106, 104, 158, 0
        .word 103, 105, 157, 0
        .word 105, 159, 157, 0
        .word 158, 104, 102, 0
        .word 158, 102, 156, 0
        .word 101, 103, 157, 0
        .word 101, 157, 155, 0
        .word 156, 102, 154, 0
        .word 102, 100, 154, 0
        .word 99, 101, 153, 0
        .word 101, 155, 153, 0
        .word 154, 100, 152, 0
        .word 100, 98, 152, 0
        .word 97, 99, 151, 0
        .word 99, 153, 151, 0
        .word 152, 98, 150, 0
        .word 98, 96, 150, 0
        .word 95, 97, 149, 0
        .word 97, 151, 149, 0
        .word 150, 96, 94, 0
        .word 150, 94, 148, 0
        .word 93, 95, 149, 0
        .word 93, 149, 147, 0
        .word 148, 94, 146, 0
        .word 94, 92, 146, 0
        .word 91, 93, 145, 0
        .word 93, 147, 145, 0
        .word 146, 92, 79, 0
        .word 146, 79, 164, 0
        .word 78, 91, 145, 0
        .word 78, 145, 163, 0
        .word 168, 166, 81, 0
        .word 168, 81, 83, 0
        .word 80, 165, 167, 0
        .word 80, 167, 82, 0
        .word 170, 168, 83, 0
        .word 170, 83, 85, 0
        .word 82, 167, 169, 0
        .word 82, 169, 84, 0
        .word 172, 170, 85, 0
        .word 172, 85, 87, 0
        .word 84, 169, 171, 0
        .word 84, 171, 86, 0
        .word 174, 172, 89, 0
        .word 172, 87, 89, 0
        .word 86, 171, 88, 0
        .word 171, 173, 88, 0
        .word 175, 174, 90, 0
        .word 174, 89, 90, 0
        .word 88, 173, 90, 0
        .word 173, 175, 90, 0
        .word 49, 47, 1, 0
        .word 49, 1, 65, 0
        .word 0, 46, 48, 0
        .word 0, 48, 64, 0
        .word 65, 1, 11, 0
        .word 65, 11, 63, 0
        .word 10, 0, 64, 0
        .word 10, 64, 62, 0
        .word 63, 11, 13, 0
        .word 63, 13, 59, 0
        .word 12, 10, 62, 0
        .word 12, 62, 58, 0
        .word 59, 13, 23, 0
        .word 59, 23, 57, 0
        .word 22, 12, 58, 0
        .word 22, 58, 56, 0
        .word 57, 23, 55, 0
        .word 23, 25, 55, 0
        .word 24, 22, 54, 0
        .word 22, 56, 54, 0
        .word 55, 25, 53, 0
        .word 25, 35, 53, 0
        .word 34, 24, 52, 0
        .word 24, 54, 52, 0
        .word 53, 35, 51, 0
        .word 35, 37, 51, 0
        .word 36, 34, 50, 0
        .word 34, 52, 50, 0
        .word 51, 37, 49, 0
        .word 37, 47, 49, 0
        .word 46, 36, 48, 0
        .word 36, 50, 48, 0
        .word 45, 47, 39, 0
        .word 47, 37, 39, 0
        .word 36, 46, 38, 0
        .word 46, 44, 38, 0
        .word 43, 45, 41, 0
        .word 45, 39, 41, 0
        .word 38, 44, 40, 0
        .word 44, 42, 40, 0
        .word 41, 39, 31, 0
        .word 39, 33, 31, 0
        .word 32, 38, 30, 0
        .word 38, 40, 30, 0
        .word 39, 37, 33, 0
        .word 37, 35, 33, 0
        .word 34, 36, 32, 0
        .word 36, 38, 32, 0
        .word 33, 35, 27, 0
        .word 35, 25, 27, 0
        .word 24, 34, 26, 0
        .word 34, 32, 26, 0
        .word 31, 33, 29, 0
        .word 33, 27, 29, 0
        .word 26, 32, 28, 0
        .word 32, 30, 28, 0
        .word 29, 27, 19, 0
        .word 27, 21, 19, 0
        .word 20, 26, 18, 0
        .word 26, 28, 18, 0
        .word 27, 25, 23, 0
        .word 27, 23, 21, 0
        .word 22, 24, 26, 0
        .word 22, 26, 20, 0
        .word 21, 23, 15, 0
        .word 23, 13, 15, 0
        .word 12, 22, 14, 0
        .word 22, 20, 14, 0
        .word 19, 21, 17, 0
        .word 21, 15, 17, 0
        .word 14, 20, 16, 0
        .word 20, 18, 16, 0
        .word 17, 15, 9, 0
        .word 17, 9, 7, 0
        .word 8, 14, 16, 0
        .word 8, 16, 6, 0
        .word 15, 13, 11, 0
        .word 15, 11, 9, 0
        .word 10, 12, 14, 0
        .word 10, 14, 8, 0
        .word 9, 11, 1, 0
        .word 9, 1, 3, 0
        .word 0, 10, 8, 0
        .word 0, 8, 2, 0
        .word 7, 9, 3, 0
        .word 7, 3, 5, 0
        .word 2, 8, 6, 0
        .word 2, 6, 4, 0
        .word 5, 3, 45, 0
        .word 5, 45, 43, 0
        .word 44, 2, 4, 0
        .word 44, 4, 42, 0
        .word 3, 1, 47, 0
        .word 3, 47, 45, 0
        .word 46, 0, 2, 0
        .word 46, 2, 44, 0

.end

