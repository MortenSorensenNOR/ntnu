module keypad (
    input logic clk,        // 1 Mhz
    input logic [3:0] btn,  // Input knappe trykk
    output logic [3:0] keys // Output knappe trykk puls
    );

    logic [3:0] Q1 = '0;
    logic [3:0] Q2 = '0;
    always_ff @(posedge clk) begin
        Q1 <= btn;
        Q2 <= Q1;
        keys[0] <= Q1[0] & ~Q2[0];
        keys[1] <= Q1[1] & ~Q2[1];
        keys[2] <= Q1[2] & ~Q2[2];
        keys[3] <= Q1[3] & ~Q2[3];
    end
endmodule
