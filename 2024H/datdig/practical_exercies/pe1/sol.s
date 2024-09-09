# Load values into registers
#li a0, -5
#li a1, 0
#li a2, 1
#li a3, 41
#li a4, 100
#li a5, -64

_start:
    add a6, a0, a1
    add a7, a2, a3
    add s2, a4, a5
    
    slt t0, a6, a7
    beq t0, zero, L1 
    mv a0, a7
    j L2
L1:
    mv a0, a6
L2:
    slt t0, a0, s2
    beq t0, zero, L3
    mv a0, s2
    j L3
L3:
    nop

