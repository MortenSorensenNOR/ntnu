module debounce (
    input logic  clk,       // 1 MHz
    input logic  i_btn,     // Input btn som vi ønsker å debounce
    output logic o_btn      // Output fra debounce
    );

    parameter c_DEBOUNCE_LIMIT = 100000; // 10ms ved 10 MHz

    reg r_State = 1'b0;
    reg [$clog2(c_DEBOUNCE_LIMIT)-1:0] r_Count = 0;
    always @(posedge clk) begin
        if (i_btn !== r_State && r_Count < c_DEBOUNCE_LIMIT) begin
            r_Count <= r_Count + 1; // Counter
        end else if (r_Count == c_DEBOUNCE_LIMIT) begin
            r_Count <= 0;
            r_State <= i_btn;
        end else begin
            r_Count <= 0;
        end
    end
    assign o_btn = r_State;
endmodule
