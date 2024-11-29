module memory_unit (
    input wire clk,
    input wire op,
    input wire select,
    input wire [2:0] addr,

    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    // FSM
    wire w_valid;
    wire w_rw;

    fsm fsm_inst (
        .clk(clk),
        .op(op),
        .select(select),
        .valid(w_valid),
        .rw(w_rw)
    );

    // Address Decoder
    wire [2:0] r_addr;
    wire [7:0] wordLine;
	wire [7:0] r_data_in;

    // Register the input address
    dff_reg_3 addr_reg_inst (
		.clk(clk),
		.i(addr),
		.o(r_addr)
	);

	// Register input data
	dff_reg_8 data_in_reg (
		.clk(clk),
		.i(data_in),
		.o(r_data_in)
	);

    AddressDec addr_dec_inst (
        .a(r_addr),
		.valid(w_valid),
        .w(wordLine)
    );
    
	// Memory array
	gridCell gridCell_inst (
		.rw(w_rw),
		.wordLine(wordLine),
		.i(r_data_in),
		.bitLinesOut(data_out)
	);						  
endmodule