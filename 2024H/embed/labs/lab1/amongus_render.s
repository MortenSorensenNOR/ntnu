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
        .float 1.25, 0.0, 0.0, 0.0
        .float 0.0, 1.25, 0.0, 0.0
        .float 0.0, 0.0, 1.25, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .rotation_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .translation_matrix:
        .float  0.707107, -0.000000, 0.707107, 0.000000
        .float  0.000000,  1.000000, 0.000000, -3.000000
        .float -0.707107,  0.000000, 0.707107, -2.000000
        .float  0.000000,  0.000000, 0.000000, 1.000000

    .view_matrix:
        .float  1.000000, -0.000000,  0.000000, -0.000000
        .float  0.000000,  0.955779, -0.294086, -0.000000
        .float -0.000000,  0.294086,  0.955779, -6.800735
        .float  0.000000,  0.000000,  0.000000,  1.000000

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

    .vertex_data_size: .word 1490
    .index_data_size: .word 2934
    .vertex_data:
        .float 0.000000000, 2.85752797, -1.04546225, 1.0
        .float 0.000000000, 3.13345504, -1.04841363, 1.0
        .float 0.25641644, 3.13336754, -1.02886605, 1.0
        .float 0.252184868, 2.85752797, -1.02551281, 1.0
        .float 0.000000000, 2.5851388, -1.03848183, 1.0
        .float -0.252186835, 2.85752797, -1.0255127, 1.0
        .float -0.256418437, 3.13336754, -1.02886581, 1.0
        .float 0.501476586, 3.13323903, -0.972472727, 1.0
        .float 0.496262401, 2.85752797, -0.968774378, 1.0
        .float 0.246041015, 2.5851388, -1.01744914, 1.0
        .float 0.000000000, 2.34752274, -1.03218341, 1.0
        .float -0.246042982, 2.5851388, -1.01744926, 1.0
        .float 0.240693316, 2.34752274, -1.00996268, 1.0
        .float 0.48596856, 2.5851388, -0.956595719, 1.0
        .float 0.723616302, 3.13246775, -0.881293356, 1.0
        .float 0.722629488, 2.85694981, -0.878573596, 1.0
        .float 0.476090968, 2.34752274, -0.94368583, 1.0
        .float 0.711661458, 2.58474398, -0.860040605, 1.0
        .float 0.000000000, 2.1678617, -1.0277096, 1.0
        .float 0.238325551, 2.16786194, -1.0048703, 1.0
        .float 0.471385419, 2.1678617, -0.935023487, 1.0
        .float 0.698942423, 2.34728813, -0.837575734, 1.0
        .float 0.915708184, 2.8529017, -0.752875268, 1.0
        .float 0.906976938, 2.58198166, -0.734909475, 1.0
        .float 0.692225814, 2.16774845, -0.821885526, 1.0
        .float 0.894186795, 2.3456471, -0.710438311, 1.0
        .float 0.470081717, 2.02297401, -0.92153734, 1.0
        .float 0.237855971, 2.02297401, -0.992218554, 1.0
        .float 0.689705491, 2.02295828, -0.806506932, 1.0
        .float 0.887149513, 2.16695499, -0.69200778, 1.0
        .float 1.04669535, 2.34211087, -0.575505257, 1.0
        .float 1.05626369, 2.57602191, -0.585713327, 1.0
        .float 0.884398401, 2.02284861, -0.676779628, 1.0
        .float 1.04197145, 2.16524506, -0.564800084, 1.0
        .float 0.469112247, 1.88357198, -0.893903315, 1.0
        .float 0.68744421, 1.88306952, -0.782860518, 1.0
        .float 1.0409919, 2.02261066, -0.554242671, 1.0
        .float 0.881802261, 1.88326824, -0.658640385, 1.0
        .float 1.14887953, 2.33986402, -0.409124821, 1.0
        .float 1.14730108, 2.16415453, -0.408272505, 1.0
        .float 1.1483165, 2.02244639, -0.403530538, 1.0
        .float 1.04013503, 1.88479567, -0.542098403, 1.0
        .float 0.682541072, 1.73784137, -0.75107348, 1.0
        .float 0.875849664, 1.73625863, -0.633757055, 1.0
        .float 1.0365082, 1.74164283, -0.522029638, 1.0
        .float 1.14916408, 1.88612998, -0.396703839, 1.0
        .float 1.19768965, 2.16503143, -0.192042053, 1.0
        .float 1.19913876, 2.02254581, -0.19055748, 1.0
        .float 1.14831007, 1.74797106, -0.381283641, 1.0
        .float 1.19966269, 1.88582313, -0.187493026, 1.0
        .float 0.863929808, 1.57874823, -0.599727511, 1.0
        .float 1.02820051, 1.59075809, -0.488837987, 1.0
        .float 1.14492917, 1.60690868, -0.351471722, 1.0
        .float 1.19907522, 1.7489233, -0.178568542, 1.0
        .float 1.19996834, 2.02281094, 0.0563908257, 1.0
        .float 1.19984019, 1.88487065, 0.0568420589, 1.0
        .float 1.19763076, 1.61138594, -0.159894168, 1.0
        .float 1.19877124, 1.7470907, 0.0596879087, 1.0
        .float 1.13980079, 1.46519935, -0.312626183, 1.0
        .float 1.01650202, 1.44154668, -0.446487516, 1.0
        .float 1.19556129, 1.47220099, -0.135343313, 1.0
        .float 1.19758189, 1.60908413, 0.0664210171, 1.0
        .float 1.0033313, 1.30264115, -0.403082311, 1.0
        .float 1.1336844, 1.3249104, -0.274296284, 1.0
        .float 0.846414447, 1.42509556, -0.557591379, 1.0
        .float 0.825534523, 1.28813362, -0.511269569, 1.0
        .float 0.807974219, 1.1571703, -0.472769648, 1.0
        .float 0.989923358, 1.16778636, -0.374127954, 1.0
        .float 1.12565124, 1.18403053, -0.2516388, 1.0
        .float 1.19256055, 1.33039188, -0.111248709, 1.0
        .float 0.977674603, 1.02915215, -0.370376557, 1.0
        .float 1.11552334, 1.04051852, -0.254460394, 1.0
        .float 0.612214863, 1.17071438, -0.552446663, 1.0
        .float 0.799368382, 1.01928687, -0.451909393, 1.0
        .float 1.10780823, 0.896285295, -0.265558332, 1.0
        .float 0.969311357, 0.887497663, -0.376166701, 1.0
        .float 1.17533183, 1.03842974, -0.0950030163, 1.0
        .float 1.16628134, 0.891420126, -0.0992614552, 1.0
        .float 1.10610294, 0.753592491, -0.266490668, 1.0
        .float 1.16445482, 0.747145891, -0.099108316, 1.0
        .float 0.796700537, 0.87618947, -0.441664904, 1.0
        .float 0.966497898, 0.745259285, -0.374215811, 1.0
        .float 1.10567176, 0.612162113, -0.260868043, 1.0
        .float 1.16433501, 0.605086088, -0.0961857662, 1.0
        .float 1.16401792, 0.736879826, 0.0930313319, 1.0
        .float 1.16378105, 0.5937922, 0.0906307548, 1.0
        .float 1.15937924, 0.466774702, -0.0940493271, 1.0
        .float 1.15862679, 0.454776764, 0.0873946622, 1.0
        .float 1.10106921, 0.473685503, -0.256102681, 1.0
        .float 0.965318263, 0.602992296, -0.367171407, 1.0
        .float 1.14914012, 0.333170652, 0.0848919004, 1.0
        .float 1.14987361, 0.344999552, -0.0925807282, 1.0
        .float 1.09234178, 0.350301981, -0.2527619, 1.0
        .float 0.961569488, 0.463184357, -0.361171365, 1.0
        .float 0.793854773, 0.588565111, -0.424823433, 1.0
        .float 0.795465708, 0.732335567, -0.43289414, 1.0
        .float 0.791181386, 0.447251797, -0.418314278, 1.0
        .float 0.955478609, 0.337917805, -0.356384575, 1.0
        .float 0.647615731, 0.581868649, -0.45132181, 1.0
        .float 0.64872241, 0.726721764, -0.460437089, 1.0
        .float 0.642574549, 0.874054432, -0.476975828, 1.0
        .float 0.518818021, 0.874334812, -0.475328177, 1.0
        .float 0.533251226, 0.725992441, -0.458449274, 1.0
        .float 0.532898307, 0.58091259, -0.449272722, 1.0
        .float 0.645880401, 0.439885855, -0.444611222, 1.0
        .float 0.425036013, 0.868771791, -0.425696403, 1.0
        .float 0.442959964, 0.725297689, -0.421149135, 1.0
        .float 0.475573957, 1.02784514, -0.507947803, 1.0
        .float 0.625239909, 1.02458119, -0.50649333, 1.0
        .float 0.390086889, 1.19177127, -0.581069171, 1.0
        .float 0.371707708, 1.00734329, -0.426277161, 1.0
        .float 0.352426469, 0.86154604, -0.321731091, 1.0
        .float 0.279010922, 1.12123966, -0.432983607, 1.0
        .float 0.303952992, 0.98483181, -0.294490308, 1.0
        .float 0.293480396, 0.858290672, -0.164004415, 1.0
        .float 0.368185282, 0.724393845, -0.329519808, 1.0
        .float 0.223768011, 1.08196473, -0.269717962, 1.0
        .float 0.259812295, 0.975199223, -0.142022341, 1.0
        .float 0.184166595, 1.25427318, -0.614280999, 1.0
        .float 0.147023201, 1.18336964, -0.444914073, 1.0
        .float 0.118487097, 1.14169145, -0.267591059, 1.0
        .float 0.197154343, 1.0667522, -0.12254221, 1.0
        .float 0.254266143, 0.858014822, 0.0239017606, 1.0
        .float 0.235860437, 0.974366903, 0.0221138224, 1.0
        .float 0.188483536, 1.06533527, 0.0157607757, 1.0
        .float 0.106348686, 1.12562299, -0.120932825, 1.0
        .float 0.000000000, 1.20121384, -0.452196568, 1.0
        .float 0.000000000, 1.16163492, -0.272373974, 1.0
        .float 0.000000000, 1.14635587, -0.124716245, 1.0
        .float 0.104750499, 1.12389493, 0.00492855161, 1.0
        .float 0.190641567, 1.06825209, 0.159736842, 1.0
        .float 0.231734723, 0.976321697, 0.191432476, 1.0
        .float 0.000000000, 1.14455056, -0.00122205168, 1.0
        .float 0.107631877, 1.12658906, 0.131518334, 1.0
        .float -0.10635066, 1.12562299, -0.12093281, 1.0
        .float -0.104752488, 1.12389493, 0.00492855906, 1.0
        .float 0.000000000, 1.14684343, 0.119342178, 1.0
        .float -0.107633851, 1.12658906, 0.131518334, 1.0
        .float -0.188485503, 1.06533527, 0.0157607757, 1.0
        .float -0.190643549, 1.06825209, 0.159736857, 1.0
        .float -0.118489079, 1.14169168, -0.267591059, 1.0
        .float -0.19715631, 1.06675243, -0.122542195, 1.0
        .float -0.235862404, 0.974366665, 0.0221138299, 1.0
        .float -0.231736675, 0.976321459, 0.191432476, 1.0
        .float -0.223769993, 1.08196497, -0.269717991, 1.0
        .float -0.259814322, 0.975198984, -0.142022341, 1.0
        .float -0.147025153, 1.18336987, -0.444914013, 1.0
        .float -0.279012889, 1.12123966, -0.432983547, 1.0
        .float -0.303954959, 0.984831572, -0.294490248, 1.0
        .float -0.25426811, 0.858014584, 0.0239017457, 1.0
        .float -0.293482393, 0.858290672, -0.164004415, 1.0
        .float -0.371709675, 1.00734329, -0.42627719, 1.0
        .float -0.352428436, 0.86154604, -0.321731061, 1.0
        .float -0.184168562, 1.25427341, -0.614281058, 1.0
        .float -0.390088886, 1.19177127, -0.581069171, 1.0
        .float -0.475575924, 1.02784514, -0.507947743, 1.0
        .float -0.42503795, 0.868771791, -0.425696433, 1.0
        .float -0.368187219, 0.724394083, -0.329519838, 1.0
        .float -0.442961931, 0.725297689, -0.421149105, 1.0
        .float -0.518820047, 0.874334574, -0.475328237, 1.0
        .float -0.533253312, 0.72599268, -0.458449215, 1.0
        .float -0.625241995, 1.02458096, -0.50649327, 1.0
        .float -0.642576635, 0.874054432, -0.476975769, 1.0
        .float -0.648724377, 0.726721764, -0.460437149, 1.0
        .float -0.532900393, 0.58091259, -0.449272722, 1.0
        .float -0.647617698, 0.581869364, -0.45132181, 1.0
        .float -0.442770392, 0.580912113, -0.413785458, 1.0
        .float -0.531898856, 0.438947439, -0.442582279, 1.0
        .float -0.64587456, 0.439998865, -0.44462201, 1.0
        .float -0.791184008, 0.447365284, -0.418323457, 1.0
        .float -0.79385674, 0.588564873, -0.424823403, 1.0
        .float -0.795467734, 0.732336044, -0.43289414, 1.0
        .float -0.961581886, 0.463295937, -0.361177653, 1.0
        .float -0.965320289, 0.602993011, -0.367171347, 1.0
        .float -0.788560867, 0.321444511, -0.412473857, 1.0
        .float -0.955563605, 0.338810444, -0.356434733, 1.0
        .float -0.646203101, 0.313481331, -0.43821314, 1.0
        .float -0.787169337, 0.223763466, -0.406420231, 1.0
        .float -0.948758364, 0.242382526, -0.352028906, 1.0
        .float -1.09248185, 0.351161718, -0.252790779, 1.0
        .float -1.08175707, 0.257149696, -0.250048429, 1.0
        .float -0.943045378, 0.177630424, -0.348533154, 1.0
        .float -1.0723356, 0.194595575, -0.248003095, 1.0
        .float -0.649534881, 0.215337276, -0.431282669, 1.0
        .float -0.786677599, 0.158087254, -0.40136382, 1.0
        .float -0.93900013, 0.14355588, -0.34513548, 1.0
        .float -1.06587684, 0.161809683, -0.245746106, 1.0
        .float -1.12202418, 0.16530323, -0.088315554, 1.0
        .float -1.12867928, 0.195993423, -0.0897292867, 1.0
        .float -1.05547059, 0.149024963, -0.237242937, 1.0
        .float -1.1119808, 0.154053688, -0.083361946, 1.0
        .float -0.786108434, 0.123506784, -0.396889001, 1.0
        .float -0.931599677, 0.129926443, -0.333997607, 1.0
        .float -0.783417046, 0.109627962, -0.38405785, 1.0
        .float -0.656081378, 0.114604473, -0.420341194, 1.0
        .float -0.653604865, 0.149348736, -0.425383866, 1.0
        .float -0.657561004, 0.100659847, -0.406698912, 1.0
        .float -0.549297094, 0.148100615, -0.423511058, 1.0
        .float -0.554178238, 0.113332748, -0.418509752, 1.0
        .float -0.541626513, 0.214133024, -0.429346889, 1.0
        .float -0.467359781, 0.148100376, -0.390699238, 1.0
        .float -0.456856549, 0.214133501, -0.395673633, 1.0
        .float -0.558956742, 0.0993785858, -0.404919654, 1.0
        .float -0.474132836, 0.11333251, -0.386299342, 1.0
        .float -0.398844451, 0.148100615, -0.306017488, 1.0
        .float -0.38597253, 0.214133024, -0.309974909, 1.0
        .float -0.373519868, 0.312343359, -0.314757645, 1.0
        .float -0.446858615, 0.312343597, -0.401629657, 1.0
        .float -0.323092192, 0.214133501, -0.160760731, 1.0
        .float -0.308469504, 0.312343597, -0.163921565, 1.0
        .float -0.407199502, 0.113332033, -0.302479029, 1.0
        .float -0.338057339, 0.148100376, -0.158027917, 1.0
        .float -0.262362719, 0.312343359, 0.0155626573, 1.0
        .float -0.278478116, 0.214133024, 0.0129155926, 1.0
        .float -0.254013062, 0.438947439, 0.0183306225, 1.0
        .float -0.301064968, 0.438946962, -0.166756481, 1.0
        .float -0.238933682, 0.438946962, 0.196783751, 1.0
        .float -0.24754703, 0.312343597, 0.183231816, 1.0
        .float -0.294878513, 0.148100615, 0.0108497143, 1.0
        .float -0.264050186, 0.214133501, 0.168690473, 1.0
        .float -0.280813575, 0.148100376, 0.156563208, 1.0
        .float -0.305596352, 0.113332033, 0.00997865573, 1.0
        .float -0.347811192, 0.11333251, -0.155667931, 1.0
        .float -0.29178521, 0.11333251, 0.149620548, 1.0
        .float -0.318423599, 0.0993783474, 0.0113271102, 1.0
        .float -0.359282255, 0.099378109, -0.149212658, 1.0
        .float -0.416745871, 0.0993783474, -0.292154193, 1.0
        .float -0.481507987, 0.099378109, -0.373691827, 1.0
        .float -0.305032194, 0.099378109, 0.145359263, 1.0
        .float -0.253203273, 0.58091259, 0.0209616832, 1.0
        .float -0.238032073, 0.580912113, 0.208683997, 1.0
        .float -0.300559402, 0.580912113, -0.169689864, 1.0
        .float -0.367476672, 0.438947439, -0.319478482, 1.0
        .float -0.367404401, 0.58091259, -0.324873656, 1.0
        .float -0.25636524, 0.72395277, 0.023113329, 1.0
        .float -0.302548468, 0.723987579, -0.171600014, 1.0
        .float -0.442353696, 0.438946962, -0.407386303, 1.0
        .float -0.242939219, 0.858684301, 0.213637948, 1.0
        .float -0.241723955, 0.724036694, 0.217207611, 1.0
        .float -0.534564137, 0.312343597, -0.436212569, 1.0
        .float -1.11415172, 0.146960974, 0.0864270478, 1.0
        .float -1.12301004, 0.15743804, 0.0855268538, 1.0
        .float -1.1291225, 0.187111378, 0.0849821419, 1.0
        .float -1.13859451, 0.255098104, -0.0910684541, 1.0
        .float -1.13837087, 0.244585037, 0.0843916982, 1.0
        .float -1.1500206, 0.345807076, -0.0926003233, 1.0
        .float -1.14927661, 0.333952904, 0.0848803446, 1.0
        .float -1.10108852, 0.47379303, -0.256106317, 1.0
        .float -1.15939927, 0.466875553, -0.0940517858, 1.0
        .float -1.10567379, 0.612161636, -0.260868073, 1.0
        .float -1.1643368, 0.605086088, -0.0961857513, 1.0
        .float -1.15864551, 0.454874516, 0.0873932093, 1.0
        .float -0.966499925, 0.745259047, -0.374215811, 1.0
        .float -1.10610485, 0.75359273, -0.266490668, 1.0
        .float -0.796702683, 0.87618947, -0.441664904, 1.0
        .float -0.969313383, 0.88749814, -0.376166731, 1.0
        .float -1.10781026, 0.896285295, -0.265558332, 1.0
        .float -1.16445673, 0.747145653, -0.0991083011, 1.0
        .float -0.799370348, 1.01928687, -0.451909333, 1.0
        .float -0.97767663, 1.02915239, -0.370376527, 1.0
        .float -0.807976246, 1.1571703, -0.472769648, 1.0
        .float -0.61221689, 1.17071462, -0.552446604, 1.0
        .float -0.989925325, 1.1677866, -0.374127924, 1.0
        .float -1.11552501, 1.04051876, -0.254460365, 1.0
        .float -1.00333309, 1.30264139, -0.403082311, 1.0
        .float -0.825536609, 1.28813338, -0.511269629, 1.0
        .float -0.628506541, 1.30380368, -0.610156119, 1.0
        .float -1.01650405, 1.44154668, -0.446487457, 1.0
        .float -0.846416533, 1.42509556, -0.557591379, 1.0
        .float -1.1336863, 1.3249104, -0.274296284, 1.0
        .float -1.13980269, 1.46519947, -0.312626183, 1.0
        .float -1.02820253, 1.59075832, -0.488838047, 1.0
        .float -1.1449312, 1.6069088, -0.351471722, 1.0
        .float -0.654154062, 1.43751276, -0.665973604, 1.0
        .float -0.863931835, 1.57874846, -0.599727571, 1.0
        .float -1.14831197, 1.74797106, -0.381283641, 1.0
        .float -1.03651011, 1.74164283, -0.522029638, 1.0
        .float -1.19763267, 1.6113857, -0.159894139, 1.0
        .float -1.19907713, 1.74892342, -0.178568542, 1.0
        .float -1.19966483, 1.88582313, -0.187493026, 1.0
        .float -1.14916599, 1.88612998, -0.396703809, 1.0
        .float -0.875851631, 1.73625875, -0.633756995, 1.0
        .float -1.04013693, 1.88479555, -0.542098403, 1.0
        .float -1.19914055, 2.02254581, -0.19055748, 1.0
        .float -1.14831841, 2.02244663, -0.403530538, 1.0
        .float -1.1998421, 1.88487065, 0.0568420514, 1.0
        .float -1.19997025, 2.02281094, 0.0563908294, 1.0
        .float -1.19769156, 2.16503143, -0.192042112, 1.0
        .float -1.19866574, 2.16669512, 0.0564431138, 1.0
        .float -1.04099381, 2.02261066, -0.554242611, 1.0
        .float -1.1473031, 2.16415453, -0.408272505, 1.0
        .float -1.1975292, 2.34502125, 0.0566555746, 1.0
        .float -1.19729614, 2.34168053, -0.190026253, 1.0
        .float -1.04197335, 2.16524506, -0.564800084, 1.0
        .float -1.14888132, 2.33986402, -0.409124821, 1.0
        .float -0.884400368, 2.02284861, -0.676779628, 1.0
        .float -0.881804347, 1.88326824, -0.658640385, 1.0
        .float -0.88715148, 2.16695499, -0.69200772, 1.0
        .float -1.04669714, 2.34211087, -0.575505257, 1.0
        .float -1.1538626, 2.57219005, -0.403499216, 1.0
        .float -1.19857836, 2.57511139, -0.182475895, 1.0
        .float -0.894188881, 2.3456471, -0.710438311, 1.0
        .float -1.05626559, 2.57602191, -0.585713327, 1.0
        .float -0.689707518, 2.02295828, -0.806506991, 1.0
        .float -0.692227781, 2.16774845, -0.821885586, 1.0
        .float -0.698944449, 2.34728813, -0.837575674, 1.0
        .float -0.906978965, 2.58198166, -0.734909415, 1.0
        .float -1.15401459, 2.83840179, -0.393988103, 1.0
        .float -1.06096649, 2.84415007, -0.589867115, 1.0
        .float -0.915710211, 2.8529017, -0.752875268, 1.0
        .float -0.711663485, 2.58474398, -0.860040665, 1.0
        .float -0.471387416, 2.1678617, -0.935023487, 1.0
        .float -0.476092935, 2.34752274, -0.94368583, 1.0
        .float -0.485970587, 2.5851388, -0.956595719, 1.0
        .float -0.722631454, 2.85694981, -0.878573656, 1.0
        .float -0.910452545, 3.12723875, -0.752127409, 1.0
        .float -1.05102396, 3.11584949, -0.583207726, 1.0
        .float -0.496264368, 2.85752797, -0.968774378, 1.0
        .float -0.723618269, 3.13246775, -0.881293356, 1.0
        .float -0.240695283, 2.34752274, -1.0099628, 1.0
        .float -0.501478612, 3.13323903, -0.972472727, 1.0
        .float -0.892080545, 3.38749123, -0.737191916, 1.0
        .float -0.71405077, 3.3931098, -0.868792892, 1.0
        .float -0.499683291, 3.39410877, -0.962907732, 1.0
        .float -0.695466101, 3.62625742, -0.843149424, 1.0
        .float -0.863718867, 3.62094855, -0.714592159, 1.0
        .float -1.02722025, 3.37485218, -0.569083393, 1.0
        .float -0.991999388, 3.60940075, -0.551556945, 1.0
        .float -0.826687574, 3.82039404, -0.68210423, 1.0
        .float -0.943891823, 3.81140423, -0.529441714, 1.0
        .float -1.07507896, 3.60356951, -0.361653864, 1.0
        .float -1.01851964, 3.81095409, -0.34843573, 1.0
        .float -1.11438942, 3.36678839, -0.37314868, 1.0
        .float -1.10992324, 3.61332631, -0.154467523, 1.0
        .float -1.04901505, 3.82552195, -0.148200363, 1.0
        .float -0.938234806, 3.98371601, -0.33434698, 1.0
        .float -0.961335301, 4.00442028, -0.141879767, 1.0
        .float -1.0426755, 3.83875394, 0.0587838143, 1.0
        .float -0.954033971, 4.01846457, 0.0592628084, 1.0
        .float -1.15142548, 3.3732636, -0.160210639, 1.0
        .float -1.10430312, 3.62529111, 0.0583754182, 1.0
        .float -1.17953074, 3.11308837, -0.165904909, 1.0
        .float -1.14636981, 3.38371325, 0.058044821, 1.0
        .float -1.14091122, 3.10825372, -0.383765101, 1.0
        .float -1.19495237, 2.84235072, -0.173105776, 1.0
        .float -1.17511475, 3.12206364, 0.0577649362, 1.0
        .float -1.19166398, 2.84969139, 0.0574477278, 1.0
        .float -1.19711065, 2.58046365, 0.0570358485, 1.0
        .float -0.831182361, 4.16710758, 0.0597289912, 1.0
        .float -0.839393914, 4.15209055, -0.138678968, 1.0
        .float -0.669038773, 4.28773403, 0.0600996986, 1.0
        .float -0.677616894, 4.27105093, -0.141179383, 1.0
        .float -0.824769735, 4.12349796, -0.327389747, 1.0
        .float -0.670191705, 4.23289967, -0.334096164, 1.0
        .float -0.878933012, 3.97464347, -0.503317893, 1.0
        .float -0.785348892, 4.09813499, -0.488566607, 1.0
        .float -0.646880388, 4.18770981, -0.503286541, 1.0
        .float -0.475629896, 4.31147194, -0.347968727, 1.0
        .float -0.462512195, 4.25039816, -0.529383361, 1.0
        .float -0.452966392, 4.15806818, -0.682104111, 1.0
        .float -0.629402518, 4.1167593, -0.637556374, 1.0
        .float -0.782231033, 3.97794175, -0.637556314, 1.0
        .float -0.739698648, 4.07278776, -0.593862474, 1.0
        .float -0.64287436, 3.99572039, -0.733348191, 1.0
        .float -0.459749579, 4.01677608, -0.799902737, 1.0
        .float -0.239692882, 4.03407288, -0.841576695, 1.0
        .float -0.236511871, 4.18588209, -0.712998331, 1.0
        .float -0.247146741, 3.84461689, -0.934014618, 1.0
        .float -0.475743473, 3.83587623, -0.883325815, 1.0
        .float -0.670191407, 3.82831645, -0.799902737, 1.0
        .float -0.253740728, 3.63181925, -0.991243184, 1.0
        .float -0.490444452, 3.62828541, -0.935476482, 1.0
        .float 0.000000000, 3.63404489, -1.00995231, 1.0
        .float 0.000000000, 3.84912086, -0.951212108, 1.0
        .float 0.000000000, 3.39583683, -1.03946447, 1.0
        .float -0.257196546, 3.39513683, -1.02010798, 1.0
        .float 0.257194549, 3.39513683, -1.02010798, 1.0
        .float 0.253738731, 3.63181925, -0.991243064, 1.0
        .float 0.499681354, 3.39410877, -0.962907732, 1.0
        .float 0.490442485, 3.62828541, -0.935476601, 1.0
        .float 0.247144759, 3.84461689, -0.934014618, 1.0
        .float 0.475741506, 3.83587623, -0.883325815, 1.0
        .float 0.695464075, 3.62625742, -0.843149424, 1.0
        .float 0.670189381, 3.82831645, -0.799902797, 1.0
        .float 0.459747583, 4.01677608, -0.799902737, 1.0
        .float 0.642872274, 3.99572039, -0.733348191, 1.0
        .float 0.23969093, 4.03407288, -0.841576636, 1.0
        .float 0.452964425, 4.15806818, -0.682104111, 1.0
        .float 0.629400492, 4.1167593, -0.637556314, 1.0
        .float 0.739696622, 4.07278776, -0.593862474, 1.0
        .float 0.782229066, 3.97794151, -0.637556374, 1.0
        .float 0.785346866, 4.09813499, -0.488566667, 1.0
        .float 0.646878421, 4.18770981, -0.503286541, 1.0
        .float 0.236509904, 4.18588209, -0.712998331, 1.0
        .float 0.462510228, 4.25039816, -0.529383421, 1.0
        .float 0.824767709, 4.12349796, -0.327389717, 1.0
        .float 0.670189619, 4.23289967, -0.334096134, 1.0
        .float 0.878931046, 3.97464347, -0.503317893, 1.0
        .float 0.826685488, 3.82039404, -0.68210429, 1.0
        .float 0.943889737, 3.81140423, -0.529441774, 1.0
        .float 0.93823272, 3.98371601, -0.33434701, 1.0
        .float 0.839391828, 4.15209055, -0.138678968, 1.0
        .float 1.01851773, 3.81095409, -0.34843573, 1.0
        .float 0.961333275, 4.00442028, -0.141879767, 1.0
        .float 0.863716781, 3.62094855, -0.714592159, 1.0
        .float 0.991997302, 3.60940075, -0.551557064, 1.0
        .float 0.714048743, 3.3931098, -0.86879307, 1.0
        .float 0.892078519, 3.38749123, -0.737191975, 1.0
        .float 1.02721834, 3.37485218, -0.569083393, 1.0
        .float 1.07507718, 3.60356951, -0.361653835, 1.0
        .float 0.910450578, 3.12723875, -0.752127349, 1.0
        .float 1.05102193, 3.11584949, -0.583207726, 1.0
        .float 1.06096458, 2.84415007, -0.589867115, 1.0
        .float 1.11438751, 3.36678839, -0.37314868, 1.0
        .float 1.14090931, 3.10825372, -0.383765101, 1.0
        .float 1.15401256, 2.83840179, -0.393988132, 1.0
        .float 1.17952895, 3.11308837, -0.165904909, 1.0
        .float 1.15142357, 3.3732636, -0.160210639, 1.0
        .float 1.10992134, 3.61332631, -0.154467523, 1.0
        .float 1.14636779, 3.38371325, 0.058044821, 1.0
        .float 1.10430133, 3.62529111, 0.0583754182, 1.0
        .float 1.04901314, 3.82552195, -0.148200363, 1.0
        .float 1.04267359, 3.83875394, 0.0587838143, 1.0
        .float 0.954031944, 4.01846457, 0.0592628084, 1.0
        .float 0.831180334, 4.16710758, 0.0597289875, 1.0
        .float 0.677614868, 4.27105093, -0.141179353, 1.0
        .float 0.669036806, 4.28773403, 0.0600997023, 1.0
        .float 0.475627929, 4.31147194, -0.347968698, 1.0
        .float 0.478221744, 4.35811138, -0.146892637, 1.0
        .float 0.24696067, 4.35831833, -0.360126197, 1.0
        .float 0.241024107, 4.28875446, -0.550141335, 1.0
        .float 0.470717251, 4.3765316, 0.0603716336, 1.0
        .float 0.247472584, 4.40971279, -0.152273804, 1.0
        .float 0.000000000, 4.3737874, -0.365181655, 1.0
        .float 0.000000000, 4.30187607, -0.558289528, 1.0
        .float 0.000000000, 4.19609833, -0.72444129, 1.0
        .float -0.246962652, 4.35831833, -0.360126168, 1.0
        .float -0.241026059, 4.28875446, -0.550141275, 1.0
        .float 0.000000000, 4.42652845, -0.154621065, 1.0
        .float -0.247474536, 4.40971279, -0.152273774, 1.0
        .float -0.478223681, 4.35811138, -0.146892607, 1.0
        .float -0.470719218, 4.3765316, 0.0603716299, 1.0
        .float -0.243112683, 4.42920017, 0.0605532676, 1.0
        .float 0.000000000, 4.44634867, 0.060620863, 1.0
        .float 0.243110701, 4.42920017, 0.0605532601, 1.0
        .float 0.000000000, 4.04132175, -0.856210709, 1.0
        .float 1.17511284, 3.12206364, 0.05776494, 1.0
        .float 1.19495034, 2.84235072, -0.173105806, 1.0
        .float 1.19166207, 2.84969139, 0.0574477166, 1.0
        .float 1.15386057, 2.57219005, -0.403499216, 1.0
        .float 1.19857633, 2.57511139, -0.182475835, 1.0
        .float 1.19729412, 2.34168053, -0.190026253, 1.0
        .float 1.19710863, 2.58046365, 0.0570358485, 1.0
        .float 1.19752729, 2.34502125, 0.0566555858, 1.0
        .float 1.19866383, 2.16669512, 0.0564431176, 1.0
        .float -0.238327503, 2.16786194, -1.00487018, 1.0
        .float 0.000000000, 2.02297401, -1.01509249, 1.0
        .float -0.237857923, 2.02297401, -0.992218673, 1.0
        .float 0.000000000, 1.88388145, -0.985276878, 1.0
        .float -0.470083684, 2.02297401, -0.92153734, 1.0
        .float -0.2376149, 1.88384283, -0.962770045, 1.0
        .float -0.469114244, 1.88357198, -0.893903375, 1.0
        .float 0.000000000, 1.74478912, -0.943969309, 1.0
        .float -0.236832917, 1.74447954, -0.921913207, 1.0
        .float 0.237612933, 1.88384283, -0.962770045, 1.0
        .float 0.23683098, 1.74447954, -0.921913266, 1.0
        .float 0.000000000, 1.60696435, -0.897140622, 1.0
        .float -0.234350622, 1.6058737, -0.875569999, 1.0
        .float -0.466748863, 1.74231267, -0.855835974, 1.0
        .float 0.000000000, 1.47674489, -0.837051332, 1.0
        .float 0.23434864, 1.60587358, -0.875570059, 1.0
        .float 0.466746867, 1.74231279, -0.855836034, 1.0
        .float 0.460872442, 1.59912491, -0.812088251, 1.0
        .float 0.226514399, 1.47390127, -0.817165196, 1.0
        .float 0.446507066, 1.46108055, -0.758526146, 1.0
        .float 0.672343194, 1.58537197, -0.712659717, 1.0
        .float 0.654152036, 1.43751276, -0.665973604, 1.0
        .float 0.420618743, 1.33282113, -0.68798244, 1.0
        .float 0.210130692, 1.35484672, -0.735680044, 1.0
        .float 0.000000000, 1.36153817, -0.75162375, 1.0
        .float 0.000000000, 1.26796055, -0.625136256, 1.0
        .float 0.628504515, 1.30380392, -0.610156178, 1.0
        .float -0.210132673, 1.35484672, -0.735680044, 1.0
        .float -0.42062071, 1.33282089, -0.68798244, 1.0
        .float -0.446509063, 1.46108043, -0.758526087, 1.0
        .float -0.226516351, 1.47390127, -0.817165196, 1.0
        .float -0.460874408, 1.59912491, -0.812088251, 1.0
        .float -0.672345281, 1.58537197, -0.712659717, 1.0
        .float -0.682543159, 1.73784125, -0.75107348, 1.0
        .float -0.687446237, 1.88306963, -0.782860458, 1.0
        .float -1.19877315, 1.7470907, 0.0596878938, 1.0
        .float -1.19758368, 1.60908413, 0.0664210245, 1.0
        .float -1.19556332, 1.47220099, -0.135343283, 1.0
        .float -1.19631243, 1.46934128, 0.0753924996, 1.0
        .float -1.19256246, 1.33039212, -0.111248709, 1.0
        .float -1.19420266, 1.32639527, 0.0842404515, 1.0
        .float -1.12565315, 1.18403053, -0.2516388, 1.0
        .float -1.18619204, 1.18565679, -0.096017845, 1.0
        .float -1.1753335, 1.03842974, -0.0950030312, 1.0
        .float -1.18809676, 1.18007755, 0.0908928216, 1.0
        .float -1.17641497, 1.03110957, 0.0939271599, 1.0
        .float -1.16628313, 0.891419888, -0.0992614552, 1.0
        .float -1.16629291, 0.882468939, 0.0942297876, 1.0
        .float -1.1640197, 0.736879826, 0.0930313319, 1.0
        .float -1.16378295, 0.5937922, 0.0906307548, 1.0
        .float 0.242937237, 0.858684301, 0.213637948, 1.0
        .float 0.256363243, 0.723952532, 0.023113329, 1.0
        .float 0.241721958, 0.724036932, 0.217207611, 1.0
        .float 0.302546531, 0.723987579, -0.171600014, 1.0
        .float 0.253201306, 0.58091259, 0.0209616832, 1.0
        .float 0.300557435, 0.580912113, -0.169689834, 1.0
        .float 0.238030076, 0.580912113, 0.208683997, 1.0
        .float 0.301091194, 0.438833237, -0.166751504, 1.0
        .float 0.25404191, 0.438833475, 0.018326927, 1.0
        .float 0.367402464, 0.58091259, -0.324873656, 1.0
        .float 0.367498994, 0.438833475, -0.3194713, 1.0
        .float 0.442768455, 0.580912113, -0.413785487, 1.0
        .float 0.442371577, 0.438833237, -0.407377303, 1.0
        .float 0.373712093, 0.311433554, -0.314700365, 1.0
        .float 0.447015464, 0.311433077, -0.401557475, 1.0
        .float 0.531911373, 0.438833475, -0.44257161, 1.0
        .float 0.534678757, 0.311433554, -0.436127573, 1.0
        .float 0.646263957, 0.312571287, -0.438127249, 1.0
        .float 0.541959703, 0.211516619, -0.42910251, 1.0
        .float 0.649713635, 0.212722301, -0.431035668, 1.0
        .float 0.788553655, 0.320539236, -0.412400484, 1.0
        .float 0.787152648, 0.221161366, -0.40620932, 1.0
        .float 0.94851768, 0.239817619, -0.351884693, 1.0
        .float 0.786655009, 0.154466152, -0.401070356, 1.0
        .float 0.942711473, 0.174061775, -0.348332524, 1.0
        .float 0.653854549, 0.145710707, -0.425040215, 1.0
        .float 0.938759565, 0.140990734, -0.344991326, 1.0
        .float 0.786091685, 0.12090373, -0.39667812, 1.0
        .float 1.07178128, 0.191156626, -0.247887284, 1.0
        .float 1.06547785, 0.159337759, -0.245662898, 1.0
        .float 1.08135808, 0.254677534, -0.249965221, 1.0
        .float 1.13817585, 0.252775908, -0.0910120979, 1.0
        .float 1.1280973, 0.192762852, -0.0896508619, 1.0
        .float 1.12160528, 0.162981033, -0.0882592127, 1.0
        .float 1.05533051, 0.148165464, -0.237213969, 1.0
        .float 1.11183381, 0.153245926, -0.083342351, 1.0
        .float 1.12262118, 0.15518856, 0.0855600759, 1.0
        .float 1.11401534, 0.146178722, 0.0864385962, 1.0
        .float 1.12858224, 0.183981419, 0.0850283578, 1.0
        .float 1.13798189, 0.242335081, 0.0844249204, 1.0
        .float 0.93151468, 0.129034519, -0.33394748, 1.0
        .float 0.783409894, 0.108722448, -0.383984476, 1.0
        .float 0.656260192, 0.111989021, -0.420094192, 1.0
        .float 0.657621861, 0.0997498035, -0.406613052, 1.0
        .float 0.549761474, 0.144459963, -0.423171192, 1.0
        .float 0.554511368, 0.110715389, -0.418265492, 1.0
        .float 0.467993081, 0.144459724, -0.390410542, 1.0
        .float 0.457311183, 0.211516857, -0.395466179, 1.0
        .float 0.559071362, 0.0984683037, -0.404834718, 1.0
        .float 0.4745875, 0.110715389, -0.386091828, 1.0
        .float 0.399618983, 0.144459963, -0.305788249, 1.0
        .float 0.38652876, 0.21151638, -0.309810102, 1.0
        .float 0.308692902, 0.311433077, -0.16388163, 1.0
        .float 0.323738039, 0.211516142, -0.160645932, 1.0
        .float 0.407755673, 0.110715628, -0.302314252, 1.0
        .float 0.338956773, 0.144459724, -0.157868177, 1.0
        .float 0.262607485, 0.311433554, 0.0155331194, 1.0
        .float 0.279185563, 0.211516619, 0.0128306709, 1.0
        .float 0.238963231, 0.438833237, 0.196761757, 1.0
        .float 0.247797176, 0.311433077, 0.183055937, 1.0
        .float 0.295863539, 0.144459963, 0.0107315555, 1.0
        .float 0.26477313, 0.211516619, 0.168184757, 1.0
        .float 0.281820118, 0.144459963, 0.155859649, 1.0
        .float 0.306303769, 0.110715389, 0.00989373401, 1.0
        .float 0.348457158, 0.110716105, -0.155553132, 1.0
        .float 0.292508125, 0.110715628, 0.149114862, 1.0
        .float 0.318668336, 0.0984683037, 0.011297565, 1.0
        .float 0.359505653, 0.0984683037, -0.149172693, 1.0
        .float 0.416938066, 0.0984680653, -0.292096913, 1.0
        .float 0.481664836, 0.0984685421, -0.373619646, 1.0
        .float 0.305282354, 0.0984680653, 0.14518337, 1.0
        .float 1.16629112, 0.8824687, 0.0942297876, 1.0
        .float 1.17641294, 1.03110957, 0.0939271599, 1.0
        .float 1.18619013, 1.18565679, -0.096017845, 1.0
        .float 1.18809485, 1.18007803, 0.0908928216, 1.0
        .float 1.19420087, 1.32639527, 0.0842404515, 1.0
        .float 1.19631052, 1.4693414, 0.0753924921, 1.0
        .float 1.13836098, 3.12568903, 0.275614798, 1.0
        .float 1.15438938, 2.85307884, 0.281608164, 1.0
        .float 1.11004364, 3.38648582, 0.271010846, 1.0
        .float 1.05419838, 3.38610721, 0.473259985, 1.0
        .float 1.08102858, 3.12659264, 0.480429858, 1.0
        .float 1.09501481, 2.85400629, 0.487846553, 1.0
        .float 1.15884984, 2.58314323, 0.28989777, 1.0
        .float 1.15834963, 2.34683847, 0.296694994, 1.0
        .float 1.09607708, 2.58387256, 0.497814268, 1.0
        .float 1.00798273, 3.12906051, 0.666327417, 1.0
        .float 1.01855981, 2.85536575, 0.668094158, 1.0
        .float 0.983957469, 3.38897824, 0.659919024, 1.0
        .float 0.877031207, 3.39282203, 0.823151588, 1.0
        .float 0.895480335, 3.13188601, 0.828338861, 1.0
        .float 0.900958717, 2.85680294, 0.823586106, 1.0
        .float 1.01473188, 2.58441901, 0.669554114, 1.0
        .float 1.0922327, 2.34736657, 0.505909145, 1.0
        .float 1.00598049, 2.34750319, 0.670489311, 1.0
        .float 0.892531037, 2.58490229, 0.815299392, 1.0
        .float 0.721745074, 3.13311768, 0.961580813, 1.0
        .float 0.720785677, 2.85743713, 0.955654383, 1.0
        .float 0.712167859, 3.39433002, 0.955247998, 1.0
        .float 0.499681324, 3.39474177, 1.05196548, 1.0
        .float 0.501476526, 3.13331819, 1.06059921, 1.0
        .float 0.496262372, 2.85752797, 1.05671227, 1.0
        .float 0.709855795, 2.58510923, 0.945357203, 1.0
        .float 0.880025089, 2.34752274, 0.808079898, 1.0
        .float 0.697172225, 2.34752274, 0.936457694, 1.0
        .float 0.48596853, 2.5851388, 1.04911566, 1.0
        .float 0.25641644, 3.13344669, 1.12069666, 1.0
        .float 0.252184868, 2.85752797, 1.11852765, 1.0
        .float 0.257194549, 3.39576983, 1.11045814, 1.0
        .float 0.000000000, 3.39646983, 1.12999928, 1.0
        .float 0.000000000, 3.13353419, 1.14077353, 1.0
        .float 0.000000000, 2.85752797, 1.13920259, 1.0
        .float 0.246041, 2.5851388, 1.11328661, 1.0
        .float 0.476090938, 2.34752274, 1.04247379, 1.0
        .float 0.240693286, 2.34752274, 1.10861242, 1.0
        .float 0.000000000, 2.5851388, 1.13479316, 1.0
        .float -0.252186805, 2.85752797, 1.11852765, 1.0
        .float -0.246042967, 2.5851388, 1.11328661, 1.0
        .float -0.256418407, 3.13344669, 1.12069678, 1.0
        .float -0.496264309, 2.85752797, 1.05671239, 1.0
        .float -0.485970497, 2.5851388, 1.04911566, 1.0
        .float -0.476092905, 2.34752274, 1.04247379, 1.0
        .float -0.240695238, 2.34752274, 1.1086123, 1.0
        .float 0.000000000, 2.34752274, 1.13081312, 1.0
        .float -0.238327503, 2.16786194, 1.10611916, 1.0
        .float -0.471387386, 2.1678617, 1.03942847, 1.0
        .float -0.690479815, 2.16786957, 0.932768881, 1.0
        .float -0.697174191, 2.34752274, 0.936457694, 1.0
        .float -0.709857821, 2.58510923, 0.945357263, 1.0
        .float -0.873167276, 2.16792393, 0.804958642, 1.0
        .float -0.880027175, 2.34752274, 0.808079898, 1.0
        .float -0.870499611, 2.02304268, 0.804491401, 1.0
        .float -0.687969983, 2.0229826, 0.932403743, 1.0
        .float -0.470083624, 2.02297401, 1.03867435, 1.0
        .float -0.68614465, 1.88389802, 0.931279242, 1.0
        .float -0.86854142, 1.88401318, 0.803849518, 1.0
        .float -1.0010289, 2.02316809, 0.668599486, 1.0
        .float -1.00071204, 1.88426781, 0.667126238, 1.0
        .float -1.00034225, 1.74565887, 0.664662778, 1.0
        .float -0.866872191, 1.74508464, 0.799139619, 1.0
        .float -0.684271216, 1.74482584, 0.922229946, 1.0
        .float -0.469264209, 1.88388145, 1.03645682, 1.0
        .float -1.0000788, 1.60708535, 0.659544647, 1.0
        .float -0.865807235, 1.60619688, 0.786421537, 1.0
        .float -1.09442985, 1.60791731, 0.501066864, 1.0
        .float -1.09439087, 1.74612951, 0.501997828, 1.0
        .float -1.09433794, 1.46806753, 0.498769283, 1.0
        .float -1.00004816, 1.46697056, 0.648464859, 1.0
        .float -0.865540922, 1.46694207, 0.76263237, 1.0
        .float -0.682533622, 1.60621321, 0.898907244, 1.0
        .float -0.999859631, 1.32375669, 0.62863946, 1.0
        .float -1.09402907, 1.3248837, 0.492497176, 1.0
        .float -1.16016924, 1.46809912, 0.298461109, 1.0
        .float -1.15904331, 1.32492042, 0.299320161, 1.0
        .float -1.09141731, 1.17840838, 0.478902519, 1.0
        .float -1.15476167, 1.17834496, 0.296821207, 1.0
        .float -0.997084737, 1.17727542, 0.601020873, 1.0
        .float -0.865743935, 1.32631755, 0.72670114, 1.0
        .float -1.08524501, 1.02960539, 0.456536919, 1.0
        .float -0.990173697, 1.02827024, 0.568530798, 1.0
        .float -1.14589357, 1.02917075, 0.289434075, 1.0
        .float -1.07956815, 0.881393909, 0.432291687, 1.0
        .float -0.983122826, 0.879733324, 0.538232327, 1.0
        .float -0.852927744, 0.878076315, 0.610414684, 1.0
        .float -0.858943045, 1.03010154, 0.643900394, 1.0
        .float -0.979637742, 0.734238148, 0.515587449, 1.0
        .float -0.848794639, 0.730585575, 0.587256253, 1.0
        .float -1.13813424, 0.880436659, 0.279471368, 1.0
        .float -1.07791054, 0.736239195, 0.412751406, 1.0
        .float -0.976712584, 0.590434551, 0.495513409, 1.0
        .float -0.845039904, 0.586046696, 0.567389488, 1.0
        .float -0.700103939, 0.728342772, 0.636886477, 1.0
        .float -0.696872056, 0.583018541, 0.616621256, 1.0
        .float -0.839766562, 0.444276571, 0.544362068, 1.0
        .float -0.693335712, 0.441106558, 0.593000472, 1.0
        .float -1.0763545, 0.592839718, 0.394933134, 1.0
        .float -0.970700026, 0.448993206, 0.472984493, 1.0
        .float -0.833737969, 0.317635298, 0.524155855, 1.0
        .float -0.691141486, 0.314455509, 0.571720481, 1.0
        .float -0.560201883, 0.312954187, 0.588952124, 1.0
        .float -0.55861032, 0.439575911, 0.61105603, 1.0
        .float -0.691286504, 0.216153622, 0.559750557, 1.0
        .float -0.565832913, 0.214712381, 0.576058984, 1.0
        .float -0.9621014, 0.322591543, 0.453748077, 1.0
        .float -0.828265786, 0.219293594, 0.513483763, 1.0
        .float -0.69249922, 0.150032759, 0.554690838, 1.0
        .float -0.572195113, 0.148649454, 0.570217133, 1.0
        .float -0.470990688, 0.214205742, 0.555959284, 1.0
        .float -0.48095125, 0.148169041, 0.549988449, 1.0
        .float -0.576261878, 0.113862753, 0.565849364, 1.0
        .float -0.487370014, 0.113399029, 0.545617223, 1.0
        .float -0.824194431, 0.15312624, 0.50954771, 1.0
        .float -0.693241239, 0.115208626, 0.550809979, 1.0
        .float -0.58021003, 0.09988904, 0.552923083, 1.0
        .float -0.49429962, 0.0994422436, 0.533159435, 1.0
        .float -0.426328927, 0.0993783474, 0.474588543, 1.0
        .float -0.417119443, 0.113332033, 0.48620221, 1.0
        .float -0.36575067, 0.099378109, 0.377769738, 1.0
        .float -0.40903756, 0.148100615, 0.49194926, 1.0
        .float -0.354539365, 0.11333251, 0.388577461, 1.0
        .float -0.321498901, 0.0993783474, 0.262478083, 1.0
        .float -0.345050991, 0.148100376, 0.398075491, 1.0
        .float -0.308821559, 0.113332033, 0.271213114, 1.0
        .float -0.396583796, 0.214133024, 0.500633717, 1.0
        .float -0.298296213, 0.148100615, 0.28238818, 1.0
        .float -0.330508411, 0.214133501, 0.413776726, 1.0
        .float -0.282211214, 0.214133024, 0.301500261, 1.0
        .float -0.38455829, 0.312343359, 0.516020834, 1.0
        .float -0.316306651, 0.312343597, 0.435342371, 1.0
        .float -0.266404033, 0.312343359, 0.325025231, 1.0
        .float -0.378771752, 0.438947439, 0.538908839, 1.0
        .float -0.309135556, 0.438946962, 0.460119873, 1.0
        .float -0.457437485, 0.43902564, 0.591141939, 1.0
        .float -0.461563796, 0.312419891, 0.568970561, 1.0
        .float -0.458016187, 0.580989361, 0.615553081, 1.0
        .float -0.378776789, 0.58091259, 0.56326586, 1.0
        .float -0.308692396, 0.580912113, 0.484056383, 1.0
        .float -0.258214504, 0.438947439, 0.347954482, 1.0
        .float -0.381430894, 0.725525618, 0.582960844, 1.0
        .float -0.460228592, 0.726350069, 0.636169672, 1.0
        .float -0.560290694, 0.58152914, 0.635315478, 1.0
        .float -0.562636554, 0.727237225, 0.656166017, 1.0
        .float -0.559762418, 0.880260468, 0.683218837, 1.0
        .float -0.456462085, 0.876687765, 0.659543037, 1.0
        .float -0.379069179, 0.870597124, 0.598296106, 1.0
        .float -0.311909527, 0.72480917, 0.502214909, 1.0
        .float -0.433312386, 1.0309844, 0.692482889, 1.0
        .float -0.359224945, 1.01194263, 0.610723138, 1.0
        .float -0.311652511, 0.86486578, 0.507523179, 1.0
        .float -0.296804756, 0.994804382, 0.495553464, 1.0
        .float -0.257442743, 0.58091259, 0.368361294, 1.0
        .float -0.261078805, 0.724291563, 0.38306585, 1.0
        .float -0.262411714, 0.860724688, 0.380793899, 1.0
        .float -0.251326561, 0.982396126, 0.353445053, 1.0
        .float -0.207793862, 1.07808256, 0.313709915, 1.0
        .float -0.244387358, 1.09866977, 0.474590689, 1.0
        .float -0.117636368, 1.13750768, 0.27890867, 1.0
        .float -0.138072699, 1.16150045, 0.455578983, 1.0
        .float 0.000000000, 1.15759921, 0.26409027, 1.0
        .float 0.117634386, 1.13750744, 0.2789087, 1.0
        .float 0.138070747, 1.16150022, 0.455579013, 1.0
        .float 0.000000000, 1.18197823, 0.447386473, 1.0
        .float -0.294746906, 1.12687993, 0.61985898, 1.0
        .float -0.166237965, 1.19388676, 0.625090122, 1.0
        .float -0.356640786, 1.16096807, 0.728065789, 1.0
        .float -0.198393553, 1.23134184, 0.751323223, 1.0
        .float 0.000000000, 1.21457791, 0.626716495, 1.0
        .float 0.166235968, 1.193887, 0.625090182, 1.0
        .float 0.198391587, 1.23134184, 0.751323164, 1.0
        .float 0.000000000, 1.25108337, 0.759141743, 1.0
        .float -0.464127511, 1.21805263, 0.801937938, 1.0
        .float -0.227511391, 1.28627825, 0.844900787, 1.0
        .float -0.540622592, 1.04448414, 0.728058994, 1.0
        .float -0.697047293, 1.03915453, 0.703245699, 1.0
        .float -0.68738246, 1.19636703, 0.756240308, 1.0
        .float -0.467004299, 1.35367632, 0.880517721, 1.0
        .float -0.235796556, 1.37184811, 0.925430119, 1.0
        .float -0.864111662, 1.1812923, 0.684648454, 1.0
        .float -0.683449507, 1.337152, 0.811811328, 1.0
        .float -0.701057136, 0.879448891, 0.662561119, 1.0
        .float -0.68201679, 1.47027779, 0.861313701, 1.0
        .float -0.465507239, 1.47551167, 0.941443026, 1.0
        .float -0.46609962, 1.60681021, 0.990525007, 1.0
        .float -0.467949033, 1.744789, 1.02316594, 1.0
        .float -0.235822454, 1.60740542, 1.05006635, 1.0
        .float -0.236982927, 1.744789, 1.086869, 1.0
        .float -0.237633631, 1.88388145, 1.10209572, 1.0
        .float  0.000000000, 1.74478912, 1.10858595, 1.0
        .float  0.000000000, 1.88388145, 1.12414134, 1.0
        .float -0.235440657, 1.48027408, 0.994558513, 1.0
        .float 0.000000000, 1.60766459, 1.07108212, 1.0
        .float 0.235820487, 1.60740542, 1.05006623, 1.0
        .float 0.23698096, 1.744789, 1.086869, 1.0
        .float 0.237631664, 1.88388145, 1.10209572, 1.0
        .float 0.000000000, 2.02297401, 1.12727094, 1.0
        .float 0.466097653, 1.60681021, 0.990525007, 1.0
        .float 0.467947096, 1.74478912, 1.02316594, 1.0
        .float 0.465505272, 1.47551155, 0.941443026, 1.0
        .float 0.23543869, 1.48027408, 0.994558573, 1.0
        .float 0.682531655, 1.60621309, 0.898907185, 1.0
        .float 0.682014763, 1.47027779, 0.861313641, 1.0
        .float 0.684269249, 1.74482584, 0.922229946, 1.0
        .float 0.469262242, 1.88388145, 1.03645682, 1.0
        .float 0.865538895, 1.46694195, 0.76263243, 1.0
        .float 0.865805209, 1.606197, 0.786421537, 1.0
        .float 0.865741968, 1.32631755, 0.726701081, 1.0
        .float 0.68344754, 1.33715224, 0.811811328, 1.0
        .float 1.00004637, 1.46697056, 0.648464859, 1.0
        .float 0.999857605, 1.32375669, 0.62863946, 1.0
        .float 1.00007689, 1.60708523, 0.659544647, 1.0
        .float 0.866870224, 1.74508476, 0.799139619, 1.0
        .float 1.09433591, 1.46806753, 0.498769283, 1.0
        .float 1.09402716, 1.3248837, 0.492497206, 1.0
        .float 1.09141541, 1.17840838, 0.478902519, 1.0
        .float 0.99708277, 1.17727566, 0.601020873, 1.0
        .float 1.15904129, 1.32492065, 0.299320161, 1.0
        .float 1.15475976, 1.17834544, 0.296821207, 1.0
        .float 1.16016722, 1.468099, 0.29846108, 1.0
        .float 1.09442794, 1.60791719, 0.501066804, 1.0
        .float 1.14589167, 1.02917075, 0.289434075, 1.0
        .float 1.08524323, 1.02960539, 0.456536859, 1.0
        .float 1.07956624, 0.881393909, 0.432291687, 1.0
        .float 1.13813233, 0.880436897, 0.279471338, 1.0
        .float 0.990171671, 1.02827024, 0.568530858, 1.0
        .float 0.983120799, 0.879733324, 0.538232327, 1.0
        .float 1.07790864, 0.736238718, 0.412751436, 1.0
        .float 0.979635715, 0.734238625, 0.515587449, 1.0
        .float 1.13645256, 0.734838724, 0.269435525, 1.0
        .float 1.0763526, 0.592839956, 0.394933164, 1.0
        .float 0.976710498, 0.590435028, 0.495513409, 1.0
        .float 0.848792613, 0.730585575, 0.587256253, 1.0
        .float 0.845037878, 0.586046457, 0.567389488, 1.0
        .float 0.970683694, 0.448879242, 0.47298032, 1.0
        .float 0.839757442, 0.444162846, 0.544356763, 1.0
        .float 1.07038212, 0.451897383, 0.375500888, 1.0
        .float 1.13579428, 0.59145546, 0.258745939, 1.0
        .float 0.833678484, 0.316723347, 0.524113655, 1.0
        .float 0.961985171, 0.321683645, 0.453714728, 1.0
        .float 0.693336368, 0.440993071, 0.59299314, 1.0
        .float 0.691160202, 0.313544035, 0.57166183, 1.0
        .float 0.828098178, 0.216671467, 0.513362408, 1.0
        .float 0.6913445, 0.213533163, 0.559582055, 1.0
        .float 1.06052804, 0.325884104, 0.359274, 1.0
        .float 0.952306449, 0.22192502, 0.443866879, 1.0
        .float 0.823962092, 0.149477243, 0.50937897, 1.0
        .float 0.69258076, 0.146387339, 0.554456353, 1.0
        .float 0.566110492, 0.212094545, 0.575857759, 1.0
        .float 0.572582126, 0.145007372, 0.569936991, 1.0
        .float 0.693299294, 0.11258769, 0.550641477, 1.0
        .float 0.576539576, 0.111244678, 0.565648198, 1.0
        .float 0.821327269, 0.115640879, 0.506327748, 1.0
        .float 0.944300473, 0.154998541, 0.440526724, 1.0
        .float 0.580305338, 0.098978281, 0.552853107, 1.0
        .float 0.693195581, 0.100276709, 0.538364112, 1.0
        .float 0.487801492, 0.110781908, 0.545410275, 1.0
        .float 0.494448423, 0.0985319614, 0.533087492, 1.0
        .float 0.481552362, 0.144528389, 0.549700618, 1.0
        .float 0.417657644, 0.110715628, 0.485875845, 1.0
        .float 0.426514894, 0.0984680653, 0.474474937, 1.0
        .float 0.409787178, 0.144459963, 0.491495162, 1.0
        .float 0.471422076, 0.211588621, 0.555752277, 1.0
        .float 0.355167061, 0.110715389, 0.387942404, 1.0
        .float 0.365967661, 0.0984685421, 0.377548814, 1.0
        .float 0.345925093, 0.144459724, 0.397191912, 1.0
        .float 0.397121996, 0.21151638, 0.500307381, 1.0
        .float 0.309515357, 0.110715628, 0.270420521, 1.0
        .float 0.321738929, 0.0984685421, 0.262202412, 1.0
        .float 0.299262255, 0.144459724, 0.281285465, 1.0
        .float 0.331136107, 0.211516857, 0.413141757, 1.0
        .float 0.461712629, 0.311509371, 0.568898618, 1.0
        .float 0.384744257, 0.311433554, 0.515907347, 1.0
        .float 0.316523671, 0.311433077, 0.435121477, 1.0
        .float 0.282904983, 0.21151638, 0.300707668, 1.0
        .float 0.457454354, 0.438911915, 0.591132998, 1.0
        .float 0.378793299, 0.438833475, 0.538894713, 1.0
        .float 0.309160918, 0.438833237, 0.460092306, 1.0
        .float 0.266644061, 0.311433554, 0.324749529, 1.0
        .float 0.258242756, 0.438833475, 0.347919971, 1.0
        .float 0.308690429, 0.580912113, 0.484056413, 1.0
        .float 0.257440776, 0.58091259, 0.368361264, 1.0
        .float 0.378774792, 0.58091259, 0.5632658, 1.0
        .float 0.31190756, 0.724809408, 0.502214849, 1.0
        .float 0.381428957, 0.725525379, 0.582960844, 1.0
        .float 0.261076868, 0.724291325, 0.38306585, 1.0
        .float 0.379067212, 0.870597124, 0.598296106, 1.0
        .float 0.311650574, 0.86486578, 0.507523179, 1.0
        .float 0.456460178, 0.876688004, 0.659543037, 1.0
        .float 0.460226625, 0.726350069, 0.636169672, 1.0
        .float 0.359222978, 1.01194263, 0.610723138, 1.0
        .float 0.296802819, 0.994804382, 0.495553404, 1.0
        .float 0.251324624, 0.982396364, 0.353445083, 1.0
        .float 0.262409747, 0.860724688, 0.38079384, 1.0
        .float 0.244385377, 1.09867024, 0.474590689, 1.0
        .float 0.207791865, 1.07808232, 0.313709915, 1.0
        .float 0.433310419, 1.0309844, 0.692482889, 1.0
        .float 0.294744968, 1.12687993, 0.619858921, 1.0
        .float 0.356638789, 1.16096807, 0.728065789, 1.0
        .float 0.540620565, 1.04448414, 0.728058934, 1.0
        .float 0.464125544, 1.21805263, 0.801937819, 1.0
        .float 0.227509424, 1.28627825, 0.844900727, 1.0
        .float 0.687380433, 1.19636703, 0.756240368, 1.0
        .float 0.467002362, 1.35367608, 0.880517721, 1.0
        .float 0.235794589, 1.37184811, 0.925430059, 1.0
        .float 0.000000000, 1.37910891, 0.941184759, 1.0
        .float 0.000000000, 1.30209231, 0.856904984, 1.0
        .float 0.000000000, 1.48234653, 1.01372111, 1.0
        .float 0.864109635, 1.1812923, 0.684648395, 1.0
        .float 0.697045386, 1.03915453, 0.703245699, 1.0
        .float 0.858941019, 1.03010154, 0.643900394, 1.0
        .float 0.559760332, 0.880260229, 0.683218896, 1.0
        .float 0.701055229, 0.879449129, 0.662561119, 1.0
        .float 0.562634528, 0.727236986, 0.656165957, 1.0
        .float 0.852925658, 0.878076553, 0.610414684, 1.0
        .float 0.700101912, 0.728342772, 0.636886477, 1.0
        .float 0.560288668, 0.58152914, 0.635315478, 1.0
        .float 0.45801422, 0.580989361, 0.615553021, 1.0
        .float 0.558620453, 0.439462185, 0.611047208, 1.0
        .float 0.696870029, 0.583019018, 0.616621256, 1.0
        .float 0.560297191, 0.312043667, 0.588882208, 1.0
        .float 0.817050099, 0.103245735, 0.495354891, 1.0
        .float 0.939172983, 0.121296644, 0.438047618, 1.0
        .float 0.931384027, 0.108887911, 0.428896815, 1.0
        .float 1.03909898, 0.162992001, 0.348658562, 1.0
        .float 1.03278041, 0.130350351, 0.34686777, 1.0
        .float 1.04892814, 0.228049994, 0.351209372, 1.0
        .float 1.09916317, 0.173091173, 0.232165098, 1.0
        .float 1.10889161, 0.234143972, 0.233129591, 1.0
        .float 1.09296286, 0.142754793, 0.231506169, 1.0
        .float 1.02322495, 0.118605614, 0.340266913, 1.0
        .float 1.12042248, 0.327868938, 0.237440467, 1.0
        .float 1.13023531, 0.451441288, 0.246981353, 1.0
        .float 1.08384883, 0.132636547, 0.228372872, 1.0
        .float 1.16079056, 1.60801148, 0.29656145, 1.0
        .float 1.16132951, 1.74626434, 0.295246065, 1.0
        .float 1.09438896, 1.74612939, 0.501997828, 1.0
        .float 1.00034034, 1.74565887, 0.664662778, 1.0
        .float 1.09386194, 1.88446689, 0.503524363, 1.0
        .float 1.00071025, 1.88426781, 0.667126179, 1.0
        .float 1.16155827, 1.88450563, 0.29557839, 1.0
        .float 1.092713, 2.02322197, 0.50576508, 1.0
        .float 1.00102699, 2.02316809, 0.668599546, 1.0
        .float 0.870497584, 2.02304268, 0.804491401, 1.0
        .float 0.868539393, 1.88401318, 0.803849578, 1.0
        .float 1.00176656, 2.1680305, 0.669948697, 1.0
        .float 0.87316525, 2.16792369, 0.804958522, 1.0
        .float 1.09136403, 2.16802979, 0.507738829, 1.0
        .float 1.1609112, 2.02307916, 0.297069103, 1.0
        .float 0.690477788, 2.16786957, 0.932768881, 1.0
        .float 0.687967896, 2.02298236, 0.932403684, 1.0
        .float 0.47138539, 2.16786146, 1.03942835, 1.0
        .float 0.470081657, 2.02297401, 1.03867435, 1.0
        .float 0.686142623, 1.88389778, 0.931279242, 1.0
        .float 0.238325536, 2.16786194, 1.10611916, 1.0
        .float 0.237855926, 2.02297401, 1.10501695, 1.0
        .float 0.000000000, 2.1678617, 1.12850773, 1.0
        .float -0.237857893, 2.02297401, 1.10501695, 1.0
        .float 1.15923297, 2.16769552, 0.298425585, 1.0
        .float -0.693176687, 0.101188421, 0.538422763, 1.0
        .float -0.821494699, 0.118263483, 0.506449163, 1.0
        .float -0.817109704, 0.104158163, 0.495397091, 1.0
        .float -0.939503312, 0.123907804, 0.438143462, 1.0
        .float -0.944759309, 0.158631325, 0.440660119, 1.0
        .float -0.952636898, 0.224536419, 0.443962723, 1.0
        .float -1.03966439, 0.166514874, 0.348755032, 1.0
        .float -1.04933512, 0.230582476, 0.351278722, 1.0
        .float -1.03318727, 0.132882357, 0.34693709, 1.0
        .float -0.931500256, 0.109796762, 0.428930163, 1.0
        .float -1.0997225, 0.176378727, 0.232189178, 1.0
        .float -1.10929406, 0.236507416, 0.233146906, 1.0
        .float -1.06067097, 0.32676506, 0.35929811, 1.0
        .float -1.12056363, 0.328691244, 0.237446487, 1.0
        .float -1.09336543, 0.145117283, 0.231523484, 1.0
        .float -1.0839901, 0.133458376, 0.228378892, 1.0
        .float -1.02336776, 0.11948657, 0.340291023, 1.0
        .float -1.13025463, 0.451544285, 0.246982098, 1.0
        .float -1.13579619, 0.59145546, 0.258745909, 1.0
        .float -1.07040179, 0.452007532, 0.375503868, 1.0
        .float -1.13645446, 0.734838724, 0.269435525, 1.0
        .float -1.16079235, 1.60801172, 0.29656148, 1.0
        .float -1.16133142, 1.74626434, 0.295246065, 1.0
        .float -1.16156006, 1.88450563, 0.295578361, 1.0
        .float -1.09386384, 1.88446701, 0.503524423, 1.0
        .float -1.09271491, 2.02322197, 0.50576508, 1.0
        .float -1.16091323, 2.02307916, 0.297069132, 1.0
        .float -1.00176871, 2.16803026, 0.669948697, 1.0
        .float -1.09136593, 2.16802979, 0.507738888, 1.0
        .float -1.0059824, 2.34750319, 0.670489311, 1.0
        .float -1.09223473, 2.34736657, 0.505909204, 1.0
        .float -1.15923488, 2.16769552, 0.298425585, 1.0
        .float -1.15835154, 2.34683847, 0.296694994, 1.0
        .float -1.01473379, 2.58441877, 0.669554114, 1.0
        .float -1.09607887, 2.58387256, 0.497814298, 1.0
        .float -0.892533004, 2.58490229, 0.815299511, 1.0
        .float -0.720787704, 2.85743737, 0.955654442, 1.0
        .float -0.900960743, 2.85680294, 0.823586106, 1.0
        .float -1.01856184, 2.85536575, 0.668094158, 1.0
        .float -1.0950166, 2.85400629, 0.487846553, 1.0
        .float -1.15885174, 2.58314323, 0.28989777, 1.0
        .float -1.00798464, 3.12906075, 0.666327417, 1.0
        .float -0.895482361, 3.13188601, 0.828338861, 1.0
        .float -0.7217471, 3.13311768, 0.961580753, 1.0
        .float -0.877033293, 3.39282203, 0.823151529, 1.0
        .float -0.712169886, 3.39433002, 0.955247998, 1.0
        .float -1.08103049, 3.12659264, 0.480429888, 1.0
        .float -0.983959377, 3.38897824, 0.659918964, 1.0
        .float -0.848810911, 3.62645102, 0.803108215, 1.0
        .float -0.693602562, 3.62805295, 0.930085719, 1.0
        .float -0.499683291, 3.39474177, 1.05196559, 1.0
        .float -0.490444422, 3.62955141, 1.02250338, 1.0
        .float -0.475743473, 3.83397722, 0.970062673, 1.0
        .float -0.668392658, 3.82689118, 0.886916816, 1.0
        .float -0.949138939, 3.62282038, 0.644906878, 1.0
        .float -0.812296689, 3.82228494, 0.771057904, 1.0
        .float -0.640006125, 3.98520684, 0.826033294, 1.0
        .float -0.458816081, 4.00562048, 0.892460048, 1.0
        .float -0.247146741, 3.84271765, 1.02075136, 1.0
        .float -0.239193007, 4.02286625, 0.934120476, 1.0
        .float -0.445498675, 4.13908768, 0.781221986, 1.0
        .float -0.232512832, 4.16649008, 0.812008798, 1.0
        .float -0.767882764, 3.97098994, 0.731230795, 1.0
        .float -0.618322372, 4.09932184, 0.736606658, 1.0
        .float -0.441042632, 4.23230505, 0.630700052, 1.0
        .float -0.229528859, 4.26947927, 0.651167095, 1.0
        .float 0.000000000, 4.17661047, 0.823414981, 1.0
        .float 0.000000000, 4.28232479, 0.659216166, 1.0
        .float 0.000000000, 4.35976887, 0.469665945, 1.0
        .float -0.230966553, 4.34468365, 0.464705497, 1.0
        .float -0.617862523, 4.17248487, 0.604811907, 1.0
        .float -0.445759207, 4.29948235, 0.452833414, 1.0
        .float -0.236477196, 4.40283108, 0.266927689, 1.0
        .float 0.000000000, 4.41938353, 0.269314706, 1.0
        .float 0.230964601, 4.34468365, 0.464705497, 1.0
        .float 0.229526907, 4.26947927, 0.651167095, 1.0
        .float 0.236475259, 4.40283155, 0.266927689, 1.0
        .float -0.457687616, 4.3523612, 0.26145342, 1.0
        .float 0.44575724, 4.29948235, 0.452833414, 1.0
        .float 0.45768562, 4.3523612, 0.26145342, 1.0
        .float 0.650043845, 4.26771402, 0.255587935, 1.0
        .float 0.630086243, 4.22450686, 0.439302474, 1.0
        .float 0.617860496, 4.17248487, 0.604811847, 1.0
        .float 0.441040665, 4.23230505, 0.630700052, 1.0
        .float 0.750375867, 4.0889492, 0.588904798, 1.0
        .float 0.777189672, 4.12113523, 0.432319641, 1.0
        .float 0.721854866, 4.05963707, 0.692011893, 1.0
        .float 0.618320346, 4.09932184, 0.736606598, 1.0
        .float 0.445496738, 4.13908768, 0.781222045, 1.0
        .float 0.767880797, 3.97098994, 0.731230736, 1.0
        .float 0.640004039, 3.98520708, 0.826033354, 1.0
        .float 0.840319812, 3.97466016, 0.6003142, 1.0
        .float 0.902516186, 3.82044077, 0.623377204, 1.0
        .float 0.812294662, 3.82228494, 0.771057963, 1.0
        .float 0.668390632, 3.82689118, 0.886916757, 1.0
        .float 0.458814144, 4.00562048, 0.892459989, 1.0
        .float 0.949136913, 3.62282038, 0.644906878, 1.0
        .float 0.848808825, 3.62645102, 0.803108215, 1.0
        .float 0.960954607, 3.82453132, 0.450639576, 1.0
        .float 1.01544499, 3.62157059, 0.463216126, 1.0
        .float 0.693600595, 3.62805295, 0.930085599, 1.0
        .float 0.475741476, 3.83397722, 0.970062673, 1.0
        .float 0.490442485, 3.62955141, 1.0225035, 1.0
        .float 0.253738701, 3.63308525, 1.07843184, 1.0
        .float 0.247144759, 3.84271765, 1.02075136, 1.0
        .float 0.239191055, 4.02286625, 0.934120476, 1.0
        .float 0.000000000, 3.84722161, 1.03794885, 1.0
        .float 0.000000000, 4.03010273, 0.94874984, 1.0
        .float 0.232510865, 4.16649008, 0.812008798, 1.0
        .float -0.253740728, 3.63308525, 1.07843173, 1.0
        .float -0.257196486, 3.39576983, 1.11045814, 1.0
        .float 0.000000000, 3.63531089, 1.0971638, 1.0
        .float -0.501478553, 3.13331819, 1.06059921, 1.0
        .float 1.06892431, 3.62558341, 0.266079545, 1.0
        .float 1.0094384, 3.83503437, 0.260560811, 1.0
        .float 0.884782016, 3.98960304, 0.437937707, 1.0
        .float 0.924585938, 4.00954342, 0.255123109, 1.0
        .float 0.80668205, 4.15248346, 0.252692014, 1.0
        .float -0.63008827, 4.22450686, 0.439302504, 1.0
        .float -0.650045693, 4.26771402, 0.255587935, 1.0
        .float -0.777191639, 4.12113523, 0.432319611, 1.0
        .float -0.806684017, 4.15248346, 0.252692014, 1.0
        .float -0.750377893, 4.0889492, 0.588904738, 1.0
        .float -0.924587905, 4.00954294, 0.255123079, 1.0
        .float -0.884784102, 3.98960304, 0.437937737, 1.0
        .float -1.0094403, 3.83503437, 0.260560811, 1.0
        .float -0.960956633, 3.82453132, 0.450639606, 1.0
        .float -0.840321839, 3.97466016, 0.6003142, 1.0
        .float -1.06892622, 3.62558341, 0.266079545, 1.0
        .float -1.01544702, 3.62157059, 0.463216096, 1.0
        .float -0.902518213, 3.82044077, 0.623377144, 1.0
        .float -0.721856952, 4.05963707, 0.692011893, 1.0
        .float -1.05420029, 3.38610721, 0.473259985, 1.0
        .float -1.13836277, 3.12568903, 0.275614798, 1.0
        .float -1.11004543, 3.38648582, 0.271010876, 1.0
        .float -1.15439129, 2.85307884, 0.281608164, 1.0
        .float 0.332663029, 0.0967116356, 0.139908314, 1.0
        .float 0.348315924, 0.0968618393, 0.24811241, 1.0
        .float 0.345482439, 0.0968618393, 0.0160336569, 1.0
        .float 0.402222961, 0.111152411, 0.0253112465, 1.0
        .float 0.388594806, 0.10994935, 0.129374728, 1.0
        .float 0.404587299, 0.111152411, 0.219047159, 1.0
        .float 0.388939142, 0.0967116356, 0.355713755, 1.0
        .float 0.44535476, 0.0968616009, 0.44576171, 1.0
        .float 0.435890287, 0.10994935, 0.310842425, 1.0
        .float 0.485167891, 0.111152411, 0.383358985, 1.0
        .float 0.508096635, 0.0967707634, 0.500853956, 1.0
        .float 0.500580192, 0.136240482, 0.248685658, 1.0
        .float 0.536069214, 0.109999657, 0.432955384, 1.0
        .float 0.554292023, 0.145619869, 0.274114877, 1.0
        .float 0.575018227, 0.13628912, 0.338716507, 1.0
        .float 0.587839425, 0.0973351002, 0.518714547, 1.0
        .float 0.60415417, 0.111553192, 0.444263875, 1.0
        .float 0.633575559, 0.14593792, 0.314338893, 1.0
        .float 0.683759809, 0.190214396, 0.073980093, 1.0
        .float 0.622494996, 0.145756245, -0.167715251, 1.0
        .float 0.669814765, 0.13739109, -0.204310924, 1.0
        .float 0.73648417, 0.152618647, -0.157467753, 1.0
        .float 0.549404562, 0.14561367, -0.108357258, 1.0
        .float 0.567454219, 0.136240482, -0.184334368, 1.0
        .float 0.857968509, 0.158528328, 0.207875341, 1.0
        .float 0.827256083, 0.142806768, 0.279018581, 1.0
        .float 0.751165569, 0.14829421, 0.285952598, 1.0
        .float 0.872361243, 0.175389767, -0.0806618258, 1.0
        .float 0.941357911, 0.176929712, -0.0154126585, 1.0
        .float 0.912618279, 0.177991867, 0.0802921504, 1.0
        .float 0.500930309, 0.14561367, 0.0396963432, 1.0
        .float 0.496855527, 0.136240005, -0.0551962703, 1.0
        .float 0.689801514, 0.137340069, 0.342153192, 1.0
        .float 0.925456285, 0.162801981, 0.164524883, 1.0
        .float 0.502501726, 0.14561367, 0.168287203, 1.0
        .float 0.827821255, 0.157034159, -0.16192171, 1.0
        .float 0.465877891, 0.136240482, 0.113980979, 1.0
        .float 0.692326665, 0.0983879566, 0.505811632, 1.0
        .float 0.69093281, 0.11136055, 0.437143981, 1.0
        .float 0.806999981, 0.101293564, 0.465450764, 1.0
        .float 0.786295891, 0.114868879, 0.400002152, 1.0
        .float 0.913478255, 0.106575012, 0.404222757, 1.0
        .float 0.877083361, 0.118411303, 0.351785004, 1.0
        .float 1.00036824, 0.117043257, 0.322006762, 1.0
        .float 0.949364543, 0.129337072, 0.280937135, 1.0
        .float 1.06137419, 0.132790327, 0.21925202, 1.0
        .float 1.00723779, 0.144012928, 0.197436213, 1.0
        .float 1.09157634, 0.147619486, 0.0877533555, 1.0
        .float 1.03146172, 0.158828259, 0.086716637, 1.0
        .float 1.08763158, 0.15356493, -0.0707127526, 1.0
        .float 1.02953994, 0.162923336, -0.0466685444, 1.0
        .float 1.03051901, 0.146804333, -0.214341372, 1.0
        .float 0.974393368, 0.155953169, -0.165575027, 1.0
        .float 0.91400373, 0.126998901, -0.304845989, 1.0
        .float 0.87780118, 0.137102127, -0.244744033, 1.0
        .float 0.776124239, 0.106993437, -0.350624502, 1.0
        .float 0.761101604, 0.12028718, -0.279708683, 1.0
        .float 0.65943867, 0.0979781151, -0.371975541, 1.0
        .float 0.663325965, 0.111091375, -0.30095318, 1.0
        .float 0.568183005, 0.0968616009, -0.369812965, 1.0
        .float 0.587674081, 0.111152411, -0.295556307, 1.0
        .float 0.496244818, 0.0967116356, -0.341342032, 1.0
        .float 0.526099741, 0.10994935, -0.275152236, 1.0
        .float 0.436488301, 0.0968616009, -0.265177816, 1.0
        .float 0.477792531, 0.111152411, -0.207900107, 1.0
        .float 0.38295725, 0.0967116356, -0.132852793, 1.0
        .float 0.430863112, 0.10994935, -0.0998682752, 1.0
        .float -0.348287672, 0.096975565, 0.248146862, 1.0
        .float -0.332633525, 0.0968251228, 0.139930293, 1.0
        .float -0.404589266, 0.111152411, 0.219047159, 1.0
        .float -0.388596803, 0.109949589, 0.129374728, 1.0
        .float -0.388913721, 0.0968251228, 0.355741382, 1.0
        .float -0.402224928, 0.111152411, 0.0253112465, 1.0
        .float -0.34545359, 0.096975565, 0.0160373487, 1.0
        .float -0.382931083, 0.0968251228, -0.1328578, 1.0
        .float -0.430865109, 0.109949589, -0.0998682752, 1.0
        .float -0.477794498, 0.111152411, -0.207900107, 1.0
        .float -0.436466008, 0.096975565, -0.265184969, 1.0
        .float -0.496857494, 0.136240482, -0.0551962554, 1.0
        .float -0.526101768, 0.109949589, -0.275152296, 1.0
        .float -0.549406588, 0.14561367, -0.108357258, 1.0
        .float -0.567456245, 0.136240482, -0.184334338, 1.0
        .float -0.496226966, 0.0968251228, -0.341351092, 1.0
        .float -0.587676108, 0.111152411, -0.295556307, 1.0
        .float -0.683761835, 0.190214634, 0.073980093, 1.0
        .float -0.622497022, 0.145756245, -0.167715251, 1.0
        .float -0.736486256, 0.152618885, -0.157467753, 1.0
        .float -0.669816852, 0.13739109, -0.204310924, 1.0
        .float -0.751167595, 0.148294449, 0.285952568, 1.0
        .float -0.82725805, 0.14280653, 0.279018581, 1.0
        .float -0.857970536, 0.158528566, 0.207875341, 1.0
        .float -0.912620246, 0.177992105, 0.0802921504, 1.0
        .float -0.941359878, 0.176929712, -0.015412651, 1.0
        .float -0.872363269, 0.175390005, -0.0806618407, 1.0
        .float -0.500932276, 0.14561367, 0.0396963432, 1.0
        .float -0.633577585, 0.145938158, 0.314338923, 1.0
        .float -0.689803481, 0.137340069, 0.342153162, 1.0
        .float -0.925458252, 0.162801981, 0.164524868, 1.0
        .float -0.502503753, 0.14561367, 0.168287188, 1.0
        .float -0.500582218, 0.136240482, 0.248685658, 1.0
        .float -0.55429405, 0.145619631, 0.274114877, 1.0
        .float -0.575020254, 0.136289597, 0.338716477, 1.0
        .float -0.827823162, 0.157034397, -0.16192168, 1.0
        .float -0.465879828, 0.136240482, 0.113980979, 1.0
        .float -0.435892224, 0.109949589, 0.310842425, 1.0
        .float -0.445333272, 0.096975565, 0.445775926, 1.0
        .float -0.485169828, 0.111152411, 0.383359015, 1.0
        .float -0.508079827, 0.0968842506, 0.500862956, 1.0
        .float -0.536071241, 0.109999657, 0.432955414, 1.0
        .float -0.587829292, 0.0974488258, 0.518723309, 1.0
        .float -0.604156256, 0.111553431, 0.444263905, 1.0
        .float -0.692326069, 0.0985021591, 0.505818963, 1.0
        .float -0.690934837, 0.11136055, 0.437143952, 1.0
        .float -0.807009101, 0.101407528, 0.465456009, 1.0
        .float -0.786297858, 0.114868641, 0.400002152, 1.0
        .float -0.913494587, 0.106688499, 0.404226929, 1.0
        .float -0.877085328, 0.118411541, 0.351784974, 1.0
        .float -1.00038767, 0.117153168, 0.322009772, 1.0
        .float -0.949366689, 0.129336834, 0.280937165, 1.0
        .float -1.06139338, 0.132892847, 0.219252795, 1.0
        .float -1.00723958, 0.144013166, 0.197436243, 1.0
        .float -1.09159493, 0.147717476, 0.0877519101, 1.0
        .float -1.03146362, 0.158828259, 0.0867166296, 1.0
        .float -1.08765185, 0.153666019, -0.0707151964, 1.0
        .float -1.02954185, 0.162923098, -0.0466685221, 1.0
        .float -1.03053808, 0.146911621, -0.214345038, 1.0
        .float -0.974395454, 0.155953407, -0.165575027, 1.0
        .float -0.914016068, 0.127110481, -0.304852307, 1.0
        .float -0.877803206, 0.137102604, -0.244744033, 1.0
        .float -0.776126921, 0.107106686, -0.35063374, 1.0
        .float -0.761103511, 0.12028718, -0.279708683, 1.0
        .float -0.659432888, 0.0980918407, -0.37198621, 1.0
        .float -0.663327992, 0.111091375, -0.30095315, 1.0
        .float -0.568170488, 0.096975565, -0.369823575, 1.0
        .float -0.492449492, 2.78501678, 1.21468663, 1.0
        .float -0.322931051, 2.75816774, 1.21468663, 1.0
        .float -0.322403222, 2.76487446, 1.29285693, 1.0
        .float -0.49035117, 2.79147482, 1.29285693, 1.0
        .float -0.636079669, 2.85820007, 1.21468663, 1.0
        .float 0.360909283, 2.75816774, 1.21468663, 1.0
        .float 0.360381454, 2.76487446, 1.29285693, 1.0
        .float -0.482839555, 2.81459308, 1.36674845, 1.0
        .float -0.320513695, 2.78888321, 1.36674845, 1.0
        .float -0.632088423, 2.86369348, 1.29285693, 1.0
        .float -0.617800474, 2.88335919, 1.36674845, 1.0
        .float -0.750065207, 2.97218561, 1.21468663, 1.0
        .float -0.744571745, 2.97617698, 1.29285693, 1.0
        .float -0.724906087, 2.99046493, 1.36674845, 1.0
        .float -0.569945097, 2.94922662, 1.42517281, 1.0
        .float -0.659038663, 3.0383203, 1.42517281, 1.0
        .float -0.716240287, 3.1505847, 1.42517281, 1.0
        .float -0.793672025, 3.12542582, 1.36674845, 1.0
        .float -0.823248386, 3.11581588, 1.21468663, 1.0
        .float -0.816790402, 3.1179142, 1.29285693, 1.0
        .float -0.738967717, 3.29408026, 1.42517281, 1.0
        .float -0.819381952, 3.28775167, 1.36674845, 1.0
        .float -0.618330419, 3.0678966, 1.43304431, 1.0
        .float -0.66838485, 3.16613388, 1.43304431, 1.0
        .float -0.689269066, 3.29799175, 1.43304431, 1.0
        .float -0.716240406, 3.44548965, 1.42517281, 1.0
        .float -0.843390763, 3.28586197, 1.29285693, 1.0
        .float -0.793672204, 3.47064877, 1.36674845, 1.0
        .float -0.66838491, 3.42994046, 1.43304431, 1.0
        .float -0.659038663, 3.55775428, 1.42517281, 1.0
        .float -0.724906087, 3.60560966, 1.36674845, 1.0
        .float -0.816790521, 3.47816038, 1.29285693, 1.0
        .float -0.850097477, 3.28533411, 1.21468663, 1.0
        .float -0.823248446, 3.4802587, 1.21468663, 1.0
        .float -0.750065207, 3.62388873, 1.21468663, 1.0
        .float -0.744571745, 3.6198976, 1.29285693, 1.0
        .float -0.636079669, 3.73787451, 1.21468663, 1.0
        .float -0.632088423, 3.73238087, 1.29285693, 1.0
        .float -0.617800534, 3.71271515, 1.36674845, 1.0
        .float -0.492449492, 3.81105757, 1.21468663, 1.0
        .float -0.49035117, 3.80459976, 1.29285693, 1.0
        .float -0.482839555, 3.78148127, 1.36674845, 1.0
        .float -0.457680434, 3.70404959, 1.42517281, 1.0
        .float -0.569945097, 3.64684772, 1.42517281, 1.0
        .float -0.314184994, 3.72677708, 1.42517281, 1.0
        .float -0.320513695, 3.80719113, 1.36674845, 1.0
        .float -0.442131251, 3.65619421, 1.43304431, 1.0
        .float -0.540368795, 3.60613966, 1.43304431, 1.0
        .float -0.618330359, 3.52817798, 1.43304431, 1.0
        .float -0.310273647, 3.67707825, 1.43304431, 1.0
        .float 0.352163255, 3.72677708, 1.42517281, 1.0
        .float 0.348251909, 3.67707825, 1.43304431, 1.0
        .float 0.495658666, 3.70404959, 1.42517281, 1.0
        .float 0.358491927, 3.80719113, 1.36674845, 1.0
        .float 0.480109453, 3.65619421, 1.43304431, 1.0
        .float 0.520817757, 3.78148127, 1.36674845, 1.0
        .float 0.607923269, 3.64684796, 1.42517281, 1.0
        .float 0.360381454, 3.83119988, 1.29285693, 1.0
        .float -0.322403222, 3.83119988, 1.29285693, 1.0
        .float 0.528329372, 3.80459976, 1.29285693, 1.0
        .float 0.655778706, 3.71271539, 1.36674845, 1.0
        .float 0.578346968, 3.60613966, 1.43304431, 1.0
        .float 0.697016835, 3.55775428, 1.42517281, 1.0
        .float 0.670066595, 3.73238087, 1.29285693, 1.0
        .float 0.762884259, 3.60560966, 1.36674845, 1.0
        .float 0.674057841, 3.73787451, 1.21468663, 1.0
        .float 0.530427694, 3.81105757, 1.21468663, 1.0
        .float 0.78804338, 3.62388873, 1.21468663, 1.0
        .float 0.782549918, 3.6198976, 1.29285693, 1.0
        .float 0.754218578, 3.44548965, 1.42517281, 1.0
        .float 0.831650376, 3.47064877, 1.36674845, 1.0
        .float 0.861226618, 3.4802587, 1.21468663, 1.0
        .float 0.854768693, 3.47816038, 1.29285693, 1.0
        .float 0.776945889, 3.30199432, 1.42517281, 1.0
        .float 0.857360125, 3.30832291, 1.36674845, 1.0
        .float 0.656308532, 3.52817798, 1.43304431, 1.0
        .float 0.706363082, 3.42994046, 1.43304431, 1.0
        .float 0.727247238, 3.29808283, 1.43304431, 1.0
        .float 0.754218459, 3.1505847, 1.42517281, 1.0
        .float 0.831650198, 3.12542582, 1.36674845, 1.0
        .float 0.881368935, 3.31021237, 1.29285693, 1.0
        .float 0.706363022, 3.16613388, 1.43304431, 1.0
        .float 0.697016835, 3.0383203, 1.42517281, 1.0
        .float 0.762884259, 2.99046493, 1.36674845, 1.0
        .float 0.854768574, 3.1179142, 1.29285693, 1.0
        .float 0.88807565, 3.31074023, 1.21468663, 1.0
        .float 0.861226559, 3.11581588, 1.21468663, 1.0
        .float 0.78804338, 2.97218561, 1.21468663, 1.0
        .float 0.782549918, 2.97617698, 1.29285693, 1.0
        .float 0.674057841, 2.85820007, 1.21468663, 1.0
        .float 0.670066595, 2.86369348, 1.29285693, 1.0
        .float 0.655778646, 2.88335919, 1.36674845, 1.0
        .float 0.530427694, 2.78501678, 1.21468663, 1.0
        .float 0.528329372, 2.79147482, 1.29285693, 1.0
        .float 0.520817757, 2.81459308, 1.36674845, 1.0
        .float 0.495658696, 2.89202499, 1.42517281, 1.0
        .float 0.60792321, 2.94922662, 1.42517281, 1.0
        .float 0.358491927, 2.78888321, 1.36674845, 1.0
        .float 0.352163225, 2.8692975, 1.42517281, 1.0
        .float 0.480109483, 2.93988037, 1.43304431, 1.0
        .float 0.578346908, 2.98993492, 1.43304431, 1.0
        .float 0.656308591, 3.0678966, 1.43304431, 1.0
        .float 0.348251879, 2.91899633, 1.43304431, 1.0
        .float -0.314185023, 2.8692975, 1.42517281, 1.0
        .float -0.310273677, 2.91899633, 1.43304431, 1.0
        .float -0.457680434, 2.89202499, 1.42517281, 1.0
        .float -0.442131221, 2.93988037, 1.43304431, 1.0
        .float -0.540368795, 2.98993492, 1.43304431, 1.0
        .float 0.360909283, 3.8379066, 1.21468663, 1.0
        .float -0.322931051, 3.8379066, 1.21468663, 1.0
        .float 0.571386397, 3.93711567, 0.647064269, 1.0
        .float 0.571386397, 3.93711567, 1.13565028, 1.0
        .float 0.751966, 3.84510565, 1.13565028, 1.0
        .float 0.751966, 3.84510565, 0.647064269, 1.0
        .float 0.371212393, 3.9688201, 0.647064269, 1.0
        .float 0.371212393, 3.9688201, 1.13565028, 1.0
        .float 0.369389236, 3.94565439, 1.19153738, 1.0
        .float 0.564132214, 3.91478968, 1.19153738, 1.0
        .float 0.895274758, 3.70179701, 1.13565028, 1.0
        .float 0.738153696, 3.82609487, 1.19153738, 1.0
        .float 0.895274758, 3.70179701, 0.647064269, 1.0
        .float 0.98728466, 3.52121735, 1.13565028, 1.0
        .float 0.876240611, 3.68796778, 1.19153738, 1.0
        .float 0.546618998, 3.86088943, 1.21468663, 1.0
        .float 0.704807997, 3.78019834, 1.21468663, 1.0
        .float 0.364987701, 3.88972783, 1.21468663, 1.0
        .float 0.830288351, 3.65458155, 1.21468663, 1.0
        .float 0.910772443, 3.49635696, 1.21468663, 1.0
        .float 0.964874744, 3.51393604, 1.19153738, 1.0
        .float 0.939375401, 3.31477761, 1.21468663, 1.0
        .float 0.995670795, 3.31920815, 1.19153738, 1.0
        .float 1.01898921, 3.32104349, 1.13565028, 1.0
        .float 0.965088367, 3.08206916, 1.19153738, 1.0
        .float 0.98728466, 3.074857, 1.13565028, 1.0
        .float 1.01898921, 3.32104349, 0.647064269, 1.0
        .float 0.98728466, 3.52121735, 0.647064269, 1.0
        .float 0.98728466, 3.074857, 0.647064269, 1.0
        .float 0.895274758, 2.89427757, 1.13565028, 1.0
        .float 0.895274758, 2.89427757, 0.647064269, 1.0
        .float 0.751966, 2.75096869, 1.13565028, 1.0
        .float 0.87636888, 2.90801334, 1.19153738, 1.0
        .float 0.751966, 2.75096869, 0.647064269, 1.0
        .float 0.571386397, 2.65895891, 1.13565028, 1.0
        .float 0.738215387, 2.7698946, 1.19153738, 1.0
        .float 0.830726027, 2.94117498, 1.21468663, 1.0
        .float 0.911501944, 3.09948039, 1.21468663, 1.0
        .float 0.70501852, 2.81558633, 1.21468663, 1.0
        .float 0.564150691, 2.68122816, 1.19153738, 1.0
        .float 0.54668206, 2.73499107, 1.21468663, 1.0
        .float 0.364992857, 2.70628119, 1.21468663, 1.0
        .float 0.369390726, 2.65040088, 1.19153738, 1.0
        .float -0.327009469, 2.70634675, 1.21468663, 1.0
        .float -0.331411004, 2.65041995, 1.19153738, 1.0
        .float 0.371212393, 2.62725449, 1.13565028, 1.0
        .float -0.333234161, 2.62725449, 1.13565028, 1.0
        .float -0.526154041, 2.6812849, 1.19153738, 1.0
        .float -0.533408225, 2.65895891, 1.13565028, 1.0
        .float 0.371212393, 2.62725449, 0.647064269, 1.0
        .float -0.333234161, 2.62725449, 0.647064269, 1.0
        .float 0.571386397, 2.65895891, 0.647064269, 1.0
        .float -0.533408225, 2.65895891, 0.647064269, 1.0
        .float -0.713987827, 2.75096869, 1.13565028, 1.0
        .float -0.713987827, 2.75096869, 0.647064269, 1.0
        .float -0.857296586, 2.89427757, 1.13565028, 1.0
        .float -0.700175583, 2.76997972, 1.19153738, 1.0
        .float -0.857296586, 2.89427757, 0.647064269, 1.0
        .float -0.949306488, 3.074857, 1.13565028, 1.0
        .float -0.838262439, 2.90810657, 1.19153738, 1.0
        .float -0.508640826, 2.73518515, 1.21468663, 1.0
        .float -0.666829824, 2.81587601, 1.21468663, 1.0
        .float -0.792310178, 2.9414928, 1.21468663, 1.0
        .float -0.926896572, 3.08213854, 1.19153738, 1.0
        .float -0.872794271, 3.09971738, 1.21468663, 1.0
        .float -0.957692623, 3.2768662, 1.19153738, 1.0
        .float -0.981010914, 3.27503109, 1.13565028, 1.0
        .float -0.901397228, 3.28129673, 1.21468663, 1.0
        .float -0.927110195, 3.51400542, 1.19153738, 1.0
        .float -0.949306488, 3.52121735, 1.13565028, 1.0
        .float -0.949306488, 3.074857, 0.647064269, 1.0
        .float -0.981010914, 3.27503109, 0.647064269, 1.0
        .float -0.949306488, 3.52121735, 0.647064269, 1.0
        .float -0.857296586, 3.70179701, 1.13565028, 1.0
        .float -0.857296586, 3.70179701, 0.647064269, 1.0
        .float -0.713987827, 3.84510565, 1.13565028, 1.0
        .float -0.838390708, 3.688061, 1.19153738, 1.0
        .float -0.713987827, 3.84510565, 0.647064269, 1.0
        .float -0.533408225, 3.93711567, 1.13565028, 1.0
        .float -0.700237215, 3.82617974, 1.19153738, 1.0
        .float -0.792747855, 3.6548996, 1.21468663, 1.0
        .float -0.873523772, 3.49659419, 1.21468663, 1.0
        .float -0.667040348, 3.78048801, 1.21468663, 1.0
        .float -0.526172519, 3.91484642, 1.19153738, 1.0
        .float -0.508703887, 3.86108351, 1.21468663, 1.0
        .float -0.327014625, 3.88979316, 1.21468663, 1.0
        .float -0.331412494, 3.94567347, 1.19153738, 1.0
        .float -0.333234161, 3.9688201, 1.13565028, 1.0
        .float -0.333234161, 3.9688201, 0.647064269, 1.0
        .float -0.533408225, 3.93711567, 0.647064269, 1.0
        .float 0.609294295, 3.6491704, -1.32206047, 1.0
        .float 0.609294295, 3.56792068, -1.4033103, 1.0
        .float -0.571316123, 3.56792068, -1.4033103, 1.0
        .float -0.571316123, 3.6491704, -1.32206047, 1.0
        .float -0.571316123, 3.67891002, -1.21107113, 1.0
        .float 0.609294295, 3.67891002, -1.21107113, 1.0
        .float 0.685548007, 3.63085175, -1.3114841, 1.0
        .float 0.685548007, 3.5573442, -1.38499129, 1.0
        .float -0.647569835, 3.63085175, -1.3114841, 1.0
        .float -0.647569835, 3.5573442, -1.38499129, 1.0
        .float -0.703391433, 3.58080339, -1.28258872, 1.0
        .float -0.647569835, 3.65847802, -1.20838118, 1.0
        .float -0.703391433, 3.52844882, -1.33494306, 1.0
        .float -0.703391433, 3.44689226, -1.35679615, 1.0
        .float -0.647569835, 3.45424128, -1.41261768, 1.0
        .float -0.723823547, 3.48897696, -1.26657581, 1.0
        .float -0.723823547, 3.43685341, -1.28054237, 1.0
        .float -0.723823547, 1.5636282, -1.28054237, 1.0
        .float -0.703391433, 1.55358922, -1.35679615, 1.0
        .float -0.571316123, 3.45693135, -1.4330498, 1.0
        .float -0.647569835, 1.54624021, -1.41261768, 1.0
        .float 0.609294295, 3.45693135, -1.4330498, 1.0
        .float -0.571316123, 1.54355025, -1.4330498, 1.0
        .float 0.609294295, 1.54355025, -1.4330498, 1.0
        .float -0.703391433, 1.47203279, -1.33494306, 1.0
        .float -0.647569835, 1.44313741, -1.38499129, 1.0
        .float -0.571316123, 1.43256092, -1.4033103, 1.0
        .float 0.609294295, 1.43256092, -1.4033103, 1.0
        .float 0.685548007, 1.44313741, -1.38499129, 1.0
        .float 0.685548007, 1.54624021, -1.41261768, 1.0
        .float -0.647569835, 1.36962986, -1.3114841, 1.0
        .float -0.571316123, 1.35131121, -1.32206047, 1.0
        .float 0.609294295, 1.35131121, -1.32206047, 1.0
        .float -0.703391433, 1.41967821, -1.28258872, 1.0
        .float -0.703391433, 1.39782524, -1.20103216, 1.0
        .float -0.647569835, 1.34200358, -1.20838118, 1.0
        .float -0.571316123, 1.32157159, -1.21107113, 1.0
        .float -0.703391433, 1.39782524, -0.546844006, 1.0
        .float -0.647569835, 1.34200358, -0.546844006, 1.0
        .float -0.723823547, 1.47407901, -1.19099319, 1.0
        .float -0.723823547, 1.47407901, -0.546844006, 1.0
        .float -0.723823547, 1.48804545, -1.24311686, 1.0
        .float -0.723823547, 3.52640247, -0.546844006, 1.0
        .float -0.723823547, 3.52640247, -1.19099319, 1.0
        .float -0.723823547, 3.51243615, -1.24311686, 1.0
        .float -0.723823547, 1.51150465, -1.26657593, 1.0
        .float -0.703391433, 3.60265636, -1.20103216, 1.0
        .float -0.647569835, 3.65847802, -0.546844006, 1.0
        .float -0.703391433, 3.60265636, -0.546844006, 1.0
        .float -0.571316123, 3.67891002, -0.546844006, 1.0
        .float 0.609294295, 3.67891002, -0.546844006, 1.0
        .float 0.685548007, 3.65847802, -0.546844006, 1.0
        .float 0.685548007, 3.65847802, -1.20838118, 1.0
        .float 0.741369605, 3.58080339, -1.28258872, 1.0
        .float 0.741369605, 3.60265636, -1.20103216, 1.0
        .float 0.741369605, 3.60265636, -0.546844006, 1.0
        .float 0.76180172, 3.51243615, -1.24311686, 1.0
        .float 0.76180172, 3.52640247, -1.19099319, 1.0
        .float 0.76180172, 3.48897696, -1.26657581, 1.0
        .float 0.741369605, 3.52844882, -1.33494306, 1.0
        .float 0.76180172, 3.43685341, -1.28054237, 1.0
        .float 0.741369605, 3.44689226, -1.35679615, 1.0
        .float 0.76180172, 1.48804545, -1.24311686, 1.0
        .float 0.76180172, 1.51150465, -1.26657593, 1.0
        .float 0.76180172, 1.5636282, -1.28054237, 1.0
        .float 0.685548007, 3.45424128, -1.41261768, 1.0
        .float 0.741369605, 1.55358922, -1.35679615, 1.0
        .float 0.741369605, 1.47203279, -1.33494306, 1.0
        .float 0.741369605, 1.41967821, -1.28258872, 1.0
        .float 0.76180172, 1.47407901, -1.19099319, 1.0
        .float 0.741369605, 1.39782524, -1.20103216, 1.0
        .float 0.685548007, 1.36962986, -1.3114841, 1.0
        .float 0.685548007, 1.34200358, -1.20838118, 1.0
        .float 0.76180172, 1.47407901, -0.546844006, 1.0
        .float 0.741369605, 1.39782524, -0.546844006, 1.0
        .float 0.609294295, 1.32157159, -1.21107113, 1.0
        .float 0.685548007, 1.34200358, -0.546844006, 1.0
        .float 0.609294295, 1.32157159, -0.546844006, 1.0
        .float -0.571316123, 1.32157159, -0.546844006, 1.0
        .float 0.76180172, 3.52640247, -0.546844006, 1.0
    
    .ndc_vertex_data:
        .float 0.000000000, 2.85752797, -1.04546225, 1.0
        .float 0.000000000, 3.13345504, -1.04841363, 1.0
        .float 0.25641644, 3.13336754, -1.02886605, 1.0
        .float 0.252184868, 2.85752797, -1.02551281, 1.0
        .float 0.000000000, 2.5851388, -1.03848183, 1.0
        .float -0.252186835, 2.85752797, -1.0255127, 1.0
        .float -0.256418437, 3.13336754, -1.02886581, 1.0
        .float 0.501476586, 3.13323903, -0.972472727, 1.0
        .float 0.496262401, 2.85752797, -0.968774378, 1.0
        .float 0.246041015, 2.5851388, -1.01744914, 1.0
        .float 0.000000000, 2.34752274, -1.03218341, 1.0
        .float -0.246042982, 2.5851388, -1.01744926, 1.0
        .float 0.240693316, 2.34752274, -1.00996268, 1.0
        .float 0.48596856, 2.5851388, -0.956595719, 1.0
        .float 0.723616302, 3.13246775, -0.881293356, 1.0
        .float 0.722629488, 2.85694981, -0.878573596, 1.0
        .float 0.476090968, 2.34752274, -0.94368583, 1.0
        .float 0.711661458, 2.58474398, -0.860040605, 1.0
        .float 0.000000000, 2.1678617, -1.0277096, 1.0
        .float 0.238325551, 2.16786194, -1.0048703, 1.0
        .float 0.471385419, 2.1678617, -0.935023487, 1.0
        .float 0.698942423, 2.34728813, -0.837575734, 1.0
        .float 0.915708184, 2.8529017, -0.752875268, 1.0
        .float 0.906976938, 2.58198166, -0.734909475, 1.0
        .float 0.692225814, 2.16774845, -0.821885526, 1.0
        .float 0.894186795, 2.3456471, -0.710438311, 1.0
        .float 0.470081717, 2.02297401, -0.92153734, 1.0
        .float 0.237855971, 2.02297401, -0.992218554, 1.0
        .float 0.689705491, 2.02295828, -0.806506932, 1.0
        .float 0.887149513, 2.16695499, -0.69200778, 1.0
        .float 1.04669535, 2.34211087, -0.575505257, 1.0
        .float 1.05626369, 2.57602191, -0.585713327, 1.0
        .float 0.884398401, 2.02284861, -0.676779628, 1.0
        .float 1.04197145, 2.16524506, -0.564800084, 1.0
        .float 0.469112247, 1.88357198, -0.893903315, 1.0
        .float 0.68744421, 1.88306952, -0.782860518, 1.0
        .float 1.0409919, 2.02261066, -0.554242671, 1.0
        .float 0.881802261, 1.88326824, -0.658640385, 1.0
        .float 1.14887953, 2.33986402, -0.409124821, 1.0
        .float 1.14730108, 2.16415453, -0.408272505, 1.0
        .float 1.1483165, 2.02244639, -0.403530538, 1.0
        .float 1.04013503, 1.88479567, -0.542098403, 1.0
        .float 0.682541072, 1.73784137, -0.75107348, 1.0
        .float 0.875849664, 1.73625863, -0.633757055, 1.0
        .float 1.0365082, 1.74164283, -0.522029638, 1.0
        .float 1.14916408, 1.88612998, -0.396703839, 1.0
        .float 1.19768965, 2.16503143, -0.192042053, 1.0
        .float 1.19913876, 2.02254581, -0.19055748, 1.0
        .float 1.14831007, 1.74797106, -0.381283641, 1.0
        .float 1.19966269, 1.88582313, -0.187493026, 1.0
        .float 0.863929808, 1.57874823, -0.599727511, 1.0
        .float 1.02820051, 1.59075809, -0.488837987, 1.0
        .float 1.14492917, 1.60690868, -0.351471722, 1.0
        .float 1.19907522, 1.7489233, -0.178568542, 1.0
        .float 1.19996834, 2.02281094, 0.0563908257, 1.0
        .float 1.19984019, 1.88487065, 0.0568420589, 1.0
        .float 1.19763076, 1.61138594, -0.159894168, 1.0
        .float 1.19877124, 1.7470907, 0.0596879087, 1.0
        .float 1.13980079, 1.46519935, -0.312626183, 1.0
        .float 1.01650202, 1.44154668, -0.446487516, 1.0
        .float 1.19556129, 1.47220099, -0.135343313, 1.0
        .float 1.19758189, 1.60908413, 0.0664210171, 1.0
        .float 1.0033313, 1.30264115, -0.403082311, 1.0
        .float 1.1336844, 1.3249104, -0.274296284, 1.0
        .float 0.846414447, 1.42509556, -0.557591379, 1.0
        .float 0.825534523, 1.28813362, -0.511269569, 1.0
        .float 0.807974219, 1.1571703, -0.472769648, 1.0
        .float 0.989923358, 1.16778636, -0.374127954, 1.0
        .float 1.12565124, 1.18403053, -0.2516388, 1.0
        .float 1.19256055, 1.33039188, -0.111248709, 1.0
        .float 0.977674603, 1.02915215, -0.370376557, 1.0
        .float 1.11552334, 1.04051852, -0.254460394, 1.0
        .float 0.612214863, 1.17071438, -0.552446663, 1.0
        .float 0.799368382, 1.01928687, -0.451909393, 1.0
        .float 1.10780823, 0.896285295, -0.265558332, 1.0
        .float 0.969311357, 0.887497663, -0.376166701, 1.0
        .float 1.17533183, 1.03842974, -0.0950030163, 1.0
        .float 1.16628134, 0.891420126, -0.0992614552, 1.0
        .float 1.10610294, 0.753592491, -0.266490668, 1.0
        .float 1.16445482, 0.747145891, -0.099108316, 1.0
        .float 0.796700537, 0.87618947, -0.441664904, 1.0
        .float 0.966497898, 0.745259285, -0.374215811, 1.0
        .float 1.10567176, 0.612162113, -0.260868043, 1.0
        .float 1.16433501, 0.605086088, -0.0961857662, 1.0
        .float 1.16401792, 0.736879826, 0.0930313319, 1.0
        .float 1.16378105, 0.5937922, 0.0906307548, 1.0
        .float 1.15937924, 0.466774702, -0.0940493271, 1.0
        .float 1.15862679, 0.454776764, 0.0873946622, 1.0
        .float 1.10106921, 0.473685503, -0.256102681, 1.0
        .float 0.965318263, 0.602992296, -0.367171407, 1.0
        .float 1.14914012, 0.333170652, 0.0848919004, 1.0
        .float 1.14987361, 0.344999552, -0.0925807282, 1.0
        .float 1.09234178, 0.350301981, -0.2527619, 1.0
        .float 0.961569488, 0.463184357, -0.361171365, 1.0
        .float 0.793854773, 0.588565111, -0.424823433, 1.0
        .float 0.795465708, 0.732335567, -0.43289414, 1.0
        .float 0.791181386, 0.447251797, -0.418314278, 1.0
        .float 0.955478609, 0.337917805, -0.356384575, 1.0
        .float 0.647615731, 0.581868649, -0.45132181, 1.0
        .float 0.64872241, 0.726721764, -0.460437089, 1.0
        .float 0.642574549, 0.874054432, -0.476975828, 1.0
        .float 0.518818021, 0.874334812, -0.475328177, 1.0
        .float 0.533251226, 0.725992441, -0.458449274, 1.0
        .float 0.532898307, 0.58091259, -0.449272722, 1.0
        .float 0.645880401, 0.439885855, -0.444611222, 1.0
        .float 0.425036013, 0.868771791, -0.425696403, 1.0
        .float 0.442959964, 0.725297689, -0.421149135, 1.0
        .float 0.475573957, 1.02784514, -0.507947803, 1.0
        .float 0.625239909, 1.02458119, -0.50649333, 1.0
        .float 0.390086889, 1.19177127, -0.581069171, 1.0
        .float 0.371707708, 1.00734329, -0.426277161, 1.0
        .float 0.352426469, 0.86154604, -0.321731091, 1.0
        .float 0.279010922, 1.12123966, -0.432983607, 1.0
        .float 0.303952992, 0.98483181, -0.294490308, 1.0
        .float 0.293480396, 0.858290672, -0.164004415, 1.0
        .float 0.368185282, 0.724393845, -0.329519808, 1.0
        .float 0.223768011, 1.08196473, -0.269717962, 1.0
        .float 0.259812295, 0.975199223, -0.142022341, 1.0
        .float 0.184166595, 1.25427318, -0.614280999, 1.0
        .float 0.147023201, 1.18336964, -0.444914073, 1.0
        .float 0.118487097, 1.14169145, -0.267591059, 1.0
        .float 0.197154343, 1.0667522, -0.12254221, 1.0
        .float 0.254266143, 0.858014822, 0.0239017606, 1.0
        .float 0.235860437, 0.974366903, 0.0221138224, 1.0
        .float 0.188483536, 1.06533527, 0.0157607757, 1.0
        .float 0.106348686, 1.12562299, -0.120932825, 1.0
        .float 0.000000000, 1.20121384, -0.452196568, 1.0
        .float 0.000000000, 1.16163492, -0.272373974, 1.0
        .float 0.000000000, 1.14635587, -0.124716245, 1.0
        .float 0.104750499, 1.12389493, 0.00492855161, 1.0
        .float 0.190641567, 1.06825209, 0.159736842, 1.0
        .float 0.231734723, 0.976321697, 0.191432476, 1.0
        .float 0.000000000, 1.14455056, -0.00122205168, 1.0
        .float 0.107631877, 1.12658906, 0.131518334, 1.0
        .float -0.10635066, 1.12562299, -0.12093281, 1.0
        .float -0.104752488, 1.12389493, 0.00492855906, 1.0
        .float 0.000000000, 1.14684343, 0.119342178, 1.0
        .float -0.107633851, 1.12658906, 0.131518334, 1.0
        .float -0.188485503, 1.06533527, 0.0157607757, 1.0
        .float -0.190643549, 1.06825209, 0.159736857, 1.0
        .float -0.118489079, 1.14169168, -0.267591059, 1.0
        .float -0.19715631, 1.06675243, -0.122542195, 1.0
        .float -0.235862404, 0.974366665, 0.0221138299, 1.0
        .float -0.231736675, 0.976321459, 0.191432476, 1.0
        .float -0.223769993, 1.08196497, -0.269717991, 1.0
        .float -0.259814322, 0.975198984, -0.142022341, 1.0
        .float -0.147025153, 1.18336987, -0.444914013, 1.0
        .float -0.279012889, 1.12123966, -0.432983547, 1.0
        .float -0.303954959, 0.984831572, -0.294490248, 1.0
        .float -0.25426811, 0.858014584, 0.0239017457, 1.0
        .float -0.293482393, 0.858290672, -0.164004415, 1.0
        .float -0.371709675, 1.00734329, -0.42627719, 1.0
        .float -0.352428436, 0.86154604, -0.321731061, 1.0
        .float -0.184168562, 1.25427341, -0.614281058, 1.0
        .float -0.390088886, 1.19177127, -0.581069171, 1.0
        .float -0.475575924, 1.02784514, -0.507947743, 1.0
        .float -0.42503795, 0.868771791, -0.425696433, 1.0
        .float -0.368187219, 0.724394083, -0.329519838, 1.0
        .float -0.442961931, 0.725297689, -0.421149105, 1.0
        .float -0.518820047, 0.874334574, -0.475328237, 1.0
        .float -0.533253312, 0.72599268, -0.458449215, 1.0
        .float -0.625241995, 1.02458096, -0.50649327, 1.0
        .float -0.642576635, 0.874054432, -0.476975769, 1.0
        .float -0.648724377, 0.726721764, -0.460437149, 1.0
        .float -0.532900393, 0.58091259, -0.449272722, 1.0
        .float -0.647617698, 0.581869364, -0.45132181, 1.0
        .float -0.442770392, 0.580912113, -0.413785458, 1.0
        .float -0.531898856, 0.438947439, -0.442582279, 1.0
        .float -0.64587456, 0.439998865, -0.44462201, 1.0
        .float -0.791184008, 0.447365284, -0.418323457, 1.0
        .float -0.79385674, 0.588564873, -0.424823403, 1.0
        .float -0.795467734, 0.732336044, -0.43289414, 1.0
        .float -0.961581886, 0.463295937, -0.361177653, 1.0
        .float -0.965320289, 0.602993011, -0.367171347, 1.0
        .float -0.788560867, 0.321444511, -0.412473857, 1.0
        .float -0.955563605, 0.338810444, -0.356434733, 1.0
        .float -0.646203101, 0.313481331, -0.43821314, 1.0
        .float -0.787169337, 0.223763466, -0.406420231, 1.0
        .float -0.948758364, 0.242382526, -0.352028906, 1.0
        .float -1.09248185, 0.351161718, -0.252790779, 1.0
        .float -1.08175707, 0.257149696, -0.250048429, 1.0
        .float -0.943045378, 0.177630424, -0.348533154, 1.0
        .float -1.0723356, 0.194595575, -0.248003095, 1.0
        .float -0.649534881, 0.215337276, -0.431282669, 1.0
        .float -0.786677599, 0.158087254, -0.40136382, 1.0
        .float -0.93900013, 0.14355588, -0.34513548, 1.0
        .float -1.06587684, 0.161809683, -0.245746106, 1.0
        .float -1.12202418, 0.16530323, -0.088315554, 1.0
        .float -1.12867928, 0.195993423, -0.0897292867, 1.0
        .float -1.05547059, 0.149024963, -0.237242937, 1.0
        .float -1.1119808, 0.154053688, -0.083361946, 1.0
        .float -0.786108434, 0.123506784, -0.396889001, 1.0
        .float -0.931599677, 0.129926443, -0.333997607, 1.0
        .float -0.783417046, 0.109627962, -0.38405785, 1.0
        .float -0.656081378, 0.114604473, -0.420341194, 1.0
        .float -0.653604865, 0.149348736, -0.425383866, 1.0
        .float -0.657561004, 0.100659847, -0.406698912, 1.0
        .float -0.549297094, 0.148100615, -0.423511058, 1.0
        .float -0.554178238, 0.113332748, -0.418509752, 1.0
        .float -0.541626513, 0.214133024, -0.429346889, 1.0
        .float -0.467359781, 0.148100376, -0.390699238, 1.0
        .float -0.456856549, 0.214133501, -0.395673633, 1.0
        .float -0.558956742, 0.0993785858, -0.404919654, 1.0
        .float -0.474132836, 0.11333251, -0.386299342, 1.0
        .float -0.398844451, 0.148100615, -0.306017488, 1.0
        .float -0.38597253, 0.214133024, -0.309974909, 1.0
        .float -0.373519868, 0.312343359, -0.314757645, 1.0
        .float -0.446858615, 0.312343597, -0.401629657, 1.0
        .float -0.323092192, 0.214133501, -0.160760731, 1.0
        .float -0.308469504, 0.312343597, -0.163921565, 1.0
        .float -0.407199502, 0.113332033, -0.302479029, 1.0
        .float -0.338057339, 0.148100376, -0.158027917, 1.0
        .float -0.262362719, 0.312343359, 0.0155626573, 1.0
        .float -0.278478116, 0.214133024, 0.0129155926, 1.0
        .float -0.254013062, 0.438947439, 0.0183306225, 1.0
        .float -0.301064968, 0.438946962, -0.166756481, 1.0
        .float -0.238933682, 0.438946962, 0.196783751, 1.0
        .float -0.24754703, 0.312343597, 0.183231816, 1.0
        .float -0.294878513, 0.148100615, 0.0108497143, 1.0
        .float -0.264050186, 0.214133501, 0.168690473, 1.0
        .float -0.280813575, 0.148100376, 0.156563208, 1.0
        .float -0.305596352, 0.113332033, 0.00997865573, 1.0
        .float -0.347811192, 0.11333251, -0.155667931, 1.0
        .float -0.29178521, 0.11333251, 0.149620548, 1.0
        .float -0.318423599, 0.0993783474, 0.0113271102, 1.0
        .float -0.359282255, 0.099378109, -0.149212658, 1.0
        .float -0.416745871, 0.0993783474, -0.292154193, 1.0
        .float -0.481507987, 0.099378109, -0.373691827, 1.0
        .float -0.305032194, 0.099378109, 0.145359263, 1.0
        .float -0.253203273, 0.58091259, 0.0209616832, 1.0
        .float -0.238032073, 0.580912113, 0.208683997, 1.0
        .float -0.300559402, 0.580912113, -0.169689864, 1.0
        .float -0.367476672, 0.438947439, -0.319478482, 1.0
        .float -0.367404401, 0.58091259, -0.324873656, 1.0
        .float -0.25636524, 0.72395277, 0.023113329, 1.0
        .float -0.302548468, 0.723987579, -0.171600014, 1.0
        .float -0.442353696, 0.438946962, -0.407386303, 1.0
        .float -0.242939219, 0.858684301, 0.213637948, 1.0
        .float -0.241723955, 0.724036694, 0.217207611, 1.0
        .float -0.534564137, 0.312343597, -0.436212569, 1.0
        .float -1.11415172, 0.146960974, 0.0864270478, 1.0
        .float -1.12301004, 0.15743804, 0.0855268538, 1.0
        .float -1.1291225, 0.187111378, 0.0849821419, 1.0
        .float -1.13859451, 0.255098104, -0.0910684541, 1.0
        .float -1.13837087, 0.244585037, 0.0843916982, 1.0
        .float -1.1500206, 0.345807076, -0.0926003233, 1.0
        .float -1.14927661, 0.333952904, 0.0848803446, 1.0
        .float -1.10108852, 0.47379303, -0.256106317, 1.0
        .float -1.15939927, 0.466875553, -0.0940517858, 1.0
        .float -1.10567379, 0.612161636, -0.260868073, 1.0
        .float -1.1643368, 0.605086088, -0.0961857513, 1.0
        .float -1.15864551, 0.454874516, 0.0873932093, 1.0
        .float -0.966499925, 0.745259047, -0.374215811, 1.0
        .float -1.10610485, 0.75359273, -0.266490668, 1.0
        .float -0.796702683, 0.87618947, -0.441664904, 1.0
        .float -0.969313383, 0.88749814, -0.376166731, 1.0
        .float -1.10781026, 0.896285295, -0.265558332, 1.0
        .float -1.16445673, 0.747145653, -0.0991083011, 1.0
        .float -0.799370348, 1.01928687, -0.451909333, 1.0
        .float -0.97767663, 1.02915239, -0.370376527, 1.0
        .float -0.807976246, 1.1571703, -0.472769648, 1.0
        .float -0.61221689, 1.17071462, -0.552446604, 1.0
        .float -0.989925325, 1.1677866, -0.374127924, 1.0
        .float -1.11552501, 1.04051876, -0.254460365, 1.0
        .float -1.00333309, 1.30264139, -0.403082311, 1.0
        .float -0.825536609, 1.28813338, -0.511269629, 1.0
        .float -0.628506541, 1.30380368, -0.610156119, 1.0
        .float -1.01650405, 1.44154668, -0.446487457, 1.0
        .float -0.846416533, 1.42509556, -0.557591379, 1.0
        .float -1.1336863, 1.3249104, -0.274296284, 1.0
        .float -1.13980269, 1.46519947, -0.312626183, 1.0
        .float -1.02820253, 1.59075832, -0.488838047, 1.0
        .float -1.1449312, 1.6069088, -0.351471722, 1.0
        .float -0.654154062, 1.43751276, -0.665973604, 1.0
        .float -0.863931835, 1.57874846, -0.599727571, 1.0
        .float -1.14831197, 1.74797106, -0.381283641, 1.0
        .float -1.03651011, 1.74164283, -0.522029638, 1.0
        .float -1.19763267, 1.6113857, -0.159894139, 1.0
        .float -1.19907713, 1.74892342, -0.178568542, 1.0
        .float -1.19966483, 1.88582313, -0.187493026, 1.0
        .float -1.14916599, 1.88612998, -0.396703809, 1.0
        .float -0.875851631, 1.73625875, -0.633756995, 1.0
        .float -1.04013693, 1.88479555, -0.542098403, 1.0
        .float -1.19914055, 2.02254581, -0.19055748, 1.0
        .float -1.14831841, 2.02244663, -0.403530538, 1.0
        .float -1.1998421, 1.88487065, 0.0568420514, 1.0
        .float -1.19997025, 2.02281094, 0.0563908294, 1.0
        .float -1.19769156, 2.16503143, -0.192042112, 1.0
        .float -1.19866574, 2.16669512, 0.0564431138, 1.0
        .float -1.04099381, 2.02261066, -0.554242611, 1.0
        .float -1.1473031, 2.16415453, -0.408272505, 1.0
        .float -1.1975292, 2.34502125, 0.0566555746, 1.0
        .float -1.19729614, 2.34168053, -0.190026253, 1.0
        .float -1.04197335, 2.16524506, -0.564800084, 1.0
        .float -1.14888132, 2.33986402, -0.409124821, 1.0
        .float -0.884400368, 2.02284861, -0.676779628, 1.0
        .float -0.881804347, 1.88326824, -0.658640385, 1.0
        .float -0.88715148, 2.16695499, -0.69200772, 1.0
        .float -1.04669714, 2.34211087, -0.575505257, 1.0
        .float -1.1538626, 2.57219005, -0.403499216, 1.0
        .float -1.19857836, 2.57511139, -0.182475895, 1.0
        .float -0.894188881, 2.3456471, -0.710438311, 1.0
        .float -1.05626559, 2.57602191, -0.585713327, 1.0
        .float -0.689707518, 2.02295828, -0.806506991, 1.0
        .float -0.692227781, 2.16774845, -0.821885586, 1.0
        .float -0.698944449, 2.34728813, -0.837575674, 1.0
        .float -0.906978965, 2.58198166, -0.734909415, 1.0
        .float -1.15401459, 2.83840179, -0.393988103, 1.0
        .float -1.06096649, 2.84415007, -0.589867115, 1.0
        .float -0.915710211, 2.8529017, -0.752875268, 1.0
        .float -0.711663485, 2.58474398, -0.860040665, 1.0
        .float -0.471387416, 2.1678617, -0.935023487, 1.0
        .float -0.476092935, 2.34752274, -0.94368583, 1.0
        .float -0.485970587, 2.5851388, -0.956595719, 1.0
        .float -0.722631454, 2.85694981, -0.878573656, 1.0
        .float -0.910452545, 3.12723875, -0.752127409, 1.0
        .float -1.05102396, 3.11584949, -0.583207726, 1.0
        .float -0.496264368, 2.85752797, -0.968774378, 1.0
        .float -0.723618269, 3.13246775, -0.881293356, 1.0
        .float -0.240695283, 2.34752274, -1.0099628, 1.0
        .float -0.501478612, 3.13323903, -0.972472727, 1.0
        .float -0.892080545, 3.38749123, -0.737191916, 1.0
        .float -0.71405077, 3.3931098, -0.868792892, 1.0
        .float -0.499683291, 3.39410877, -0.962907732, 1.0
        .float -0.695466101, 3.62625742, -0.843149424, 1.0
        .float -0.863718867, 3.62094855, -0.714592159, 1.0
        .float -1.02722025, 3.37485218, -0.569083393, 1.0
        .float -0.991999388, 3.60940075, -0.551556945, 1.0
        .float -0.826687574, 3.82039404, -0.68210423, 1.0
        .float -0.943891823, 3.81140423, -0.529441714, 1.0
        .float -1.07507896, 3.60356951, -0.361653864, 1.0
        .float -1.01851964, 3.81095409, -0.34843573, 1.0
        .float -1.11438942, 3.36678839, -0.37314868, 1.0
        .float -1.10992324, 3.61332631, -0.154467523, 1.0
        .float -1.04901505, 3.82552195, -0.148200363, 1.0
        .float -0.938234806, 3.98371601, -0.33434698, 1.0
        .float -0.961335301, 4.00442028, -0.141879767, 1.0
        .float -1.0426755, 3.83875394, 0.0587838143, 1.0
        .float -0.954033971, 4.01846457, 0.0592628084, 1.0
        .float -1.15142548, 3.3732636, -0.160210639, 1.0
        .float -1.10430312, 3.62529111, 0.0583754182, 1.0
        .float -1.17953074, 3.11308837, -0.165904909, 1.0
        .float -1.14636981, 3.38371325, 0.058044821, 1.0
        .float -1.14091122, 3.10825372, -0.383765101, 1.0
        .float -1.19495237, 2.84235072, -0.173105776, 1.0
        .float -1.17511475, 3.12206364, 0.0577649362, 1.0
        .float -1.19166398, 2.84969139, 0.0574477278, 1.0
        .float -1.19711065, 2.58046365, 0.0570358485, 1.0
        .float -0.831182361, 4.16710758, 0.0597289912, 1.0
        .float -0.839393914, 4.15209055, -0.138678968, 1.0
        .float -0.669038773, 4.28773403, 0.0600996986, 1.0
        .float -0.677616894, 4.27105093, -0.141179383, 1.0
        .float -0.824769735, 4.12349796, -0.327389747, 1.0
        .float -0.670191705, 4.23289967, -0.334096164, 1.0
        .float -0.878933012, 3.97464347, -0.503317893, 1.0
        .float -0.785348892, 4.09813499, -0.488566607, 1.0
        .float -0.646880388, 4.18770981, -0.503286541, 1.0
        .float -0.475629896, 4.31147194, -0.347968727, 1.0
        .float -0.462512195, 4.25039816, -0.529383361, 1.0
        .float -0.452966392, 4.15806818, -0.682104111, 1.0
        .float -0.629402518, 4.1167593, -0.637556374, 1.0
        .float -0.782231033, 3.97794175, -0.637556314, 1.0
        .float -0.739698648, 4.07278776, -0.593862474, 1.0
        .float -0.64287436, 3.99572039, -0.733348191, 1.0
        .float -0.459749579, 4.01677608, -0.799902737, 1.0
        .float -0.239692882, 4.03407288, -0.841576695, 1.0
        .float -0.236511871, 4.18588209, -0.712998331, 1.0
        .float -0.247146741, 3.84461689, -0.934014618, 1.0
        .float -0.475743473, 3.83587623, -0.883325815, 1.0
        .float -0.670191407, 3.82831645, -0.799902737, 1.0
        .float -0.253740728, 3.63181925, -0.991243184, 1.0
        .float -0.490444452, 3.62828541, -0.935476482, 1.0
        .float 0.000000000, 3.63404489, -1.00995231, 1.0
        .float 0.000000000, 3.84912086, -0.951212108, 1.0
        .float 0.000000000, 3.39583683, -1.03946447, 1.0
        .float -0.257196546, 3.39513683, -1.02010798, 1.0
        .float 0.257194549, 3.39513683, -1.02010798, 1.0
        .float 0.253738731, 3.63181925, -0.991243064, 1.0
        .float 0.499681354, 3.39410877, -0.962907732, 1.0
        .float 0.490442485, 3.62828541, -0.935476601, 1.0
        .float 0.247144759, 3.84461689, -0.934014618, 1.0
        .float 0.475741506, 3.83587623, -0.883325815, 1.0
        .float 0.695464075, 3.62625742, -0.843149424, 1.0
        .float 0.670189381, 3.82831645, -0.799902797, 1.0
        .float 0.459747583, 4.01677608, -0.799902737, 1.0
        .float 0.642872274, 3.99572039, -0.733348191, 1.0
        .float 0.23969093, 4.03407288, -0.841576636, 1.0
        .float 0.452964425, 4.15806818, -0.682104111, 1.0
        .float 0.629400492, 4.1167593, -0.637556314, 1.0
        .float 0.739696622, 4.07278776, -0.593862474, 1.0
        .float 0.782229066, 3.97794151, -0.637556374, 1.0
        .float 0.785346866, 4.09813499, -0.488566667, 1.0
        .float 0.646878421, 4.18770981, -0.503286541, 1.0
        .float 0.236509904, 4.18588209, -0.712998331, 1.0
        .float 0.462510228, 4.25039816, -0.529383421, 1.0
        .float 0.824767709, 4.12349796, -0.327389717, 1.0
        .float 0.670189619, 4.23289967, -0.334096134, 1.0
        .float 0.878931046, 3.97464347, -0.503317893, 1.0
        .float 0.826685488, 3.82039404, -0.68210429, 1.0
        .float 0.943889737, 3.81140423, -0.529441774, 1.0
        .float 0.93823272, 3.98371601, -0.33434701, 1.0
        .float 0.839391828, 4.15209055, -0.138678968, 1.0
        .float 1.01851773, 3.81095409, -0.34843573, 1.0
        .float 0.961333275, 4.00442028, -0.141879767, 1.0
        .float 0.863716781, 3.62094855, -0.714592159, 1.0
        .float 0.991997302, 3.60940075, -0.551557064, 1.0
        .float 0.714048743, 3.3931098, -0.86879307, 1.0
        .float 0.892078519, 3.38749123, -0.737191975, 1.0
        .float 1.02721834, 3.37485218, -0.569083393, 1.0
        .float 1.07507718, 3.60356951, -0.361653835, 1.0
        .float 0.910450578, 3.12723875, -0.752127349, 1.0
        .float 1.05102193, 3.11584949, -0.583207726, 1.0
        .float 1.06096458, 2.84415007, -0.589867115, 1.0
        .float 1.11438751, 3.36678839, -0.37314868, 1.0
        .float 1.14090931, 3.10825372, -0.383765101, 1.0
        .float 1.15401256, 2.83840179, -0.393988132, 1.0
        .float 1.17952895, 3.11308837, -0.165904909, 1.0
        .float 1.15142357, 3.3732636, -0.160210639, 1.0
        .float 1.10992134, 3.61332631, -0.154467523, 1.0
        .float 1.14636779, 3.38371325, 0.058044821, 1.0
        .float 1.10430133, 3.62529111, 0.0583754182, 1.0
        .float 1.04901314, 3.82552195, -0.148200363, 1.0
        .float 1.04267359, 3.83875394, 0.0587838143, 1.0
        .float 0.954031944, 4.01846457, 0.0592628084, 1.0
        .float 0.831180334, 4.16710758, 0.0597289875, 1.0
        .float 0.677614868, 4.27105093, -0.141179353, 1.0
        .float 0.669036806, 4.28773403, 0.0600997023, 1.0
        .float 0.475627929, 4.31147194, -0.347968698, 1.0
        .float 0.478221744, 4.35811138, -0.146892637, 1.0
        .float 0.24696067, 4.35831833, -0.360126197, 1.0
        .float 0.241024107, 4.28875446, -0.550141335, 1.0
        .float 0.470717251, 4.3765316, 0.0603716336, 1.0
        .float 0.247472584, 4.40971279, -0.152273804, 1.0
        .float 0.000000000, 4.3737874, -0.365181655, 1.0
        .float 0.000000000, 4.30187607, -0.558289528, 1.0
        .float 0.000000000, 4.19609833, -0.72444129, 1.0
        .float -0.246962652, 4.35831833, -0.360126168, 1.0
        .float -0.241026059, 4.28875446, -0.550141275, 1.0
        .float 0.000000000, 4.42652845, -0.154621065, 1.0
        .float -0.247474536, 4.40971279, -0.152273774, 1.0
        .float -0.478223681, 4.35811138, -0.146892607, 1.0
        .float -0.470719218, 4.3765316, 0.0603716299, 1.0
        .float -0.243112683, 4.42920017, 0.0605532676, 1.0
        .float 0.000000000, 4.44634867, 0.060620863, 1.0
        .float 0.243110701, 4.42920017, 0.0605532601, 1.0
        .float 0.000000000, 4.04132175, -0.856210709, 1.0
        .float 1.17511284, 3.12206364, 0.05776494, 1.0
        .float 1.19495034, 2.84235072, -0.173105806, 1.0
        .float 1.19166207, 2.84969139, 0.0574477166, 1.0
        .float 1.15386057, 2.57219005, -0.403499216, 1.0
        .float 1.19857633, 2.57511139, -0.182475835, 1.0
        .float 1.19729412, 2.34168053, -0.190026253, 1.0
        .float 1.19710863, 2.58046365, 0.0570358485, 1.0
        .float 1.19752729, 2.34502125, 0.0566555858, 1.0
        .float 1.19866383, 2.16669512, 0.0564431176, 1.0
        .float -0.238327503, 2.16786194, -1.00487018, 1.0
        .float 0.000000000, 2.02297401, -1.01509249, 1.0
        .float -0.237857923, 2.02297401, -0.992218673, 1.0
        .float 0.000000000, 1.88388145, -0.985276878, 1.0
        .float -0.470083684, 2.02297401, -0.92153734, 1.0
        .float -0.2376149, 1.88384283, -0.962770045, 1.0
        .float -0.469114244, 1.88357198, -0.893903375, 1.0
        .float 0.000000000, 1.74478912, -0.943969309, 1.0
        .float -0.236832917, 1.74447954, -0.921913207, 1.0
        .float 0.237612933, 1.88384283, -0.962770045, 1.0
        .float 0.23683098, 1.74447954, -0.921913266, 1.0
        .float 0.000000000, 1.60696435, -0.897140622, 1.0
        .float -0.234350622, 1.6058737, -0.875569999, 1.0
        .float -0.466748863, 1.74231267, -0.855835974, 1.0
        .float 0.000000000, 1.47674489, -0.837051332, 1.0
        .float 0.23434864, 1.60587358, -0.875570059, 1.0
        .float 0.466746867, 1.74231279, -0.855836034, 1.0
        .float 0.460872442, 1.59912491, -0.812088251, 1.0
        .float 0.226514399, 1.47390127, -0.817165196, 1.0
        .float 0.446507066, 1.46108055, -0.758526146, 1.0
        .float 0.672343194, 1.58537197, -0.712659717, 1.0
        .float 0.654152036, 1.43751276, -0.665973604, 1.0
        .float 0.420618743, 1.33282113, -0.68798244, 1.0
        .float 0.210130692, 1.35484672, -0.735680044, 1.0
        .float 0.000000000, 1.36153817, -0.75162375, 1.0
        .float 0.000000000, 1.26796055, -0.625136256, 1.0
        .float 0.628504515, 1.30380392, -0.610156178, 1.0
        .float -0.210132673, 1.35484672, -0.735680044, 1.0
        .float -0.42062071, 1.33282089, -0.68798244, 1.0
        .float -0.446509063, 1.46108043, -0.758526087, 1.0
        .float -0.226516351, 1.47390127, -0.817165196, 1.0
        .float -0.460874408, 1.59912491, -0.812088251, 1.0
        .float -0.672345281, 1.58537197, -0.712659717, 1.0
        .float -0.682543159, 1.73784125, -0.75107348, 1.0
        .float -0.687446237, 1.88306963, -0.782860458, 1.0
        .float -1.19877315, 1.7470907, 0.0596878938, 1.0
        .float -1.19758368, 1.60908413, 0.0664210245, 1.0
        .float -1.19556332, 1.47220099, -0.135343283, 1.0
        .float -1.19631243, 1.46934128, 0.0753924996, 1.0
        .float -1.19256246, 1.33039212, -0.111248709, 1.0
        .float -1.19420266, 1.32639527, 0.0842404515, 1.0
        .float -1.12565315, 1.18403053, -0.2516388, 1.0
        .float -1.18619204, 1.18565679, -0.096017845, 1.0
        .float -1.1753335, 1.03842974, -0.0950030312, 1.0
        .float -1.18809676, 1.18007755, 0.0908928216, 1.0
        .float -1.17641497, 1.03110957, 0.0939271599, 1.0
        .float -1.16628313, 0.891419888, -0.0992614552, 1.0
        .float -1.16629291, 0.882468939, 0.0942297876, 1.0
        .float -1.1640197, 0.736879826, 0.0930313319, 1.0
        .float -1.16378295, 0.5937922, 0.0906307548, 1.0
        .float 0.242937237, 0.858684301, 0.213637948, 1.0
        .float 0.256363243, 0.723952532, 0.023113329, 1.0
        .float 0.241721958, 0.724036932, 0.217207611, 1.0
        .float 0.302546531, 0.723987579, -0.171600014, 1.0
        .float 0.253201306, 0.58091259, 0.0209616832, 1.0
        .float 0.300557435, 0.580912113, -0.169689834, 1.0
        .float 0.238030076, 0.580912113, 0.208683997, 1.0
        .float 0.301091194, 0.438833237, -0.166751504, 1.0
        .float 0.25404191, 0.438833475, 0.018326927, 1.0
        .float 0.367402464, 0.58091259, -0.324873656, 1.0
        .float 0.367498994, 0.438833475, -0.3194713, 1.0
        .float 0.442768455, 0.580912113, -0.413785487, 1.0
        .float 0.442371577, 0.438833237, -0.407377303, 1.0
        .float 0.373712093, 0.311433554, -0.314700365, 1.0
        .float 0.447015464, 0.311433077, -0.401557475, 1.0
        .float 0.531911373, 0.438833475, -0.44257161, 1.0
        .float 0.534678757, 0.311433554, -0.436127573, 1.0
        .float 0.646263957, 0.312571287, -0.438127249, 1.0
        .float 0.541959703, 0.211516619, -0.42910251, 1.0
        .float 0.649713635, 0.212722301, -0.431035668, 1.0
        .float 0.788553655, 0.320539236, -0.412400484, 1.0
        .float 0.787152648, 0.221161366, -0.40620932, 1.0
        .float 0.94851768, 0.239817619, -0.351884693, 1.0
        .float 0.786655009, 0.154466152, -0.401070356, 1.0
        .float 0.942711473, 0.174061775, -0.348332524, 1.0
        .float 0.653854549, 0.145710707, -0.425040215, 1.0
        .float 0.938759565, 0.140990734, -0.344991326, 1.0
        .float 0.786091685, 0.12090373, -0.39667812, 1.0
        .float 1.07178128, 0.191156626, -0.247887284, 1.0
        .float 1.06547785, 0.159337759, -0.245662898, 1.0
        .float 1.08135808, 0.254677534, -0.249965221, 1.0
        .float 1.13817585, 0.252775908, -0.0910120979, 1.0
        .float 1.1280973, 0.192762852, -0.0896508619, 1.0
        .float 1.12160528, 0.162981033, -0.0882592127, 1.0
        .float 1.05533051, 0.148165464, -0.237213969, 1.0
        .float 1.11183381, 0.153245926, -0.083342351, 1.0
        .float 1.12262118, 0.15518856, 0.0855600759, 1.0
        .float 1.11401534, 0.146178722, 0.0864385962, 1.0
        .float 1.12858224, 0.183981419, 0.0850283578, 1.0
        .float 1.13798189, 0.242335081, 0.0844249204, 1.0
        .float 0.93151468, 0.129034519, -0.33394748, 1.0
        .float 0.783409894, 0.108722448, -0.383984476, 1.0
        .float 0.656260192, 0.111989021, -0.420094192, 1.0
        .float 0.657621861, 0.0997498035, -0.406613052, 1.0
        .float 0.549761474, 0.144459963, -0.423171192, 1.0
        .float 0.554511368, 0.110715389, -0.418265492, 1.0
        .float 0.467993081, 0.144459724, -0.390410542, 1.0
        .float 0.457311183, 0.211516857, -0.395466179, 1.0
        .float 0.559071362, 0.0984683037, -0.404834718, 1.0
        .float 0.4745875, 0.110715389, -0.386091828, 1.0
        .float 0.399618983, 0.144459963, -0.305788249, 1.0
        .float 0.38652876, 0.21151638, -0.309810102, 1.0
        .float 0.308692902, 0.311433077, -0.16388163, 1.0
        .float 0.323738039, 0.211516142, -0.160645932, 1.0
        .float 0.407755673, 0.110715628, -0.302314252, 1.0
        .float 0.338956773, 0.144459724, -0.157868177, 1.0
        .float 0.262607485, 0.311433554, 0.0155331194, 1.0
        .float 0.279185563, 0.211516619, 0.0128306709, 1.0
        .float 0.238963231, 0.438833237, 0.196761757, 1.0
        .float 0.247797176, 0.311433077, 0.183055937, 1.0
        .float 0.295863539, 0.144459963, 0.0107315555, 1.0
        .float 0.26477313, 0.211516619, 0.168184757, 1.0
        .float 0.281820118, 0.144459963, 0.155859649, 1.0
        .float 0.306303769, 0.110715389, 0.00989373401, 1.0
        .float 0.348457158, 0.110716105, -0.155553132, 1.0
        .float 0.292508125, 0.110715628, 0.149114862, 1.0
        .float 0.318668336, 0.0984683037, 0.011297565, 1.0
        .float 0.359505653, 0.0984683037, -0.149172693, 1.0
        .float 0.416938066, 0.0984680653, -0.292096913, 1.0
        .float 0.481664836, 0.0984685421, -0.373619646, 1.0
        .float 0.305282354, 0.0984680653, 0.14518337, 1.0
        .float 1.16629112, 0.8824687, 0.0942297876, 1.0
        .float 1.17641294, 1.03110957, 0.0939271599, 1.0
        .float 1.18619013, 1.18565679, -0.096017845, 1.0
        .float 1.18809485, 1.18007803, 0.0908928216, 1.0
        .float 1.19420087, 1.32639527, 0.0842404515, 1.0
        .float 1.19631052, 1.4693414, 0.0753924921, 1.0
        .float 1.13836098, 3.12568903, 0.275614798, 1.0
        .float 1.15438938, 2.85307884, 0.281608164, 1.0
        .float 1.11004364, 3.38648582, 0.271010846, 1.0
        .float 1.05419838, 3.38610721, 0.473259985, 1.0
        .float 1.08102858, 3.12659264, 0.480429858, 1.0
        .float 1.09501481, 2.85400629, 0.487846553, 1.0
        .float 1.15884984, 2.58314323, 0.28989777, 1.0
        .float 1.15834963, 2.34683847, 0.296694994, 1.0
        .float 1.09607708, 2.58387256, 0.497814268, 1.0
        .float 1.00798273, 3.12906051, 0.666327417, 1.0
        .float 1.01855981, 2.85536575, 0.668094158, 1.0
        .float 0.983957469, 3.38897824, 0.659919024, 1.0
        .float 0.877031207, 3.39282203, 0.823151588, 1.0
        .float 0.895480335, 3.13188601, 0.828338861, 1.0
        .float 0.900958717, 2.85680294, 0.823586106, 1.0
        .float 1.01473188, 2.58441901, 0.669554114, 1.0
        .float 1.0922327, 2.34736657, 0.505909145, 1.0
        .float 1.00598049, 2.34750319, 0.670489311, 1.0
        .float 0.892531037, 2.58490229, 0.815299392, 1.0
        .float 0.721745074, 3.13311768, 0.961580813, 1.0
        .float 0.720785677, 2.85743713, 0.955654383, 1.0
        .float 0.712167859, 3.39433002, 0.955247998, 1.0
        .float 0.499681324, 3.39474177, 1.05196548, 1.0
        .float 0.501476526, 3.13331819, 1.06059921, 1.0
        .float 0.496262372, 2.85752797, 1.05671227, 1.0
        .float 0.709855795, 2.58510923, 0.945357203, 1.0
        .float 0.880025089, 2.34752274, 0.808079898, 1.0
        .float 0.697172225, 2.34752274, 0.936457694, 1.0
        .float 0.48596853, 2.5851388, 1.04911566, 1.0
        .float 0.25641644, 3.13344669, 1.12069666, 1.0
        .float 0.252184868, 2.85752797, 1.11852765, 1.0
        .float 0.257194549, 3.39576983, 1.11045814, 1.0
        .float 0.000000000, 3.39646983, 1.12999928, 1.0
        .float 0.000000000, 3.13353419, 1.14077353, 1.0
        .float 0.000000000, 2.85752797, 1.13920259, 1.0
        .float 0.246041, 2.5851388, 1.11328661, 1.0
        .float 0.476090938, 2.34752274, 1.04247379, 1.0
        .float 0.240693286, 2.34752274, 1.10861242, 1.0
        .float 0.000000000, 2.5851388, 1.13479316, 1.0
        .float -0.252186805, 2.85752797, 1.11852765, 1.0
        .float -0.246042967, 2.5851388, 1.11328661, 1.0
        .float -0.256418407, 3.13344669, 1.12069678, 1.0
        .float -0.496264309, 2.85752797, 1.05671239, 1.0
        .float -0.485970497, 2.5851388, 1.04911566, 1.0
        .float -0.476092905, 2.34752274, 1.04247379, 1.0
        .float -0.240695238, 2.34752274, 1.1086123, 1.0
        .float 0.000000000, 2.34752274, 1.13081312, 1.0
        .float -0.238327503, 2.16786194, 1.10611916, 1.0
        .float -0.471387386, 2.1678617, 1.03942847, 1.0
        .float -0.690479815, 2.16786957, 0.932768881, 1.0
        .float -0.697174191, 2.34752274, 0.936457694, 1.0
        .float -0.709857821, 2.58510923, 0.945357263, 1.0
        .float -0.873167276, 2.16792393, 0.804958642, 1.0
        .float -0.880027175, 2.34752274, 0.808079898, 1.0
        .float -0.870499611, 2.02304268, 0.804491401, 1.0
        .float -0.687969983, 2.0229826, 0.932403743, 1.0
        .float -0.470083624, 2.02297401, 1.03867435, 1.0
        .float -0.68614465, 1.88389802, 0.931279242, 1.0
        .float -0.86854142, 1.88401318, 0.803849518, 1.0
        .float -1.0010289, 2.02316809, 0.668599486, 1.0
        .float -1.00071204, 1.88426781, 0.667126238, 1.0
        .float -1.00034225, 1.74565887, 0.664662778, 1.0
        .float -0.866872191, 1.74508464, 0.799139619, 1.0
        .float -0.684271216, 1.74482584, 0.922229946, 1.0
        .float -0.469264209, 1.88388145, 1.03645682, 1.0
        .float -1.0000788, 1.60708535, 0.659544647, 1.0
        .float -0.865807235, 1.60619688, 0.786421537, 1.0
        .float -1.09442985, 1.60791731, 0.501066864, 1.0
        .float -1.09439087, 1.74612951, 0.501997828, 1.0
        .float -1.09433794, 1.46806753, 0.498769283, 1.0
        .float -1.00004816, 1.46697056, 0.648464859, 1.0
        .float -0.865540922, 1.46694207, 0.76263237, 1.0
        .float -0.682533622, 1.60621321, 0.898907244, 1.0
        .float -0.999859631, 1.32375669, 0.62863946, 1.0
        .float -1.09402907, 1.3248837, 0.492497176, 1.0
        .float -1.16016924, 1.46809912, 0.298461109, 1.0
        .float -1.15904331, 1.32492042, 0.299320161, 1.0
        .float -1.09141731, 1.17840838, 0.478902519, 1.0
        .float -1.15476167, 1.17834496, 0.296821207, 1.0
        .float -0.997084737, 1.17727542, 0.601020873, 1.0
        .float -0.865743935, 1.32631755, 0.72670114, 1.0
        .float -1.08524501, 1.02960539, 0.456536919, 1.0
        .float -0.990173697, 1.02827024, 0.568530798, 1.0
        .float -1.14589357, 1.02917075, 0.289434075, 1.0
        .float -1.07956815, 0.881393909, 0.432291687, 1.0
        .float -0.983122826, 0.879733324, 0.538232327, 1.0
        .float -0.852927744, 0.878076315, 0.610414684, 1.0
        .float -0.858943045, 1.03010154, 0.643900394, 1.0
        .float -0.979637742, 0.734238148, 0.515587449, 1.0
        .float -0.848794639, 0.730585575, 0.587256253, 1.0
        .float -1.13813424, 0.880436659, 0.279471368, 1.0
        .float -1.07791054, 0.736239195, 0.412751406, 1.0
        .float -0.976712584, 0.590434551, 0.495513409, 1.0
        .float -0.845039904, 0.586046696, 0.567389488, 1.0
        .float -0.700103939, 0.728342772, 0.636886477, 1.0
        .float -0.696872056, 0.583018541, 0.616621256, 1.0
        .float -0.839766562, 0.444276571, 0.544362068, 1.0
        .float -0.693335712, 0.441106558, 0.593000472, 1.0
        .float -1.0763545, 0.592839718, 0.394933134, 1.0
        .float -0.970700026, 0.448993206, 0.472984493, 1.0
        .float -0.833737969, 0.317635298, 0.524155855, 1.0
        .float -0.691141486, 0.314455509, 0.571720481, 1.0
        .float -0.560201883, 0.312954187, 0.588952124, 1.0
        .float -0.55861032, 0.439575911, 0.61105603, 1.0
        .float -0.691286504, 0.216153622, 0.559750557, 1.0
        .float -0.565832913, 0.214712381, 0.576058984, 1.0
        .float -0.9621014, 0.322591543, 0.453748077, 1.0
        .float -0.828265786, 0.219293594, 0.513483763, 1.0
        .float -0.69249922, 0.150032759, 0.554690838, 1.0
        .float -0.572195113, 0.148649454, 0.570217133, 1.0
        .float -0.470990688, 0.214205742, 0.555959284, 1.0
        .float -0.48095125, 0.148169041, 0.549988449, 1.0
        .float -0.576261878, 0.113862753, 0.565849364, 1.0
        .float -0.487370014, 0.113399029, 0.545617223, 1.0
        .float -0.824194431, 0.15312624, 0.50954771, 1.0
        .float -0.693241239, 0.115208626, 0.550809979, 1.0
        .float -0.58021003, 0.09988904, 0.552923083, 1.0
        .float -0.49429962, 0.0994422436, 0.533159435, 1.0
        .float -0.426328927, 0.0993783474, 0.474588543, 1.0
        .float -0.417119443, 0.113332033, 0.48620221, 1.0
        .float -0.36575067, 0.099378109, 0.377769738, 1.0
        .float -0.40903756, 0.148100615, 0.49194926, 1.0
        .float -0.354539365, 0.11333251, 0.388577461, 1.0
        .float -0.321498901, 0.0993783474, 0.262478083, 1.0
        .float -0.345050991, 0.148100376, 0.398075491, 1.0
        .float -0.308821559, 0.113332033, 0.271213114, 1.0
        .float -0.396583796, 0.214133024, 0.500633717, 1.0
        .float -0.298296213, 0.148100615, 0.28238818, 1.0
        .float -0.330508411, 0.214133501, 0.413776726, 1.0
        .float -0.282211214, 0.214133024, 0.301500261, 1.0
        .float -0.38455829, 0.312343359, 0.516020834, 1.0
        .float -0.316306651, 0.312343597, 0.435342371, 1.0
        .float -0.266404033, 0.312343359, 0.325025231, 1.0
        .float -0.378771752, 0.438947439, 0.538908839, 1.0
        .float -0.309135556, 0.438946962, 0.460119873, 1.0
        .float -0.457437485, 0.43902564, 0.591141939, 1.0
        .float -0.461563796, 0.312419891, 0.568970561, 1.0
        .float -0.458016187, 0.580989361, 0.615553081, 1.0
        .float -0.378776789, 0.58091259, 0.56326586, 1.0
        .float -0.308692396, 0.580912113, 0.484056383, 1.0
        .float -0.258214504, 0.438947439, 0.347954482, 1.0
        .float -0.381430894, 0.725525618, 0.582960844, 1.0
        .float -0.460228592, 0.726350069, 0.636169672, 1.0
        .float -0.560290694, 0.58152914, 0.635315478, 1.0
        .float -0.562636554, 0.727237225, 0.656166017, 1.0
        .float -0.559762418, 0.880260468, 0.683218837, 1.0
        .float -0.456462085, 0.876687765, 0.659543037, 1.0
        .float -0.379069179, 0.870597124, 0.598296106, 1.0
        .float -0.311909527, 0.72480917, 0.502214909, 1.0
        .float -0.433312386, 1.0309844, 0.692482889, 1.0
        .float -0.359224945, 1.01194263, 0.610723138, 1.0
        .float -0.311652511, 0.86486578, 0.507523179, 1.0
        .float -0.296804756, 0.994804382, 0.495553464, 1.0
        .float -0.257442743, 0.58091259, 0.368361294, 1.0
        .float -0.261078805, 0.724291563, 0.38306585, 1.0
        .float -0.262411714, 0.860724688, 0.380793899, 1.0
        .float -0.251326561, 0.982396126, 0.353445053, 1.0
        .float -0.207793862, 1.07808256, 0.313709915, 1.0
        .float -0.244387358, 1.09866977, 0.474590689, 1.0
        .float -0.117636368, 1.13750768, 0.27890867, 1.0
        .float -0.138072699, 1.16150045, 0.455578983, 1.0
        .float 0.000000000, 1.15759921, 0.26409027, 1.0
        .float 0.117634386, 1.13750744, 0.2789087, 1.0
        .float 0.138070747, 1.16150022, 0.455579013, 1.0
        .float 0.000000000, 1.18197823, 0.447386473, 1.0
        .float -0.294746906, 1.12687993, 0.61985898, 1.0
        .float -0.166237965, 1.19388676, 0.625090122, 1.0
        .float -0.356640786, 1.16096807, 0.728065789, 1.0
        .float -0.198393553, 1.23134184, 0.751323223, 1.0
        .float 0.000000000, 1.21457791, 0.626716495, 1.0
        .float 0.166235968, 1.193887, 0.625090182, 1.0
        .float 0.198391587, 1.23134184, 0.751323164, 1.0
        .float 0.000000000, 1.25108337, 0.759141743, 1.0
        .float -0.464127511, 1.21805263, 0.801937938, 1.0
        .float -0.227511391, 1.28627825, 0.844900787, 1.0
        .float -0.540622592, 1.04448414, 0.728058994, 1.0
        .float -0.697047293, 1.03915453, 0.703245699, 1.0
        .float -0.68738246, 1.19636703, 0.756240308, 1.0
        .float -0.467004299, 1.35367632, 0.880517721, 1.0
        .float -0.235796556, 1.37184811, 0.925430119, 1.0
        .float -0.864111662, 1.1812923, 0.684648454, 1.0
        .float -0.683449507, 1.337152, 0.811811328, 1.0
        .float -0.701057136, 0.879448891, 0.662561119, 1.0
        .float -0.68201679, 1.47027779, 0.861313701, 1.0
        .float -0.465507239, 1.47551167, 0.941443026, 1.0
        .float -0.46609962, 1.60681021, 0.990525007, 1.0
        .float -0.467949033, 1.744789, 1.02316594, 1.0
        .float -0.235822454, 1.60740542, 1.05006635, 1.0
        .float -0.236982927, 1.744789, 1.086869, 1.0
        .float -0.237633631, 1.88388145, 1.10209572, 1.0
        .float  0.000000000, 1.74478912, 1.10858595, 1.0
        .float  0.000000000, 1.88388145, 1.12414134, 1.0
        .float -0.235440657, 1.48027408, 0.994558513, 1.0
        .float 0.000000000, 1.60766459, 1.07108212, 1.0
        .float 0.235820487, 1.60740542, 1.05006623, 1.0
        .float 0.23698096, 1.744789, 1.086869, 1.0
        .float 0.237631664, 1.88388145, 1.10209572, 1.0
        .float 0.000000000, 2.02297401, 1.12727094, 1.0
        .float 0.466097653, 1.60681021, 0.990525007, 1.0
        .float 0.467947096, 1.74478912, 1.02316594, 1.0
        .float 0.465505272, 1.47551155, 0.941443026, 1.0
        .float 0.23543869, 1.48027408, 0.994558573, 1.0
        .float 0.682531655, 1.60621309, 0.898907185, 1.0
        .float 0.682014763, 1.47027779, 0.861313641, 1.0
        .float 0.684269249, 1.74482584, 0.922229946, 1.0
        .float 0.469262242, 1.88388145, 1.03645682, 1.0
        .float 0.865538895, 1.46694195, 0.76263243, 1.0
        .float 0.865805209, 1.606197, 0.786421537, 1.0
        .float 0.865741968, 1.32631755, 0.726701081, 1.0
        .float 0.68344754, 1.33715224, 0.811811328, 1.0
        .float 1.00004637, 1.46697056, 0.648464859, 1.0
        .float 0.999857605, 1.32375669, 0.62863946, 1.0
        .float 1.00007689, 1.60708523, 0.659544647, 1.0
        .float 0.866870224, 1.74508476, 0.799139619, 1.0
        .float 1.09433591, 1.46806753, 0.498769283, 1.0
        .float 1.09402716, 1.3248837, 0.492497206, 1.0
        .float 1.09141541, 1.17840838, 0.478902519, 1.0
        .float 0.99708277, 1.17727566, 0.601020873, 1.0
        .float 1.15904129, 1.32492065, 0.299320161, 1.0
        .float 1.15475976, 1.17834544, 0.296821207, 1.0
        .float 1.16016722, 1.468099, 0.29846108, 1.0
        .float 1.09442794, 1.60791719, 0.501066804, 1.0
        .float 1.14589167, 1.02917075, 0.289434075, 1.0
        .float 1.08524323, 1.02960539, 0.456536859, 1.0
        .float 1.07956624, 0.881393909, 0.432291687, 1.0
        .float 1.13813233, 0.880436897, 0.279471338, 1.0
        .float 0.990171671, 1.02827024, 0.568530858, 1.0
        .float 0.983120799, 0.879733324, 0.538232327, 1.0
        .float 1.07790864, 0.736238718, 0.412751436, 1.0
        .float 0.979635715, 0.734238625, 0.515587449, 1.0
        .float 1.13645256, 0.734838724, 0.269435525, 1.0
        .float 1.0763526, 0.592839956, 0.394933164, 1.0
        .float 0.976710498, 0.590435028, 0.495513409, 1.0
        .float 0.848792613, 0.730585575, 0.587256253, 1.0
        .float 0.845037878, 0.586046457, 0.567389488, 1.0
        .float 0.970683694, 0.448879242, 0.47298032, 1.0
        .float 0.839757442, 0.444162846, 0.544356763, 1.0
        .float 1.07038212, 0.451897383, 0.375500888, 1.0
        .float 1.13579428, 0.59145546, 0.258745939, 1.0
        .float 0.833678484, 0.316723347, 0.524113655, 1.0
        .float 0.961985171, 0.321683645, 0.453714728, 1.0
        .float 0.693336368, 0.440993071, 0.59299314, 1.0
        .float 0.691160202, 0.313544035, 0.57166183, 1.0
        .float 0.828098178, 0.216671467, 0.513362408, 1.0
        .float 0.6913445, 0.213533163, 0.559582055, 1.0
        .float 1.06052804, 0.325884104, 0.359274, 1.0
        .float 0.952306449, 0.22192502, 0.443866879, 1.0
        .float 0.823962092, 0.149477243, 0.50937897, 1.0
        .float 0.69258076, 0.146387339, 0.554456353, 1.0
        .float 0.566110492, 0.212094545, 0.575857759, 1.0
        .float 0.572582126, 0.145007372, 0.569936991, 1.0
        .float 0.693299294, 0.11258769, 0.550641477, 1.0
        .float 0.576539576, 0.111244678, 0.565648198, 1.0
        .float 0.821327269, 0.115640879, 0.506327748, 1.0
        .float 0.944300473, 0.154998541, 0.440526724, 1.0
        .float 0.580305338, 0.098978281, 0.552853107, 1.0
        .float 0.693195581, 0.100276709, 0.538364112, 1.0
        .float 0.487801492, 0.110781908, 0.545410275, 1.0
        .float 0.494448423, 0.0985319614, 0.533087492, 1.0
        .float 0.481552362, 0.144528389, 0.549700618, 1.0
        .float 0.417657644, 0.110715628, 0.485875845, 1.0
        .float 0.426514894, 0.0984680653, 0.474474937, 1.0
        .float 0.409787178, 0.144459963, 0.491495162, 1.0
        .float 0.471422076, 0.211588621, 0.555752277, 1.0
        .float 0.355167061, 0.110715389, 0.387942404, 1.0
        .float 0.365967661, 0.0984685421, 0.377548814, 1.0
        .float 0.345925093, 0.144459724, 0.397191912, 1.0
        .float 0.397121996, 0.21151638, 0.500307381, 1.0
        .float 0.309515357, 0.110715628, 0.270420521, 1.0
        .float 0.321738929, 0.0984685421, 0.262202412, 1.0
        .float 0.299262255, 0.144459724, 0.281285465, 1.0
        .float 0.331136107, 0.211516857, 0.413141757, 1.0
        .float 0.461712629, 0.311509371, 0.568898618, 1.0
        .float 0.384744257, 0.311433554, 0.515907347, 1.0
        .float 0.316523671, 0.311433077, 0.435121477, 1.0
        .float 0.282904983, 0.21151638, 0.300707668, 1.0
        .float 0.457454354, 0.438911915, 0.591132998, 1.0
        .float 0.378793299, 0.438833475, 0.538894713, 1.0
        .float 0.309160918, 0.438833237, 0.460092306, 1.0
        .float 0.266644061, 0.311433554, 0.324749529, 1.0
        .float 0.258242756, 0.438833475, 0.347919971, 1.0
        .float 0.308690429, 0.580912113, 0.484056413, 1.0
        .float 0.257440776, 0.58091259, 0.368361264, 1.0
        .float 0.378774792, 0.58091259, 0.5632658, 1.0
        .float 0.31190756, 0.724809408, 0.502214849, 1.0
        .float 0.381428957, 0.725525379, 0.582960844, 1.0
        .float 0.261076868, 0.724291325, 0.38306585, 1.0
        .float 0.379067212, 0.870597124, 0.598296106, 1.0
        .float 0.311650574, 0.86486578, 0.507523179, 1.0
        .float 0.456460178, 0.876688004, 0.659543037, 1.0
        .float 0.460226625, 0.726350069, 0.636169672, 1.0
        .float 0.359222978, 1.01194263, 0.610723138, 1.0
        .float 0.296802819, 0.994804382, 0.495553404, 1.0
        .float 0.251324624, 0.982396364, 0.353445083, 1.0
        .float 0.262409747, 0.860724688, 0.38079384, 1.0
        .float 0.244385377, 1.09867024, 0.474590689, 1.0
        .float 0.207791865, 1.07808232, 0.313709915, 1.0
        .float 0.433310419, 1.0309844, 0.692482889, 1.0
        .float 0.294744968, 1.12687993, 0.619858921, 1.0
        .float 0.356638789, 1.16096807, 0.728065789, 1.0
        .float 0.540620565, 1.04448414, 0.728058934, 1.0
        .float 0.464125544, 1.21805263, 0.801937819, 1.0
        .float 0.227509424, 1.28627825, 0.844900727, 1.0
        .float 0.687380433, 1.19636703, 0.756240368, 1.0
        .float 0.467002362, 1.35367608, 0.880517721, 1.0
        .float 0.235794589, 1.37184811, 0.925430059, 1.0
        .float 0.000000000, 1.37910891, 0.941184759, 1.0
        .float 0.000000000, 1.30209231, 0.856904984, 1.0
        .float 0.000000000, 1.48234653, 1.01372111, 1.0
        .float 0.864109635, 1.1812923, 0.684648395, 1.0
        .float 0.697045386, 1.03915453, 0.703245699, 1.0
        .float 0.858941019, 1.03010154, 0.643900394, 1.0
        .float 0.559760332, 0.880260229, 0.683218896, 1.0
        .float 0.701055229, 0.879449129, 0.662561119, 1.0
        .float 0.562634528, 0.727236986, 0.656165957, 1.0
        .float 0.852925658, 0.878076553, 0.610414684, 1.0
        .float 0.700101912, 0.728342772, 0.636886477, 1.0
        .float 0.560288668, 0.58152914, 0.635315478, 1.0
        .float 0.45801422, 0.580989361, 0.615553021, 1.0
        .float 0.558620453, 0.439462185, 0.611047208, 1.0
        .float 0.696870029, 0.583019018, 0.616621256, 1.0
        .float 0.560297191, 0.312043667, 0.588882208, 1.0
        .float 0.817050099, 0.103245735, 0.495354891, 1.0
        .float 0.939172983, 0.121296644, 0.438047618, 1.0
        .float 0.931384027, 0.108887911, 0.428896815, 1.0
        .float 1.03909898, 0.162992001, 0.348658562, 1.0
        .float 1.03278041, 0.130350351, 0.34686777, 1.0
        .float 1.04892814, 0.228049994, 0.351209372, 1.0
        .float 1.09916317, 0.173091173, 0.232165098, 1.0
        .float 1.10889161, 0.234143972, 0.233129591, 1.0
        .float 1.09296286, 0.142754793, 0.231506169, 1.0
        .float 1.02322495, 0.118605614, 0.340266913, 1.0
        .float 1.12042248, 0.327868938, 0.237440467, 1.0
        .float 1.13023531, 0.451441288, 0.246981353, 1.0
        .float 1.08384883, 0.132636547, 0.228372872, 1.0
        .float 1.16079056, 1.60801148, 0.29656145, 1.0
        .float 1.16132951, 1.74626434, 0.295246065, 1.0
        .float 1.09438896, 1.74612939, 0.501997828, 1.0
        .float 1.00034034, 1.74565887, 0.664662778, 1.0
        .float 1.09386194, 1.88446689, 0.503524363, 1.0
        .float 1.00071025, 1.88426781, 0.667126179, 1.0
        .float 1.16155827, 1.88450563, 0.29557839, 1.0
        .float 1.092713, 2.02322197, 0.50576508, 1.0
        .float 1.00102699, 2.02316809, 0.668599546, 1.0
        .float 0.870497584, 2.02304268, 0.804491401, 1.0
        .float 0.868539393, 1.88401318, 0.803849578, 1.0
        .float 1.00176656, 2.1680305, 0.669948697, 1.0
        .float 0.87316525, 2.16792369, 0.804958522, 1.0
        .float 1.09136403, 2.16802979, 0.507738829, 1.0
        .float 1.1609112, 2.02307916, 0.297069103, 1.0
        .float 0.690477788, 2.16786957, 0.932768881, 1.0
        .float 0.687967896, 2.02298236, 0.932403684, 1.0
        .float 0.47138539, 2.16786146, 1.03942835, 1.0
        .float 0.470081657, 2.02297401, 1.03867435, 1.0
        .float 0.686142623, 1.88389778, 0.931279242, 1.0
        .float 0.238325536, 2.16786194, 1.10611916, 1.0
        .float 0.237855926, 2.02297401, 1.10501695, 1.0
        .float 0.000000000, 2.1678617, 1.12850773, 1.0
        .float -0.237857893, 2.02297401, 1.10501695, 1.0
        .float 1.15923297, 2.16769552, 0.298425585, 1.0
        .float -0.693176687, 0.101188421, 0.538422763, 1.0
        .float -0.821494699, 0.118263483, 0.506449163, 1.0
        .float -0.817109704, 0.104158163, 0.495397091, 1.0
        .float -0.939503312, 0.123907804, 0.438143462, 1.0
        .float -0.944759309, 0.158631325, 0.440660119, 1.0
        .float -0.952636898, 0.224536419, 0.443962723, 1.0
        .float -1.03966439, 0.166514874, 0.348755032, 1.0
        .float -1.04933512, 0.230582476, 0.351278722, 1.0
        .float -1.03318727, 0.132882357, 0.34693709, 1.0
        .float -0.931500256, 0.109796762, 0.428930163, 1.0
        .float -1.0997225, 0.176378727, 0.232189178, 1.0
        .float -1.10929406, 0.236507416, 0.233146906, 1.0
        .float -1.06067097, 0.32676506, 0.35929811, 1.0
        .float -1.12056363, 0.328691244, 0.237446487, 1.0
        .float -1.09336543, 0.145117283, 0.231523484, 1.0
        .float -1.0839901, 0.133458376, 0.228378892, 1.0
        .float -1.02336776, 0.11948657, 0.340291023, 1.0
        .float -1.13025463, 0.451544285, 0.246982098, 1.0
        .float -1.13579619, 0.59145546, 0.258745909, 1.0
        .float -1.07040179, 0.452007532, 0.375503868, 1.0
        .float -1.13645446, 0.734838724, 0.269435525, 1.0
        .float -1.16079235, 1.60801172, 0.29656148, 1.0
        .float -1.16133142, 1.74626434, 0.295246065, 1.0
        .float -1.16156006, 1.88450563, 0.295578361, 1.0
        .float -1.09386384, 1.88446701, 0.503524423, 1.0
        .float -1.09271491, 2.02322197, 0.50576508, 1.0
        .float -1.16091323, 2.02307916, 0.297069132, 1.0
        .float -1.00176871, 2.16803026, 0.669948697, 1.0
        .float -1.09136593, 2.16802979, 0.507738888, 1.0
        .float -1.0059824, 2.34750319, 0.670489311, 1.0
        .float -1.09223473, 2.34736657, 0.505909204, 1.0
        .float -1.15923488, 2.16769552, 0.298425585, 1.0
        .float -1.15835154, 2.34683847, 0.296694994, 1.0
        .float -1.01473379, 2.58441877, 0.669554114, 1.0
        .float -1.09607887, 2.58387256, 0.497814298, 1.0
        .float -0.892533004, 2.58490229, 0.815299511, 1.0
        .float -0.720787704, 2.85743737, 0.955654442, 1.0
        .float -0.900960743, 2.85680294, 0.823586106, 1.0
        .float -1.01856184, 2.85536575, 0.668094158, 1.0
        .float -1.0950166, 2.85400629, 0.487846553, 1.0
        .float -1.15885174, 2.58314323, 0.28989777, 1.0
        .float -1.00798464, 3.12906075, 0.666327417, 1.0
        .float -0.895482361, 3.13188601, 0.828338861, 1.0
        .float -0.7217471, 3.13311768, 0.961580753, 1.0
        .float -0.877033293, 3.39282203, 0.823151529, 1.0
        .float -0.712169886, 3.39433002, 0.955247998, 1.0
        .float -1.08103049, 3.12659264, 0.480429888, 1.0
        .float -0.983959377, 3.38897824, 0.659918964, 1.0
        .float -0.848810911, 3.62645102, 0.803108215, 1.0
        .float -0.693602562, 3.62805295, 0.930085719, 1.0
        .float -0.499683291, 3.39474177, 1.05196559, 1.0
        .float -0.490444422, 3.62955141, 1.02250338, 1.0
        .float -0.475743473, 3.83397722, 0.970062673, 1.0
        .float -0.668392658, 3.82689118, 0.886916816, 1.0
        .float -0.949138939, 3.62282038, 0.644906878, 1.0
        .float -0.812296689, 3.82228494, 0.771057904, 1.0
        .float -0.640006125, 3.98520684, 0.826033294, 1.0
        .float -0.458816081, 4.00562048, 0.892460048, 1.0
        .float -0.247146741, 3.84271765, 1.02075136, 1.0
        .float -0.239193007, 4.02286625, 0.934120476, 1.0
        .float -0.445498675, 4.13908768, 0.781221986, 1.0
        .float -0.232512832, 4.16649008, 0.812008798, 1.0
        .float -0.767882764, 3.97098994, 0.731230795, 1.0
        .float -0.618322372, 4.09932184, 0.736606658, 1.0
        .float -0.441042632, 4.23230505, 0.630700052, 1.0
        .float -0.229528859, 4.26947927, 0.651167095, 1.0
        .float 0.000000000, 4.17661047, 0.823414981, 1.0
        .float 0.000000000, 4.28232479, 0.659216166, 1.0
        .float 0.000000000, 4.35976887, 0.469665945, 1.0
        .float -0.230966553, 4.34468365, 0.464705497, 1.0
        .float -0.617862523, 4.17248487, 0.604811907, 1.0
        .float -0.445759207, 4.29948235, 0.452833414, 1.0
        .float -0.236477196, 4.40283108, 0.266927689, 1.0
        .float 0.000000000, 4.41938353, 0.269314706, 1.0
        .float 0.230964601, 4.34468365, 0.464705497, 1.0
        .float 0.229526907, 4.26947927, 0.651167095, 1.0
        .float 0.236475259, 4.40283155, 0.266927689, 1.0
        .float -0.457687616, 4.3523612, 0.26145342, 1.0
        .float 0.44575724, 4.29948235, 0.452833414, 1.0
        .float 0.45768562, 4.3523612, 0.26145342, 1.0
        .float 0.650043845, 4.26771402, 0.255587935, 1.0
        .float 0.630086243, 4.22450686, 0.439302474, 1.0
        .float 0.617860496, 4.17248487, 0.604811847, 1.0
        .float 0.441040665, 4.23230505, 0.630700052, 1.0
        .float 0.750375867, 4.0889492, 0.588904798, 1.0
        .float 0.777189672, 4.12113523, 0.432319641, 1.0
        .float 0.721854866, 4.05963707, 0.692011893, 1.0
        .float 0.618320346, 4.09932184, 0.736606598, 1.0
        .float 0.445496738, 4.13908768, 0.781222045, 1.0
        .float 0.767880797, 3.97098994, 0.731230736, 1.0
        .float 0.640004039, 3.98520708, 0.826033354, 1.0
        .float 0.840319812, 3.97466016, 0.6003142, 1.0
        .float 0.902516186, 3.82044077, 0.623377204, 1.0
        .float 0.812294662, 3.82228494, 0.771057963, 1.0
        .float 0.668390632, 3.82689118, 0.886916757, 1.0
        .float 0.458814144, 4.00562048, 0.892459989, 1.0
        .float 0.949136913, 3.62282038, 0.644906878, 1.0
        .float 0.848808825, 3.62645102, 0.803108215, 1.0
        .float 0.960954607, 3.82453132, 0.450639576, 1.0
        .float 1.01544499, 3.62157059, 0.463216126, 1.0
        .float 0.693600595, 3.62805295, 0.930085599, 1.0
        .float 0.475741476, 3.83397722, 0.970062673, 1.0
        .float 0.490442485, 3.62955141, 1.0225035, 1.0
        .float 0.253738701, 3.63308525, 1.07843184, 1.0
        .float 0.247144759, 3.84271765, 1.02075136, 1.0
        .float 0.239191055, 4.02286625, 0.934120476, 1.0
        .float 0.000000000, 3.84722161, 1.03794885, 1.0
        .float 0.000000000, 4.03010273, 0.94874984, 1.0
        .float 0.232510865, 4.16649008, 0.812008798, 1.0
        .float -0.253740728, 3.63308525, 1.07843173, 1.0
        .float -0.257196486, 3.39576983, 1.11045814, 1.0
        .float 0.000000000, 3.63531089, 1.0971638, 1.0
        .float -0.501478553, 3.13331819, 1.06059921, 1.0
        .float 1.06892431, 3.62558341, 0.266079545, 1.0
        .float 1.0094384, 3.83503437, 0.260560811, 1.0
        .float 0.884782016, 3.98960304, 0.437937707, 1.0
        .float 0.924585938, 4.00954342, 0.255123109, 1.0
        .float 0.80668205, 4.15248346, 0.252692014, 1.0
        .float -0.63008827, 4.22450686, 0.439302504, 1.0
        .float -0.650045693, 4.26771402, 0.255587935, 1.0
        .float -0.777191639, 4.12113523, 0.432319611, 1.0
        .float -0.806684017, 4.15248346, 0.252692014, 1.0
        .float -0.750377893, 4.0889492, 0.588904738, 1.0
        .float -0.924587905, 4.00954294, 0.255123079, 1.0
        .float -0.884784102, 3.98960304, 0.437937737, 1.0
        .float -1.0094403, 3.83503437, 0.260560811, 1.0
        .float -0.960956633, 3.82453132, 0.450639606, 1.0
        .float -0.840321839, 3.97466016, 0.6003142, 1.0
        .float -1.06892622, 3.62558341, 0.266079545, 1.0
        .float -1.01544702, 3.62157059, 0.463216096, 1.0
        .float -0.902518213, 3.82044077, 0.623377144, 1.0
        .float -0.721856952, 4.05963707, 0.692011893, 1.0
        .float -1.05420029, 3.38610721, 0.473259985, 1.0
        .float -1.13836277, 3.12568903, 0.275614798, 1.0
        .float -1.11004543, 3.38648582, 0.271010876, 1.0
        .float -1.15439129, 2.85307884, 0.281608164, 1.0
        .float 0.332663029, 0.0967116356, 0.139908314, 1.0
        .float 0.348315924, 0.0968618393, 0.24811241, 1.0
        .float 0.345482439, 0.0968618393, 0.0160336569, 1.0
        .float 0.402222961, 0.111152411, 0.0253112465, 1.0
        .float 0.388594806, 0.10994935, 0.129374728, 1.0
        .float 0.404587299, 0.111152411, 0.219047159, 1.0
        .float 0.388939142, 0.0967116356, 0.355713755, 1.0
        .float 0.44535476, 0.0968616009, 0.44576171, 1.0
        .float 0.435890287, 0.10994935, 0.310842425, 1.0
        .float 0.485167891, 0.111152411, 0.383358985, 1.0
        .float 0.508096635, 0.0967707634, 0.500853956, 1.0
        .float 0.500580192, 0.136240482, 0.248685658, 1.0
        .float 0.536069214, 0.109999657, 0.432955384, 1.0
        .float 0.554292023, 0.145619869, 0.274114877, 1.0
        .float 0.575018227, 0.13628912, 0.338716507, 1.0
        .float 0.587839425, 0.0973351002, 0.518714547, 1.0
        .float 0.60415417, 0.111553192, 0.444263875, 1.0
        .float 0.633575559, 0.14593792, 0.314338893, 1.0
        .float 0.683759809, 0.190214396, 0.073980093, 1.0
        .float 0.622494996, 0.145756245, -0.167715251, 1.0
        .float 0.669814765, 0.13739109, -0.204310924, 1.0
        .float 0.73648417, 0.152618647, -0.157467753, 1.0
        .float 0.549404562, 0.14561367, -0.108357258, 1.0
        .float 0.567454219, 0.136240482, -0.184334368, 1.0
        .float 0.857968509, 0.158528328, 0.207875341, 1.0
        .float 0.827256083, 0.142806768, 0.279018581, 1.0
        .float 0.751165569, 0.14829421, 0.285952598, 1.0
        .float 0.872361243, 0.175389767, -0.0806618258, 1.0
        .float 0.941357911, 0.176929712, -0.0154126585, 1.0
        .float 0.912618279, 0.177991867, 0.0802921504, 1.0
        .float 0.500930309, 0.14561367, 0.0396963432, 1.0
        .float 0.496855527, 0.136240005, -0.0551962703, 1.0
        .float 0.689801514, 0.137340069, 0.342153192, 1.0
        .float 0.925456285, 0.162801981, 0.164524883, 1.0
        .float 0.502501726, 0.14561367, 0.168287203, 1.0
        .float 0.827821255, 0.157034159, -0.16192171, 1.0
        .float 0.465877891, 0.136240482, 0.113980979, 1.0
        .float 0.692326665, 0.0983879566, 0.505811632, 1.0
        .float 0.69093281, 0.11136055, 0.437143981, 1.0
        .float 0.806999981, 0.101293564, 0.465450764, 1.0
        .float 0.786295891, 0.114868879, 0.400002152, 1.0
        .float 0.913478255, 0.106575012, 0.404222757, 1.0
        .float 0.877083361, 0.118411303, 0.351785004, 1.0
        .float 1.00036824, 0.117043257, 0.322006762, 1.0
        .float 0.949364543, 0.129337072, 0.280937135, 1.0
        .float 1.06137419, 0.132790327, 0.21925202, 1.0
        .float 1.00723779, 0.144012928, 0.197436213, 1.0
        .float 1.09157634, 0.147619486, 0.0877533555, 1.0
        .float 1.03146172, 0.158828259, 0.086716637, 1.0
        .float 1.08763158, 0.15356493, -0.0707127526, 1.0
        .float 1.02953994, 0.162923336, -0.0466685444, 1.0
        .float 1.03051901, 0.146804333, -0.214341372, 1.0
        .float 0.974393368, 0.155953169, -0.165575027, 1.0
        .float 0.91400373, 0.126998901, -0.304845989, 1.0
        .float 0.87780118, 0.137102127, -0.244744033, 1.0
        .float 0.776124239, 0.106993437, -0.350624502, 1.0
        .float 0.761101604, 0.12028718, -0.279708683, 1.0
        .float 0.65943867, 0.0979781151, -0.371975541, 1.0
        .float 0.663325965, 0.111091375, -0.30095318, 1.0
        .float 0.568183005, 0.0968616009, -0.369812965, 1.0
        .float 0.587674081, 0.111152411, -0.295556307, 1.0
        .float 0.496244818, 0.0967116356, -0.341342032, 1.0
        .float 0.526099741, 0.10994935, -0.275152236, 1.0
        .float 0.436488301, 0.0968616009, -0.265177816, 1.0
        .float 0.477792531, 0.111152411, -0.207900107, 1.0
        .float 0.38295725, 0.0967116356, -0.132852793, 1.0
        .float 0.430863112, 0.10994935, -0.0998682752, 1.0
        .float -0.348287672, 0.096975565, 0.248146862, 1.0
        .float -0.332633525, 0.0968251228, 0.139930293, 1.0
        .float -0.404589266, 0.111152411, 0.219047159, 1.0
        .float -0.388596803, 0.109949589, 0.129374728, 1.0
        .float -0.388913721, 0.0968251228, 0.355741382, 1.0
        .float -0.402224928, 0.111152411, 0.0253112465, 1.0
        .float -0.34545359, 0.096975565, 0.0160373487, 1.0
        .float -0.382931083, 0.0968251228, -0.1328578, 1.0
        .float -0.430865109, 0.109949589, -0.0998682752, 1.0
        .float -0.477794498, 0.111152411, -0.207900107, 1.0
        .float -0.436466008, 0.096975565, -0.265184969, 1.0
        .float -0.496857494, 0.136240482, -0.0551962554, 1.0
        .float -0.526101768, 0.109949589, -0.275152296, 1.0
        .float -0.549406588, 0.14561367, -0.108357258, 1.0
        .float -0.567456245, 0.136240482, -0.184334338, 1.0
        .float -0.496226966, 0.0968251228, -0.341351092, 1.0
        .float -0.587676108, 0.111152411, -0.295556307, 1.0
        .float -0.683761835, 0.190214634, 0.073980093, 1.0
        .float -0.622497022, 0.145756245, -0.167715251, 1.0
        .float -0.736486256, 0.152618885, -0.157467753, 1.0
        .float -0.669816852, 0.13739109, -0.204310924, 1.0
        .float -0.751167595, 0.148294449, 0.285952568, 1.0
        .float -0.82725805, 0.14280653, 0.279018581, 1.0
        .float -0.857970536, 0.158528566, 0.207875341, 1.0
        .float -0.912620246, 0.177992105, 0.0802921504, 1.0
        .float -0.941359878, 0.176929712, -0.015412651, 1.0
        .float -0.872363269, 0.175390005, -0.0806618407, 1.0
        .float -0.500932276, 0.14561367, 0.0396963432, 1.0
        .float -0.633577585, 0.145938158, 0.314338923, 1.0
        .float -0.689803481, 0.137340069, 0.342153162, 1.0
        .float -0.925458252, 0.162801981, 0.164524868, 1.0
        .float -0.502503753, 0.14561367, 0.168287188, 1.0
        .float -0.500582218, 0.136240482, 0.248685658, 1.0
        .float -0.55429405, 0.145619631, 0.274114877, 1.0
        .float -0.575020254, 0.136289597, 0.338716477, 1.0
        .float -0.827823162, 0.157034397, -0.16192168, 1.0
        .float -0.465879828, 0.136240482, 0.113980979, 1.0
        .float -0.435892224, 0.109949589, 0.310842425, 1.0
        .float -0.445333272, 0.096975565, 0.445775926, 1.0
        .float -0.485169828, 0.111152411, 0.383359015, 1.0
        .float -0.508079827, 0.0968842506, 0.500862956, 1.0
        .float -0.536071241, 0.109999657, 0.432955414, 1.0
        .float -0.587829292, 0.0974488258, 0.518723309, 1.0
        .float -0.604156256, 0.111553431, 0.444263905, 1.0
        .float -0.692326069, 0.0985021591, 0.505818963, 1.0
        .float -0.690934837, 0.11136055, 0.437143952, 1.0
        .float -0.807009101, 0.101407528, 0.465456009, 1.0
        .float -0.786297858, 0.114868641, 0.400002152, 1.0
        .float -0.913494587, 0.106688499, 0.404226929, 1.0
        .float -0.877085328, 0.118411541, 0.351784974, 1.0
        .float -1.00038767, 0.117153168, 0.322009772, 1.0
        .float -0.949366689, 0.129336834, 0.280937165, 1.0
        .float -1.06139338, 0.132892847, 0.219252795, 1.0
        .float -1.00723958, 0.144013166, 0.197436243, 1.0
        .float -1.09159493, 0.147717476, 0.0877519101, 1.0
        .float -1.03146362, 0.158828259, 0.0867166296, 1.0
        .float -1.08765185, 0.153666019, -0.0707151964, 1.0
        .float -1.02954185, 0.162923098, -0.0466685221, 1.0
        .float -1.03053808, 0.146911621, -0.214345038, 1.0
        .float -0.974395454, 0.155953407, -0.165575027, 1.0
        .float -0.914016068, 0.127110481, -0.304852307, 1.0
        .float -0.877803206, 0.137102604, -0.244744033, 1.0
        .float -0.776126921, 0.107106686, -0.35063374, 1.0
        .float -0.761103511, 0.12028718, -0.279708683, 1.0
        .float -0.659432888, 0.0980918407, -0.37198621, 1.0
        .float -0.663327992, 0.111091375, -0.30095315, 1.0
        .float -0.568170488, 0.096975565, -0.369823575, 1.0
        .float -0.492449492, 2.78501678, 1.21468663, 1.0
        .float -0.322931051, 2.75816774, 1.21468663, 1.0
        .float -0.322403222, 2.76487446, 1.29285693, 1.0
        .float -0.49035117, 2.79147482, 1.29285693, 1.0
        .float -0.636079669, 2.85820007, 1.21468663, 1.0
        .float 0.360909283, 2.75816774, 1.21468663, 1.0
        .float 0.360381454, 2.76487446, 1.29285693, 1.0
        .float -0.482839555, 2.81459308, 1.36674845, 1.0
        .float -0.320513695, 2.78888321, 1.36674845, 1.0
        .float -0.632088423, 2.86369348, 1.29285693, 1.0
        .float -0.617800474, 2.88335919, 1.36674845, 1.0
        .float -0.750065207, 2.97218561, 1.21468663, 1.0
        .float -0.744571745, 2.97617698, 1.29285693, 1.0
        .float -0.724906087, 2.99046493, 1.36674845, 1.0
        .float -0.569945097, 2.94922662, 1.42517281, 1.0
        .float -0.659038663, 3.0383203, 1.42517281, 1.0
        .float -0.716240287, 3.1505847, 1.42517281, 1.0
        .float -0.793672025, 3.12542582, 1.36674845, 1.0
        .float -0.823248386, 3.11581588, 1.21468663, 1.0
        .float -0.816790402, 3.1179142, 1.29285693, 1.0
        .float -0.738967717, 3.29408026, 1.42517281, 1.0
        .float -0.819381952, 3.28775167, 1.36674845, 1.0
        .float -0.618330419, 3.0678966, 1.43304431, 1.0
        .float -0.66838485, 3.16613388, 1.43304431, 1.0
        .float -0.689269066, 3.29799175, 1.43304431, 1.0
        .float -0.716240406, 3.44548965, 1.42517281, 1.0
        .float -0.843390763, 3.28586197, 1.29285693, 1.0
        .float -0.793672204, 3.47064877, 1.36674845, 1.0
        .float -0.66838491, 3.42994046, 1.43304431, 1.0
        .float -0.659038663, 3.55775428, 1.42517281, 1.0
        .float -0.724906087, 3.60560966, 1.36674845, 1.0
        .float -0.816790521, 3.47816038, 1.29285693, 1.0
        .float -0.850097477, 3.28533411, 1.21468663, 1.0
        .float -0.823248446, 3.4802587, 1.21468663, 1.0
        .float -0.750065207, 3.62388873, 1.21468663, 1.0
        .float -0.744571745, 3.6198976, 1.29285693, 1.0
        .float -0.636079669, 3.73787451, 1.21468663, 1.0
        .float -0.632088423, 3.73238087, 1.29285693, 1.0
        .float -0.617800534, 3.71271515, 1.36674845, 1.0
        .float -0.492449492, 3.81105757, 1.21468663, 1.0
        .float -0.49035117, 3.80459976, 1.29285693, 1.0
        .float -0.482839555, 3.78148127, 1.36674845, 1.0
        .float -0.457680434, 3.70404959, 1.42517281, 1.0
        .float -0.569945097, 3.64684772, 1.42517281, 1.0
        .float -0.314184994, 3.72677708, 1.42517281, 1.0
        .float -0.320513695, 3.80719113, 1.36674845, 1.0
        .float -0.442131251, 3.65619421, 1.43304431, 1.0
        .float -0.540368795, 3.60613966, 1.43304431, 1.0
        .float -0.618330359, 3.52817798, 1.43304431, 1.0
        .float -0.310273647, 3.67707825, 1.43304431, 1.0
        .float 0.352163255, 3.72677708, 1.42517281, 1.0
        .float 0.348251909, 3.67707825, 1.43304431, 1.0
        .float 0.495658666, 3.70404959, 1.42517281, 1.0
        .float 0.358491927, 3.80719113, 1.36674845, 1.0
        .float 0.480109453, 3.65619421, 1.43304431, 1.0
        .float 0.520817757, 3.78148127, 1.36674845, 1.0
        .float 0.607923269, 3.64684796, 1.42517281, 1.0
        .float 0.360381454, 3.83119988, 1.29285693, 1.0
        .float -0.322403222, 3.83119988, 1.29285693, 1.0
        .float 0.528329372, 3.80459976, 1.29285693, 1.0
        .float 0.655778706, 3.71271539, 1.36674845, 1.0
        .float 0.578346968, 3.60613966, 1.43304431, 1.0
        .float 0.697016835, 3.55775428, 1.42517281, 1.0
        .float 0.670066595, 3.73238087, 1.29285693, 1.0
        .float 0.762884259, 3.60560966, 1.36674845, 1.0
        .float 0.674057841, 3.73787451, 1.21468663, 1.0
        .float 0.530427694, 3.81105757, 1.21468663, 1.0
        .float 0.78804338, 3.62388873, 1.21468663, 1.0
        .float 0.782549918, 3.6198976, 1.29285693, 1.0
        .float 0.754218578, 3.44548965, 1.42517281, 1.0
        .float 0.831650376, 3.47064877, 1.36674845, 1.0
        .float 0.861226618, 3.4802587, 1.21468663, 1.0
        .float 0.854768693, 3.47816038, 1.29285693, 1.0
        .float 0.776945889, 3.30199432, 1.42517281, 1.0
        .float 0.857360125, 3.30832291, 1.36674845, 1.0
        .float 0.656308532, 3.52817798, 1.43304431, 1.0
        .float 0.706363082, 3.42994046, 1.43304431, 1.0
        .float 0.727247238, 3.29808283, 1.43304431, 1.0
        .float 0.754218459, 3.1505847, 1.42517281, 1.0
        .float 0.831650198, 3.12542582, 1.36674845, 1.0
        .float 0.881368935, 3.31021237, 1.29285693, 1.0
        .float 0.706363022, 3.16613388, 1.43304431, 1.0
        .float 0.697016835, 3.0383203, 1.42517281, 1.0
        .float 0.762884259, 2.99046493, 1.36674845, 1.0
        .float 0.854768574, 3.1179142, 1.29285693, 1.0
        .float 0.88807565, 3.31074023, 1.21468663, 1.0
        .float 0.861226559, 3.11581588, 1.21468663, 1.0
        .float 0.78804338, 2.97218561, 1.21468663, 1.0
        .float 0.782549918, 2.97617698, 1.29285693, 1.0
        .float 0.674057841, 2.85820007, 1.21468663, 1.0
        .float 0.670066595, 2.86369348, 1.29285693, 1.0
        .float 0.655778646, 2.88335919, 1.36674845, 1.0
        .float 0.530427694, 2.78501678, 1.21468663, 1.0
        .float 0.528329372, 2.79147482, 1.29285693, 1.0
        .float 0.520817757, 2.81459308, 1.36674845, 1.0
        .float 0.495658696, 2.89202499, 1.42517281, 1.0
        .float 0.60792321, 2.94922662, 1.42517281, 1.0
        .float 0.358491927, 2.78888321, 1.36674845, 1.0
        .float 0.352163225, 2.8692975, 1.42517281, 1.0
        .float 0.480109483, 2.93988037, 1.43304431, 1.0
        .float 0.578346908, 2.98993492, 1.43304431, 1.0
        .float 0.656308591, 3.0678966, 1.43304431, 1.0
        .float 0.348251879, 2.91899633, 1.43304431, 1.0
        .float -0.314185023, 2.8692975, 1.42517281, 1.0
        .float -0.310273677, 2.91899633, 1.43304431, 1.0
        .float -0.457680434, 2.89202499, 1.42517281, 1.0
        .float -0.442131221, 2.93988037, 1.43304431, 1.0
        .float -0.540368795, 2.98993492, 1.43304431, 1.0
        .float 0.360909283, 3.8379066, 1.21468663, 1.0
        .float -0.322931051, 3.8379066, 1.21468663, 1.0
        .float 0.571386397, 3.93711567, 0.647064269, 1.0
        .float 0.571386397, 3.93711567, 1.13565028, 1.0
        .float 0.751966, 3.84510565, 1.13565028, 1.0
        .float 0.751966, 3.84510565, 0.647064269, 1.0
        .float 0.371212393, 3.9688201, 0.647064269, 1.0
        .float 0.371212393, 3.9688201, 1.13565028, 1.0
        .float 0.369389236, 3.94565439, 1.19153738, 1.0
        .float 0.564132214, 3.91478968, 1.19153738, 1.0
        .float 0.895274758, 3.70179701, 1.13565028, 1.0
        .float 0.738153696, 3.82609487, 1.19153738, 1.0
        .float 0.895274758, 3.70179701, 0.647064269, 1.0
        .float 0.98728466, 3.52121735, 1.13565028, 1.0
        .float 0.876240611, 3.68796778, 1.19153738, 1.0
        .float 0.546618998, 3.86088943, 1.21468663, 1.0
        .float 0.704807997, 3.78019834, 1.21468663, 1.0
        .float 0.364987701, 3.88972783, 1.21468663, 1.0
        .float 0.830288351, 3.65458155, 1.21468663, 1.0
        .float 0.910772443, 3.49635696, 1.21468663, 1.0
        .float 0.964874744, 3.51393604, 1.19153738, 1.0
        .float 0.939375401, 3.31477761, 1.21468663, 1.0
        .float 0.995670795, 3.31920815, 1.19153738, 1.0
        .float 1.01898921, 3.32104349, 1.13565028, 1.0
        .float 0.965088367, 3.08206916, 1.19153738, 1.0
        .float 0.98728466, 3.074857, 1.13565028, 1.0
        .float 1.01898921, 3.32104349, 0.647064269, 1.0
        .float 0.98728466, 3.52121735, 0.647064269, 1.0
        .float 0.98728466, 3.074857, 0.647064269, 1.0
        .float 0.895274758, 2.89427757, 1.13565028, 1.0
        .float 0.895274758, 2.89427757, 0.647064269, 1.0
        .float 0.751966, 2.75096869, 1.13565028, 1.0
        .float 0.87636888, 2.90801334, 1.19153738, 1.0
        .float 0.751966, 2.75096869, 0.647064269, 1.0
        .float 0.571386397, 2.65895891, 1.13565028, 1.0
        .float 0.738215387, 2.7698946, 1.19153738, 1.0
        .float 0.830726027, 2.94117498, 1.21468663, 1.0
        .float 0.911501944, 3.09948039, 1.21468663, 1.0
        .float 0.70501852, 2.81558633, 1.21468663, 1.0
        .float 0.564150691, 2.68122816, 1.19153738, 1.0
        .float 0.54668206, 2.73499107, 1.21468663, 1.0
        .float 0.364992857, 2.70628119, 1.21468663, 1.0
        .float 0.369390726, 2.65040088, 1.19153738, 1.0
        .float -0.327009469, 2.70634675, 1.21468663, 1.0
        .float -0.331411004, 2.65041995, 1.19153738, 1.0
        .float 0.371212393, 2.62725449, 1.13565028, 1.0
        .float -0.333234161, 2.62725449, 1.13565028, 1.0
        .float -0.526154041, 2.6812849, 1.19153738, 1.0
        .float -0.533408225, 2.65895891, 1.13565028, 1.0
        .float 0.371212393, 2.62725449, 0.647064269, 1.0
        .float -0.333234161, 2.62725449, 0.647064269, 1.0
        .float 0.571386397, 2.65895891, 0.647064269, 1.0
        .float -0.533408225, 2.65895891, 0.647064269, 1.0
        .float -0.713987827, 2.75096869, 1.13565028, 1.0
        .float -0.713987827, 2.75096869, 0.647064269, 1.0
        .float -0.857296586, 2.89427757, 1.13565028, 1.0
        .float -0.700175583, 2.76997972, 1.19153738, 1.0
        .float -0.857296586, 2.89427757, 0.647064269, 1.0
        .float -0.949306488, 3.074857, 1.13565028, 1.0
        .float -0.838262439, 2.90810657, 1.19153738, 1.0
        .float -0.508640826, 2.73518515, 1.21468663, 1.0
        .float -0.666829824, 2.81587601, 1.21468663, 1.0
        .float -0.792310178, 2.9414928, 1.21468663, 1.0
        .float -0.926896572, 3.08213854, 1.19153738, 1.0
        .float -0.872794271, 3.09971738, 1.21468663, 1.0
        .float -0.957692623, 3.2768662, 1.19153738, 1.0
        .float -0.981010914, 3.27503109, 1.13565028, 1.0
        .float -0.901397228, 3.28129673, 1.21468663, 1.0
        .float -0.927110195, 3.51400542, 1.19153738, 1.0
        .float -0.949306488, 3.52121735, 1.13565028, 1.0
        .float -0.949306488, 3.074857, 0.647064269, 1.0
        .float -0.981010914, 3.27503109, 0.647064269, 1.0
        .float -0.949306488, 3.52121735, 0.647064269, 1.0
        .float -0.857296586, 3.70179701, 1.13565028, 1.0
        .float -0.857296586, 3.70179701, 0.647064269, 1.0
        .float -0.713987827, 3.84510565, 1.13565028, 1.0
        .float -0.838390708, 3.688061, 1.19153738, 1.0
        .float -0.713987827, 3.84510565, 0.647064269, 1.0
        .float -0.533408225, 3.93711567, 1.13565028, 1.0
        .float -0.700237215, 3.82617974, 1.19153738, 1.0
        .float -0.792747855, 3.6548996, 1.21468663, 1.0
        .float -0.873523772, 3.49659419, 1.21468663, 1.0
        .float -0.667040348, 3.78048801, 1.21468663, 1.0
        .float -0.526172519, 3.91484642, 1.19153738, 1.0
        .float -0.508703887, 3.86108351, 1.21468663, 1.0
        .float -0.327014625, 3.88979316, 1.21468663, 1.0
        .float -0.331412494, 3.94567347, 1.19153738, 1.0
        .float -0.333234161, 3.9688201, 1.13565028, 1.0
        .float -0.333234161, 3.9688201, 0.647064269, 1.0
        .float -0.533408225, 3.93711567, 0.647064269, 1.0
        .float 0.609294295, 3.6491704, -1.32206047, 1.0
        .float 0.609294295, 3.56792068, -1.4033103, 1.0
        .float -0.571316123, 3.56792068, -1.4033103, 1.0
        .float -0.571316123, 3.6491704, -1.32206047, 1.0
        .float -0.571316123, 3.67891002, -1.21107113, 1.0
        .float 0.609294295, 3.67891002, -1.21107113, 1.0
        .float 0.685548007, 3.63085175, -1.3114841, 1.0
        .float 0.685548007, 3.5573442, -1.38499129, 1.0
        .float -0.647569835, 3.63085175, -1.3114841, 1.0
        .float -0.647569835, 3.5573442, -1.38499129, 1.0
        .float -0.703391433, 3.58080339, -1.28258872, 1.0
        .float -0.647569835, 3.65847802, -1.20838118, 1.0
        .float -0.703391433, 3.52844882, -1.33494306, 1.0
        .float -0.703391433, 3.44689226, -1.35679615, 1.0
        .float -0.647569835, 3.45424128, -1.41261768, 1.0
        .float -0.723823547, 3.48897696, -1.26657581, 1.0
        .float -0.723823547, 3.43685341, -1.28054237, 1.0
        .float -0.723823547, 1.5636282, -1.28054237, 1.0
        .float -0.703391433, 1.55358922, -1.35679615, 1.0
        .float -0.571316123, 3.45693135, -1.4330498, 1.0
        .float -0.647569835, 1.54624021, -1.41261768, 1.0
        .float 0.609294295, 3.45693135, -1.4330498, 1.0
        .float -0.571316123, 1.54355025, -1.4330498, 1.0
        .float 0.609294295, 1.54355025, -1.4330498, 1.0
        .float -0.703391433, 1.47203279, -1.33494306, 1.0
        .float -0.647569835, 1.44313741, -1.38499129, 1.0
        .float -0.571316123, 1.43256092, -1.4033103, 1.0
        .float 0.609294295, 1.43256092, -1.4033103, 1.0
        .float 0.685548007, 1.44313741, -1.38499129, 1.0
        .float 0.685548007, 1.54624021, -1.41261768, 1.0
        .float -0.647569835, 1.36962986, -1.3114841, 1.0
        .float -0.571316123, 1.35131121, -1.32206047, 1.0
        .float 0.609294295, 1.35131121, -1.32206047, 1.0
        .float -0.703391433, 1.41967821, -1.28258872, 1.0
        .float -0.703391433, 1.39782524, -1.20103216, 1.0
        .float -0.647569835, 1.34200358, -1.20838118, 1.0
        .float -0.571316123, 1.32157159, -1.21107113, 1.0
        .float -0.703391433, 1.39782524, -0.546844006, 1.0
        .float -0.647569835, 1.34200358, -0.546844006, 1.0
        .float -0.723823547, 1.47407901, -1.19099319, 1.0
        .float -0.723823547, 1.47407901, -0.546844006, 1.0
        .float -0.723823547, 1.48804545, -1.24311686, 1.0
        .float -0.723823547, 3.52640247, -0.546844006, 1.0
        .float -0.723823547, 3.52640247, -1.19099319, 1.0
        .float -0.723823547, 3.51243615, -1.24311686, 1.0
        .float -0.723823547, 1.51150465, -1.26657593, 1.0
        .float -0.703391433, 3.60265636, -1.20103216, 1.0
        .float -0.647569835, 3.65847802, -0.546844006, 1.0
        .float -0.703391433, 3.60265636, -0.546844006, 1.0
        .float -0.571316123, 3.67891002, -0.546844006, 1.0
        .float 0.609294295, 3.67891002, -0.546844006, 1.0
        .float 0.685548007, 3.65847802, -0.546844006, 1.0
        .float 0.685548007, 3.65847802, -1.20838118, 1.0
        .float 0.741369605, 3.58080339, -1.28258872, 1.0
        .float 0.741369605, 3.60265636, -1.20103216, 1.0
        .float 0.741369605, 3.60265636, -0.546844006, 1.0
        .float 0.76180172, 3.51243615, -1.24311686, 1.0
        .float 0.76180172, 3.52640247, -1.19099319, 1.0
        .float 0.76180172, 3.48897696, -1.26657581, 1.0
        .float 0.741369605, 3.52844882, -1.33494306, 1.0
        .float 0.76180172, 3.43685341, -1.28054237, 1.0
        .float 0.741369605, 3.44689226, -1.35679615, 1.0
        .float 0.76180172, 1.48804545, -1.24311686, 1.0
        .float 0.76180172, 1.51150465, -1.26657593, 1.0
        .float 0.76180172, 1.5636282, -1.28054237, 1.0
        .float 0.685548007, 3.45424128, -1.41261768, 1.0
        .float 0.741369605, 1.55358922, -1.35679615, 1.0
        .float 0.741369605, 1.47203279, -1.33494306, 1.0
        .float 0.741369605, 1.41967821, -1.28258872, 1.0
        .float 0.76180172, 1.47407901, -1.19099319, 1.0
        .float 0.741369605, 1.39782524, -1.20103216, 1.0
        .float 0.685548007, 1.36962986, -1.3114841, 1.0
        .float 0.685548007, 1.34200358, -1.20838118, 1.0
        .float 0.76180172, 1.47407901, -0.546844006, 1.0
        .float 0.741369605, 1.39782524, -0.546844006, 1.0
        .float 0.609294295, 1.32157159, -1.21107113, 1.0
        .float 0.685548007, 1.34200358, -0.546844006, 1.0
        .float 0.609294295, 1.32157159, -0.546844006, 1.0
        .float -0.571316123, 1.32157159, -0.546844006, 1.0
        .float 0.76180172, 3.52640247, -0.546844006, 1.0


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
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
        .word 0, 0 
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
        .word 0, 1, 2, 0
        .word 0, 2, 3, 0
        .word 4, 0, 3, 0
        .word 0, 5, 6, 0
        .word 0, 6, 1, 0
        .word 4, 5, 0, 0
        .word 3, 2, 7, 0
        .word 3, 7, 8, 0
        .word 4, 3, 9, 0
        .word 9, 3, 8, 0
        .word 10, 4, 9, 0
        .word 10, 11, 4, 0
        .word 4, 11, 5, 0
        .word 10, 9, 12, 0
        .word 9, 8, 13, 0
        .word 12, 9, 13, 0
        .word 8, 7, 14, 0
        .word 8, 14, 15, 0
        .word 13, 8, 15, 0
        .word 16, 13, 17, 0
        .word 13, 15, 17, 0
        .word 12, 13, 16, 0
        .word 18, 10, 12, 0
        .word 18, 12, 19, 0
        .word 19, 12, 16, 0
        .word 20, 16, 21, 0
        .word 19, 16, 20, 0
        .word 16, 17, 21, 0
        .word 17, 15, 22, 0
        .word 17, 22, 23, 0
        .word 21, 17, 23, 0
        .word 20, 21, 24, 0
        .word 24, 21, 25, 0
        .word 21, 23, 25, 0
        .word 26, 20, 24, 0
        .word 27, 19, 20, 0
        .word 27, 20, 26, 0
        .word 26, 24, 28, 0
        .word 24, 25, 29, 0
        .word 28, 24, 29, 0
        .word 29, 25, 30, 0
        .word 25, 23, 31, 0
        .word 25, 31, 30, 0
        .word 32, 29, 33, 0
        .word 29, 30, 33, 0
        .word 28, 29, 32, 0
        .word 34, 26, 28, 0
        .word 34, 28, 35, 0
        .word 35, 28, 32, 0
        .word 32, 33, 36, 0
        .word 35, 32, 37, 0
        .word 37, 32, 36, 0
        .word 33, 30, 38, 0
        .word 33, 38, 39, 0
        .word 36, 33, 39, 0
        .word 36, 39, 40, 0
        .word 37, 36, 41, 0
        .word 41, 36, 40, 0
        .word 42, 35, 37, 0
        .word 42, 37, 43, 0
        .word 43, 37, 41, 0
        .word 43, 41, 44, 0
        .word 41, 40, 45, 0
        .word 44, 41, 45, 0
        .word 40, 39, 46, 0
        .word 40, 46, 47, 0
        .word 45, 40, 47, 0
        .word 48, 45, 49, 0
        .word 45, 47, 49, 0
        .word 44, 45, 48, 0
        .word 50, 43, 44, 0
        .word 50, 44, 51, 0
        .word 51, 44, 48, 0
        .word 52, 48, 53, 0
        .word 51, 48, 52, 0
        .word 48, 49, 53, 0
        .word 49, 47, 54, 0
        .word 49, 54, 55, 0
        .word 53, 49, 55, 0
        .word 52, 53, 56, 0
        .word 56, 53, 57, 0
        .word 53, 55, 57, 0
        .word 58, 52, 56, 0
        .word 59, 51, 52, 0
        .word 59, 52, 58, 0
        .word 58, 56, 60, 0
        .word 56, 57, 61, 0
        .word 60, 56, 61, 0
        .word 62, 59, 58, 0
        .word 62, 58, 63, 0
        .word 63, 58, 60, 0
        .word 64, 51, 59, 0
        .word 65, 64, 59, 0
        .word 65, 59, 62, 0
        .word 66, 65, 62, 0
        .word 66, 62, 67, 0
        .word 67, 62, 63, 0
        .word 67, 63, 68, 0
        .word 68, 63, 69, 0
        .word 63, 60, 69, 0
        .word 66, 67, 70, 0
        .word 67, 68, 71, 0
        .word 67, 71, 70, 0
        .word 72, 65, 66, 0
        .word 66, 70, 73, 0
        .word 72, 66, 73, 0
        .word 70, 71, 74, 0
        .word 70, 74, 75, 0
        .word 73, 70, 75, 0
        .word 68, 76, 71, 0
        .word 71, 76, 77, 0
        .word 71, 77, 74, 0
        .word 75, 74, 78, 0
        .word 74, 77, 79, 0
        .word 74, 79, 78, 0
        .word 73, 75, 80, 0
        .word 80, 75, 81, 0
        .word 75, 78, 81, 0
        .word 81, 78, 82, 0
        .word 78, 79, 83, 0
        .word 78, 83, 82, 0
        .word 77, 84, 79, 0
        .word 79, 84, 85, 0
        .word 79, 85, 83, 0
        .word 82, 83, 86, 0
        .word 83, 85, 87, 0
        .word 83, 87, 86, 0
        .word 82, 86, 88, 0
        .word 89, 82, 88, 0
        .word 81, 82, 89, 0
        .word 86, 87, 90, 0
        .word 86, 90, 91, 0
        .word 88, 86, 91, 0
        .word 88, 91, 92, 0
        .word 89, 88, 93, 0
        .word 93, 88, 92, 0
        .word 94, 89, 93, 0
        .word 95, 81, 89, 0
        .word 95, 89, 94, 0
        .word 94, 93, 96, 0
        .word 93, 92, 97, 0
        .word 96, 93, 97, 0
        .word 98, 94, 96, 0
        .word 99, 95, 94, 0
        .word 99, 94, 98, 0
        .word 80, 81, 95, 0
        .word 100, 80, 95, 0
        .word 100, 95, 99, 0
        .word 101, 100, 99, 0
        .word 101, 99, 102, 0
        .word 102, 99, 98, 0
        .word 103, 98, 104, 0
        .word 98, 96, 104, 0
        .word 102, 98, 103, 0
        .word 105, 101, 102, 0
        .word 105, 102, 106, 0
        .word 106, 102, 103, 0
        .word 107, 100, 101, 0
        .word 107, 101, 105, 0
        .word 108, 80, 100, 0
        .word 107, 108, 100, 0
        .word 108, 73, 80, 0
        .word 109, 72, 108, 0
        .word 109, 108, 107, 0
        .word 72, 73, 108, 0
        .word 109, 107, 110, 0
        .word 107, 105, 110, 0
        .word 110, 105, 111, 0
        .word 111, 105, 106, 0
        .word 109, 110, 112, 0
        .word 110, 111, 113, 0
        .word 112, 110, 113, 0
        .word 113, 111, 114, 0
        .word 111, 106, 115, 0
        .word 114, 111, 115, 0
        .word 112, 113, 116, 0
        .word 116, 113, 117, 0
        .word 113, 114, 117, 0
        .word 118, 109, 112, 0
        .word 118, 112, 119, 0
        .word 119, 112, 116, 0
        .word 119, 116, 120, 0
        .word 116, 117, 121, 0
        .word 120, 116, 121, 0
        .word 117, 114, 122, 0
        .word 117, 122, 123, 0
        .word 121, 117, 123, 0
        .word 121, 123, 124, 0
        .word 120, 121, 125, 0
        .word 125, 121, 124, 0
        .word 126, 119, 120, 0
        .word 126, 120, 127, 0
        .word 127, 120, 125, 0
        .word 127, 125, 128, 0
        .word 125, 124, 129, 0
        .word 128, 125, 129, 0
        .word 129, 124, 130, 0
        .word 124, 123, 131, 0
        .word 124, 131, 130, 0
        .word 128, 129, 132, 0
        .word 132, 129, 133, 0
        .word 129, 130, 133, 0
        .word 127, 128, 134, 0
        .word 128, 132, 135, 0
        .word 128, 135, 134, 0
        .word 132, 133, 136, 0
        .word 132, 136, 137, 0
        .word 132, 137, 135, 0
        .word 134, 135, 138, 0
        .word 135, 137, 139, 0
        .word 135, 139, 138, 0
        .word 127, 134, 140, 0
        .word 134, 138, 141, 0
        .word 140, 134, 141, 0
        .word 141, 138, 142, 0
        .word 138, 139, 143, 0
        .word 138, 143, 142, 0
        .word 144, 141, 145, 0
        .word 141, 142, 145, 0
        .word 140, 141, 144, 0
        .word 126, 127, 140, 0
        .word 126, 140, 146, 0
        .word 146, 140, 144, 0
        .word 146, 144, 147, 0
        .word 147, 144, 148, 0
        .word 144, 145, 148, 0
        .word 145, 142, 149, 0
        .word 145, 149, 150, 0
        .word 148, 145, 150, 0
        .word 147, 148, 151, 0
        .word 151, 148, 152, 0
        .word 148, 150, 152, 0
        .word 153, 146, 147, 0
        .word 153, 147, 154, 0
        .word 154, 147, 151, 0
        .word 154, 151, 155, 0
        .word 151, 152, 156, 0
        .word 155, 151, 156, 0
        .word 152, 157, 158, 0
        .word 152, 158, 156, 0
        .word 150, 157, 152, 0
        .word 155, 156, 159, 0
        .word 156, 158, 160, 0
        .word 156, 160, 159, 0
        .word 154, 155, 161, 0
        .word 155, 159, 162, 0
        .word 155, 162, 161, 0
        .word 159, 160, 163, 0
        .word 159, 163, 162, 0
        .word 158, 164, 160, 0
        .word 160, 164, 165, 0
        .word 160, 165, 163, 0
        .word 157, 166, 158, 0
        .word 158, 166, 164, 0
        .word 164, 167, 168, 0
        .word 164, 168, 165, 0
        .word 166, 167, 164, 0
        .word 165, 168, 169, 0
        .word 165, 169, 170, 0
        .word 163, 165, 170, 0
        .word 163, 170, 171, 0
        .word 162, 163, 171, 0
        .word 170, 169, 172, 0
        .word 170, 172, 173, 0
        .word 171, 170, 173, 0
        .word 168, 174, 169, 0
        .word 169, 174, 175, 0
        .word 169, 175, 172, 0
        .word 167, 176, 168, 0
        .word 168, 176, 174, 0
        .word 176, 177, 174, 0
        .word 174, 177, 178, 0
        .word 174, 178, 175, 0
        .word 172, 175, 179, 0
        .word 175, 178, 180, 0
        .word 175, 180, 179, 0
        .word 177, 181, 178, 0
        .word 178, 181, 182, 0
        .word 178, 182, 180, 0
        .word 183, 184, 177, 0
        .word 176, 183, 177, 0
        .word 177, 184, 181, 0
        .word 184, 185, 181, 0
        .word 181, 185, 186, 0
        .word 181, 186, 182, 0
        .word 182, 186, 187, 0
        .word 182, 187, 188, 0
        .word 180, 182, 188, 0
        .word 185, 189, 186, 0
        .word 186, 189, 190, 0
        .word 186, 190, 187, 0
        .word 184, 191, 185, 0
        .word 191, 192, 185, 0
        .word 185, 192, 189, 0
        .word 191, 193, 192, 0
        .word 194, 193, 191, 0
        .word 195, 194, 191, 0
        .word 195, 191, 184, 0
        .word 194, 196, 193, 0
        .word 197, 198, 194, 0
        .word 197, 194, 195, 0
        .word 198, 196, 194, 0
        .word 199, 197, 195, 0
        .word 199, 195, 183, 0
        .word 183, 195, 184, 0
        .word 200, 198, 197, 0
        .word 201, 200, 197, 0
        .word 201, 197, 199, 0
        .word 198, 202, 196, 0
        .word 203, 202, 198, 0
        .word 200, 203, 198, 0
        .word 204, 203, 200, 0
        .word 205, 204, 200, 0
        .word 205, 200, 201, 0
        .word 206, 205, 201, 0
        .word 206, 201, 207, 0
        .word 207, 201, 199, 0
        .word 208, 204, 205, 0
        .word 209, 208, 205, 0
        .word 209, 205, 206, 0
        .word 204, 210, 203, 0
        .word 211, 210, 204, 0
        .word 208, 211, 204, 0
        .word 212, 213, 208, 0
        .word 212, 208, 209, 0
        .word 213, 211, 208, 0
        .word 214, 212, 209, 0
        .word 214, 209, 215, 0
        .word 215, 209, 206, 0
        .word 216, 217, 212, 0
        .word 216, 212, 214, 0
        .word 217, 213, 212, 0
        .word 213, 218, 211, 0
        .word 219, 218, 213, 0
        .word 217, 219, 213, 0
        .word 220, 221, 218, 0
        .word 218, 221, 222, 0
        .word 218, 222, 211, 0
        .word 219, 220, 218, 0
        .word 220, 223, 221, 0
        .word 223, 224, 221, 0
        .word 221, 224, 225, 0
        .word 221, 225, 222, 0
        .word 222, 225, 226, 0
        .word 222, 226, 210, 0
        .word 211, 222, 210, 0
        .word 210, 226, 227, 0
        .word 210, 227, 203, 0
        .word 203, 227, 202, 0
        .word 223, 228, 224, 0
        .word 229, 214, 215, 0
        .word 230, 216, 214, 0
        .word 230, 214, 229, 0
        .word 229, 215, 231, 0
        .word 215, 206, 232, 0
        .word 231, 215, 232, 0
        .word 231, 232, 233, 0
        .word 234, 229, 231, 0
        .word 234, 231, 235, 0
        .word 235, 231, 233, 0
        .word 233, 232, 236, 0
        .word 232, 206, 207, 0
        .word 232, 207, 236, 0
        .word 233, 236, 166, 0
        .word 157, 233, 166, 0
        .word 235, 233, 157, 0
        .word 149, 234, 235, 0
        .word 149, 235, 150, 0
        .word 150, 235, 157, 0
        .word 142, 237, 149, 0
        .word 237, 234, 149, 0
        .word 142, 143, 237, 0
        .word 237, 238, 234, 0
        .word 238, 230, 229, 0
        .word 238, 229, 234, 0
        .word 166, 236, 167, 0
        .word 236, 207, 239, 0
        .word 236, 239, 167, 0
        .word 167, 239, 176, 0
        .word 207, 199, 239, 0
        .word 239, 199, 183, 0
        .word 239, 183, 176, 0
        .word 187, 190, 240, 0
        .word 187, 240, 241, 0
        .word 188, 187, 241, 0
        .word 188, 241, 242, 0
        .word 180, 188, 243, 0
        .word 243, 188, 242, 0
        .word 243, 242, 244, 0
        .word 179, 180, 243, 0
        .word 179, 243, 245, 0
        .word 245, 243, 244, 0
        .word 245, 244, 246, 0
        .word 247, 179, 245, 0
        .word 247, 245, 248, 0
        .word 248, 245, 246, 0
        .word 172, 179, 247, 0
        .word 249, 247, 248, 0
        .word 173, 172, 247, 0
        .word 173, 247, 249, 0
        .word 249, 248, 250, 0
        .word 248, 246, 251, 0
        .word 250, 248, 251, 0
        .word 252, 173, 249, 0
        .word 252, 249, 253, 0
        .word 253, 249, 250, 0
        .word 171, 173, 252, 0
        .word 254, 171, 252, 0
        .word 254, 252, 255, 0
        .word 255, 252, 253, 0
        .word 255, 253, 256, 0
        .word 256, 253, 257, 0
        .word 253, 250, 257, 0
        .word 258, 254, 255, 0
        .word 258, 255, 259, 0
        .word 259, 255, 256, 0
        .word 161, 162, 254, 0
        .word 161, 254, 258, 0
        .word 162, 171, 254, 0
        .word 260, 258, 259, 0
        .word 261, 161, 258, 0
        .word 261, 258, 260, 0
        .word 260, 259, 262, 0
        .word 259, 256, 263, 0
        .word 262, 259, 263, 0
        .word 260, 262, 264, 0
        .word 260, 264, 265, 0
        .word 261, 260, 265, 0
        .word 154, 261, 266, 0
        .word 261, 265, 266, 0
        .word 154, 161, 261, 0
        .word 265, 264, 267, 0
        .word 265, 267, 268, 0
        .word 266, 265, 268, 0
        .word 262, 269, 264, 0
        .word 264, 269, 270, 0
        .word 264, 270, 267, 0
        .word 268, 267, 271, 0
        .word 267, 270, 272, 0
        .word 267, 272, 271, 0
        .word 273, 268, 274, 0
        .word 268, 271, 274, 0
        .word 266, 268, 273, 0
        .word 271, 272, 275, 0
        .word 271, 275, 276, 0
        .word 274, 271, 276, 0
        .word 270, 277, 272, 0
        .word 272, 277, 278, 0
        .word 272, 278, 275, 0
        .word 275, 278, 279, 0
        .word 275, 279, 280, 0
        .word 276, 275, 280, 0
        .word 274, 276, 281, 0
        .word 281, 276, 282, 0
        .word 276, 280, 282, 0
        .word 280, 279, 283, 0
        .word 280, 283, 284, 0
        .word 282, 280, 284, 0
        .word 278, 285, 279, 0
        .word 279, 285, 286, 0
        .word 279, 286, 283, 0
        .word 284, 283, 287, 0
        .word 283, 286, 288, 0
        .word 283, 288, 287, 0
        .word 289, 284, 290, 0
        .word 284, 287, 290, 0
        .word 282, 284, 289, 0
        .word 287, 288, 291, 0
        .word 287, 291, 292, 0
        .word 290, 287, 292, 0
        .word 289, 290, 293, 0
        .word 293, 290, 294, 0
        .word 290, 292, 294, 0
        .word 295, 289, 293, 0
        .word 296, 282, 289, 0
        .word 296, 289, 295, 0
        .word 295, 293, 297, 0
        .word 293, 294, 298, 0
        .word 297, 293, 298, 0
        .word 298, 294, 299, 0
        .word 294, 292, 300, 0
        .word 294, 300, 299, 0
        .word 297, 298, 301, 0
        .word 301, 298, 302, 0
        .word 298, 299, 302, 0
        .word 303, 295, 297, 0
        .word 303, 297, 304, 0
        .word 304, 297, 301, 0
        .word 304, 301, 305, 0
        .word 301, 302, 306, 0
        .word 305, 301, 306, 0
        .word 302, 299, 307, 0
        .word 302, 307, 308, 0
        .word 306, 302, 308, 0
        .word 306, 308, 309, 0
        .word 305, 306, 310, 0
        .word 310, 306, 309, 0
        .word 311, 304, 305, 0
        .word 311, 305, 312, 0
        .word 312, 305, 310, 0
        .word 312, 310, 313, 0
        .word 310, 309, 314, 0
        .word 313, 310, 314, 0
        .word 314, 309, 315, 0
        .word 309, 308, 316, 0
        .word 309, 316, 315, 0
        .word 317, 314, 318, 0
        .word 314, 315, 318, 0
        .word 313, 314, 317, 0
        .word 319, 312, 313, 0
        .word 319, 313, 11, 0
        .word 11, 313, 317, 0
        .word 5, 317, 320, 0
        .word 317, 318, 320, 0
        .word 11, 317, 5, 0
        .word 318, 315, 321, 0
        .word 318, 321, 322, 0
        .word 320, 318, 322, 0
        .word 5, 320, 6, 0
        .word 6, 320, 323, 0
        .word 320, 322, 323, 0
        .word 323, 322, 324, 0
        .word 322, 321, 325, 0
        .word 322, 325, 324, 0
        .word 315, 326, 321, 0
        .word 321, 326, 327, 0
        .word 321, 327, 325, 0
        .word 324, 325, 328, 0
        .word 325, 327, 329, 0
        .word 325, 329, 328, 0
        .word 326, 330, 327, 0
        .word 327, 330, 331, 0
        .word 327, 331, 329, 0
        .word 316, 332, 326, 0
        .word 315, 316, 326, 0
        .word 326, 332, 330, 0
        .word 332, 333, 330, 0
        .word 330, 333, 334, 0
        .word 330, 334, 331, 0
        .word 329, 331, 335, 0
        .word 331, 334, 336, 0
        .word 331, 336, 335, 0
        .word 333, 337, 334, 0
        .word 334, 337, 338, 0
        .word 334, 338, 336, 0
        .word 332, 339, 333, 0
        .word 339, 340, 333, 0
        .word 333, 340, 337, 0
        .word 341, 342, 339, 0
        .word 343, 341, 339, 0
        .word 343, 339, 332, 0
        .word 339, 342, 340, 0
        .word 307, 344, 341, 0
        .word 307, 341, 343, 0
        .word 344, 345, 341, 0
        .word 341, 345, 342, 0
        .word 308, 307, 343, 0
        .word 308, 343, 316, 0
        .word 316, 343, 332, 0
        .word 299, 344, 307, 0
        .word 344, 346, 345, 0
        .word 300, 346, 344, 0
        .word 299, 300, 344, 0
        .word 300, 347, 346, 0
        .word 292, 347, 300, 0
        .word 292, 291, 347, 0
        .word 336, 338, 348, 0
        .word 336, 348, 349, 0
        .word 335, 336, 349, 0
        .word 348, 350, 351, 0
        .word 348, 351, 349, 0
        .word 335, 349, 352, 0
        .word 349, 351, 353, 0
        .word 349, 353, 352, 0
        .word 329, 335, 354, 0
        .word 354, 335, 352, 0
        .word 354, 352, 355, 0
        .word 352, 353, 356, 0
        .word 352, 356, 355, 0
        .word 351, 357, 353, 0
        .word 353, 357, 358, 0
        .word 353, 358, 356, 0
        .word 356, 358, 359, 0
        .word 356, 359, 360, 0
        .word 355, 356, 360, 0
        .word 361, 354, 355, 0
        .word 361, 355, 362, 0
        .word 355, 360, 362, 0
        .word 363, 362, 360, 0
        .word 364, 363, 360, 0
        .word 364, 360, 359, 0
        .word 365, 364, 359, 0
        .word 365, 359, 366, 0
        .word 358, 366, 359, 0
        .word 367, 368, 364, 0
        .word 367, 364, 365, 0
        .word 368, 363, 364, 0
        .word 368, 369, 363, 0
        .word 369, 361, 363, 0
        .word 363, 361, 362, 0
        .word 370, 371, 368, 0
        .word 370, 368, 367, 0
        .word 371, 369, 368, 0
        .word 372, 370, 367, 0
        .word 372, 367, 373, 0
        .word 373, 367, 365, 0
        .word 374, 375, 370, 0
        .word 374, 370, 372, 0
        .word 375, 371, 370, 0
        .word 375, 323, 371, 0
        .word 323, 324, 371, 0
        .word 371, 324, 369, 0
        .word 6, 323, 375, 0
        .word 1, 6, 375, 0
        .word 1, 375, 374, 0
        .word 1, 374, 376, 0
        .word 374, 372, 377, 0
        .word 374, 377, 376, 0
        .word 1, 376, 2, 0
        .word 2, 376, 378, 0
        .word 376, 377, 379, 0
        .word 376, 379, 378, 0
        .word 372, 380, 377, 0
        .word 377, 380, 381, 0
        .word 377, 381, 379, 0
        .word 378, 379, 382, 0
        .word 379, 381, 383, 0
        .word 379, 383, 382, 0
        .word 380, 384, 381, 0
        .word 381, 384, 385, 0
        .word 381, 385, 383, 0
        .word 372, 373, 380, 0
        .word 373, 386, 380, 0
        .word 380, 386, 384, 0
        .word 386, 387, 384, 0
        .word 384, 387, 388, 0
        .word 384, 388, 385, 0
        .word 385, 388, 389, 0
        .word 385, 389, 390, 0
        .word 383, 385, 390, 0
        .word 391, 389, 388, 0
        .word 391, 388, 392, 0
        .word 392, 388, 387, 0
        .word 386, 393, 387, 0
        .word 392, 387, 394, 0
        .word 394, 387, 393, 0
        .word 395, 391, 392, 0
        .word 395, 392, 396, 0
        .word 396, 392, 394, 0
        .word 390, 389, 391, 0
        .word 390, 391, 397, 0
        .word 397, 391, 395, 0
        .word 383, 390, 398, 0
        .word 398, 390, 397, 0
        .word 398, 397, 399, 0
        .word 397, 395, 400, 0
        .word 399, 397, 400, 0
        .word 400, 395, 401, 0
        .word 401, 395, 396, 0
        .word 399, 400, 402, 0
        .word 402, 400, 403, 0
        .word 400, 401, 403, 0
        .word 404, 398, 399, 0
        .word 404, 399, 405, 0
        .word 405, 399, 402, 0
        .word 382, 383, 398, 0
        .word 382, 398, 404, 0
        .word 406, 382, 404, 0
        .word 406, 404, 407, 0
        .word 407, 404, 405, 0
        .word 407, 405, 408, 0
        .word 405, 402, 409, 0
        .word 408, 405, 409, 0
        .word 14, 406, 407, 0
        .word 14, 407, 410, 0
        .word 410, 407, 408, 0
        .word 378, 382, 406, 0
        .word 7, 378, 406, 0
        .word 7, 406, 14, 0
        .word 15, 14, 410, 0
        .word 15, 410, 22, 0
        .word 22, 410, 411, 0
        .word 410, 408, 411, 0
        .word 22, 411, 412, 0
        .word 23, 22, 412, 0
        .word 411, 408, 413, 0
        .word 411, 413, 414, 0
        .word 412, 411, 414, 0
        .word 412, 414, 415, 0
        .word 23, 412, 31, 0
        .word 31, 412, 415, 0
        .word 415, 414, 416, 0
        .word 414, 413, 417, 0
        .word 414, 417, 416, 0
        .word 413, 409, 418, 0
        .word 413, 418, 417, 0
        .word 408, 409, 413, 0
        .word 416, 417, 419, 0
        .word 417, 418, 420, 0
        .word 417, 420, 419, 0
        .word 409, 421, 418, 0
        .word 418, 421, 422, 0
        .word 418, 422, 420, 0
        .word 409, 402, 421, 0
        .word 402, 403, 421, 0
        .word 421, 403, 423, 0
        .word 421, 423, 422, 0
        .word 403, 401, 424, 0
        .word 403, 424, 423, 0
        .word 424, 401, 425, 0
        .word 401, 396, 425, 0
        .word 424, 425, 426, 0
        .word 425, 396, 427, 0
        .word 425, 427, 428, 0
        .word 426, 425, 428, 0
        .word 396, 394, 427, 0
        .word 428, 427, 429, 0
        .word 427, 394, 430, 0
        .word 427, 430, 429, 0
        .word 431, 428, 432, 0
        .word 428, 429, 432, 0
        .word 426, 428, 431, 0
        .word 432, 429, 433, 0
        .word 429, 430, 434, 0
        .word 429, 434, 433, 0
        .word 394, 393, 430, 0
        .word 430, 393, 435, 0
        .word 430, 435, 434, 0
        .word 436, 433, 434, 0
        .word 436, 434, 437, 0
        .word 437, 434, 435, 0
        .word 432, 433, 438, 0
        .word 439, 438, 433, 0
        .word 439, 433, 436, 0
        .word 440, 439, 436, 0
        .word 440, 436, 357, 0
        .word 357, 436, 437, 0
        .word 357, 437, 358, 0
        .word 437, 435, 366, 0
        .word 358, 437, 366, 0
        .word 351, 440, 357, 0
        .word 441, 439, 440, 0
        .word 350, 441, 440, 0
        .word 350, 440, 351, 0
        .word 441, 442, 439, 0
        .word 442, 438, 439, 0
        .word 442, 443, 438, 0
        .word 444, 438, 443, 0
        .word 431, 432, 444, 0
        .word 444, 432, 438, 0
        .word 445, 365, 366, 0
        .word 445, 366, 435, 0
        .word 373, 445, 386, 0
        .word 445, 435, 393, 0
        .word 445, 393, 386, 0
        .word 373, 365, 445, 0
        .word 416, 419, 446, 0
        .word 415, 416, 447, 0
        .word 447, 416, 446, 0
        .word 447, 446, 448, 0
        .word 449, 415, 447, 0
        .word 449, 447, 450, 0
        .word 450, 447, 448, 0
        .word 31, 415, 449, 0
        .word 30, 31, 449, 0
        .word 30, 449, 38, 0
        .word 38, 449, 450, 0
        .word 38, 450, 451, 0
        .word 450, 448, 452, 0
        .word 451, 450, 452, 0
        .word 39, 38, 451, 0
        .word 39, 451, 46, 0
        .word 46, 451, 453, 0
        .word 451, 452, 453, 0
        .word 46, 453, 454, 0
        .word 47, 46, 454, 0
        .word 47, 454, 54, 0
        .word 2, 378, 7, 0
        .word 369, 328, 361, 0
        .word 324, 328, 369, 0
        .word 328, 329, 354, 0
        .word 328, 354, 361, 0
        .word 10, 319, 11, 0
        .word 18, 319, 10, 0
        .word 455, 312, 319, 0
        .word 18, 455, 319, 0
        .word 456, 18, 19, 0
        .word 456, 455, 18, 0
        .word 456, 457, 455, 0
        .word 457, 311, 455, 0
        .word 455, 311, 312, 0
        .word 456, 19, 27, 0
        .word 458, 456, 27, 0
        .word 458, 457, 456, 0
        .word 457, 459, 311, 0
        .word 460, 459, 457, 0
        .word 458, 460, 457, 0
        .word 459, 304, 311, 0
        .word 459, 303, 304, 0
        .word 460, 461, 459, 0
        .word 461, 303, 459, 0
        .word 462, 463, 460, 0
        .word 462, 460, 458, 0
        .word 463, 461, 460, 0
        .word 462, 458, 464, 0
        .word 458, 27, 464, 0
        .word 464, 27, 26, 0
        .word 462, 464, 465, 0
        .word 464, 26, 34, 0
        .word 465, 464, 34, 0
        .word 466, 462, 465, 0
        .word 466, 463, 462, 0
        .word 467, 468, 463, 0
        .word 466, 467, 463, 0
        .word 463, 468, 461, 0
        .word 469, 466, 470, 0
        .word 466, 465, 470, 0
        .word 469, 467, 466, 0
        .word 470, 465, 471, 0
        .word 465, 34, 471, 0
        .word 471, 34, 35, 0
        .word 470, 471, 472, 0
        .word 472, 471, 42, 0
        .word 471, 35, 42, 0
        .word 469, 470, 473, 0
        .word 473, 470, 472, 0
        .word 473, 472, 474, 0
        .word 474, 472, 475, 0
        .word 472, 42, 475, 0
        .word 475, 42, 43, 0
        .word 474, 475, 476, 0
        .word 475, 43, 50, 0
        .word 476, 475, 50, 0
        .word 477, 474, 476, 0
        .word 478, 473, 474, 0
        .word 478, 474, 477, 0
        .word 479, 469, 473, 0
        .word 479, 473, 478, 0
        .word 480, 479, 478, 0
        .word 480, 478, 118, 0
        .word 118, 478, 477, 0
        .word 109, 477, 481, 0
        .word 477, 476, 481, 0
        .word 118, 477, 109, 0
        .word 480, 118, 119, 0
        .word 480, 119, 126, 0
        .word 480, 126, 146, 0
        .word 480, 146, 153, 0
        .word 480, 153, 482, 0
        .word 480, 482, 479, 0
        .word 153, 154, 483, 0
        .word 153, 483, 482, 0
        .word 482, 483, 484, 0
        .word 482, 484, 485, 0
        .word 479, 482, 485, 0
        .word 154, 266, 483, 0
        .word 483, 266, 273, 0
        .word 483, 273, 484, 0
        .word 485, 484, 486, 0
        .word 484, 273, 487, 0
        .word 484, 487, 486, 0
        .word 469, 485, 467, 0
        .word 485, 486, 467, 0
        .word 479, 485, 469, 0
        .word 467, 486, 468, 0
        .word 486, 487, 488, 0
        .word 486, 488, 468, 0
        .word 273, 274, 487, 0
        .word 487, 274, 281, 0
        .word 487, 281, 488, 0
        .word 468, 488, 489, 0
        .word 488, 281, 296, 0
        .word 488, 296, 489, 0
        .word 468, 489, 461, 0
        .word 489, 296, 295, 0
        .word 489, 295, 303, 0
        .word 461, 489, 303, 0
        .word 281, 282, 296, 0
        .word 109, 481, 72, 0
        .word 481, 476, 64, 0
        .word 481, 64, 65, 0
        .word 72, 481, 65, 0
        .word 476, 50, 64, 0
        .word 64, 50, 51, 0
        .word 278, 490, 285, 0
        .word 277, 490, 278, 0
        .word 277, 491, 490, 0
        .word 270, 492, 277, 0
        .word 492, 491, 277, 0
        .word 492, 493, 491, 0
        .word 494, 493, 492, 0
        .word 269, 494, 492, 0
        .word 269, 492, 270, 0
        .word 494, 495, 493, 0
        .word 496, 497, 494, 0
        .word 496, 494, 269, 0
        .word 497, 495, 494, 0
        .word 262, 496, 269, 0
        .word 262, 263, 496, 0
        .word 496, 263, 498, 0
        .word 496, 498, 497, 0
        .word 497, 499, 495, 0
        .word 497, 498, 500, 0
        .word 497, 500, 499, 0
        .word 263, 501, 498, 0
        .word 498, 501, 502, 0
        .word 498, 502, 500, 0
        .word 263, 256, 501, 0
        .word 256, 257, 501, 0
        .word 501, 257, 503, 0
        .word 501, 503, 502, 0
        .word 257, 250, 504, 0
        .word 257, 504, 503, 0
        .word 250, 251, 504, 0
        .word 123, 505, 131, 0
        .word 123, 122, 505, 0
        .word 505, 122, 506, 0
        .word 505, 506, 507, 0
        .word 122, 114, 508, 0
        .word 122, 508, 506, 0
        .word 507, 506, 509, 0
        .word 506, 508, 510, 0
        .word 506, 510, 509, 0
        .word 507, 509, 511, 0
        .word 509, 510, 512, 0
        .word 509, 512, 513, 0
        .word 511, 509, 513, 0
        .word 510, 514, 515, 0
        .word 510, 515, 512, 0
        .word 508, 514, 510, 0
        .word 114, 115, 508, 0
        .word 508, 115, 514, 0
        .word 514, 516, 517, 0
        .word 514, 517, 515, 0
        .word 115, 516, 514, 0
        .word 512, 515, 518, 0
        .word 515, 517, 519, 0
        .word 515, 519, 518, 0
        .word 516, 520, 517, 0
        .word 517, 520, 521, 0
        .word 517, 521, 519, 0
        .word 516, 103, 520, 0
        .word 106, 103, 516, 0
        .word 115, 106, 516, 0
        .word 103, 104, 520, 0
        .word 520, 104, 522, 0
        .word 520, 522, 521, 0
        .word 519, 521, 523, 0
        .word 521, 522, 524, 0
        .word 521, 524, 523, 0
        .word 104, 525, 522, 0
        .word 522, 525, 526, 0
        .word 522, 526, 524, 0
        .word 104, 96, 525, 0
        .word 96, 97, 525, 0
        .word 525, 97, 527, 0
        .word 525, 527, 526, 0
        .word 524, 526, 528, 0
        .word 526, 527, 529, 0
        .word 526, 529, 528, 0
        .word 524, 528, 530, 0
        .word 523, 524, 530, 0
        .word 528, 529, 531, 0
        .word 528, 531, 532, 0
        .word 530, 528, 532, 0
        .word 529, 533, 534, 0
        .word 529, 534, 531, 0
        .word 527, 533, 529, 0
        .word 97, 535, 527, 0
        .word 527, 535, 533, 0
        .word 97, 92, 535, 0
        .word 92, 536, 535, 0
        .word 535, 536, 537, 0
        .word 535, 537, 533, 0
        .word 533, 537, 538, 0
        .word 533, 538, 534, 0
        .word 531, 534, 539, 0
        .word 534, 538, 540, 0
        .word 534, 540, 539, 0
        .word 537, 541, 538, 0
        .word 538, 541, 542, 0
        .word 538, 542, 540, 0
        .word 537, 543, 541, 0
        .word 536, 543, 537, 0
        .word 536, 544, 543, 0
        .word 91, 90, 544, 0
        .word 91, 544, 536, 0
        .word 92, 91, 536, 0
        .word 531, 539, 545, 0
        .word 532, 531, 545, 0
        .word 532, 545, 546, 0
        .word 530, 532, 547, 0
        .word 547, 532, 546, 0
        .word 547, 546, 548, 0
        .word 549, 530, 547, 0
        .word 549, 547, 550, 0
        .word 550, 547, 548, 0
        .word 523, 530, 549, 0
        .word 551, 549, 550, 0
        .word 552, 523, 549, 0
        .word 552, 549, 551, 0
        .word 550, 548, 553, 0
        .word 551, 550, 554, 0
        .word 554, 550, 553, 0
        .word 555, 551, 554, 0
        .word 556, 552, 551, 0
        .word 556, 551, 555, 0
        .word 518, 519, 552, 0
        .word 518, 552, 556, 0
        .word 519, 523, 552, 0
        .word 557, 518, 556, 0
        .word 557, 556, 558, 0
        .word 558, 556, 555, 0
        .word 555, 554, 559, 0
        .word 560, 555, 559, 0
        .word 558, 555, 560, 0
        .word 561, 557, 558, 0
        .word 561, 558, 562, 0
        .word 562, 558, 560, 0
        .word 512, 518, 557, 0
        .word 513, 512, 557, 0
        .word 513, 557, 561, 0
        .word 563, 513, 561, 0
        .word 563, 561, 564, 0
        .word 564, 561, 562, 0
        .word 562, 560, 565, 0
        .word 564, 562, 566, 0
        .word 566, 562, 565, 0
        .word 567, 565, 568, 0
        .word 565, 560, 569, 0
        .word 565, 569, 568, 0
        .word 566, 565, 567, 0
        .word 567, 568, 570, 0
        .word 570, 568, 571, 0
        .word 568, 569, 572, 0
        .word 568, 572, 571, 0
        .word 560, 559, 569, 0
        .word 569, 559, 573, 0
        .word 569, 573, 572, 0
        .word 559, 554, 574, 0
        .word 559, 574, 573, 0
        .word 554, 553, 574, 0
        .word 570, 571, 575, 0
        .word 511, 513, 563, 0
        .word 77, 576, 84, 0
        .word 76, 576, 77, 0
        .word 76, 577, 576, 0
        .word 68, 578, 76, 0
        .word 578, 577, 76, 0
        .word 578, 579, 577, 0
        .word 68, 69, 578, 0
        .word 578, 69, 580, 0
        .word 578, 580, 579, 0
        .word 69, 60, 581, 0
        .word 69, 581, 580, 0
        .word 60, 61, 581, 0
        .word 448, 446, 582, 0
        .word 448, 582, 583, 0
        .word 452, 448, 583, 0
        .word 446, 419, 584, 0
        .word 446, 584, 582, 0
        .word 582, 584, 585, 0
        .word 582, 585, 586, 0
        .word 583, 582, 586, 0
        .word 583, 586, 587, 0
        .word 452, 583, 588, 0
        .word 588, 583, 587, 0
        .word 453, 452, 588, 0
        .word 453, 588, 589, 0
        .word 588, 587, 590, 0
        .word 589, 588, 590, 0
        .word 587, 586, 591, 0
        .word 587, 591, 592, 0
        .word 590, 587, 592, 0
        .word 586, 585, 593, 0
        .word 586, 593, 591, 0
        .word 591, 593, 594, 0
        .word 591, 594, 595, 0
        .word 592, 591, 595, 0
        .word 592, 595, 596, 0
        .word 590, 592, 597, 0
        .word 597, 592, 596, 0
        .word 598, 590, 597, 0
        .word 589, 590, 598, 0
        .word 598, 597, 599, 0
        .word 597, 596, 600, 0
        .word 599, 597, 600, 0
        .word 596, 595, 601, 0
        .word 596, 601, 602, 0
        .word 600, 596, 602, 0
        .word 595, 594, 603, 0
        .word 595, 603, 601, 0
        .word 601, 603, 604, 0
        .word 601, 604, 605, 0
        .word 602, 601, 605, 0
        .word 602, 605, 606, 0
        .word 600, 602, 607, 0
        .word 607, 602, 606, 0
        .word 608, 600, 607, 0
        .word 599, 600, 608, 0
        .word 608, 607, 609, 0
        .word 607, 606, 610, 0
        .word 609, 607, 610, 0
        .word 606, 605, 611, 0
        .word 606, 611, 612, 0
        .word 610, 606, 612, 0
        .word 605, 604, 613, 0
        .word 605, 613, 611, 0
        .word 611, 613, 614, 0
        .word 611, 614, 615, 0
        .word 612, 611, 615, 0
        .word 612, 615, 616, 0
        .word 610, 612, 617, 0
        .word 617, 612, 616, 0
        .word 609, 610, 618, 0
        .word 618, 610, 617, 0
        .word 618, 617, 619, 0
        .word 617, 616, 620, 0
        .word 619, 617, 620, 0
        .word 621, 616, 615, 0
        .word 622, 620, 616, 0
        .word 622, 616, 621, 0
        .word 621, 615, 623, 0
        .word 623, 615, 614, 0
        .word 624, 621, 623, 0
        .word 625, 622, 621, 0
        .word 625, 621, 624, 0
        .word 626, 627, 622, 0
        .word 626, 622, 625, 0
        .word 627, 620, 622, 0
        .word 619, 620, 628, 0
        .word 627, 628, 620, 0
        .word 629, 628, 627, 0
        .word 630, 629, 627, 0
        .word 630, 627, 626, 0
        .word 631, 630, 626, 0
        .word 631, 626, 632, 0
        .word 632, 626, 625, 0
        .word 632, 625, 633, 0
        .word 633, 625, 624, 0
        .word 634, 631, 632, 0
        .word 634, 632, 635, 0
        .word 635, 632, 633, 0
        .word 636, 637, 631, 0
        .word 636, 631, 634, 0
        .word 637, 630, 631, 0
        .word 637, 638, 630, 0
        .word 638, 629, 630, 0
        .word 639, 638, 637, 0
        .word 640, 639, 637, 0
        .word 640, 637, 636, 0
        .word 641, 636, 634, 0
        .word 642, 640, 636, 0
        .word 642, 636, 641, 0
        .word 643, 644, 640, 0
        .word 643, 640, 642, 0
        .word 644, 639, 640, 0
        .word 644, 645, 639, 0
        .word 645, 646, 639, 0
        .word 639, 646, 638, 0
        .word 647, 648, 644, 0
        .word 647, 644, 643, 0
        .word 648, 645, 644, 0
        .word 649, 647, 643, 0
        .word 649, 643, 650, 0
        .word 650, 643, 642, 0
        .word 651, 652, 647, 0
        .word 651, 647, 649, 0
        .word 652, 648, 647, 0
        .word 652, 653, 648, 0
        .word 653, 654, 648, 0
        .word 648, 654, 645, 0
        .word 655, 653, 652, 0
        .word 656, 655, 652, 0
        .word 656, 652, 651, 0
        .word 657, 651, 649, 0
        .word 658, 656, 651, 0
        .word 658, 651, 657, 0
        .word 659, 655, 656, 0
        .word 660, 659, 656, 0
        .word 660, 656, 658, 0
        .word 659, 661, 655, 0
        .word 661, 662, 655, 0
        .word 655, 662, 653, 0
        .word 659, 663, 664, 0
        .word 659, 664, 661, 0
        .word 660, 663, 659, 0
        .word 499, 660, 658, 0
        .word 499, 665, 660, 0
        .word 660, 665, 663, 0
        .word 663, 666, 667, 0
        .word 663, 667, 664, 0
        .word 665, 666, 663, 0
        .word 664, 667, 668, 0
        .word 664, 668, 669, 0
        .word 661, 664, 669, 0
        .word 666, 670, 667, 0
        .word 667, 670, 671, 0
        .word 667, 671, 668, 0
        .word 665, 672, 666, 0
        .word 672, 673, 666, 0
        .word 666, 673, 670, 0
        .word 673, 674, 670, 0
        .word 670, 674, 675, 0
        .word 670, 675, 671, 0
        .word 668, 671, 676, 0
        .word 671, 675, 677, 0
        .word 671, 677, 676, 0
        .word 674, 678, 675, 0
        .word 675, 678, 679, 0
        .word 675, 679, 677, 0
        .word 680, 681, 674, 0
        .word 674, 681, 678, 0
        .word 673, 680, 674, 0
        .word 681, 682, 678, 0
        .word 678, 682, 683, 0
        .word 678, 683, 679, 0
        .word 679, 683, 684, 0
        .word 679, 684, 685, 0
        .word 677, 679, 685, 0
        .word 682, 686, 683, 0
        .word 683, 686, 687, 0
        .word 683, 687, 684, 0
        .word 681, 688, 682, 0
        .word 688, 689, 682, 0
        .word 682, 689, 686, 0
        .word 689, 690, 686, 0
        .word 686, 690, 691, 0
        .word 686, 691, 687, 0
        .word 684, 687, 692, 0
        .word 687, 691, 693, 0
        .word 687, 693, 692, 0
        .word 690, 694, 691, 0
        .word 691, 694, 695, 0
        .word 691, 695, 693, 0
        .word 696, 697, 690, 0
        .word 690, 697, 694, 0
        .word 689, 696, 690, 0
        .word 697, 698, 694, 0
        .word 694, 698, 699, 0
        .word 694, 699, 695, 0
        .word 695, 699, 700, 0
        .word 695, 700, 701, 0
        .word 693, 695, 701, 0
        .word 701, 700, 702, 0
        .word 703, 701, 704, 0
        .word 701, 702, 704, 0
        .word 693, 701, 703, 0
        .word 704, 702, 705, 0
        .word 703, 704, 706, 0
        .word 704, 705, 707, 0
        .word 706, 704, 707, 0
        .word 692, 693, 703, 0
        .word 692, 703, 708, 0
        .word 708, 703, 706, 0
        .word 706, 707, 709, 0
        .word 708, 706, 710, 0
        .word 710, 706, 709, 0
        .word 709, 707, 223, 0
        .word 707, 705, 228, 0
        .word 707, 228, 223, 0
        .word 709, 223, 220, 0
        .word 711, 709, 220, 0
        .word 710, 709, 711, 0
        .word 712, 708, 710, 0
        .word 712, 710, 713, 0
        .word 713, 710, 711, 0
        .word 714, 711, 219, 0
        .word 711, 220, 219, 0
        .word 713, 711, 714, 0
        .word 715, 712, 713, 0
        .word 715, 713, 716, 0
        .word 716, 713, 714, 0
        .word 717, 718, 712, 0
        .word 717, 712, 715, 0
        .word 718, 708, 712, 0
        .word 719, 717, 715, 0
        .word 719, 715, 720, 0
        .word 720, 715, 716, 0
        .word 720, 716, 721, 0
        .word 716, 714, 722, 0
        .word 721, 716, 722, 0
        .word 723, 720, 721, 0
        .word 724, 719, 720, 0
        .word 724, 720, 723, 0
        .word 725, 717, 719, 0
        .word 726, 725, 719, 0
        .word 726, 719, 724, 0
        .word 727, 726, 724, 0
        .word 727, 724, 728, 0
        .word 728, 724, 723, 0
        .word 729, 723, 730, 0
        .word 723, 721, 730, 0
        .word 728, 723, 729, 0
        .word 727, 728, 731, 0
        .word 728, 729, 732, 0
        .word 728, 732, 731, 0
        .word 729, 733, 734, 0
        .word 729, 734, 732, 0
        .word 729, 730, 733, 0
        .word 730, 721, 735, 0
        .word 730, 735, 736, 0
        .word 733, 730, 736, 0
        .word 733, 737, 738, 0
        .word 733, 738, 734, 0
        .word 733, 736, 737, 0
        .word 734, 738, 739, 0
        .word 734, 739, 740, 0
        .word 732, 734, 740, 0
        .word 139, 739, 738, 0
        .word 139, 738, 143, 0
        .word 143, 738, 737, 0
        .word 143, 737, 237, 0
        .word 737, 736, 238, 0
        .word 737, 238, 237, 0
        .word 736, 230, 238, 0
        .word 736, 735, 230, 0
        .word 735, 216, 230, 0
        .word 735, 722, 216, 0
        .word 722, 217, 216, 0
        .word 721, 722, 735, 0
        .word 722, 714, 217, 0
        .word 714, 219, 217, 0
        .word 137, 739, 139, 0
        .word 136, 741, 137, 0
        .word 137, 741, 739, 0
        .word 740, 739, 741, 0
        .word 740, 741, 742, 0
        .word 742, 741, 743, 0
        .word 136, 743, 741, 0
        .word 136, 133, 744, 0
        .word 136, 744, 743, 0
        .word 745, 746, 743, 0
        .word 745, 743, 744, 0
        .word 742, 743, 746, 0
        .word 747, 740, 742, 0
        .word 747, 742, 748, 0
        .word 748, 742, 746, 0
        .word 732, 740, 747, 0
        .word 731, 732, 747, 0
        .word 731, 747, 749, 0
        .word 749, 747, 748, 0
        .word 749, 748, 750, 0
        .word 750, 748, 751, 0
        .word 748, 746, 751, 0
        .word 752, 751, 746, 0
        .word 752, 746, 745, 0
        .word 753, 754, 751, 0
        .word 753, 751, 752, 0
        .word 750, 751, 754, 0
        .word 755, 749, 750, 0
        .word 755, 750, 756, 0
        .word 756, 750, 754, 0
        .word 757, 731, 749, 0
        .word 757, 749, 755, 0
        .word 727, 731, 757, 0
        .word 758, 727, 757, 0
        .word 759, 758, 757, 0
        .word 759, 757, 755, 0
        .word 759, 755, 760, 0
        .word 755, 756, 761, 0
        .word 755, 761, 760, 0
        .word 762, 759, 763, 0
        .word 759, 760, 763, 0
        .word 762, 758, 759, 0
        .word 762, 669, 758, 0
        .word 669, 764, 758, 0
        .word 758, 764, 727, 0
        .word 764, 726, 727, 0
        .word 669, 668, 764, 0
        .word 668, 676, 764, 0
        .word 764, 676, 726, 0
        .word 661, 669, 762, 0
        .word 762, 763, 662, 0
        .word 661, 762, 662, 0
        .word 662, 763, 765, 0
        .word 662, 765, 653, 0
        .word 653, 765, 654, 0
        .word 765, 766, 767, 0
        .word 765, 767, 654, 0
        .word 763, 766, 765, 0
        .word 654, 767, 768, 0
        .word 654, 768, 645, 0
        .word 766, 769, 767, 0
        .word 767, 769, 770, 0
        .word 767, 770, 768, 0
        .word 768, 770, 771, 0
        .word 768, 771, 646, 0
        .word 645, 768, 646, 0
        .word 769, 772, 770, 0
        .word 770, 772, 773, 0
        .word 770, 773, 771, 0
        .word 766, 774, 769, 0
        .word 774, 775, 769, 0
        .word 769, 775, 772, 0
        .word 776, 777, 772, 0
        .word 776, 772, 775, 0
        .word 777, 773, 772, 0
        .word 778, 779, 773, 0
        .word 777, 778, 773, 0
        .word 771, 773, 779, 0
        .word 780, 781, 777, 0
        .word 780, 777, 776, 0
        .word 781, 778, 777, 0
        .word 782, 780, 776, 0
        .word 782, 776, 783, 0
        .word 783, 776, 775, 0
        .word 784, 781, 780, 0
        .word 785, 784, 780, 0
        .word 785, 780, 782, 0
        .word 784, 786, 781, 0
        .word 781, 787, 778, 0
        .word 786, 787, 781, 0
        .word 788, 789, 784, 0
        .word 788, 784, 785, 0
        .word 789, 786, 784, 0
        .word 790, 788, 785, 0
        .word 790, 785, 791, 0
        .word 791, 785, 782, 0
        .word 792, 789, 788, 0
        .word 793, 792, 788, 0
        .word 793, 788, 790, 0
        .word 794, 795, 789, 0
        .word 792, 794, 789, 0
        .word 789, 795, 786, 0
        .word 796, 794, 792, 0
        .word 797, 796, 792, 0
        .word 797, 792, 793, 0
        .word 798, 797, 793, 0
        .word 798, 793, 799, 0
        .word 799, 793, 790, 0
        .word 800, 796, 797, 0
        .word 801, 800, 797, 0
        .word 801, 797, 798, 0
        .word 802, 803, 796, 0
        .word 796, 803, 794, 0
        .word 800, 802, 796, 0
        .word 579, 580, 800, 0
        .word 579, 800, 801, 0
        .word 580, 802, 800, 0
        .word 579, 801, 804, 0
        .word 801, 798, 805, 0
        .word 801, 805, 804, 0
        .word 579, 804, 577, 0
        .word 804, 805, 806, 0
        .word 804, 806, 807, 0
        .word 577, 804, 807, 0
        .word 798, 808, 805, 0
        .word 805, 808, 809, 0
        .word 805, 809, 806, 0
        .word 807, 806, 810, 0
        .word 806, 809, 811, 0
        .word 806, 811, 810, 0
        .word 577, 807, 576, 0
        .word 576, 807, 812, 0
        .word 807, 810, 812, 0
        .word 812, 810, 813, 0
        .word 810, 811, 814, 0
        .word 810, 814, 813, 0
        .word 809, 815, 811, 0
        .word 811, 815, 816, 0
        .word 811, 816, 814, 0
        .word 813, 814, 817, 0
        .word 814, 816, 818, 0
        .word 814, 818, 817, 0
        .word 813, 817, 819, 0
        .word 820, 813, 819, 0
        .word 812, 813, 820, 0
        .word 817, 818, 821, 0
        .word 817, 821, 822, 0
        .word 819, 817, 822, 0
        .word 816, 823, 818, 0
        .word 818, 823, 824, 0
        .word 818, 824, 821, 0
        .word 822, 821, 825, 0
        .word 821, 824, 826, 0
        .word 821, 826, 825, 0
        .word 819, 822, 827, 0
        .word 827, 822, 828, 0
        .word 822, 825, 828, 0
        .word 828, 825, 829, 0
        .word 825, 826, 830, 0
        .word 825, 830, 829, 0
        .word 824, 831, 826, 0
        .word 826, 831, 832, 0
        .word 826, 832, 830, 0
        .word 829, 830, 833, 0
        .word 830, 832, 834, 0
        .word 830, 834, 833, 0
        .word 829, 833, 835, 0
        .word 836, 829, 835, 0
        .word 828, 829, 836, 0
        .word 833, 834, 837, 0
        .word 833, 837, 838, 0
        .word 835, 833, 838, 0
        .word 832, 839, 834, 0
        .word 834, 839, 840, 0
        .word 834, 840, 837, 0
        .word 832, 841, 839, 0
        .word 841, 842, 839, 0
        .word 839, 842, 843, 0
        .word 839, 843, 840, 0
        .word 841, 844, 842, 0
        .word 845, 844, 841, 0
        .word 831, 845, 841, 0
        .word 831, 841, 832, 0
        .word 844, 846, 842, 0
        .word 842, 846, 847, 0
        .word 842, 847, 843, 0
        .word 844, 848, 846, 0
        .word 845, 849, 844, 0
        .word 849, 848, 844, 0
        .word 848, 850, 846, 0
        .word 846, 850, 851, 0
        .word 846, 851, 847, 0
        .word 848, 852, 850, 0
        .word 853, 852, 848, 0
        .word 849, 853, 848, 0
        .word 854, 855, 849, 0
        .word 854, 849, 845, 0
        .word 855, 853, 849, 0
        .word 855, 856, 853, 0
        .word 856, 857, 853, 0
        .word 853, 857, 852, 0
        .word 858, 859, 855, 0
        .word 858, 855, 854, 0
        .word 859, 856, 855, 0
        .word 860, 861, 856, 0
        .word 859, 860, 856, 0
        .word 856, 861, 857, 0
        .word 861, 566, 857, 0
        .word 857, 566, 567, 0
        .word 857, 567, 852, 0
        .word 860, 862, 861, 0
        .word 862, 564, 861, 0
        .word 861, 564, 566, 0
        .word 863, 864, 862, 0
        .word 863, 862, 860, 0
        .word 864, 563, 862, 0
        .word 862, 563, 564, 0
        .word 865, 863, 860, 0
        .word 866, 864, 863, 0
        .word 867, 866, 863, 0
        .word 867, 863, 865, 0
        .word 864, 511, 563, 0
        .word 868, 511, 864, 0
        .word 866, 868, 864, 0
        .word 869, 870, 866, 0
        .word 869, 866, 867, 0
        .word 870, 868, 866, 0
        .word 871, 869, 867, 0
        .word 871, 867, 872, 0
        .word 872, 867, 865, 0
        .word 871, 873, 869, 0
        .word 869, 873, 874, 0
        .word 869, 874, 870, 0
        .word 870, 874, 875, 0
        .word 870, 875, 876, 0
        .word 870, 876, 868, 0
        .word 873, 877, 874, 0
        .word 874, 877, 878, 0
        .word 874, 878, 875, 0
        .word 879, 880, 873, 0
        .word 871, 879, 873, 0
        .word 873, 880, 877, 0
        .word 880, 745, 877, 0
        .word 877, 745, 744, 0
        .word 877, 744, 878, 0
        .word 133, 130, 878, 0
        .word 133, 878, 744, 0
        .word 130, 875, 878, 0
        .word 130, 131, 875, 0
        .word 131, 505, 876, 0
        .word 131, 876, 875, 0
        .word 876, 505, 507, 0
        .word 876, 507, 868, 0
        .word 868, 507, 511, 0
        .word 880, 752, 745, 0
        .word 881, 753, 752, 0
        .word 881, 752, 880, 0
        .word 882, 883, 881, 0
        .word 882, 881, 879, 0
        .word 879, 881, 880, 0
        .word 883, 753, 881, 0
        .word 883, 884, 753, 0
        .word 884, 754, 753, 0
        .word 885, 886, 883, 0
        .word 883, 886, 887, 0
        .word 883, 887, 884, 0
        .word 885, 883, 882, 0
        .word 884, 887, 888, 0
        .word 884, 888, 889, 0
        .word 884, 889, 754, 0
        .word 756, 754, 889, 0
        .word 756, 889, 888, 0
        .word 887, 890, 888, 0
        .word 756, 888, 761, 0
        .word 761, 888, 890, 0
        .word 886, 783, 887, 0
        .word 887, 783, 890, 0
        .word 783, 775, 890, 0
        .word 774, 890, 775, 0
        .word 761, 890, 774, 0
        .word 760, 761, 774, 0
        .word 760, 774, 766, 0
        .word 763, 760, 766, 0
        .word 886, 782, 783, 0
        .word 791, 782, 886, 0
        .word 885, 791, 886, 0
        .word 891, 790, 791, 0
        .word 891, 791, 885, 0
        .word 891, 885, 892, 0
        .word 885, 882, 892, 0
        .word 799, 790, 891, 0
        .word 799, 891, 893, 0
        .word 891, 892, 893, 0
        .word 892, 882, 894, 0
        .word 892, 894, 895, 0
        .word 893, 892, 895, 0
        .word 894, 882, 879, 0
        .word 894, 879, 871, 0
        .word 895, 894, 896, 0
        .word 894, 871, 872, 0
        .word 894, 872, 896, 0
        .word 893, 895, 897, 0
        .word 897, 895, 898, 0
        .word 895, 896, 898, 0
        .word 898, 896, 899, 0
        .word 896, 872, 900, 0
        .word 896, 900, 899, 0
        .word 872, 865, 900, 0
        .word 899, 900, 858, 0
        .word 900, 865, 859, 0
        .word 900, 859, 858, 0
        .word 899, 858, 901, 0
        .word 902, 899, 901, 0
        .word 898, 899, 902, 0
        .word 897, 898, 815, 0
        .word 815, 898, 902, 0
        .word 816, 902, 823, 0
        .word 902, 901, 823, 0
        .word 815, 902, 816, 0
        .word 901, 858, 854, 0
        .word 901, 854, 903, 0
        .word 823, 901, 903, 0
        .word 823, 903, 824, 0
        .word 903, 854, 845, 0
        .word 903, 845, 831, 0
        .word 824, 903, 831, 0
        .word 809, 897, 815, 0
        .word 808, 897, 809, 0
        .word 808, 893, 897, 0
        .word 798, 799, 808, 0
        .word 799, 893, 808, 0
        .word 865, 860, 859, 0
        .word 852, 567, 570, 0
        .word 852, 570, 850, 0
        .word 850, 570, 575, 0
        .word 850, 575, 851, 0
        .word 835, 838, 904, 0
        .word 836, 835, 905, 0
        .word 905, 835, 904, 0
        .word 905, 904, 906, 0
        .word 907, 836, 905, 0
        .word 907, 905, 908, 0
        .word 908, 905, 906, 0
        .word 909, 828, 836, 0
        .word 909, 836, 907, 0
        .word 910, 907, 908, 0
        .word 911, 909, 907, 0
        .word 911, 907, 910, 0
        .word 910, 908, 912, 0
        .word 912, 908, 913, 0
        .word 908, 906, 913, 0
        .word 543, 910, 912, 0
        .word 544, 911, 910, 0
        .word 544, 910, 543, 0
        .word 90, 914, 911, 0
        .word 90, 911, 544, 0
        .word 914, 909, 911, 0
        .word 87, 914, 90, 0
        .word 915, 827, 914, 0
        .word 87, 915, 914, 0
        .word 914, 827, 909, 0
        .word 85, 915, 87, 0
        .word 85, 820, 915, 0
        .word 820, 819, 915, 0
        .word 915, 819, 827, 0
        .word 827, 828, 909, 0
        .word 84, 812, 820, 0
        .word 84, 820, 85, 0
        .word 576, 812, 84, 0
        .word 543, 912, 541, 0
        .word 912, 913, 916, 0
        .word 541, 912, 916, 0
        .word 541, 916, 542, 0
        .word 581, 917, 802, 0
        .word 802, 917, 803, 0
        .word 580, 581, 802, 0
        .word 581, 61, 917, 0
        .word 61, 918, 917, 0
        .word 917, 918, 919, 0
        .word 917, 919, 803, 0
        .word 803, 919, 920, 0
        .word 803, 920, 794, 0
        .word 918, 921, 919, 0
        .word 919, 921, 922, 0
        .word 919, 922, 920, 0
        .word 61, 57, 918, 0
        .word 57, 923, 918, 0
        .word 918, 923, 921, 0
        .word 923, 924, 921, 0
        .word 921, 924, 925, 0
        .word 921, 925, 922, 0
        .word 922, 925, 926, 0
        .word 922, 926, 927, 0
        .word 920, 922, 927, 0
        .word 924, 928, 925, 0
        .word 925, 928, 929, 0
        .word 925, 929, 926, 0
        .word 924, 930, 928, 0
        .word 931, 930, 924, 0
        .word 923, 931, 924, 0
        .word 930, 599, 928, 0
        .word 928, 599, 608, 0
        .word 928, 608, 929, 0
        .word 926, 929, 932, 0
        .word 929, 608, 609, 0
        .word 929, 609, 932, 0
        .word 926, 932, 933, 0
        .word 932, 609, 618, 0
        .word 932, 618, 934, 0
        .word 933, 932, 934, 0
        .word 933, 934, 935, 0
        .word 927, 926, 933, 0
        .word 927, 933, 936, 0
        .word 936, 933, 935, 0
        .word 935, 934, 937, 0
        .word 934, 618, 619, 0
        .word 934, 619, 937, 0
        .word 935, 937, 938, 0
        .word 787, 935, 938, 0
        .word 936, 935, 787, 0
        .word 795, 927, 936, 0
        .word 795, 936, 786, 0
        .word 786, 936, 787, 0
        .word 920, 927, 795, 0
        .word 794, 920, 795, 0
        .word 787, 938, 778, 0
        .word 778, 938, 779, 0
        .word 938, 937, 939, 0
        .word 938, 939, 779, 0
        .word 940, 779, 939, 0
        .word 771, 779, 940, 0
        .word 937, 628, 939, 0
        .word 940, 939, 629, 0
        .word 629, 939, 628, 0
        .word 638, 940, 629, 0
        .word 646, 771, 940, 0
        .word 646, 940, 638, 0
        .word 937, 619, 628, 0
        .word 930, 598, 599, 0
        .word 941, 598, 930, 0
        .word 931, 941, 930, 0
        .word 941, 589, 598, 0
        .word 54, 454, 941, 0
        .word 54, 941, 931, 0
        .word 454, 589, 941, 0
        .word 55, 54, 931, 0
        .word 55, 931, 923, 0
        .word 57, 55, 923, 0
        .word 454, 453, 589, 0
        .word 676, 725, 726, 0
        .word 676, 677, 725, 0
        .word 725, 685, 717, 0
        .word 677, 685, 725, 0
        .word 685, 684, 718, 0
        .word 685, 718, 717, 0
        .word 684, 692, 718, 0
        .word 718, 692, 708, 0
        .word 697, 942, 698, 0
        .word 696, 943, 697, 0
        .word 943, 942, 697, 0
        .word 943, 944, 942, 0
        .word 945, 944, 943, 0
        .word 946, 945, 943, 0
        .word 946, 943, 696, 0
        .word 947, 946, 696, 0
        .word 947, 696, 689, 0
        .word 948, 945, 946, 0
        .word 949, 948, 946, 0
        .word 949, 946, 947, 0
        .word 948, 950, 945, 0
        .word 950, 951, 945, 0
        .word 945, 951, 944, 0
        .word 952, 950, 948, 0
        .word 953, 952, 948, 0
        .word 953, 948, 949, 0
        .word 954, 949, 947, 0
        .word 955, 953, 949, 0
        .word 955, 949, 954, 0
        .word 246, 244, 953, 0
        .word 246, 953, 955, 0
        .word 244, 952, 953, 0
        .word 242, 956, 952, 0
        .word 952, 956, 950, 0
        .word 244, 242, 952, 0
        .word 242, 241, 956, 0
        .word 241, 957, 956, 0
        .word 956, 957, 958, 0
        .word 956, 958, 950, 0
        .word 241, 240, 957, 0
        .word 950, 958, 951, 0
        .word 251, 246, 955, 0
        .word 251, 955, 959, 0
        .word 959, 955, 954, 0
        .word 504, 251, 959, 0
        .word 504, 959, 960, 0
        .word 959, 954, 961, 0
        .word 960, 959, 961, 0
        .word 961, 954, 688, 0
        .word 954, 947, 688, 0
        .word 680, 961, 681, 0
        .word 961, 688, 681, 0
        .word 960, 961, 680, 0
        .word 503, 504, 960, 0
        .word 503, 960, 962, 0
        .word 962, 960, 680, 0
        .word 962, 680, 673, 0
        .word 502, 503, 962, 0
        .word 502, 962, 672, 0
        .word 672, 962, 673, 0
        .word 500, 502, 672, 0
        .word 500, 672, 665, 0
        .word 499, 500, 665, 0
        .word 499, 658, 495, 0
        .word 495, 658, 657, 0
        .word 495, 657, 493, 0
        .word 493, 657, 963, 0
        .word 657, 649, 963, 0
        .word 493, 963, 491, 0
        .word 963, 649, 650, 0
        .word 963, 650, 964, 0
        .word 491, 963, 964, 0
        .word 491, 964, 490, 0
        .word 490, 964, 965, 0
        .word 964, 650, 966, 0
        .word 964, 966, 965, 0
        .word 650, 642, 966, 0
        .word 965, 966, 967, 0
        .word 966, 642, 641, 0
        .word 966, 641, 967, 0
        .word 490, 965, 285, 0
        .word 965, 967, 968, 0
        .word 285, 965, 968, 0
        .word 967, 641, 969, 0
        .word 967, 969, 970, 0
        .word 968, 967, 970, 0
        .word 641, 634, 969, 0
        .word 969, 634, 635, 0
        .word 969, 635, 971, 0
        .word 970, 969, 971, 0
        .word 970, 971, 972, 0
        .word 968, 970, 973, 0
        .word 973, 970, 972, 0
        .word 286, 968, 973, 0
        .word 285, 968, 286, 0
        .word 286, 973, 288, 0
        .word 973, 972, 974, 0
        .word 288, 973, 974, 0
        .word 972, 971, 975, 0
        .word 972, 975, 976, 0
        .word 974, 972, 976, 0
        .word 971, 635, 977, 0
        .word 971, 977, 975, 0
        .word 635, 633, 977, 0
        .word 977, 633, 978, 0
        .word 977, 978, 979, 0
        .word 975, 977, 979, 0
        .word 975, 979, 980, 0
        .word 976, 975, 980, 0
        .word 976, 980, 981, 0
        .word 974, 976, 982, 0
        .word 982, 976, 981, 0
        .word 981, 980, 983, 0
        .word 980, 979, 984, 0
        .word 980, 984, 983, 0
        .word 979, 978, 985, 0
        .word 979, 985, 984, 0
        .word 983, 984, 986, 0
        .word 984, 985, 987, 0
        .word 984, 987, 986, 0
        .word 981, 983, 988, 0
        .word 983, 986, 989, 0
        .word 988, 983, 989, 0
        .word 989, 986, 990, 0
        .word 986, 987, 991, 0
        .word 986, 991, 990, 0
        .word 985, 992, 987, 0
        .word 987, 992, 993, 0
        .word 987, 993, 991, 0
        .word 991, 993, 994, 0
        .word 991, 994, 995, 0
        .word 990, 991, 995, 0
        .word 989, 990, 996, 0
        .word 996, 990, 997, 0
        .word 990, 995, 997, 0
        .word 997, 995, 998, 0
        .word 995, 994, 999, 0
        .word 995, 999, 998, 0
        .word 993, 1000, 994, 0
        .word 994, 1000, 1001, 0
        .word 994, 1001, 999, 0
        .word 998, 999, 1002, 0
        .word 999, 1001, 1003, 0
        .word 999, 1003, 1002, 0
        .word 997, 998, 1004, 0
        .word 998, 1002, 1005, 0
        .word 1004, 998, 1005, 0
        .word 1005, 1002, 1006, 0
        .word 1002, 1003, 1007, 0
        .word 1002, 1007, 1006, 0
        .word 1001, 1008, 1003, 0
        .word 1003, 1008, 1009, 0
        .word 1003, 1009, 1007, 0
        .word 1007, 1009, 1010, 0
        .word 1007, 1010, 1011, 0
        .word 1006, 1007, 1011, 0
        .word 1005, 1006, 1012, 0
        .word 1012, 1006, 1013, 0
        .word 1006, 1011, 1013, 0
        .word 1013, 1011, 1014, 0
        .word 1011, 1010, 1015, 0
        .word 1011, 1015, 1014, 0
        .word 1016, 1015, 1010, 0
        .word 1017, 1016, 1010, 0
        .word 1017, 1010, 1009, 0
        .word 1018, 443, 1015, 0
        .word 1016, 1018, 1015, 0
        .word 1014, 1015, 443, 0
        .word 1013, 1014, 1019, 0
        .word 1014, 443, 442, 0
        .word 1019, 1014, 442, 0
        .word 1018, 444, 443, 0
        .word 1020, 1021, 1018, 0
        .word 1020, 1018, 1016, 0
        .word 1021, 444, 1018, 0
        .word 1021, 431, 444, 0
        .word 1022, 431, 1021, 0
        .word 1023, 1022, 1021, 0
        .word 1023, 1021, 1020, 0
        .word 1024, 1023, 1020, 0
        .word 1024, 1020, 1025, 0
        .word 1025, 1020, 1016, 0
        .word 1026, 1027, 1023, 0
        .word 1026, 1023, 1024, 0
        .word 1027, 1022, 1023, 0
        .word 1028, 1026, 1024, 0
        .word 1028, 1024, 1029, 0
        .word 1029, 1024, 1025, 0
        .word 1029, 1025, 1030, 0
        .word 1030, 1025, 1017, 0
        .word 1025, 1016, 1017, 0
        .word 1031, 1028, 1029, 0
        .word 1031, 1029, 1032, 0
        .word 1032, 1029, 1030, 0
        .word 1033, 1026, 1028, 0
        .word 1033, 1028, 1031, 0
        .word 1034, 1033, 1031, 0
        .word 1034, 1031, 1035, 0
        .word 1035, 1031, 1032, 0
        .word 1035, 1032, 1036, 0
        .word 1032, 1030, 1037, 0
        .word 1036, 1032, 1037, 0
        .word 1038, 1034, 1035, 0
        .word 1038, 1035, 1039, 0
        .word 1039, 1035, 1036, 0
        .word 1040, 1033, 1034, 0
        .word 1041, 1040, 1034, 0
        .word 1041, 1034, 1038, 0
        .word 585, 1041, 1038, 0
        .word 585, 1038, 593, 0
        .word 593, 1038, 1039, 0
        .word 593, 1039, 594, 0
        .word 594, 1039, 1042, 0
        .word 1039, 1036, 1042, 0
        .word 594, 1042, 603, 0
        .word 1042, 1036, 1043, 0
        .word 1042, 1043, 1044, 0
        .word 603, 1042, 1044, 0
        .word 603, 1044, 604, 0
        .word 604, 1044, 1045, 0
        .word 1044, 1043, 1046, 0
        .word 1044, 1046, 1045, 0
        .word 1036, 1037, 1043, 0
        .word 1043, 1037, 1047, 0
        .word 1043, 1047, 1046, 0
        .word 1045, 1046, 1048, 0
        .word 1046, 1047, 1049, 0
        .word 1046, 1049, 1048, 0
        .word 1037, 1050, 1047, 0
        .word 1047, 1050, 1008, 0
        .word 1047, 1008, 1049, 0
        .word 1037, 1030, 1050, 0
        .word 1030, 1017, 1050, 0
        .word 1050, 1017, 1009, 0
        .word 1050, 1009, 1008, 0
        .word 1001, 1049, 1008, 0
        .word 1000, 1048, 1049, 0
        .word 1000, 1049, 1001, 0
        .word 1051, 1048, 1000, 0
        .word 993, 1051, 1000, 0
        .word 992, 1052, 1051, 0
        .word 992, 1051, 993, 0
        .word 1052, 1053, 1051, 0
        .word 1051, 1053, 1048, 0
        .word 1054, 1052, 992, 0
        .word 985, 1054, 992, 0
        .word 623, 614, 1052, 0
        .word 1054, 623, 1052, 0
        .word 1052, 614, 1053, 0
        .word 1045, 1048, 1053, 0
        .word 613, 1045, 1053, 0
        .word 613, 1053, 614, 0
        .word 604, 1045, 613, 0
        .word 624, 623, 1054, 0
        .word 978, 624, 1054, 0
        .word 978, 1054, 985, 0
        .word 633, 624, 978, 0
        .word 584, 1041, 585, 0
        .word 419, 1055, 584, 0
        .word 584, 1055, 1041, 0
        .word 1055, 1040, 1041, 0
        .word 419, 420, 1055, 0
        .word 420, 1056, 1055, 0
        .word 1055, 1056, 1040, 0
        .word 1056, 1057, 1040, 0
        .word 1040, 1057, 1033, 0
        .word 420, 422, 1056, 0
        .word 422, 1058, 1056, 0
        .word 1056, 1058, 1057, 0
        .word 1058, 1027, 1057, 0
        .word 1057, 1027, 1026, 0
        .word 1057, 1026, 1033, 0
        .word 422, 423, 1058, 0
        .word 423, 1059, 1058, 0
        .word 1058, 1059, 1027, 0
        .word 1027, 1059, 1022, 0
        .word 423, 424, 1059, 0
        .word 1059, 424, 426, 0
        .word 1059, 426, 1022, 0
        .word 1022, 426, 431, 0
        .word 1019, 442, 441, 0
        .word 1060, 1013, 1019, 0
        .word 1060, 1019, 1061, 0
        .word 1061, 1019, 441, 0
        .word 1061, 441, 350, 0
        .word 1062, 1060, 1061, 0
        .word 1062, 1061, 1063, 0
        .word 1063, 1061, 350, 0
        .word 1012, 1013, 1060, 0
        .word 1064, 1012, 1060, 0
        .word 1064, 1060, 1062, 0
        .word 1065, 1066, 1062, 0
        .word 1065, 1062, 1063, 0
        .word 1066, 1064, 1062, 0
        .word 338, 1065, 1063, 0
        .word 338, 1063, 348, 0
        .word 1063, 350, 348, 0
        .word 337, 1067, 1065, 0
        .word 337, 1065, 338, 0
        .word 1067, 1066, 1065, 0
        .word 1067, 1068, 1066, 0
        .word 1068, 1069, 1066, 0
        .word 1066, 1069, 1064, 0
        .word 1070, 1068, 1067, 0
        .word 340, 1070, 1067, 0
        .word 340, 1067, 337, 0
        .word 1070, 1071, 1068, 0
        .word 1068, 1072, 1069, 0
        .word 1071, 1072, 1068, 0
        .word 1072, 1004, 1069, 0
        .word 1069, 1004, 1073, 0
        .word 1069, 1073, 1064, 0
        .word 1072, 997, 1004, 0
        .word 996, 997, 1072, 0
        .word 1071, 996, 1072, 0
        .word 1004, 1005, 1073, 0
        .word 1073, 1005, 1012, 0
        .word 1073, 1012, 1064, 0
        .word 1074, 989, 996, 0
        .word 1074, 996, 1071, 0
        .word 1075, 988, 1074, 0
        .word 1075, 1074, 1076, 0
        .word 1076, 1074, 1071, 0
        .word 988, 989, 1074, 0
        .word 346, 1077, 1075, 0
        .word 346, 1075, 345, 0
        .word 1077, 988, 1075, 0
        .word 345, 1075, 1076, 0
        .word 1077, 981, 988, 0
        .word 982, 981, 1077, 0
        .word 347, 982, 1077, 0
        .word 347, 1077, 346, 0
        .word 291, 974, 982, 0
        .word 291, 982, 347, 0
        .word 288, 974, 291, 0
        .word 345, 1076, 342, 0
        .word 342, 1076, 1070, 0
        .word 1076, 1071, 1070, 0
        .word 342, 1070, 340, 0
        .word 688, 947, 689, 0
        .word 851, 575, 1078, 0
        .word 851, 1078, 1079, 0
        .word 847, 851, 1079, 0
        .word 575, 571, 1080, 0
        .word 575, 1080, 1078, 0
        .word 1078, 1080, 1081, 0
        .word 1078, 1081, 1082, 0
        .word 1079, 1078, 1082, 0
        .word 1079, 1082, 1083, 0
        .word 847, 1079, 1084, 0
        .word 1084, 1079, 1083, 0
        .word 843, 847, 1084, 0
        .word 843, 1084, 1085, 0
        .word 1084, 1083, 1086, 0
        .word 1085, 1084, 1086, 0
        .word 840, 843, 1085, 0
        .word 1085, 1086, 1087, 0
        .word 840, 1085, 1088, 0
        .word 1088, 1085, 1087, 0
        .word 1087, 1086, 1089, 0
        .word 1083, 1089, 1086, 0
        .word 1088, 1087, 1090, 0
        .word 1087, 1089, 1091, 0
        .word 1087, 1091, 1092, 0
        .word 1087, 1092, 1090, 0
        .word 837, 840, 1088, 0
        .word 837, 1088, 1093, 0
        .word 1093, 1088, 1090, 0
        .word 1093, 1090, 1094, 0
        .word 1094, 1090, 1092, 0
        .word 1094, 1092, 1095, 0
        .word 1096, 1095, 1092, 0
        .word 1096, 1092, 1091, 0
        .word 1096, 1091, 1089, 0
        .word 1096, 1097, 1098, 0
        .word 1096, 1098, 1099, 0
        .word 1096, 1100, 1101, 0
        .word 1096, 1101, 1097, 0
        .word 1096, 1102, 1103, 0
        .word 1096, 1103, 1104, 0
        .word 1096, 1105, 1106, 0
        .word 1096, 1106, 1107, 0
        .word 1096, 1108, 1109, 0
        .word 1096, 1109, 1100, 0
        .word 1096, 1104, 1110, 0
        .word 1096, 1110, 1095, 0
        .word 1096, 1107, 1111, 0
        .word 1096, 1111, 1102, 0
        .word 1096, 1089, 1112, 0
        .word 1096, 1099, 1113, 0
        .word 1096, 1113, 1105, 0
        .word 1096, 1112, 1114, 0
        .word 1096, 1114, 1108, 0
        .word 1094, 1095, 1110, 0
        .word 1115, 1093, 1094, 0
        .word 1115, 1094, 1116, 0
        .word 1094, 1110, 1116, 0
        .word 904, 838, 1115, 0
        .word 904, 1115, 1117, 0
        .word 838, 1093, 1115, 0
        .word 1117, 1115, 1116, 0
        .word 838, 837, 1093, 0
        .word 1117, 1116, 1118, 0
        .word 1118, 1116, 1110, 0
        .word 1118, 1110, 1104, 0
        .word 1119, 1117, 1118, 0
        .word 1119, 1118, 1120, 0
        .word 1118, 1104, 1103, 0
        .word 1118, 1103, 1120, 0
        .word 906, 904, 1117, 0
        .word 906, 1117, 1119, 0
        .word 913, 906, 1119, 0
        .word 913, 1119, 1121, 0
        .word 1121, 1119, 1120, 0
        .word 1121, 1120, 1122, 0
        .word 1122, 1120, 1103, 0
        .word 1122, 1103, 1102, 0
        .word 1123, 1121, 1122, 0
        .word 1123, 1122, 1124, 0
        .word 1122, 1102, 1111, 0
        .word 1122, 1111, 1124, 0
        .word 916, 913, 1121, 0
        .word 916, 1121, 1123, 0
        .word 542, 916, 1123, 0
        .word 542, 1123, 1125, 0
        .word 1125, 1123, 1124, 0
        .word 1125, 1124, 1126, 0
        .word 1126, 1124, 1111, 0
        .word 1126, 1111, 1107, 0
        .word 1127, 1125, 1126, 0
        .word 1127, 1126, 1128, 0
        .word 1126, 1107, 1106, 0
        .word 1126, 1106, 1128, 0
        .word 540, 542, 1125, 0
        .word 540, 1125, 1127, 0
        .word 539, 540, 1127, 0
        .word 539, 1127, 1129, 0
        .word 1129, 1127, 1128, 0
        .word 1129, 1128, 1130, 0
        .word 1130, 1128, 1106, 0
        .word 1130, 1106, 1105, 0
        .word 1131, 1129, 1130, 0
        .word 1131, 1130, 1132, 0
        .word 1130, 1105, 1113, 0
        .word 1130, 1113, 1132, 0
        .word 545, 539, 1129, 0
        .word 545, 1129, 1131, 0
        .word 546, 545, 1131, 0
        .word 546, 1131, 1133, 0
        .word 1133, 1131, 1132, 0
        .word 1133, 1132, 1134, 0
        .word 1134, 1132, 1113, 0
        .word 1134, 1113, 1099, 0
        .word 1135, 1133, 1134, 0
        .word 1135, 1134, 1136, 0
        .word 1134, 1099, 1098, 0
        .word 1134, 1098, 1136, 0
        .word 548, 546, 1133, 0
        .word 548, 1133, 1135, 0
        .word 553, 548, 1135, 0
        .word 553, 1135, 1137, 0
        .word 1137, 1135, 1136, 0
        .word 1137, 1136, 1138, 0
        .word 1138, 1136, 1098, 0
        .word 1138, 1098, 1097, 0
        .word 1139, 1137, 1138, 0
        .word 1139, 1138, 1140, 0
        .word 1138, 1097, 1101, 0
        .word 1138, 1101, 1140, 0
        .word 574, 553, 1137, 0
        .word 574, 1137, 1139, 0
        .word 573, 574, 1139, 0
        .word 573, 1139, 1141, 0
        .word 1141, 1139, 1140, 0
        .word 1141, 1140, 1142, 0
        .word 1142, 1140, 1101, 0
        .word 1142, 1101, 1100, 0
        .word 1143, 1141, 1142, 0
        .word 1143, 1142, 1144, 0
        .word 1142, 1100, 1109, 0
        .word 1142, 1109, 1144, 0
        .word 572, 573, 1141, 0
        .word 572, 1141, 1143, 0
        .word 571, 572, 1143, 0
        .word 571, 1143, 1080, 0
        .word 1080, 1143, 1144, 0
        .word 1080, 1144, 1081, 0
        .word 1081, 1144, 1109, 0
        .word 1081, 1109, 1108, 0
        .word 1081, 1108, 1114, 0
        .word 1081, 1114, 1082, 0
        .word 1083, 1082, 1114, 0
        .word 1083, 1114, 1112, 0
        .word 1083, 1112, 1089, 0
        .word 705, 1145, 1146, 0
        .word 705, 1146, 228, 0
        .word 702, 1145, 705, 0
        .word 1145, 1147, 1148, 0
        .word 1145, 1148, 1146, 0
        .word 1149, 1147, 1145, 0
        .word 702, 1149, 1145, 0
        .word 1146, 1148, 1150, 0
        .word 1146, 1150, 1151, 0
        .word 228, 1146, 1151, 0
        .word 228, 1151, 224, 0
        .word 224, 1151, 1152, 0
        .word 1151, 1150, 1153, 0
        .word 1151, 1153, 1152, 0
        .word 224, 1152, 225, 0
        .word 1152, 1153, 1154, 0
        .word 1152, 1154, 1155, 0
        .word 225, 1152, 1155, 0
        .word 1150, 1156, 1153, 0
        .word 1154, 1153, 1156, 0
        .word 1155, 1154, 1157, 0
        .word 1154, 1158, 1159, 0
        .word 1154, 1159, 1157, 0
        .word 1154, 1156, 1158, 0
        .word 226, 1155, 1160, 0
        .word 1155, 1157, 1160, 0
        .word 225, 1155, 226, 0
        .word 1160, 1157, 1161, 0
        .word 1161, 1157, 1159, 0
        .word 1162, 1163, 1159, 0
        .word 1162, 1159, 1158, 0
        .word 1161, 1159, 1163, 0
        .word 1162, 1158, 1156, 0
        .word 1162, 1164, 1165, 0
        .word 1162, 1165, 1163, 0
        .word 1162, 1166, 1167, 0
        .word 1162, 1167, 1168, 0
        .word 1162, 1169, 1170, 0
        .word 1162, 1170, 1171, 0
        .word 1162, 1156, 1172, 0
        .word 1162, 1173, 1174, 0
        .word 1162, 1174, 1166, 0
        .word 1162, 1168, 1175, 0
        .word 1162, 1175, 1169, 0
        .word 1162, 1176, 1177, 0
        .word 1162, 1177, 1178, 0
        .word 1162, 1178, 1179, 0
        .word 1162, 1179, 1173, 0
        .word 1162, 1171, 1180, 0
        .word 1162, 1180, 1164, 0
        .word 1162, 1172, 1181, 0
        .word 1162, 1181, 1176, 0
        .word 1147, 1177, 1176, 0
        .word 1147, 1176, 1181, 0
        .word 1147, 1181, 1148, 0
        .word 1150, 1148, 1181, 0
        .word 1150, 1181, 1172, 0
        .word 1149, 1182, 1147, 0
        .word 1147, 1182, 1177, 0
        .word 700, 1183, 1149, 0
        .word 700, 1149, 702, 0
        .word 1183, 1182, 1149, 0
        .word 1183, 1184, 1182, 0
        .word 1184, 1177, 1182, 0
        .word 1185, 1184, 1183, 0
        .word 699, 1185, 1183, 0
        .word 699, 1183, 700, 0
        .word 1185, 1186, 1184, 0
        .word 1184, 1178, 1177, 0
        .word 1184, 1186, 1179, 0
        .word 1184, 1179, 1178, 0
        .word 698, 1187, 1185, 0
        .word 698, 1185, 699, 0
        .word 1187, 1186, 1185, 0
        .word 1187, 1188, 1186, 0
        .word 1188, 1179, 1186, 0
        .word 1188, 1173, 1179, 0
        .word 1189, 1190, 1188, 0
        .word 1189, 1188, 1187, 0
        .word 1188, 1190, 1174, 0
        .word 1188, 1174, 1173, 0
        .word 942, 1189, 1187, 0
        .word 942, 1187, 698, 0
        .word 944, 1191, 1189, 0
        .word 944, 1189, 942, 0
        .word 1191, 1190, 1189, 0
        .word 1191, 1192, 1190, 0
        .word 1192, 1174, 1190, 0
        .word 1192, 1166, 1174, 0
        .word 1193, 1194, 1192, 0
        .word 1193, 1192, 1191, 0
        .word 1192, 1194, 1167, 0
        .word 1192, 1167, 1166, 0
        .word 951, 1193, 1191, 0
        .word 951, 1191, 944, 0
        .word 958, 1195, 1193, 0
        .word 958, 1193, 951, 0
        .word 1195, 1194, 1193, 0
        .word 1195, 1196, 1194, 0
        .word 1196, 1167, 1194, 0
        .word 1196, 1168, 1167, 0
        .word 1197, 1198, 1196, 0
        .word 1197, 1196, 1195, 0
        .word 1196, 1198, 1175, 0
        .word 1196, 1175, 1168, 0
        .word 957, 1197, 1195, 0
        .word 957, 1195, 958, 0
        .word 240, 1199, 1197, 0
        .word 240, 1197, 957, 0
        .word 1199, 1198, 1197, 0
        .word 1199, 1200, 1198, 0
        .word 1200, 1175, 1198, 0
        .word 1200, 1169, 1175, 0
        .word 1201, 1202, 1200, 0
        .word 1201, 1200, 1199, 0
        .word 1200, 1202, 1170, 0
        .word 1200, 1170, 1169, 0
        .word 190, 1201, 1199, 0
        .word 190, 1199, 240, 0
        .word 189, 1203, 1201, 0
        .word 189, 1201, 190, 0
        .word 1203, 1202, 1201, 0
        .word 1203, 1204, 1202, 0
        .word 1204, 1170, 1202, 0
        .word 1204, 1171, 1170, 0
        .word 1205, 1206, 1204, 0
        .word 1205, 1204, 1203, 0
        .word 1204, 1206, 1180, 0
        .word 1204, 1180, 1171, 0
        .word 192, 1205, 1203, 0
        .word 192, 1203, 189, 0
        .word 193, 1207, 1205, 0
        .word 193, 1205, 192, 0
        .word 1207, 1206, 1205, 0
        .word 1207, 1208, 1206, 0
        .word 1208, 1180, 1206, 0
        .word 1208, 1164, 1180, 0
        .word 1209, 1210, 1208, 0
        .word 1209, 1208, 1207, 0
        .word 1208, 1210, 1165, 0
        .word 1208, 1165, 1164, 0
        .word 196, 1209, 1207, 0
        .word 196, 1207, 193, 0
        .word 202, 1211, 1209, 0
        .word 202, 1209, 196, 0
        .word 1211, 1210, 1209, 0
        .word 1211, 1161, 1210, 0
        .word 1161, 1165, 1210, 0
        .word 1161, 1163, 1165, 0
        .word 1160, 1161, 1211, 0
        .word 227, 1160, 1211, 0
        .word 227, 1211, 202, 0
        .word 226, 1160, 227, 0
        .word 1150, 1172, 1156, 0
        .word 1212, 1213, 1214, 0
        .word 1212, 1214, 1215, 0
        .word 1216, 1212, 1215, 0
        .word 1213, 1217, 1218, 0
        .word 1213, 1218, 1214, 0
        .word 1219, 1215, 1214, 0
        .word 1219, 1214, 1220, 0
        .word 1220, 1214, 1218, 0
        .word 1216, 1215, 1221, 0
        .word 1222, 1221, 1215, 0
        .word 1222, 1215, 1219, 0
        .word 1223, 1216, 1221, 0
        .word 1223, 1221, 1224, 0
        .word 1225, 1224, 1221, 0
        .word 1225, 1221, 1222, 0
        .word 1226, 1222, 1219, 0
        .word 1227, 1225, 1222, 0
        .word 1227, 1222, 1226, 0
        .word 1228, 1229, 1225, 0
        .word 1228, 1225, 1227, 0
        .word 1229, 1224, 1225, 0
        .word 1230, 1223, 1224, 0
        .word 1230, 1224, 1231, 0
        .word 1229, 1231, 1224, 0
        .word 1232, 1233, 1229, 0
        .word 1232, 1229, 1228, 0
        .word 1233, 1231, 1229, 0
        .word 1234, 1235, 1228, 0
        .word 1234, 1228, 1227, 0
        .word 1235, 1232, 1228, 0
        .word 1236, 1237, 1232, 0
        .word 1235, 1236, 1232, 0
        .word 1237, 1233, 1232, 0
        .word 1233, 1238, 1231, 0
        .word 1239, 1238, 1233, 0
        .word 1237, 1239, 1233, 0
        .word 1236, 1240, 1237, 0
        .word 1241, 1239, 1237, 0
        .word 1240, 1241, 1237, 0
        .word 1241, 1242, 1239, 0
        .word 1242, 1243, 1239, 0
        .word 1239, 1243, 1238, 0
        .word 1244, 1231, 1238, 0
        .word 1245, 1244, 1238, 0
        .word 1245, 1238, 1243, 0
        .word 1246, 1245, 1243, 0
        .word 1246, 1243, 1247, 0
        .word 1242, 1247, 1243, 0
        .word 1248, 1246, 1247, 0
        .word 1248, 1247, 1249, 0
        .word 1250, 1249, 1247, 0
        .word 1250, 1247, 1242, 0
        .word 1251, 1248, 1249, 0
        .word 1251, 1249, 1252, 0
        .word 1253, 1252, 1249, 0
        .word 1253, 1249, 1250, 0
        .word 1254, 1253, 1250, 0
        .word 1254, 1250, 1255, 0
        .word 1255, 1250, 1242, 0
        .word 1256, 1257, 1253, 0
        .word 1256, 1253, 1254, 0
        .word 1257, 1252, 1253, 0
        .word 1258, 1256, 1254, 0
        .word 1259, 1258, 1254, 0
        .word 1259, 1254, 1255, 0
        .word 1255, 1242, 1241, 0
        .word 1260, 1259, 1255, 0
        .word 1260, 1255, 1241, 0
        .word 1240, 1260, 1241, 0
        .word 1258, 1261, 1256, 0
        .word 1262, 1257, 1256, 0
        .word 1261, 1262, 1256, 0
        .word 1261, 1263, 1262, 0
        .word 1264, 1265, 1262, 0
        .word 1263, 1264, 1262, 0
        .word 1262, 1265, 1257, 0
        .word 1263, 1266, 1264, 0
        .word 1264, 1267, 1265, 0
        .word 1268, 1267, 1264, 0
        .word 1266, 1268, 1264, 0
        .word 1267, 1269, 1265, 0
        .word 1265, 1269, 1270, 0
        .word 1265, 1270, 1257, 0
        .word 1267, 1271, 1269, 0
        .word 1268, 1272, 1267, 0
        .word 1272, 1271, 1267, 0
        .word 1266, 1273, 1268, 0
        .word 1274, 1272, 1268, 0
        .word 1273, 1274, 1268, 0
        .word 1272, 1275, 1271, 0
        .word 1274, 1276, 1272, 0
        .word 1276, 1275, 1272, 0
        .word 1277, 1278, 1271, 0
        .word 1277, 1271, 1275, 0
        .word 1278, 1269, 1271, 0
        .word 1279, 1277, 1275, 0
        .word 1279, 1275, 1280, 0
        .word 1276, 1280, 1275, 0
        .word 1281, 1282, 1276, 0
        .word 1281, 1276, 1274, 0
        .word 1282, 1280, 1276, 0
        .word 1283, 1279, 1280, 0
        .word 1283, 1280, 1284, 0
        .word 1282, 1284, 1280, 0
        .word 1285, 1286, 1282, 0
        .word 1285, 1282, 1281, 0
        .word 1286, 1284, 1282, 0
        .word 1287, 1288, 1281, 0
        .word 1287, 1281, 1274, 0
        .word 1288, 1285, 1281, 0
        .word 1289, 1290, 1285, 0
        .word 1288, 1289, 1285, 0
        .word 1290, 1286, 1285, 0
        .word 1291, 1292, 1286, 0
        .word 1286, 1292, 1284, 0
        .word 1290, 1291, 1286, 0
        .word 1289, 1293, 1290, 0
        .word 1294, 1291, 1290, 0
        .word 1293, 1294, 1290, 0
        .word 1294, 1295, 1291, 0
        .word 1295, 1296, 1291, 0
        .word 1291, 1296, 1292, 0
        .word 1297, 1284, 1292, 0
        .word 1298, 1297, 1292, 0
        .word 1298, 1292, 1296, 0
        .word 1299, 1298, 1296, 0
        .word 1299, 1296, 1300, 0
        .word 1295, 1300, 1296, 0
        .word 1301, 1299, 1300, 0
        .word 1301, 1300, 1302, 0
        .word 1303, 1302, 1300, 0
        .word 1303, 1300, 1295, 0
        .word 1304, 1301, 1302, 0
        .word 1304, 1302, 1305, 0
        .word 1306, 1305, 1302, 0
        .word 1306, 1302, 1303, 0
        .word 1307, 1306, 1303, 0
        .word 1307, 1303, 1308, 0
        .word 1308, 1303, 1295, 0
        .word 1309, 1305, 1306, 0
        .word 1310, 1309, 1306, 0
        .word 1310, 1306, 1307, 0
        .word 1311, 1310, 1307, 0
        .word 1312, 1311, 1307, 0
        .word 1312, 1307, 1308, 0
        .word 1308, 1295, 1294, 0
        .word 1313, 1312, 1308, 0
        .word 1313, 1308, 1294, 0
        .word 1293, 1313, 1294, 0
        .word 1311, 1314, 1310, 0
        .word 1315, 1309, 1310, 0
        .word 1314, 1315, 1310, 0
        .word 1314, 1316, 1315, 0
        .word 1317, 1220, 1315, 0
        .word 1316, 1317, 1315, 0
        .word 1315, 1220, 1309, 0
        .word 1316, 1318, 1317, 0
        .word 1317, 1219, 1220, 0
        .word 1226, 1219, 1317, 0
        .word 1318, 1226, 1317, 0
        .word 1220, 1218, 1309, 0
        .word 1309, 1218, 1305, 0
        .word 1217, 1305, 1218, 0
        .word 1217, 1304, 1305, 0
        .word 1318, 1319, 1226, 0
        .word 1319, 1227, 1226, 0
        .word 1319, 1234, 1227, 0
        .word 1297, 1283, 1284, 0
        .word 1273, 1287, 1274, 0
        .word 1320, 1270, 1269, 0
        .word 1278, 1320, 1269, 0
        .word 1320, 1321, 1270, 0
        .word 1321, 1252, 1270, 0
        .word 1257, 1270, 1252, 0
        .word 1321, 1251, 1252, 0
        .word 1244, 1230, 1231, 0
        .word 1322, 1323, 1324, 0
        .word 1322, 1324, 1325, 0
        .word 1326, 1323, 1322, 0
        .word 1326, 1327, 1323, 0
        .word 1328, 1329, 1323, 0
        .word 1328, 1323, 1327, 0
        .word 1329, 1324, 1323, 0
        .word 1325, 1324, 1330, 0
        .word 1329, 1331, 1324, 0
        .word 1331, 1330, 1324, 0
        .word 1325, 1330, 1332, 0
        .word 1332, 1330, 1333, 0
        .word 1331, 1334, 1330, 0
        .word 1334, 1333, 1330, 0
        .word 1335, 1336, 1331, 0
        .word 1335, 1331, 1329, 0
        .word 1336, 1334, 1331, 0
        .word 1337, 1335, 1329, 0
        .word 1337, 1329, 1328, 0
        .word 1278, 1336, 1335, 0
        .word 1320, 1278, 1335, 0
        .word 1320, 1335, 1337, 0
        .word 1278, 1277, 1336, 0
        .word 1277, 1338, 1336, 0
        .word 1336, 1338, 1334, 0
        .word 1277, 1279, 1338, 0
        .word 1279, 1339, 1338, 0
        .word 1338, 1339, 1340, 0
        .word 1338, 1340, 1334, 0
        .word 1279, 1283, 1339, 0
        .word 1283, 1341, 1339, 0
        .word 1339, 1341, 1342, 0
        .word 1339, 1342, 1340, 0
        .word 1334, 1340, 1333, 0
        .word 1340, 1342, 1343, 0
        .word 1340, 1343, 1333, 0
        .word 1341, 1344, 1342, 0
        .word 1342, 1344, 1345, 0
        .word 1342, 1345, 1343, 0
        .word 1345, 1346, 1343, 0
        .word 1347, 1333, 1343, 0
        .word 1347, 1343, 1346, 0
        .word 1332, 1333, 1347, 0
        .word 1345, 1348, 1346, 0
        .word 1349, 1348, 1345, 0
        .word 1344, 1349, 1345, 0
        .word 1349, 1350, 1348, 0
        .word 1351, 1350, 1349, 0
        .word 1352, 1351, 1349, 0
        .word 1344, 1352, 1349, 0
        .word 1351, 1353, 1350, 0
        .word 1354, 1353, 1351, 0
        .word 1355, 1354, 1351, 0
        .word 1352, 1355, 1351, 0
        .word 1356, 1355, 1352, 0
        .word 1357, 1356, 1352, 0
        .word 1357, 1352, 1344, 0
        .word 1358, 1359, 1355, 0
        .word 1355, 1359, 1354, 0
        .word 1356, 1358, 1355, 0
        .word 1299, 1358, 1356, 0
        .word 1298, 1299, 1356, 0
        .word 1298, 1356, 1357, 0
        .word 1297, 1298, 1357, 0
        .word 1297, 1357, 1341, 0
        .word 1341, 1357, 1344, 0
        .word 1283, 1297, 1341, 0
        .word 1299, 1301, 1358, 0
        .word 1301, 1360, 1358, 0
        .word 1358, 1360, 1359, 0
        .word 1301, 1304, 1360, 0
        .word 1360, 1361, 1362, 0
        .word 1360, 1362, 1359, 0
        .word 1304, 1361, 1360, 0
        .word 1304, 1217, 1361, 0
        .word 1217, 1363, 1361, 0
        .word 1361, 1363, 1364, 0
        .word 1361, 1364, 1362, 0
        .word 1359, 1362, 1365, 0
        .word 1362, 1364, 1366, 0
        .word 1362, 1366, 1365, 0
        .word 1363, 1367, 1364, 0
        .word 1364, 1367, 1368, 0
        .word 1364, 1368, 1366, 0
        .word 1369, 1365, 1366, 0
        .word 1369, 1366, 1370, 0
        .word 1370, 1366, 1368, 0
        .word 1365, 1369, 1371, 0
        .word 1365, 1371, 1354, 0
        .word 1359, 1365, 1354, 0
        .word 1354, 1371, 1353, 0
        .word 1370, 1368, 1372, 0
        .word 1372, 1368, 1373, 0
        .word 1367, 1373, 1368, 0
        .word 1372, 1373, 1374, 0
        .word 1374, 1373, 1375, 0
        .word 1367, 1376, 1373, 0
        .word 1376, 1375, 1373, 0
        .word 1374, 1375, 1377, 0
        .word 1377, 1375, 1378, 0
        .word 1376, 1379, 1375, 0
        .word 1379, 1378, 1375, 0
        .word 1380, 1381, 1376, 0
        .word 1380, 1376, 1367, 0
        .word 1381, 1379, 1376, 0
        .word 1381, 1382, 1379, 0
        .word 1382, 1383, 1379, 0
        .word 1379, 1383, 1378, 0
        .word 1212, 1216, 1381, 0
        .word 1212, 1381, 1380, 0
        .word 1216, 1382, 1381, 0
        .word 1216, 1223, 1382, 0
        .word 1223, 1384, 1382, 0
        .word 1382, 1384, 1383, 0
        .word 1384, 1385, 1383, 0
        .word 1383, 1385, 1386, 0
        .word 1383, 1386, 1378, 0
        .word 1223, 1230, 1384, 0
        .word 1230, 1387, 1384, 0
        .word 1384, 1387, 1385, 0
        .word 1387, 1388, 1385, 0
        .word 1385, 1388, 1389, 0
        .word 1385, 1389, 1386, 0
        .word 1390, 1378, 1386, 0
        .word 1390, 1386, 1391, 0
        .word 1389, 1391, 1386, 0
        .word 1377, 1378, 1390, 0
        .word 1389, 1392, 1391, 0
        .word 1393, 1392, 1389, 0
        .word 1388, 1393, 1389, 0
        .word 1393, 1394, 1392, 0
        .word 1395, 1394, 1393, 0
        .word 1396, 1395, 1393, 0
        .word 1388, 1396, 1393, 0
        .word 1395, 1397, 1394, 0
        .word 1398, 1397, 1395, 0
        .word 1399, 1398, 1395, 0
        .word 1396, 1399, 1395, 0
        .word 1400, 1399, 1396, 0
        .word 1401, 1400, 1396, 0
        .word 1401, 1396, 1388, 0
        .word 1402, 1403, 1399, 0
        .word 1399, 1403, 1398, 0
        .word 1400, 1402, 1399, 0
        .word 1246, 1402, 1400, 0
        .word 1245, 1246, 1400, 0
        .word 1245, 1400, 1401, 0
        .word 1244, 1245, 1401, 0
        .word 1244, 1401, 1387, 0
        .word 1387, 1401, 1388, 0
        .word 1230, 1244, 1387, 0
        .word 1246, 1248, 1402, 0
        .word 1248, 1404, 1402, 0
        .word 1402, 1404, 1403, 0
        .word 1248, 1251, 1404, 0
        .word 1251, 1405, 1404, 0
        .word 1404, 1405, 1406, 0
        .word 1404, 1406, 1403, 0
        .word 1251, 1321, 1405, 0
        .word 1321, 1337, 1405, 0
        .word 1405, 1337, 1328, 0
        .word 1405, 1328, 1406, 0
        .word 1403, 1406, 1407, 0
        .word 1406, 1328, 1327, 0
        .word 1406, 1327, 1407, 0
        .word 1403, 1407, 1398, 0
        .word 1327, 1408, 1407, 0
        .word 1407, 1408, 1409, 0
        .word 1407, 1409, 1398, 0
        .word 1327, 1326, 1408, 0
        .word 1398, 1409, 1397, 0
        .word 1321, 1320, 1337, 0
        .word 1213, 1212, 1380, 0
        .word 1213, 1380, 1363, 0
        .word 1363, 1380, 1367, 0
        .word 1217, 1213, 1363, 0
        .word 1316, 1314, 1311, 0
        .word 1316, 1311, 1318, 0
        .word 1318, 1311, 1312, 0
        .word 1318, 1312, 1319, 0
        .word 1319, 1312, 1313, 0
        .word 1319, 1313, 1234, 0
        .word 1234, 1313, 1293, 0
        .word 1234, 1293, 1235, 0
        .word 1235, 1293, 1289, 0
        .word 1235, 1289, 1236, 0
        .word 1236, 1289, 1288, 0
        .word 1236, 1288, 1240, 0
        .word 1240, 1288, 1287, 0
        .word 1240, 1287, 1260, 0
        .word 1260, 1287, 1273, 0
        .word 1260, 1273, 1259, 0
        .word 1259, 1273, 1266, 0
        .word 1259, 1266, 1258, 0
        .word 1258, 1266, 1263, 0
        .word 1258, 1263, 1261, 0
        .word 1410, 1411, 1412, 0
        .word 1410, 1412, 1413, 0
        .word 1410, 1413, 1414, 0
        .word 1410, 1414, 1415, 0
        .word 1416, 1410, 1415, 0
        .word 1417, 1411, 1410, 0
        .word 1417, 1410, 1416, 0
        .word 1418, 1414, 1413, 0
        .word 1419, 1418, 1413, 0
        .word 1419, 1413, 1412, 0
        .word 1420, 1421, 1418, 0
        .word 1418, 1421, 1414, 0
        .word 1422, 1420, 1418, 0
        .word 1422, 1418, 1419, 0
        .word 1423, 1422, 1419, 0
        .word 1423, 1419, 1424, 0
        .word 1424, 1419, 1412, 0
        .word 1425, 1420, 1422, 0
        .word 1426, 1425, 1422, 0
        .word 1426, 1422, 1423, 0
        .word 1427, 1426, 1423, 0
        .word 1427, 1423, 1428, 0
        .word 1428, 1423, 1424, 0
        .word 1424, 1412, 1429, 0
        .word 1428, 1424, 1430, 0
        .word 1430, 1424, 1429, 0
        .word 1431, 1429, 1412, 0
        .word 1431, 1412, 1411, 0
        .word 1430, 1429, 1432, 0
        .word 1433, 1432, 1429, 0
        .word 1433, 1429, 1431, 0
        .word 1434, 1428, 1430, 0
        .word 1434, 1430, 1435, 0
        .word 1435, 1430, 1432, 0
        .word 1435, 1432, 1436, 0
        .word 1436, 1432, 1433, 0
        .word 1436, 1433, 1437, 0
        .word 1438, 1437, 1433, 0
        .word 1438, 1433, 1439, 0
        .word 1439, 1433, 1431, 0
        .word 1440, 1435, 1436, 0
        .word 1440, 1436, 1441, 0
        .word 1436, 1437, 1442, 0
        .word 1436, 1442, 1441, 0
        .word 1443, 1434, 1435, 0
        .word 1443, 1435, 1440, 0
        .word 1444, 1443, 1440, 0
        .word 1444, 1440, 1445, 0
        .word 1445, 1440, 1441, 0
        .word 1445, 1441, 1446, 0
        .word 1446, 1441, 1442, 0
        .word 1447, 1444, 1445, 0
        .word 1447, 1445, 1448, 0
        .word 1448, 1445, 1446, 0
        .word 1449, 1443, 1444, 0
        .word 1450, 1449, 1444, 0
        .word 1450, 1444, 1447, 0
        .word 1449, 1451, 1443, 0
        .word 1451, 1434, 1443, 0
        .word 1452, 1453, 1449, 0
        .word 1452, 1449, 1450, 0
        .word 1454, 1451, 1449, 0
        .word 1454, 1449, 1453, 0
        .word 1451, 1455, 1434, 0
        .word 1425, 1455, 1451, 0
        .word 1425, 1451, 1454, 0
        .word 1455, 1428, 1434, 0
        .word 1455, 1427, 1428, 0
        .word 1426, 1427, 1455, 0
        .word 1426, 1455, 1425, 0
        .word 1425, 1454, 1420, 0
        .word 1454, 1453, 1456, 0
        .word 1454, 1456, 1420, 0
        .word 1420, 1456, 1421, 0
        .word 1457, 1421, 1456, 0
        .word 1457, 1456, 1458, 0
        .word 1458, 1456, 1453, 0
        .word 1459, 1414, 1421, 0
        .word 1459, 1421, 1457, 0
        .word 1414, 1459, 1460, 0
        .word 1414, 1460, 1415, 0
        .word 1460, 1461, 1462, 0
        .word 1460, 1462, 1415, 0
        .word 1416, 1415, 1462, 0
        .word 1463, 1416, 1462, 0
        .word 1463, 1462, 1464, 0
        .word 1461, 1464, 1462, 0
        .word 1461, 1465, 1464, 0
        .word 1466, 1463, 1464, 0
        .word 1466, 1464, 1467, 0
        .word 1465, 1467, 1464, 0
        .word 1468, 1469, 1463, 0
        .word 1468, 1463, 1466, 0
        .word 1469, 1416, 1463, 0
        .word 1469, 1417, 1416, 0
        .word 1470, 1471, 1469, 0
        .word 1470, 1469, 1468, 0
        .word 1471, 1417, 1469, 0
        .word 1472, 1473, 1468, 0
        .word 1472, 1468, 1466, 0
        .word 1473, 1470, 1468, 0
        .word 1474, 1471, 1470, 0
        .word 1473, 1474, 1470, 0
        .word 1471, 1475, 1417, 0
        .word 1474, 1476, 1471, 0
        .word 1476, 1475, 1471, 0
        .word 1475, 1411, 1417, 0
        .word 1475, 1431, 1411, 0
        .word 1476, 1439, 1475, 0
        .word 1439, 1431, 1475, 0
        .word 1473, 1477, 1476, 0
        .word 1473, 1476, 1474, 0
        .word 1477, 1439, 1476, 0
        .word 1472, 1477, 1473, 0
        .word 1472, 1478, 1477, 0
        .word 1478, 1438, 1477, 0
        .word 1477, 1438, 1439, 0
        .word 1479, 1480, 1478, 0
        .word 1479, 1478, 1472, 0
        .word 1480, 1481, 1478, 0
        .word 1478, 1481, 1438, 0
        .word 1481, 1437, 1438, 0
        .word 1480, 1482, 1481, 0
        .word 1482, 1442, 1481, 0
        .word 1481, 1442, 1437, 0
        .word 1483, 1484, 1480, 0
        .word 1483, 1480, 1479, 0
        .word 1484, 1482, 1480, 0
        .word 1482, 1485, 1442, 0
        .word 1484, 1486, 1482, 0
        .word 1486, 1485, 1482, 0
        .word 1446, 1442, 1485, 0
        .word 1486, 1487, 1485, 0
        .word 1488, 1446, 1485, 0
        .word 1488, 1485, 1487, 0
        .word 1448, 1446, 1488, 0
        .word 1479, 1467, 1489, 0
        .word 1479, 1489, 1483, 0
        .word 1479, 1472, 1466, 0
        .word 1479, 1466, 1467, 0
        .word 1465, 1489, 1467, 0
        .word 1458, 1453, 1452, 0
.end

