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
    
    // dx = abs(x1 - x0)
    sub r4, r2, r0
    push {r0, lr}
    mov r0, r4
    bl abs
    mov r4, r0
    pop {lr, r0}

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
    ldr r11, =matrixA
    add r12, r11, r10           // R12 = &matrixA[i][k]
    vldr s1, [r12]              // Load matrixA[i][k] into S1

    # Load B[k][j] into S2
    lsl r10, r8, #4             // R10 = k * 16 (size of a row in bytes)
    add r10, r10, r9, lsl #2    // R10 = address of B[k][j]
    ldr r11, =matrixB
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
    ldr r11, =matrixC
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

main_graphics_loop:
    ldr r3, =0x0000
    bl _clear_screen

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

    .rotation_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .translation_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .view_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

    .projection_matrix:
        .float 1.0, 0.0, 0.0, 0.0
        .float 0.0, 1.0, 0.0, 0.0
        .float 0.0, 0.0, 1.0, 0.0
        .float 0.0, 0.0, 0.0, 1.0

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

    .vertex_data_cube:
        .float 0.0, 0.0, 0.0
        .float 1.0, 0.0, 0.0
        .float 1.0, 1.0, 0.0
        .float 0.0, 1.0, 0.0
        .float 0.0, 0.0, 1.0
        .float 1.0, 0.0, 1.0
        .float 1.0, 1.0, 1.0
        .float 0.0, 1.0, 1.0 

    .index_data_cube:
        .word 0, 1, 2
        .word 0, 2, 3
        .word 1, 5, 6
        .word 1, 6, 2
        .word 5, 4, 7
        .word 5, 7, 6
        .word 4, 0, 3
        .word 4, 3, 7
        .word 3, 2, 6
        .word 3, 6, 7
        .word 4, 5, 1
        .word 4, 1, 0

.end
