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

_start:
    ldr r3, =0x0000
    bl _clear_screen
    
    ldr r0, =0
    ldr r1, =0
    ldr r2, =120
    ldr r3, =100

    // ldr r4, =VGA_WIDTH
    // ldr r2, [r4]
    // sub r2, r2, #1
    // ldr r4, =VGA_HEIGHT
    // ldr r3, [r4]
    // sub r3, r3, #1
    bl bresenham

    b .

.data
.align
    VGA_WIDTH: .word 320
    VGA_HEIGHT: .word 240
.end
