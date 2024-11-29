// States are:
// 00: Idle
// 10: Read
// 11: Write
// 01: Stable

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
    dff_reg_2 state_reg_inst (
        .clk(clk),
        .i(next_state),
        .o(current_state)
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