module clock_10Mhz (
    input logic clk_100m,    // 100 Mhz
    output logic clk_10m,
    output logic clk_10m_5x,
    output logic clk_10m_locked
    );

    localparam MULT_MASTER = 10;    // Multiply input to reach VCO range
    localparam DIV_MASTER = 1;      // No division at input stage
    localparam DIV_5X = 20;        // Divide VCO to 50 MHz for optional clk_1m_5x
    localparam DIV_1X = 100;       // Divide VCO to 10 MHz
    localparam IN_PERIOD = 10.0;    // Period of 100 MHz input clock in ns

    logic feedback;
    logic clk_10m_unbuf;
    logic clk_10m_5x_unbuf;
    logic locked;

    MMCME2_BASE #(
        .CLKFBOUT_MULT_F(MULT_MASTER),
        .CLKIN1_PERIOD(IN_PERIOD),
        .CLKOUT0_DIVIDE_F(DIV_5X),  // Divide VCO to get 50 MHz
        .CLKOUT1_DIVIDE(DIV_1X),    // Divide VCO to get 10 MHz
        .DIVCLK_DIVIDE(DIV_MASTER)
    ) MMCME2_BASE_inst (
        .CLKIN1(clk_100m),
        .RST(0),
        .CLKOUT0(clk_10m_5x_unbuf),  // 50 MHz clock
        .CLKOUT1(clk_10m_unbuf),     // 10 MHz clock
        .LOCKED(locked),
        .CLKFBOUT(feedback),
        .CLKFBIN(feedback),
        /* verilator lint_off PINCONNECTEMPTY */
        .CLKOUT0B(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUTB(),
        .PWRDWN()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // Buffer output clocks
    BUFG bufg_clk(.I(clk_10m_unbuf), .O(clk_10m));
    BUFG bufg_clk_5x(.I(clk_10m_5x_unbuf), .O(clk_1m_5x));

    // Synchronize the lock signal with clk_100m
    logic locked_sync_0;
    always_ff @(posedge clk_10m) begin
        locked_sync_0 <= locked;
        clk_10m_locked <= locked_sync_0;
    end
endmodule

module top (
    input logic clk,        // 100 Mhz external oscillator
    input logic [3:0] btn,  // Keypad buttons
    output logic [4:0] LED,
    output logic [3:0] keys
    );

    // 100 Mhz klokken er noe rask for å kunne analysere med digilenten,
    // så vi må genere en lavere klokke frekvens, som f.eks. 10 Mhz
    // Modulen er basert på en user guide for Xilinx FPGA-er
    logic rstn;
    logic clk_10m;
    logic clk_10m_locked;

    clock_10Mhz clock_1m_inst (
        .clk_100m(clk),
        .clk_10m(clk_10m),
        .clk_10m_5x(),
        .clk_10m_locked(clk_10m_locked)
    );
    always_ff @(posedge clk_10m) rstn <= !clk_10m_locked;
    assign LED[0] = clk_10m_locked;

    // Debounce
    logic [3:0] debounced_btns;
    debounce debounce_inst0 (
        .clk(clk_10m),
        .i_btn(btn[0]),
        .o_btn(debounced_btns[0])
    );
    debounce debounce_inst1 (
        .clk(clk_10m),
        .i_btn(btn[1]),
        .o_btn(debounced_btns[1])
    );
    debounce debounce_inst2 (
        .clk(clk_10m),
        .i_btn(btn[2]),
        .o_btn(debounced_btns[2])
    );
    debounce debounce_inst3 (
        .clk(clk_10m),
        .i_btn(btn[3]),
        .o_btn(debounced_btns[3])
    );

    assign LED[1] = debounced_btns[0];
    assign LED[2] = debounced_btns[1];
    assign LED[3] = debounced_btns[2];
    assign LED[4] = debounced_btns[3];

    // Keypad
    logic [3:0] w_keys;
    keypad keypad_inst (
        .clk(clk_10m),
        .btn(debounced_btns),
        .keys(w_keys)
    );
    assign keys = w_keys;

endmodule
