.data
    matrixA: .float 1.0, 2.0, 3.0, 4.0
             .float 5.0, 6.0, 7.0, 8.0
             .float 9.0, 10.0, 11.0, 12.0
             .float 13.0, 14.0, 15.0, 16.0

    matrixB: .float 16.0, 15.0, 14.0, 13.0
             .float 12.0, 11.0, 10.0, 9.0
             .float 8.0, 7.0, 6.0, 5.0
             .float 4.0, 3.0, 2.0, 1.0

    .float_zero_val: .float 0.0         // Used to null out float registers because fmov.fp32 s0, #0.0 gives "immediate out of range" error

    matrixC: .space 64  // Reserve space for the result matrix (4x4 * 4 bytes per float = 64 bytes)

.text
.global _start

_start:
    # Load addresses of the matrices into registers
    ldr r0, =matrixA
    ldr r1, =matrixB
    ldr r2, =matrixC

    # Call the matrix multiplication function
    bl matmul4

    ldr r3, =matrixC      // Load address of matrixC into R3

    # Load matrixC into registers
    vldr s0, [r3]
    vldr s1, [r3, #4]
    vldr s2, [r3, #8]
    vldr s3, [r3, #12]
    vldr s4, [r3, #16]
    vldr s5, [r3, #20]
    vldr s6, [r3, #24]
    vldr s7, [r3, #28]
    vldr s8, [r3, #32]
    vldr s9, [r3, #36]
    vldr s10, [r3, #40]
    vldr s11, [r3, #44]
    vldr s12, [r3, #48]
    vldr s13, [r3, #52]
    vldr s14, [r3, #56]
    vldr s15, [r3, #60]

    # Exit the program (using a system call)
    b . 

# Function to multiply two 4x4 matrices
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

