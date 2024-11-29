.global _start
.section .text

cos_lookup:
    // r0:  index
    lsl r0, r0, #2
    ldr r1, =cosine_table
    add r1, r1, r0
    vldr s0, [r1]
    bx lr

_start:
    ldr r0, #0
    bl cos_lookup
    b .

.data:
    cosine_table: 
        .float  1.00,  0.95,  0.79,  0.55
        .float  0.25, -0.08, -0.40, -0.68
        .float -0.88, -0.99, -0.99, -0.88
        .float -0.68, -0.40, -0.08,  0.25
        .float  0.55,  0.79,  0.95,  1.00

    sine_table:
        .float  0.00,  0.32,  0.61,  0.84
        .float  0.97,  1.00,  0.92,  0.74
        .float  0.48,  0.16, -0.16, -0.48
        .float -0.74, -0.92, -1.00, -0.97
        .float -0.84, -0.61, -0.32, -0.00

