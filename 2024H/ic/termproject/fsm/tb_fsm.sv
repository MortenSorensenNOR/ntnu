`timescale 1ps/1ns

module fsm_tb;
    reg op, select;
    wire valid, rw;

    fsm dut (op, select, valid, rw);

    initial begin
        // Initialize inputs
        op = 0; select = 0;
        #5 select = 1; // Start by selecting the memory
        #10 op = 1;     // Perform a write operation
        #20 op = 0;     // Perform a read operation
        #40 select = 0; // Deselect the memory

        #40 $finish;
    end
endmodule