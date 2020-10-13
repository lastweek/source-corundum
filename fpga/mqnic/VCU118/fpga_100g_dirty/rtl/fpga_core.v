// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * FPGA core logic
 */
module fpga_core #
(
    parameter TARGET = "XILINX",
    parameter AXIS_PCIE_DATA_WIDTH = 512,
    parameter AXIS_PCIE_KEEP_WIDTH = (AXIS_PCIE_DATA_WIDTH/32),
    parameter AXIS_PCIE_RC_USER_WIDTH = 161,
    parameter AXIS_PCIE_RQ_USER_WIDTH = 137,
    parameter AXIS_PCIE_CQ_USER_WIDTH = 183,
    parameter AXIS_PCIE_CC_USER_WIDTH = 81,
    parameter RQ_SEQ_NUM_WIDTH = 6,
    parameter BAR0_APERTURE = 24,
    parameter AXIS_ETH_DATA_WIDTH = 512,
    parameter AXIS_ETH_KEEP_WIDTH = AXIS_ETH_DATA_WIDTH/8
)
(
    /*
     * Clock: 250 MHz
     * Synchronous reset
     */
    input  wire                               clk_250mhz,
    input  wire                               rst_250mhz,

    /*
     * GPIO
     */
    input  wire                               btnu,
    input  wire                               btnl,
    input  wire                               btnd,
    input  wire                               btnr,
    input  wire                               btnc,
    input  wire [3:0]                         sw,

    /*
     * I2C
     */
    input  wire                               i2c_scl_i,
    output wire                               i2c_scl_o,
    output wire                               i2c_scl_t,
    input  wire                               i2c_sda_i,
    output wire                               i2c_sda_o,
    output wire                               i2c_sda_t,

    /*
     * Ethernet: QSFP28
     */
    input  wire                               qsfp1_tx_clk,
    input  wire                               qsfp1_tx_rst,

    output wire [AXIS_ETH_DATA_WIDTH-1:0]     qsfp1_tx_axis_tdata,
    output wire [AXIS_ETH_KEEP_WIDTH-1:0]     qsfp1_tx_axis_tkeep,
    output wire                               qsfp1_tx_axis_tvalid,
    input  wire                               qsfp1_tx_axis_tready,
    output wire                               qsfp1_tx_axis_tlast,
    output wire                               qsfp1_tx_axis_tuser,

    input  wire                               qsfp1_rx_clk,
    input  wire                               qsfp1_rx_rst,

    input  wire [AXIS_ETH_DATA_WIDTH-1:0]     qsfp1_rx_axis_tdata,
    input  wire [AXIS_ETH_KEEP_WIDTH-1:0]     qsfp1_rx_axis_tkeep,
    input  wire                               qsfp1_rx_axis_tvalid,
    input  wire                               qsfp1_rx_axis_tlast,
    input  wire                               qsfp1_rx_axis_tuser,

    output wire                               qsfp1_modsell,
    output wire                               qsfp1_resetl,
    input  wire                               qsfp1_modprsl,
    input  wire                               qsfp1_intl,
    output wire                               qsfp1_lpmode,

    input  wire                               qsfp2_tx_clk,
    input  wire                               qsfp2_tx_rst,

    /*
     * Ethernet: QSFP28
     */
    output wire [AXIS_ETH_DATA_WIDTH-1:0]     qsfp2_tx_axis_tdata,
    output wire [AXIS_ETH_KEEP_WIDTH-1:0]     qsfp2_tx_axis_tkeep,
    output wire                               qsfp2_tx_axis_tvalid,
    input  wire                               qsfp2_tx_axis_tready,
    output wire                               qsfp2_tx_axis_tlast,
    output wire                               qsfp2_tx_axis_tuser,

    input  wire                               qsfp2_rx_clk,
    input  wire                               qsfp2_rx_rst,

    input  wire [AXIS_ETH_DATA_WIDTH-1:0]     qsfp2_rx_axis_tdata,
    input  wire [AXIS_ETH_KEEP_WIDTH-1:0]     qsfp2_rx_axis_tkeep,
    input  wire                               qsfp2_rx_axis_tvalid,
    input  wire                               qsfp2_rx_axis_tlast,
    input  wire                               qsfp2_rx_axis_tuser,

    output wire                               qsfp2_modsell,
    output wire                               qsfp2_resetl,
    input  wire                               qsfp2_modprsl,
    input  wire                               qsfp2_intl,
    output wire                               qsfp2_lpmode
);

// FW and board IDs
parameter FW_ID = 32'd0;
parameter FW_VER = {16'd0, 16'd1};
parameter BOARD_ID = {16'h10ee, 16'h9076};
parameter BOARD_VER = {16'd0, 16'd1};
parameter FPGA_ID = 32'h4B31093;

// Structural parameters
parameter IF_COUNT = 2;
parameter PORTS_PER_IF = 1;

parameter PORT_COUNT = IF_COUNT*PORTS_PER_IF;

// AXI stream interface parameters
parameter AXIS_DATA_WIDTH = AXIS_ETH_DATA_WIDTH;
parameter AXIS_KEEP_WIDTH = AXIS_ETH_KEEP_WIDTH;

reg qsfp1_reset_reg = 1'b0;
reg qsfp2_reset_reg = 1'b0;

reg qsfp1_lpmode_reg = 1'b0;
reg qsfp2_lpmode_reg = 1'b0;

reg i2c_scl_o_reg = 1'b1;
reg i2c_sda_o_reg = 1'b1;

assign qsfp1_modsell = 1'b0;
assign qsfp2_modsell = 1'b0;

assign qsfp1_resetl = !qsfp1_reset_reg;
assign qsfp2_resetl = !qsfp2_reset_reg;

assign qsfp1_lpmode = qsfp1_lpmode_reg;
assign qsfp2_lpmode = qsfp2_lpmode_reg;

assign i2c_scl_o = i2c_scl_o_reg;
assign i2c_scl_t = i2c_scl_o_reg;
assign i2c_sda_o = i2c_sda_o_reg;
assign i2c_sda_t = i2c_sda_o_reg;

endmodule
