ClearScreen:
    PUSH {LR}
    PUSH {R4, R5} 
    LDR R5, =0
    LDR R3, =0
    _ClearScreen_loop:
    LDR R4, =0
    _ClearScreen_line:
    LDR R1, R4
    LDR R2, R5
    BL SetPixel
    ADD R4, R4, #1
    CMP R4, #320
    BLT _ClearScreen_line
    ADD R5, R5, #1
    CMP R5, #240
    BLT _ClearScreen_loop
    POP {R4,R5}
    POP {LR} 
    BX LR");
