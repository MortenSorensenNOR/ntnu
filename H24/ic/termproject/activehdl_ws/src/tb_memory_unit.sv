module tb_memory_unit ();
    localparam unsigned CLOCK_PERIOD_HALF = 5;

    reg clk;
    reg op;
    reg select;
    reg [2:0] tb_addr;

    reg [7:0] tb_data_in;
    wire [7:0] w_data_out;
	
    memory_unit memory_unit_inst (
        .clk(clk),
        .op(op),
        .select(select),
		.addr(tb_addr),
        .data_in(tb_data_in),
        .data_out(w_data_out)
    );

    // Generate clock
    initial begin
        clk = 0;
        forever begin
            clk = ~clk;
            #CLOCK_PERIOD_HALF;
        end
    end

    task write_data(
        input [2:0] addr,
        input [7:0] write_data,
		output w_select,
		output w_op
    );
        w_select = 1;
        w_op = 1;
        tb_addr = addr;
        tb_data_in = write_data;   
    endtask //automatic

    task read_data(
		input [2:0] addr,
		output w_select,
		output w_op
    );
        w_select = 1;
        w_op = 0;
        tb_addr = addr;
        tb_data_in = '0;
    endtask //automatic

    // Generate data sigals
    initial begin
        op = 0; select = 0; tb_addr = '0; tb_data_in = '0; #40

        write_data(3'b000, 8'b01101101, select, op); #20
        write_data(3'b001, 8'b01101111, select, op); #20
        write_data(3'b010, 8'b01110010, select, op); #20
        write_data(3'b011, 8'b01110100, select, op); #20
        write_data(3'b100, 8'b01100101, select, op); #20
        write_data(3'b101, 8'b01101110, select, op); #20

        read_data(3'b000, select, op); #10
        read_data(3'b001, select, op); #10
        read_data(3'b010, select, op); #10
        read_data(3'b011, select, op); #10
        read_data(3'b100, select, op); #10
        read_data(3'b101, select, op); #10
		
		op = 0; select = 0;
		
		#40 $finish;
    end

endmodule