// States are:
// 00: Idle
// 10: Read
// 11: Write
// 01: Stable

`timescale 1ns / 1ps

module fsm (
    input wire clk,
    input wire op,
    input wire select,
    output wire valid,
    output wire rw
    );

    wire [1:0] current_state;
    wire [1:0] next_state;

    // State D Flip-Flop
    d_flip_flop state_dff_0 (
		.clk(clk),
        .D(next_state[0]),
        .Q(current_state[0]),
        .Qn()
    );

    d_flip_flop state_dff_1 (
		.clk(clk),
        .D(next_state[1]),
        .Q(current_state[1]),
        .Qn()
    );

    // Next state
    fsm_comb fsm_comb_inst (
        .op(op),
        .select(select),
        .current_state(current_state),
        .next_state(next_state)
    );

    // Assign output signals
    assign valid = current_state[1];
    assign rw = current_state[0];
endmodule