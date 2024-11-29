`timescale 1ns / 1ps

module tb_fsm_comb ();
    reg op;
    reg select;
    reg [1:0] current_state;
    wire [1:0] next_state;

    fsm_comb fsm_comb_inst (
        .op(op),
        .select(select),
        .current_state(current_state),
        .next_state(next_state)
    );

    // Assign signals
    initial begin
        #0 op = 1'b0; select = 1'b0;
        #0 current_state = 2'b00;
        #10 op = 1'b1;
        #10 op = 1'b0; select = 1'b1;
        #10 op = 1'b1;

        #10 op = 1'b0; select = 1'b0;
        #0 current_state = 2'b01;
        #10 op = 1'b1;
        #10 op = 1'b0; select = 1'b1;
        #10 op = 1'b1;

        #10 op = 1'b0; select = 1'b0;
        #0 current_state = 2'b10;
        #10 op = 1'b1;
        #10 op = 1'b0; select = 1'b1;
        #10 op = 1'b1;

        #10 op = 1'b0; select = 1'b0;
        #0 current_state = 2'b11;
        #10 op = 1'b1;
        #10 op = 1'b0; select = 1'b1;
        #10 op = 1'b1;

        #20 $finish;
    end

endmodule