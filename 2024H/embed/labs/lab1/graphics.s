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

    // TODO: Fix rotation matrix
    push {r0, lr}
    mov r0, r0     // Index for trig table lookup
    ldr r1, =.rotation_matrix
    bl rotation_matrix_y
    pop {r0, lr}

    // Calculate model matrix
    push {lr}
    ldr r0, =.translation_matrix
    ldr r1, =.rotation_matrix
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
    vadd.f32 s1, s6, s1     // y = 1 + y
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

    .vertex_data_size: .word 8
    .index_data_size: .word 12

    .vertex_data:
        .float  1.0, -1.0, -1.0, 1.0
        .float  1.0, -1.0,  1.0, 1.0
        .float -1.0, -1.0,  1.0, 1.0
        .float -1.0, -1.0, -1.0, 1.0
        .float  1.0,  1.0, -1.0, 1.0
        .float  1.0,  1.0,  1.0, 1.0
        .float -1.0,  1.0,  1.0, 1.0
        .float -1.0,  1.0, -1.0, 1.0


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
        .word 1,3,0, 0    // Last value is for padding to make it memory alligned
        .word 7,5,4, 0
        .word 4,1,0, 0
        .word 5,2,1, 0
        .word 2,7,3, 0
        .word 0,7,4, 0
        .word 1,2,3, 0
        .word 7,6,5, 0
        .word 4,5,1, 0
        .word 5,6,2, 0
        .word 2,6,7, 0
        .word 0,3,7, 0

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
.end
