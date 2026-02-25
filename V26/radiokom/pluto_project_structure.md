# Main Components

## AD9361/AD9363 RF Transceiver Driver:
  - drivers/iio/adc/ad9361.c - Main driver for the RF chip (SPI control)
  - drivers/iio/adc/ad9361_conv.c - Configuration routines

## AXI FPGA Cores (data path through the FPGA fabric):
  - drivers/iio/adc/cf_axi_adc_core.c - RX path (ADC core, decimation)
  - drivers/iio/frequency/cf_axi_dds.c - TX path (DDS/DAC core, interpolation)
  - drivers/iio/frequency/cf_axi_dds_buffer_stream.c - TX DMA streaming

## DMA for high-speed data transfer:
  - drivers/dma/dma-axi-dmac.c - AXI DMA controller

## PlutoSDR Device Tree (defines the hardware layout):
  - arch/arm/boot/dts/zynq-pluto-sdr.dtsi - Base DT with memory-mapped addresses for RX/TX DMA, ADC
  core, DAC core, and AD9363 SPI

## Data Flow

RX: AD9363 → AXI ADC Core (0x79020000) → RX DMA (0x7c400000) → Memory
TX: Memory → TX DMA (0x7c420000) → AXI DDS Core (0x79024000) → AD9363

The cf_axi_* drivers are the key FPGA interface layer - they talk to the Analog Devices HDL IP cores
running in the Zynq PL (programmable logic). The register definitions in cf_axi_adc.h and
cf_axi_dds.h show the actual FPGA register map.
