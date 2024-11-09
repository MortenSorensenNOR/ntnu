`timescale 1ps/1ps

// Nand based D-Latch to be used in D flip-flop
module d_latch (
    input wire D,
    input wire enable,
    output wire Q,
    output wire Qn
);
    wire Dn, R, S;

    not (Dn, D);
    nand (R, D, enable);
    nand (S, Dn, enable);
    nand (Q, Qn, R);
    nand (Qn, Q, S);
endmodule


module d_flip_flop (
    input wire D,
    input wire clk,
    output wire Q,
    output wire Qn
);

	wire Qm, Qmn;   // Master latch output

    // Master latch
    d_latch master_latch (
        .D(D),
        .enable(~clk),
        .Q(Qm),
        .Qn(Qmn)
    );

    // Slave latch
    d_latch slave_latch (
        .D(Qm),
        .enable(clk),
        .Q(Q),
        .Qn(Qn)
    );

endmodule