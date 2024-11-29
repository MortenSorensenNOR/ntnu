_start:
    li s0, 1
    li s2, 1

_loop:
    mul s1, s0, s0
    bgt s1, a0, _finish

    bne a0, s1, _not_square
    li a1, 1
    ble s0, s2, _not_greatest_divisor
    mv a0, s0

_not_greatest_divisor:
    jal _finish
    
_not_square:
    rem s1, a0, s0
    bne s1, zero, _loop_continue
    div s1, a0, s0
    ble s1, s2, _loop_continue
    beq s1, a0, _loop_continue
    mv s2, s1

_loop_continue:
    addi s0, s0, 1
    jal _loop

_finish:
    mv a0, s2

