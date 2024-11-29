#include <vector>
#include <cstdlib>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "obj_dir/Vlfsr.h"

#define RESET_CLKS 8

#define MAX_SIM_TIME 123456789
vluint64_t sim_time = 0;
vluint64_t posedge_cnt = 0;

int main(int argc, char** argv) {
    srand(time(NULL));

    Verilated::commandArgs(argc, argv);
    Vlfsr* dut = new Vlfsr;
    
    Verilated::traceEverOn(true);
    VerilatedVcdC* m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    for (int i = 0; i < RESET_CLKS; i++) {
        dut->clk ^= 1;
        dut->eval();

        dut->rst = 1;

        m_trace->dump(sim_time);
        sim_time++;
    }
    dut->rst = 0;

    std::vector<int> v_vals;
    
    vluint64_t sr_clk_last_time = 0;
    while (sim_time < MAX_SIM_TIME) {
        dut->clk ^= 1;
        dut->eval();
    
        if (dut->clk == 1) {
            posedge_cnt++;

            static int sr_clk_last = 0;
            if (dut->lfsr__DOT__sr_clk == 1 && sr_clk_last == 0) {
                int o_v = dut->v;
                v_vals.push_back(o_v);
                printf("%ld\n", posedge_cnt);
            }
            sr_clk_last = dut->lfsr__DOT__sr_clk;
        }
    
        m_trace->dump(sim_time);
        sim_time++;
    }

    // Write v values to file
    // Format: Time, Value
    FILE* f = fopen("v_vals.txt", "w");
    for (int i = 0; i < v_vals.size(); i++) {
        fprintf(f, "%f, %d\n", i * 0.000013f, v_vals[i]);
    }
    fclose(f);
    
    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}


