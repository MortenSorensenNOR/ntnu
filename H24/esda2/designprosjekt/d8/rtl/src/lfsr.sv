// 31 bit lengde LFSR for å generere støy mellom 20Hz og 20kHz
`timescale 1ns / 1ps

/* verilator lint_off WIDTH */
module lfsr #(
    parameter logic [30:0] SEED = 31'h608420dd, // Seed for å starte LFSR-en
    parameter unsigned OVERSAMPLING = 4         // Hvor mye skal klokken kjøre over 20kHz
                                                // for å oppnå Nykvist kriteriet
) (
    input logic clk,
    input logic rst,

    output logic v
);
    // Teller for å generere klokke på 20kHz * OVERSAMPLING
    localparam unsigned NUM_CLKS_PER_SHIFT = 100_000_000 / (20_000 * OVERSAMPLING) / 2;
    logic [$clog2(NUM_CLKS_PER_SHIFT)-1:0] clk_cntr = '0;
    logic sr_clk = '0;

    always_ff @(posedge clk) begin
        if (rst) begin
            clk_cntr <= '0;
        end else begin
            if (clk_cntr == NUM_CLKS_PER_SHIFT - 1) begin
                clk_cntr <= '0;
                sr_clk <= ~sr_clk;
            end else begin
                clk_cntr <= clk_cntr + 1;
            end
        end
    end

    // Shift registeret
    logic [30:0] SR = SEED;

    // Funksjonen for å finne neste bit
    logic Q_n;
    always_comb begin
        Q_n = SR[2] ^ SR[30];
    end

    logic sr_clk_r = '0;
    always_ff @(posedge clk) begin
        if (rst) begin
            SR <= SEED;
        end else begin
            sr_clk_r <= sr_clk;

            // Shift kunn på positiv flanke
            if (sr_clk == 1'b1 && sr_clk_r == 1'b0) begin
                SR <= {SR[29:0], Q_n};
            end
        end
    end

    assign v = SR[30];
endmodule
