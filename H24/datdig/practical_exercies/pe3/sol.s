j main

swap:
    blt a0, a1, swap_end
    mv t1, a0
    mv a0, a1
    mv a1, t1
    li s6, 1
    
swap_end:
    ret

main:
    mv s0, a0
    mv s1, a1
    mv s2, a2
    mv s3, a3
    mv s4, a4
    mv s5, a5
    
    # Bubble sort
    li t0, 5
main_loop:
    ble t0, zero, main_loop_end
    li s6, 0
    
    # 0 <-> 1
    mv a0, s0
    mv a1, s1
    call swap
    mv s0, a0
    mv s1, a1
    
    # 1 <-> 2
    mv a0, s1
    mv a1, s2
    call swap
    mv s1, a0
    mv s2, a1
    
    # 2 <-> 3
    mv a0, s2
    mv a1, s3
    call swap
    mv s2, a0
    mv s3, a1
    
    # 3 <-> 4
    mv a0, s3
    mv a1, s4
    call swap
    mv s3, a0
    mv s4, a1
    
    # 4 <-> 5
    mv a0, s4
    mv a1, s5
    call swap
    mv s4, a0
    mv s5, a1
    
    beq s6, zero, main_loop_end
    
    addi t0, t0, -1
    j main_loop
    
main_loop_end:
    mv a0, s0
    mv a1, s1
    mv a2, s2
    mv a3, s3
    mv a4, s4
    mv a5, s5
    
    nop
