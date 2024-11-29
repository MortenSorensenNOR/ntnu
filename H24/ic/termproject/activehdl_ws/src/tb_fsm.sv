`timescale 1ns / 1ps

module tb_fsm ();
    localparam unsigned CLK_PERIOD_HALF = 5;    // 100 MHz CLK    

    reg clk;
    reg op;
    reg select;

    wire rw;
    wire valid;

    fsm fsm_inst (
        .clk(clk),
        .op(op),
        .select(select),
        .rw(rw),
        .valid(valid)
    );

    // Generate clk
    initial begin
        clk = 0;
        forever #CLK_PERIOD_HALF clk = ~clk;
    end

    // Assign signals
    initial begin
        $monitor("Time = %0d, sel = %b, op = %b -> rw = %b, valid = %b", $time, select, op, rw, valid); 

        // Reset state by leaving select = 0 for two clock cycles
        #0 op = 1'b0; select = 1'b0;

        #20 op = 1'b1;
        #20 op = 1'b0;
        #20 select = 1'b1;
        #20 op = 1'b1;
        #20 op = 1'b0;
        #20 select = 1'b0;

        $finish;
    end

endmodule