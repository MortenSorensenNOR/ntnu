greatest_divider:
    li a1, 2
    
    greatest_divider_loop:
    rem s0, a0, a1
    beq s0, zero, smallest_divider_found
    addi a1, a1, 1
    blt a1, a0, greatest_divider_loop
    
smallest_divider_found:
    div t0, a0, a1
    
check_perfect_square:
    # Get log2 of A
    li a1, 0
    li a2, 31
    li a3, 1
    slli a3, a3, 31    # a3 -> Mask
    
    most_significant_bit_set_loop:
    and a4, a0, a3
    bne a4, x0, most_significant_bit_found
    srli a3, a3, 1
    addi a1, a1, 1
    j most_significant_bit_set_loop
    
    most_significant_bit_found:
    # log2_A
    sub a1, a2, a1
    addi a1, a1, 1
    andi a2, a1, 1
    beq a2, zero, not_odd
    addi a1, a1, 1
    not_odd:
    
    # upper_bound
    srli a1, a1, 1
    li a5, 1
    sll a1, a5, a1 # a1 -> upper_bound_sqrt(A)
    
    # Find if A is square
    square_loop:
    mul a2, a1, a1
    beq a2, a0, perfect_square
    addi a1, a1, -1
    bgt a2, a0, square_loop
    
not_perfect_square:
    li a1, 0
    mv a0, t0
    j end

perfect_square:
    li a1, 1
    mv a0, t0
    j end
    
end:
    nop
