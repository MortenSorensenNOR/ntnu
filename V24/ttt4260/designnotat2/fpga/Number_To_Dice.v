module Number_To_Dice
    (input i_Clk,
     input [2:0] i_Number,
     output [6:0] o_Dice);

 reg [6:0] r_Dice = 7'b0000000;

 // Se bit-order i Designnotat 
 always @(posedge i_Clk)
    begin
        case (i_Number)
            3'b001 : r_Dice = 7'b0000001;
            3'b010 : r_Dice = 7'b1000010;
            3'b011 : r_Dice = 7'b1000011;
            3'b100 : r_Dice = 7'b1100110;
            3'b101 : r_Dice = 7'b1100111;
            3'b110 : r_Dice = 7'b1111110;
        endcase
    end

 assign o_Dice = r_Dice;

endmodule
