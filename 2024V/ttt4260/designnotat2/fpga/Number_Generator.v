module Dice
    (input i_Clk,
     input i_Switch_1,
     output io_PMOD_1,
     output io_PMOD_2,
     output io_PMOD_3,
     output io_PMOD_4,
     output io_PMOD_7,
     output io_PMOD_8,
     output io_PMOD_9);

 wire w_Switch_1;
 reg  r_Switch_1 = 1'b0;

 wire [6:0] r_Dice;
 reg [2:0] r_Number_Counter = 3'b000;
 reg [2:0] r_Number_Output = 3'b110;

 Debounce_Switch Debounce_Switch_Inst
    (.i_Clk(i_Clk),
     .i_Switch(i_Switch_1),
     .o_Switch(w_Switch_1));

 always @(posedge i_Clk)
 begin
     if (r_Number_Counter >= 3'b110)
     begin
         r_Number_Counter = 3'b000;
     end
     r_Number_Counter = r_Number_Counter + 1;

     r_Switch_1 <= w_Switch_1;
     
     // Input switchen går fra høyt til lavt
     if (w_Switch_1 == 1'b0 && r_Switch_1 == 1'b1)
     begin
         r_Number_Output <= r_Number_Counter;
     end
 end

 Number_To_Dice Number_To_Dice_Inst
    (.i_Clk(i_Clk),
     .i_Number(r_Number_Output),
     .o_Dice(r_Dice));


 assign io_PMOD_1 = r_Dice[6];
 assign io_PMOD_2 = r_Dice[5];
 assign io_PMOD_3 = r_Dice[4];
 assign io_PMOD_4 = r_Dice[3];
 assign io_PMOD_7 = r_Dice[2];
 assign io_PMOD_8 = r_Dice[1];
 assign io_PMOD_9 = r_Dice[0];

endmodule
