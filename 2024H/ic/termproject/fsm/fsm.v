// States are:
// 00: Idle
// 10: Read
// 11: Write
// 01: Stable

`timescale 1ns / 1ps

module fsm (
    input wire op,
    input wire select,
    output wire valid,
    output wire rw
    );

    wire [1:0] current_state;
    wire [1:0] current_state_n;
    wire [1:0] next_state;

    wire t0, t1, t2;

    // State D Latch
    nor U1 (current_state[0], ~next_state[0], current_state_n[0]);
    nor U2 (current_state_n[0], next_state[0], current_state[0]);

    nor U3 (current_state[1], ~next_state[1], current_state_n[1]);
    nor U4 (current_state_n[1], next_state[1], current_state[1]);

    // Next state
    and U5 (t0, current_state[0], current_state[1]);
    and U6 (t1, select, op);
    or U7 (next_state[0], t0, t1);

    nand U8 (t2, current_state[0], current_state[1]);
    or U9 (next_state[1], select, t2);

    // Assign output signals
    assign valid = current_state[1];
    assign rw = current_state[0];
endmodule
