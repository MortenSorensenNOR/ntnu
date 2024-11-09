
module AddressDec(
    input [2:0] a, 
    input valid,    // For now, just and addr with valid
    output [7:0] w
);

	wire [2:0] nota;
    not (nota[0], a[0]);
    not (nota[1], a[1]);
    not (nota[2], a[2]);

    wire T0, T1, T2, T3;

    and U0 (T0, nota[2], nota[1]);
    and U1 (T1, nota[2],    a[1]);
    and U2 (T2,    a[2], nota[1]);
    and U3 (T3,    a[2],    a[1]);

    wire [7:0] w_t;
    and U4 (w_t[0], T0, nota[0]);
    and U5 (w_t[1], T0,    a[0]);
    and U6 (w_t[2], T1, nota[0]);
    and U7 (w_t[3], T1,    a[0]);
    and U8 (w_t[4], T2, nota[0]);
    and U9 (w_t[5], T2,    a[0]);
    and U10 (w_t[6], T3, nota[0]);
    and U11 (w_t[7], T3,    a[0]);

    // Gate wordline with valid signal
    and U12 (w[0], w_t[0], valid);
    and U13 (w[1], w_t[1], valid);
    and U14 (w[2], w_t[2], valid);
    and U15 (w[3], w_t[3], valid);
    and U16 (w[4], w_t[4], valid);
    and U17 (w[5], w_t[5], valid);
    and U18 (w[6], w_t[6], valid);
    and U19 (w[7], w_t[7], valid);

endmodule


   