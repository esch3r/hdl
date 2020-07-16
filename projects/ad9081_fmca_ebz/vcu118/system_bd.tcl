
## ADC FIFO depth in samples per converter
set adc_fifo_samples_per_converter [expr 64*1024]
## DAC FIFO depth in samples per converter
set dac_fifo_samples_per_converter [expr 64*1024]


source $ad_hdl_dir/projects/common/vcu118/vcu118_system_bd.tcl
source $ad_hdl_dir/projects/common/xilinx/adcfifo_bd.tcl
source $ad_hdl_dir/projects/common/xilinx/dacfifo_bd.tcl
source ../common/ad9081_fmca_ebz_bd.tcl

ad_ip_parameter axi_mxfe_rx_jesd/rx CONFIG.NUM_INPUT_PIPELINE 2
ad_ip_parameter axi_mxfe_tx_jesd/tx CONFIG.NUM_OUTPUT_PIPELINE 1

#system ID
ad_ip_parameter axi_sysid_0 CONFIG.ROM_ADDR_BITS 9
ad_ip_parameter rom_sys_0 CONFIG.PATH_TO_FILE "[pwd]/mem_init_sys.txt"
ad_ip_parameter rom_sys_0 CONFIG.ROM_ADDR_BITS 9
set sys_cstring "sys rom custom string placeholder"
sysid_gen_sys_init_file $sys_cstring

if {$ad_project_params(JESD_MODE) == "8B10B"} {
# Parameters for 15.5Gpbs lane rate

ad_ip_parameter util_mxfe_xcvr CONFIG.RX_CLK25_DIV 31
ad_ip_parameter util_mxfe_xcvr CONFIG.TX_CLK25_DIV 31
ad_ip_parameter util_mxfe_xcvr CONFIG.CPLL_CFG0 0x1fa
ad_ip_parameter util_mxfe_xcvr CONFIG.CPLL_CFG1 0x2b
ad_ip_parameter util_mxfe_xcvr CONFIG.CPLL_CFG2 0x2
ad_ip_parameter util_mxfe_xcvr CONFIG.CPLL_FBDIV 2
ad_ip_parameter util_mxfe_xcvr CONFIG.CH_HSPMUX 0x4040
ad_ip_parameter util_mxfe_xcvr CONFIG.PREIQ_FREQ_BST 1
ad_ip_parameter util_mxfe_xcvr CONFIG.RTX_BUF_CML_CTRL 0x5
ad_ip_parameter util_mxfe_xcvr CONFIG.RXPI_CFG0 0x3002
ad_ip_parameter util_mxfe_xcvr CONFIG.RXCDR_CFG2 0x1E9
ad_ip_parameter util_mxfe_xcvr CONFIG.RXCDR_CFG3 0x23
ad_ip_parameter util_mxfe_xcvr CONFIG.RXCDR_CFG3_GEN2 0x23
ad_ip_parameter util_mxfe_xcvr CONFIG.RXCDR_CFG3_GEN3 0x23
ad_ip_parameter util_mxfe_xcvr CONFIG.RXCDR_CFG3_GEN4 0x23
ad_ip_parameter util_mxfe_xcvr CONFIG.RX_WIDEMODE_CDR 0x1
ad_ip_parameter util_mxfe_xcvr CONFIG.RX_XMODE_SEL 0x0
ad_ip_parameter util_mxfe_xcvr CONFIG.TXDRV_FREQBAND 1
ad_ip_parameter util_mxfe_xcvr CONFIG.TXFE_CFG1 0xAA00
ad_ip_parameter util_mxfe_xcvr CONFIG.TXFE_CFG2 0xAA00
ad_ip_parameter util_mxfe_xcvr CONFIG.TXFE_CFG3 0xAA00
ad_ip_parameter util_mxfe_xcvr CONFIG.TXPI_CFG0 0x3100
ad_ip_parameter util_mxfe_xcvr CONFIG.TXPI_CFG1 0x0
ad_ip_parameter util_mxfe_xcvr CONFIG.TX_PI_BIASSET 1

ad_ip_parameter util_mxfe_xcvr CONFIG.QPLL_REFCLK_DIV 1
ad_ip_parameter util_mxfe_xcvr CONFIG.QPLL_CFG0 0x333c
ad_ip_parameter util_mxfe_xcvr CONFIG.QPLL_CFG4 0x2
ad_ip_parameter util_mxfe_xcvr CONFIG.QPLL_FBDIV 20
ad_ip_parameter util_mxfe_xcvr CONFIG.PPF0_CFG 0xB00
ad_ip_parameter util_mxfe_xcvr CONFIG.QPLL_LPF 0x2ff
} else {
  set_property -dict [list CONFIG.ADDN_UI_CLKOUT4_FREQ_HZ {50}] [get_bd_cells axi_ddr_cntrl]
  ad_connect  /axi_ddr_cntrl/addn_ui_clkout4 jesd204_phy_121/drpclk
  ad_connect  /axi_ddr_cntrl/addn_ui_clkout4 jesd204_phy_126/drpclk  
}

# Second timer for benchmarking
ad_ip_instance axi_timer axi_timer2
ad_cpu_interrupt ps-13 mb-5 axi_timer2/interrupt

ad_cpu_interconnect 0x41D00000 axi_timer2

# connect 300Mhz to MicroBlaze
disconnect_bd_net /sys_cpu_clk [get_bd_pins sys_mb/Clk]
connect_bd_net [get_bd_pins axi_ddr_cntrl/c0_ddr4_ui_clk] [get_bd_pins sys_mb/Clk]
delete_bd_objs [get_bd_nets sys_rstgen_mb_reset]
connect_bd_net [get_bd_pins axi_ddr_cntrl_rstgen/mb_reset] [get_bd_pins sys_mb/Reset]
disconnect_bd_net /sys_cpu_resetn [get_bd_pins axi_cpu_interconnect/S00_ARESETN]
connect_bd_net [get_bd_pins axi_ddr_cntrl_rstgen/peripheral_aresetn] [get_bd_pins axi_cpu_interconnect/S00_ARESETN]
disconnect_bd_net /sys_cpu_clk [get_bd_pins axi_cpu_interconnect/S00_ACLK]
connect_bd_net [get_bd_pins axi_ddr_cntrl/c0_ddr4_ui_clk] [get_bd_pins axi_cpu_interconnect/S00_ACLK]

disconnect_bd_net /sys_rstgen_bus_struct_reset [get_bd_pins sys_rstgen/bus_struct_reset]
connect_bd_net [get_bd_pins axi_ddr_cntrl_rstgen/bus_struct_reset] [get_bd_pins sys_dlmb/SYS_Rst]
disconnect_bd_net /sys_cpu_clk [get_bd_pins sys_dlmb/LMB_Clk]
disconnect_bd_net /sys_cpu_clk [get_bd_pins sys_ilmb/LMB_Clk]
disconnect_bd_net /sys_cpu_clk [get_bd_pins sys_dlmb_cntlr/LMB_Clk]
disconnect_bd_net /sys_cpu_clk [get_bd_pins sys_ilmb_cntlr/LMB_Clk]
connect_bd_net [get_bd_pins axi_ddr_cntrl/c0_ddr4_ui_clk] [get_bd_pins sys_dlmb/LMB_Clk]
connect_bd_net [get_bd_pins axi_ddr_cntrl/c0_ddr4_ui_clk] [get_bd_pins sys_ilmb/LMB_Clk]
connect_bd_net [get_bd_pins axi_ddr_cntrl/c0_ddr4_ui_clk] [get_bd_pins sys_dlmb_cntlr/LMB_Clk]
connect_bd_net [get_bd_pins axi_ddr_cntrl/c0_ddr4_ui_clk] [get_bd_pins sys_ilmb_cntlr/LMB_Clk]

#set_property -dict [list CONFIG.NUM_CLKS {4}] [get_bd_cells axi_mem_interconnect]
#connect_bd_net [get_bd_pins axi_mem_interconnect/aclk3] [get_bd_pins axi_ddr_cntrl/c0_ddr4_ui_clk]
#
set_property -dict [list CONFIG.C_AREA_OPTIMIZED {2}] [get_bd_cells sys_mb]
set_property -dict [list CONFIG.G_TEMPLATE_LIST {7} CONFIG.C_USE_FPU {2} CONFIG.C_FPU_EXCEPTION {1} CONFIG.C_ICACHE_VICTIMS {0} CONFIG.C_ICACHE_STREAMS {0} CONFIG.C_DCACHE_USE_WRITEBACK {1} CONFIG.C_DCACHE_VICTIMS {0} CONFIG.C_USE_BRANCH_TARGET_CACHE {1}] [get_bd_cells sys_mb]

# increase implemenation effort
set_property strategy Performance_Explore [get_runs impl_1]
