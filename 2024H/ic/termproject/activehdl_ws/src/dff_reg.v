module dff_reg_8 (
    input wire clk,
    input wire [7:0] i,
    output wire [7:0] o
    );

    d_flip_flop dff_reg0_inst (
        .clk(clk),
        .D(i[0]),
        .Q(o[0]),
        .Qn()
    );

    d_flip_flop dff_reg1_inst (
        .clk(clk),
        .D(i[1]),
        .Q(o[1]),
        .Qn()
    );

    d_flip_flop dff_reg2_inst (
        .clk(clk),
        .D(i[2]),
        .Q(o[2]),
        .Qn()
    );

    d_flip_flop dff_reg3_inst (
        .clk(clk),
        .D(i[3]),
        .Q(o[3]),
        .Qn()
    );

    d_flip_flop dff_reg4_inst (
        .clk(clk),
        .D(i[4]),
        .Q(o[4]),
        .Qn()
    );

    d_flip_flop dff_reg5_inst (
        .clk(clk),
        .D(i[5]),
        .Q(o[5]),
        .Qn()
    );

    d_flip_flop dff_reg6_inst (
        .clk(clk),
        .D(i[6]),
        .Q(o[6]),
        .Qn()
    );

    d_flip_flop dff_reg7_inst (
        .clk(clk),
        .D(i[7]),
        .Q(o[7]),
        .Qn()
    );

endmodule

module dff_reg_2 (
    input wire clk,
    input wire [1:0] i,
    output wire [1:0] o
    );

    d_flip_flop dff_reg0_inst (
        .clk(clk),
        .D(i[0]),
        .Q(o[0]),
        .Qn()
    );

    d_flip_flop dff_reg1_inst (
        .clk(clk),
        .D(i[1]),
        .Q(o[1]),
        .Qn()
    );
endmodule

module dff_reg_3 (
    input wire clk,
    input wire [2:0] i,
    output wire [2:0] o
    );

    d_flip_flop dff_reg0_inst (
        .clk(clk),
        .D(i[0]),
        .Q(o[0]),
        .Qn()
    );

    d_flip_flop dff_reg1_inst (
        .clk(clk),
        .D(i[1]),
        .Q(o[1]),
        .Qn()
    );

    d_flip_flop dff_reg2_inst (
        .clk(clk),
        .D(i[2]),
        .Q(o[2]),
        .Qn()
    );
endmodule