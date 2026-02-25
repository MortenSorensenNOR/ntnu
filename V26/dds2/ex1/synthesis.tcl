
# 1. Setup the Libraries

set_app_var target_library {/eda/tools/synopsys/dc.w-2024.09-sp4/libraries/syn/class.db}
set_app_var link_library [list * \
    /eda/tools/synopsys/dc.w-2024.09-sp4/libraries/syn/class.db \
    /eda/tools/synopsys/dc.w-2024.09-sp4/libraries/syn/dw_foundation.sldb]

set_app_var hdlin_check_no_latch true


analyze -format sverilog ./rtl/NtnuTfe4171Lab1Fifo.sv
elaborate NtnuTfe4171Lab1Fifo

# 3. Define Constraints
create_clock -name clk -period 62.5 [get_ports clk]

# Verify the design is ready for synthesis
check_design

# 4. Synthesis Flow

compile_ultra

# 5. Generate Reports
file mkdir reports
report_area   > reports/area.rpt
report_timing > reports/timing.rpt
report_qor    > reports/qor.rpt

# 6. Export Netlist
write -format verilog -hierarchy -output synthesized_netlist.v

puts "Synthesis Finished. Check reports/timing.rpt for slack values."
