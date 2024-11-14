`timescale 1ns/1ps

module fsm_comb(
    input wire op,
    input wire select,
    input wire [1:0] current_state,
    output wire [1:0] next_state
);

    wire t0, t1, t2;

    and U5 (t0, current_state[0], current_state[1]);
    and U6 (t1, select, op);
    or U7 (next_state[0], t0, t1);

    nand U8 (t2, current_state[0], current_state[1]);
    and U9 (next_state[1], select, t2);
    
endmodule