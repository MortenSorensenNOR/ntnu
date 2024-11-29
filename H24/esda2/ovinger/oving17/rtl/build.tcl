set design_name "top"
set board_name "Basys3"

# MH FPGA
set fpga_part "xc7a35tcpg236-1"

# Create log directory
file mkdir logs
file mkdir output

# Read lib files
read_verilog -sv "debounce.sv"
read_verilog -sv "keypad.sv"
read_verilog -sv "top.sv"

# Read constraints
read_xdc "${board_name}.xdc"

# Synthesis
synth_design -top "${design_name}" -part ${fpga_part}

# Optimize design
opt_design

# Place design
place_design

# Route design
route_design

# Generate Timing Reports

# 1. Generate Timing Summary Report
report_timing_summary -file logs/timing_summary.txt

# 2. Generate Detailed Timing Report (Top 10 Critical Paths)
report_timing -delay_type max -sort_by slack -max_paths 10 -file logs/detailed_timing_report.txt

# Write bitstream
write_bitstream -force "output/${design_name}.bit"
