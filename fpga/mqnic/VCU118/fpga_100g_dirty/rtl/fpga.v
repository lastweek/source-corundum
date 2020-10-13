// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * FPGA top-level module
 */
module fpga (
    /*
     * Clock: 125MHz LVDS
     */
    input  wire         clk_125mhz_p,
    input  wire         clk_125mhz_n,

    /*
     * GPIO
     */
    input  wire         btnu,
    input  wire         btnl,
    input  wire         btnd,
    input  wire         btnr,
    input  wire         btnc,
    input  wire [3:0]   sw,
    output wire [7:0]   led,
    output wire [7:0]   pmod0,
    output wire [7:0]   pmod1,

    /*
     * I2C for board management
     */
    inout  wire         i2c_scl,
    inout  wire         i2c_sda,

    /*
     * Ethernet: QSFP28
     */
    output wire         qsfp1_tx1_p,
    output wire         qsfp1_tx1_n,
    input  wire         qsfp1_rx1_p,
    input  wire         qsfp1_rx1_n,
    output wire         qsfp1_tx2_p,
    output wire         qsfp1_tx2_n,
    input  wire         qsfp1_rx2_p,
    input  wire         qsfp1_rx2_n,
    output wire         qsfp1_tx3_p,
    output wire         qsfp1_tx3_n,
    input  wire         qsfp1_rx3_p,
    input  wire         qsfp1_rx3_n,
    output wire         qsfp1_tx4_p,
    output wire         qsfp1_tx4_n,
    input  wire         qsfp1_rx4_p,
    input  wire         qsfp1_rx4_n,
    input  wire         qsfp1_mgt_refclk_0_p,
    input  wire         qsfp1_mgt_refclk_0_n,
    // input  wire         qsfp1_mgt_refclk_1_p,
    // input  wire         qsfp1_mgt_refclk_1_n,
    // output wire         qsfp1_recclk_p,
    // output wire         qsfp1_recclk_n,
    output wire         qsfp1_modsell,
    output wire         qsfp1_resetl,
    input  wire         qsfp1_modprsl,
    input  wire         qsfp1_intl,
    output wire         qsfp1_lpmode,

    output wire         qsfp2_tx1_p,
    output wire         qsfp2_tx1_n,
    input  wire         qsfp2_rx1_p,
    input  wire         qsfp2_rx1_n,
    output wire         qsfp2_tx2_p,
    output wire         qsfp2_tx2_n,
    input  wire         qsfp2_rx2_p,
    input  wire         qsfp2_rx2_n,
    output wire         qsfp2_tx3_p,
    output wire         qsfp2_tx3_n,
    input  wire         qsfp2_rx3_p,
    input  wire         qsfp2_rx3_n,
    output wire         qsfp2_tx4_p,
    output wire         qsfp2_tx4_n,
    input  wire         qsfp2_rx4_p,
    input  wire         qsfp2_rx4_n,
    input  wire         qsfp2_mgt_refclk_0_p,
    input  wire         qsfp2_mgt_refclk_0_n,
    // input  wire         qsfp2_mgt_refclk_1_p,
    // input  wire         qsfp2_mgt_refclk_1_n,
    // output wire         qsfp2_recclk_p,
    // output wire         qsfp2_recclk_n,
    output wire         qsfp2_modsell,
    output wire         qsfp2_resetl,
    input  wire         qsfp2_modprsl,
    input  wire         qsfp2_intl,
    output wire         qsfp2_lpmode
);

parameter AXIS_PCIE_DATA_WIDTH = 512;
parameter AXIS_PCIE_KEEP_WIDTH = (AXIS_PCIE_DATA_WIDTH/32);
parameter AXIS_PCIE_RC_USER_WIDTH = 161;
parameter AXIS_PCIE_RQ_USER_WIDTH = 137;
parameter AXIS_PCIE_CQ_USER_WIDTH = 183;
parameter AXIS_PCIE_CC_USER_WIDTH = 81;
parameter RQ_SEQ_NUM_WIDTH = 6;
parameter BAR0_APERTURE = 24;

parameter AXIS_ETH_DATA_WIDTH = 512;
parameter AXIS_ETH_KEEP_WIDTH = AXIS_ETH_DATA_WIDTH/8;

wire clk_250mhz;
wire clk_250mhz_rst;
wire clk_125mhz;
wire clk_125mhz_rst;
wire clk_locked;

sysclk_bd sysclk_bd_i (
        .clk_125mhz (clk_125mhz),
        .clk_250mhz (clk_250mhz),
        .clk_locked (clk_locked),

	// TODO which rst shall we use?
        .reset_0 (reset_0),
        .sysclk_125_clk_n (clk_125mhz_n),
        .sysclk_125_clk_p (clk_125mhz_p)
);

sync_reset #(
    .N(4)
)
sync_reset_125mhz_inst (
    .clk(clk_125mhz),
    .rst(~clk_locked),
    .out(clk_125mhz_rst)
);

sync_reset #(
    .N(4)
)
sync_reset_250mhz_inst (
    .clk(clk_250mhz),
    .rst(~clk_locked),
    .out(clk_250mhz_rst)
);

// GPIO
wire btnu_int;
wire btnl_int;
wire btnd_int;
wire btnr_int;
wire btnc_int;
wire [3:0] sw_int;
wire qsfp1_modprsl_int;
wire qsfp2_modprsl_int;
wire qsfp1_intl_int;
wire qsfp2_intl_int;
wire i2c_scl_i;
wire i2c_scl_o;
wire i2c_scl_t;
wire i2c_sda_i;
wire i2c_sda_o;
wire i2c_sda_t;

debounce_switch #(
    .WIDTH(9),
    .N(4),
    .RATE(250000)
)
debounce_switch_inst (
    .clk(clk_250mhz),
    .rst(clk_250mhz_rst),
    .in({btnu,
        btnl,
        btnd,
        btnr,
        btnc,
        sw}),
    .out({btnu_int,
        btnl_int,
        btnd_int,
        btnr_int,
        btnc_int,
        sw_int})
);

sync_signal #(
    .WIDTH(6),
    .N(2)
)
sync_signal_inst (
    .clk(clk_250mhz),
    .in({qsfp1_modprsl, qsfp2_modprsl, qsfp1_intl, qsfp2_intl,
        i2c_scl, i2c_sda}),
    .out({qsfp1_modprsl_int, qsfp2_modprsl_int, qsfp1_intl_int, qsfp2_intl_int,
        i2c_scl_i, i2c_sda_i})
);

assign i2c_scl = i2c_scl_t ? 1'bz : i2c_scl_o;
assign i2c_sda = i2c_sda_t ? 1'bz : i2c_sda_o;

// CMAC
wire                           qsfp1_tx_clk_int;
wire                           qsfp1_tx_rst_int;

wire [AXIS_ETH_DATA_WIDTH-1:0] qsfp1_tx_axis_tdata_int;
wire [AXIS_ETH_KEEP_WIDTH-1:0] qsfp1_tx_axis_tkeep_int;
wire                           qsfp1_tx_axis_tvalid_int;
wire                           qsfp1_tx_axis_tready_int;
wire                           qsfp1_tx_axis_tlast_int;
wire                           qsfp1_tx_axis_tuser_int;

wire [AXIS_ETH_DATA_WIDTH-1:0] qsfp1_mac_tx_axis_tdata;
wire [AXIS_ETH_KEEP_WIDTH-1:0] qsfp1_mac_tx_axis_tkeep;
wire                           qsfp1_mac_tx_axis_tvalid;
wire                           qsfp1_mac_tx_axis_tready;
wire                           qsfp1_mac_tx_axis_tlast;
wire                           qsfp1_mac_tx_axis_tuser;

wire                           qsfp1_rx_clk_int;
wire                           qsfp1_rx_rst_int;

wire [AXIS_ETH_DATA_WIDTH-1:0] qsfp1_rx_axis_tdata_int;
wire [AXIS_ETH_KEEP_WIDTH-1:0] qsfp1_rx_axis_tkeep_int;
wire                           qsfp1_rx_axis_tvalid_int;
wire                           qsfp1_rx_axis_tlast_int;
wire                           qsfp1_rx_axis_tuser_int;

wire                           qsfp2_tx_clk_int;
wire                           qsfp2_tx_rst_int;

wire [AXIS_ETH_DATA_WIDTH-1:0] qsfp2_tx_axis_tdata_int;
wire [AXIS_ETH_KEEP_WIDTH-1:0] qsfp2_tx_axis_tkeep_int;
wire                           qsfp2_tx_axis_tvalid_int;
wire                           qsfp2_tx_axis_tready_int;
wire                           qsfp2_tx_axis_tlast_int;
wire                           qsfp2_tx_axis_tuser_int;

wire [AXIS_ETH_DATA_WIDTH-1:0] qsfp2_mac_tx_axis_tdata;
wire [AXIS_ETH_KEEP_WIDTH-1:0] qsfp2_mac_tx_axis_tkeep;
wire                           qsfp2_mac_tx_axis_tvalid;
wire                           qsfp2_mac_tx_axis_tready;
wire                           qsfp2_mac_tx_axis_tlast;
wire                           qsfp2_mac_tx_axis_tuser;

wire                           qsfp2_rx_clk_int;
wire                           qsfp2_rx_rst_int;

wire [AXIS_ETH_DATA_WIDTH-1:0] qsfp2_rx_axis_tdata_int;
wire [AXIS_ETH_KEEP_WIDTH-1:0] qsfp2_rx_axis_tkeep_int;
wire                           qsfp2_rx_axis_tvalid_int;
wire                           qsfp2_rx_axis_tlast_int;
wire                           qsfp2_rx_axis_tuser_int;

wire qsfp1_txuserclk2;

assign qsfp1_tx_clk_int = qsfp1_txuserclk2;
assign qsfp1_rx_clk_int = qsfp1_txuserclk2;

wire qsfp2_txuserclk2;

assign qsfp2_tx_clk_int = qsfp2_txuserclk2;
assign qsfp2_rx_clk_int = qsfp2_txuserclk2;

cmac_pad #(
    .DATA_WIDTH(AXIS_ETH_DATA_WIDTH),
    .KEEP_WIDTH(AXIS_ETH_KEEP_WIDTH),
    .USER_WIDTH(1)
)
qsfp1_cmac_pad_inst (
    .clk(qsfp1_tx_clk_int),
    .rst(qsfp1_tx_rst_int),

    .s_axis_tdata(qsfp1_tx_axis_tdata_int),
    .s_axis_tkeep(qsfp1_tx_axis_tkeep_int),
    .s_axis_tvalid(qsfp1_tx_axis_tvalid_int),
    .s_axis_tready(qsfp1_tx_axis_tready_int),
    .s_axis_tlast(qsfp1_tx_axis_tlast_int),
    .s_axis_tuser(qsfp1_tx_axis_tuser_int),

    .m_axis_tdata(qsfp1_mac_tx_axis_tdata),
    .m_axis_tkeep(qsfp1_mac_tx_axis_tkeep),
    .m_axis_tvalid(qsfp1_mac_tx_axis_tvalid),
    .m_axis_tready(qsfp1_mac_tx_axis_tready),
    .m_axis_tlast(qsfp1_mac_tx_axis_tlast),
    .m_axis_tuser(qsfp1_mac_tx_axis_tuser)
);

cmac_usplus_0
qsfp1_cmac_inst (
    .gt_rxp_in({qsfp1_rx4_p, qsfp1_rx3_p, qsfp1_rx2_p, qsfp1_rx1_p}),  // input
    .gt_rxn_in({qsfp1_rx4_n, qsfp1_rx3_n, qsfp1_rx2_n, qsfp1_rx1_n}),  // input
    .gt_txp_out({qsfp1_tx4_p, qsfp1_tx3_p, qsfp1_tx2_p, qsfp1_tx1_p}), // output
    .gt_txn_out({qsfp1_tx4_n, qsfp1_tx3_n, qsfp1_tx2_n, qsfp1_tx1_n}), // output

    .gt_txusrclk2(qsfp1_txuserclk2),	// output

    .gt_loopback_in(12'd0),		// input [11:0]
    .gt_rxrecclkout(),			// output [3:0]
    .gt_powergoodout(),			// output [3:0]
    .gt_ref_clk_out(),			// output
    .gtwiz_reset_tx_datapath(1'b0),	// input
    .gtwiz_reset_rx_datapath(1'b0),	// input

    .gt_ref_clk_p(qsfp1_mgt_refclk_0_p),// input
    .gt_ref_clk_n(qsfp1_mgt_refclk_0_n),// input

    .init_clk(clk_125mhz),		// input
    .sys_reset(clk_125mhz_rst),		// input

    .rx_axis_tvalid(qsfp1_rx_axis_tvalid_int),	// output
    .rx_axis_tdata(qsfp1_rx_axis_tdata_int),	// output [511:0]
    .rx_axis_tlast(qsfp1_rx_axis_tlast_int),	// output
    .rx_axis_tkeep(qsfp1_rx_axis_tkeep_int),	// output [63:0]
    .rx_axis_tuser(qsfp1_rx_axis_tuser_int),	// output

    .rx_otn_bip8_0(), // output [7:0]
    .rx_otn_bip8_1(), // output [7:0]
    .rx_otn_bip8_2(), // output [7:0]
    .rx_otn_bip8_3(), // output [7:0]
    .rx_otn_bip8_4(), // output [7:0]
    .rx_otn_data_0(), // output [65:0]
    .rx_otn_data_1(), // output [65:0]
    .rx_otn_data_2(), // output [65:0]
    .rx_otn_data_3(), // output [65:0]
    .rx_otn_data_4(), // output [65:0]
    .rx_otn_ena(), // output
    .rx_otn_lane0(), // output
    .rx_otn_vlmarker(), // output
    .rx_preambleout(), // output [55:0]

    .usr_rx_reset(qsfp1_rx_rst_int),	// output
    .gt_rxusrclk2(),			// output

    .stat_rx_aligned(led[1]), // output
    .stat_rx_aligned_err(), // output
    .stat_rx_bad_code(), // output [2:0]
    .stat_rx_bad_fcs(), // output [2:0]
    .stat_rx_bad_preamble(), // output
    .stat_rx_bad_sfd(), // output
    .stat_rx_bip_err_0(), // output
    .stat_rx_bip_err_1(), // output
    .stat_rx_bip_err_10(), // output
    .stat_rx_bip_err_11(), // output
    .stat_rx_bip_err_12(), // output
    .stat_rx_bip_err_13(), // output
    .stat_rx_bip_err_14(), // output
    .stat_rx_bip_err_15(), // output
    .stat_rx_bip_err_16(), // output
    .stat_rx_bip_err_17(), // output
    .stat_rx_bip_err_18(), // output
    .stat_rx_bip_err_19(), // output
    .stat_rx_bip_err_2(), // output
    .stat_rx_bip_err_3(), // output
    .stat_rx_bip_err_4(), // output
    .stat_rx_bip_err_5(), // output
    .stat_rx_bip_err_6(), // output
    .stat_rx_bip_err_7(), // output
    .stat_rx_bip_err_8(), // output
    .stat_rx_bip_err_9(), // output
    .stat_rx_block_lock(), // output [19:0]
    .stat_rx_broadcast(), // output
    .stat_rx_fragment(), // output [2:0]
    .stat_rx_framing_err_0(), // output [1:0]
    .stat_rx_framing_err_1(), // output [1:0]
    .stat_rx_framing_err_10(), // output [1:0]
    .stat_rx_framing_err_11(), // output [1:0]
    .stat_rx_framing_err_12(), // output [1:0]
    .stat_rx_framing_err_13(), // output [1:0]
    .stat_rx_framing_err_14(), // output [1:0]
    .stat_rx_framing_err_15(), // output [1:0]
    .stat_rx_framing_err_16(), // output [1:0]
    .stat_rx_framing_err_17(), // output [1:0]
    .stat_rx_framing_err_18(), // output [1:0]
    .stat_rx_framing_err_19(), // output [1:0]
    .stat_rx_framing_err_2(), // output [1:0]
    .stat_rx_framing_err_3(), // output [1:0]
    .stat_rx_framing_err_4(), // output [1:0]
    .stat_rx_framing_err_5(), // output [1:0]
    .stat_rx_framing_err_6(), // output [1:0]
    .stat_rx_framing_err_7(), // output [1:0]
    .stat_rx_framing_err_8(), // output [1:0]
    .stat_rx_framing_err_9(), // output [1:0]
    .stat_rx_framing_err_valid_0(), // output
    .stat_rx_framing_err_valid_1(), // output
    .stat_rx_framing_err_valid_10(), // output
    .stat_rx_framing_err_valid_11(), // output
    .stat_rx_framing_err_valid_12(), // output
    .stat_rx_framing_err_valid_13(), // output
    .stat_rx_framing_err_valid_14(), // output
    .stat_rx_framing_err_valid_15(), // output
    .stat_rx_framing_err_valid_16(), // output
    .stat_rx_framing_err_valid_17(), // output
    .stat_rx_framing_err_valid_18(), // output
    .stat_rx_framing_err_valid_19(), // output
    .stat_rx_framing_err_valid_2(), // output
    .stat_rx_framing_err_valid_3(), // output
    .stat_rx_framing_err_valid_4(), // output
    .stat_rx_framing_err_valid_5(), // output
    .stat_rx_framing_err_valid_6(), // output
    .stat_rx_framing_err_valid_7(), // output
    .stat_rx_framing_err_valid_8(), // output
    .stat_rx_framing_err_valid_9(), // output
    .stat_rx_got_signal_os(), // output
    .stat_rx_hi_ber(), // output
    .stat_rx_inrangeerr(), // output
    .stat_rx_internal_local_fault(), // output
    .stat_rx_jabber(), // output
    .stat_rx_local_fault(), // output
    .stat_rx_mf_err(), // output [19:0]
    .stat_rx_mf_len_err(), // output [19:0]
    .stat_rx_mf_repeat_err(), // output [19:0]
    .stat_rx_misaligned(), // output
    .stat_rx_multicast(), // output
    .stat_rx_oversize(), // output
    .stat_rx_packet_1024_1518_bytes(), // output
    .stat_rx_packet_128_255_bytes(), // output
    .stat_rx_packet_1519_1522_bytes(), // output
    .stat_rx_packet_1523_1548_bytes(), // output
    .stat_rx_packet_1549_2047_bytes(), // output
    .stat_rx_packet_2048_4095_bytes(), // output
    .stat_rx_packet_256_511_bytes(), // output
    .stat_rx_packet_4096_8191_bytes(), // output
    .stat_rx_packet_512_1023_bytes(), // output
    .stat_rx_packet_64_bytes(), // output
    .stat_rx_packet_65_127_bytes(), // output
    .stat_rx_packet_8192_9215_bytes(), // output
    .stat_rx_packet_bad_fcs(), // output
    .stat_rx_packet_large(), // output
    .stat_rx_packet_small(), // output [2:0]

    /*
     * TODO
     * The RS-FEC is enabled by default
     * Can we disable this?
     */
    .ctl_rx_enable(1'b1), // input
    .ctl_rx_force_resync(1'b0), // input
    .ctl_rx_test_pattern(1'b0), // input
    .ctl_rsfec_ieee_error_indication_mode(1'b0), // input
    .ctl_rx_rsfec_enable(1'b1), // input
    .ctl_rx_rsfec_enable_correction(1'b1), // input
    .ctl_rx_rsfec_enable_indication(1'b1), // input
    .core_rx_reset(1'b0), // input
    .rx_clk(qsfp1_rx_clk_int), // input

    .stat_rx_received_local_fault(), // output
    .stat_rx_remote_fault(), // output
    .stat_rx_status(), // output
    .stat_rx_stomped_fcs(), // output [2:0]
    .stat_rx_synced(), // output [19:0]
    .stat_rx_synced_err(), // output [19:0]
    .stat_rx_test_pattern_mismatch(), // output [2:0]
    .stat_rx_toolong(), // output
    .stat_rx_total_bytes(), // output [6:0]
    .stat_rx_total_good_bytes(), // output [13:0]
    .stat_rx_total_good_packets(), // output
    .stat_rx_total_packets(), // output [2:0]
    .stat_rx_truncated(), // output
    .stat_rx_undersize(), // output [2:0]
    .stat_rx_unicast(), // output
    .stat_rx_vlan(), // output
    .stat_rx_pcsl_demuxed(), // output [19:0]
    .stat_rx_pcsl_number_0(), // output [4:0]
    .stat_rx_pcsl_number_1(), // output [4:0]
    .stat_rx_pcsl_number_10(), // output [4:0]
    .stat_rx_pcsl_number_11(), // output [4:0]
    .stat_rx_pcsl_number_12(), // output [4:0]
    .stat_rx_pcsl_number_13(), // output [4:0]
    .stat_rx_pcsl_number_14(), // output [4:0]
    .stat_rx_pcsl_number_15(), // output [4:0]
    .stat_rx_pcsl_number_16(), // output [4:0]
    .stat_rx_pcsl_number_17(), // output [4:0]
    .stat_rx_pcsl_number_18(), // output [4:0]
    .stat_rx_pcsl_number_19(), // output [4:0]
    .stat_rx_pcsl_number_2(), // output [4:0]
    .stat_rx_pcsl_number_3(), // output [4:0]
    .stat_rx_pcsl_number_4(), // output [4:0]
    .stat_rx_pcsl_number_5(), // output [4:0]
    .stat_rx_pcsl_number_6(), // output [4:0]
    .stat_rx_pcsl_number_7(), // output [4:0]
    .stat_rx_pcsl_number_8(), // output [4:0]
    .stat_rx_pcsl_number_9(), // output [4:0]
    .stat_rx_rsfec_am_lock0(), // output
    .stat_rx_rsfec_am_lock1(), // output
    .stat_rx_rsfec_am_lock2(), // output
    .stat_rx_rsfec_am_lock3(), // output
    .stat_rx_rsfec_corrected_cw_inc(), // output
    .stat_rx_rsfec_cw_inc(), // output
    .stat_rx_rsfec_err_count0_inc(), // output [2:0]
    .stat_rx_rsfec_err_count1_inc(), // output [2:0]
    .stat_rx_rsfec_err_count2_inc(), // output [2:0]
    .stat_rx_rsfec_err_count3_inc(), // output [2:0]
    .stat_rx_rsfec_hi_ser(), // output
    .stat_rx_rsfec_lane_alignment_status(), // output
    .stat_rx_rsfec_lane_fill_0(), // output [13:0]
    .stat_rx_rsfec_lane_fill_1(), // output [13:0]
    .stat_rx_rsfec_lane_fill_2(), // output [13:0]
    .stat_rx_rsfec_lane_fill_3(), // output [13:0]
    .stat_rx_rsfec_lane_mapping(), // output [7:0]
    .stat_rx_rsfec_uncorrected_cw_inc(), // output

    .stat_tx_bad_fcs(), // output
    .stat_tx_broadcast(), // output
    .stat_tx_frame_error(), // output
    .stat_tx_local_fault(), // output
    .stat_tx_multicast(), // output
    .stat_tx_packet_1024_1518_bytes(), // output
    .stat_tx_packet_128_255_bytes(), // output
    .stat_tx_packet_1519_1522_bytes(), // output
    .stat_tx_packet_1523_1548_bytes(), // output
    .stat_tx_packet_1549_2047_bytes(), // output
    .stat_tx_packet_2048_4095_bytes(), // output
    .stat_tx_packet_256_511_bytes(), // output
    .stat_tx_packet_4096_8191_bytes(), // output
    .stat_tx_packet_512_1023_bytes(), // output
    .stat_tx_packet_64_bytes(), // output
    .stat_tx_packet_65_127_bytes(), // output
    .stat_tx_packet_8192_9215_bytes(), // output
    .stat_tx_packet_large(), // output
    .stat_tx_packet_small(), // output
    .stat_tx_total_bytes(), // output [5:0]
    .stat_tx_total_good_bytes(), // output [13:0]
    .stat_tx_total_good_packets(), // output
    .stat_tx_total_packets(), // output
    .stat_tx_unicast(), // output
    .stat_tx_vlan(), // output

    .ctl_tx_enable(1'b1), // input
    .ctl_tx_test_pattern(1'b0), // input
    .ctl_tx_rsfec_enable(1'b1), // input
    .ctl_tx_send_idle(1'b0), // input
    .ctl_tx_send_rfi(1'b0), // input
    .ctl_tx_send_lfi(1'b0), // input
    .core_tx_reset(1'b0), // input

    .tx_axis_tready(qsfp1_mac_tx_axis_tready), // output
    .tx_axis_tvalid(qsfp1_mac_tx_axis_tvalid), // input
    .tx_axis_tdata(qsfp1_mac_tx_axis_tdata), // input [511:0]
    .tx_axis_tlast(qsfp1_mac_tx_axis_tlast), // input
    .tx_axis_tkeep(qsfp1_mac_tx_axis_tkeep), // input [63:0]
    .tx_axis_tuser(qsfp1_mac_tx_axis_tuser), // input

    .tx_ovfout(), // output
    .tx_unfout(), // output
    .tx_preamblein(56'd0), // input [55:0]

    .usr_tx_reset(qsfp1_tx_rst_int), // output

    .core_drp_reset(1'b0), // input
    .drp_clk(1'b0), // input
    .drp_addr(10'd0), // input [9:0]
    .drp_di(16'd0), // input [15:0]
    .drp_en(1'b0), // input
    .drp_do(), // output [15:0]
    .drp_rdy(), // output
    .drp_we(1'b0) // input
);

cmac_pad #(
    .DATA_WIDTH(AXIS_ETH_DATA_WIDTH),
    .KEEP_WIDTH(AXIS_ETH_KEEP_WIDTH),
    .USER_WIDTH(1)
)
qsfp2_cmac_pad_inst (
    .clk(qsfp2_tx_clk_int),
    .rst(qsfp2_tx_rst_int),

    .s_axis_tdata(qsfp2_tx_axis_tdata_int),
    .s_axis_tkeep(qsfp2_tx_axis_tkeep_int),
    .s_axis_tvalid(qsfp2_tx_axis_tvalid_int),
    .s_axis_tready(qsfp2_tx_axis_tready_int),
    .s_axis_tlast(qsfp2_tx_axis_tlast_int),
    .s_axis_tuser(qsfp2_tx_axis_tuser_int),

    .m_axis_tdata(qsfp2_mac_tx_axis_tdata),
    .m_axis_tkeep(qsfp2_mac_tx_axis_tkeep),
    .m_axis_tvalid(qsfp2_mac_tx_axis_tvalid),
    .m_axis_tready(qsfp2_mac_tx_axis_tready),
    .m_axis_tlast(qsfp2_mac_tx_axis_tlast),
    .m_axis_tuser(qsfp2_mac_tx_axis_tuser)
);

cmac_usplus_1
qsfp2_cmac_inst (
    .gt_rxp_in({qsfp2_rx4_p, qsfp2_rx3_p, qsfp2_rx2_p, qsfp2_rx1_p}), // input
    .gt_rxn_in({qsfp2_rx4_n, qsfp2_rx3_n, qsfp2_rx2_n, qsfp2_rx1_n}), // input
    .gt_txp_out({qsfp2_tx4_p, qsfp2_tx3_p, qsfp2_tx2_p, qsfp2_tx1_p}), // output
    .gt_txn_out({qsfp2_tx4_n, qsfp2_tx3_n, qsfp2_tx2_n, qsfp2_tx1_n}), // output
    .gt_txusrclk2(qsfp2_txuserclk2), // output
    .gt_loopback_in(12'd0), // input [11:0]
    .gt_rxrecclkout(), // output [3:0]
    .gt_powergoodout(), // output [3:0]
    .gt_ref_clk_out(), // output
    .gtwiz_reset_tx_datapath(1'b0), // input
    .gtwiz_reset_rx_datapath(1'b0), // input

    .gt_ref_clk_p(qsfp2_mgt_refclk_0_p), // input
    .gt_ref_clk_n(qsfp2_mgt_refclk_0_n), // input

    .init_clk(clk_125mhz), // input
    .sys_reset(clk_125mhz_rst), // input

    .rx_axis_tvalid(qsfp2_rx_axis_tvalid_int), // output
    .rx_axis_tdata(qsfp2_rx_axis_tdata_int), // output [511:0]
    .rx_axis_tlast(qsfp2_rx_axis_tlast_int), // output
    .rx_axis_tkeep(qsfp2_rx_axis_tkeep_int), // output [63:0]
    .rx_axis_tuser(qsfp2_rx_axis_tuser_int), // output

    .rx_otn_bip8_0(), // output [7:0]
    .rx_otn_bip8_1(), // output [7:0]
    .rx_otn_bip8_2(), // output [7:0]
    .rx_otn_bip8_3(), // output [7:0]
    .rx_otn_bip8_4(), // output [7:0]
    .rx_otn_data_0(), // output [65:0]
    .rx_otn_data_1(), // output [65:0]
    .rx_otn_data_2(), // output [65:0]
    .rx_otn_data_3(), // output [65:0]
    .rx_otn_data_4(), // output [65:0]
    .rx_otn_ena(), // output
    .rx_otn_lane0(), // output
    .rx_otn_vlmarker(), // output
    .rx_preambleout(), // output [55:0]
    .usr_rx_reset(qsfp2_rx_rst_int), // output
    .gt_rxusrclk2(), // output

    .stat_rx_aligned(led[0]), // output
    .stat_rx_aligned_err(), // output
    .stat_rx_bad_code(), // output [2:0]
    .stat_rx_bad_fcs(), // output [2:0]
    .stat_rx_bad_preamble(), // output
    .stat_rx_bad_sfd(), // output
    .stat_rx_bip_err_0(), // output
    .stat_rx_bip_err_1(), // output
    .stat_rx_bip_err_10(), // output
    .stat_rx_bip_err_11(), // output
    .stat_rx_bip_err_12(), // output
    .stat_rx_bip_err_13(), // output
    .stat_rx_bip_err_14(), // output
    .stat_rx_bip_err_15(), // output
    .stat_rx_bip_err_16(), // output
    .stat_rx_bip_err_17(), // output
    .stat_rx_bip_err_18(), // output
    .stat_rx_bip_err_19(), // output
    .stat_rx_bip_err_2(), // output
    .stat_rx_bip_err_3(), // output
    .stat_rx_bip_err_4(), // output
    .stat_rx_bip_err_5(), // output
    .stat_rx_bip_err_6(), // output
    .stat_rx_bip_err_7(), // output
    .stat_rx_bip_err_8(), // output
    .stat_rx_bip_err_9(), // output
    .stat_rx_block_lock(), // output [19:0]
    .stat_rx_broadcast(), // output
    .stat_rx_fragment(), // output [2:0]
    .stat_rx_framing_err_0(), // output [1:0]
    .stat_rx_framing_err_1(), // output [1:0]
    .stat_rx_framing_err_10(), // output [1:0]
    .stat_rx_framing_err_11(), // output [1:0]
    .stat_rx_framing_err_12(), // output [1:0]
    .stat_rx_framing_err_13(), // output [1:0]
    .stat_rx_framing_err_14(), // output [1:0]
    .stat_rx_framing_err_15(), // output [1:0]
    .stat_rx_framing_err_16(), // output [1:0]
    .stat_rx_framing_err_17(), // output [1:0]
    .stat_rx_framing_err_18(), // output [1:0]
    .stat_rx_framing_err_19(), // output [1:0]
    .stat_rx_framing_err_2(), // output [1:0]
    .stat_rx_framing_err_3(), // output [1:0]
    .stat_rx_framing_err_4(), // output [1:0]
    .stat_rx_framing_err_5(), // output [1:0]
    .stat_rx_framing_err_6(), // output [1:0]
    .stat_rx_framing_err_7(), // output [1:0]
    .stat_rx_framing_err_8(), // output [1:0]
    .stat_rx_framing_err_9(), // output [1:0]
    .stat_rx_framing_err_valid_0(), // output
    .stat_rx_framing_err_valid_1(), // output
    .stat_rx_framing_err_valid_10(), // output
    .stat_rx_framing_err_valid_11(), // output
    .stat_rx_framing_err_valid_12(), // output
    .stat_rx_framing_err_valid_13(), // output
    .stat_rx_framing_err_valid_14(), // output
    .stat_rx_framing_err_valid_15(), // output
    .stat_rx_framing_err_valid_16(), // output
    .stat_rx_framing_err_valid_17(), // output
    .stat_rx_framing_err_valid_18(), // output
    .stat_rx_framing_err_valid_19(), // output
    .stat_rx_framing_err_valid_2(), // output
    .stat_rx_framing_err_valid_3(), // output
    .stat_rx_framing_err_valid_4(), // output
    .stat_rx_framing_err_valid_5(), // output
    .stat_rx_framing_err_valid_6(), // output
    .stat_rx_framing_err_valid_7(), // output
    .stat_rx_framing_err_valid_8(), // output
    .stat_rx_framing_err_valid_9(), // output
    .stat_rx_got_signal_os(), // output
    .stat_rx_hi_ber(), // output
    .stat_rx_inrangeerr(), // output
    .stat_rx_internal_local_fault(), // output
    .stat_rx_jabber(), // output
    .stat_rx_local_fault(), // output
    .stat_rx_mf_err(), // output [19:0]
    .stat_rx_mf_len_err(), // output [19:0]
    .stat_rx_mf_repeat_err(), // output [19:0]
    .stat_rx_misaligned(), // output
    .stat_rx_multicast(), // output
    .stat_rx_oversize(), // output
    .stat_rx_packet_1024_1518_bytes(), // output
    .stat_rx_packet_128_255_bytes(), // output
    .stat_rx_packet_1519_1522_bytes(), // output
    .stat_rx_packet_1523_1548_bytes(), // output
    .stat_rx_packet_1549_2047_bytes(), // output
    .stat_rx_packet_2048_4095_bytes(), // output
    .stat_rx_packet_256_511_bytes(), // output
    .stat_rx_packet_4096_8191_bytes(), // output
    .stat_rx_packet_512_1023_bytes(), // output
    .stat_rx_packet_64_bytes(), // output
    .stat_rx_packet_65_127_bytes(), // output
    .stat_rx_packet_8192_9215_bytes(), // output
    .stat_rx_packet_bad_fcs(), // output
    .stat_rx_packet_large(), // output
    .stat_rx_packet_small(), // output [2:0]

    .ctl_rx_enable(1'b1), // input
    .ctl_rx_force_resync(1'b0), // input
    .ctl_rx_test_pattern(1'b0), // input
    .ctl_rsfec_ieee_error_indication_mode(1'b0), // input
    .ctl_rx_rsfec_enable(1'b1), // input
    .ctl_rx_rsfec_enable_correction(1'b1), // input
    .ctl_rx_rsfec_enable_indication(1'b1), // input
    .core_rx_reset(1'b0), // input
    .rx_clk(qsfp2_rx_clk_int), // input

    .stat_rx_received_local_fault(), // output
    .stat_rx_remote_fault(), // output
    .stat_rx_status(), // output
    .stat_rx_stomped_fcs(), // output [2:0]
    .stat_rx_synced(), // output [19:0]
    .stat_rx_synced_err(), // output [19:0]
    .stat_rx_test_pattern_mismatch(), // output [2:0]
    .stat_rx_toolong(), // output
    .stat_rx_total_bytes(), // output [6:0]
    .stat_rx_total_good_bytes(), // output [13:0]
    .stat_rx_total_good_packets(), // output
    .stat_rx_total_packets(), // output [2:0]
    .stat_rx_truncated(), // output
    .stat_rx_undersize(), // output [2:0]
    .stat_rx_unicast(), // output
    .stat_rx_vlan(), // output
    .stat_rx_pcsl_demuxed(), // output [19:0]
    .stat_rx_pcsl_number_0(), // output [4:0]
    .stat_rx_pcsl_number_1(), // output [4:0]
    .stat_rx_pcsl_number_10(), // output [4:0]
    .stat_rx_pcsl_number_11(), // output [4:0]
    .stat_rx_pcsl_number_12(), // output [4:0]
    .stat_rx_pcsl_number_13(), // output [4:0]
    .stat_rx_pcsl_number_14(), // output [4:0]
    .stat_rx_pcsl_number_15(), // output [4:0]
    .stat_rx_pcsl_number_16(), // output [4:0]
    .stat_rx_pcsl_number_17(), // output [4:0]
    .stat_rx_pcsl_number_18(), // output [4:0]
    .stat_rx_pcsl_number_19(), // output [4:0]
    .stat_rx_pcsl_number_2(), // output [4:0]
    .stat_rx_pcsl_number_3(), // output [4:0]
    .stat_rx_pcsl_number_4(), // output [4:0]
    .stat_rx_pcsl_number_5(), // output [4:0]
    .stat_rx_pcsl_number_6(), // output [4:0]
    .stat_rx_pcsl_number_7(), // output [4:0]
    .stat_rx_pcsl_number_8(), // output [4:0]
    .stat_rx_pcsl_number_9(), // output [4:0]
    .stat_rx_rsfec_am_lock0(), // output
    .stat_rx_rsfec_am_lock1(), // output
    .stat_rx_rsfec_am_lock2(), // output
    .stat_rx_rsfec_am_lock3(), // output
    .stat_rx_rsfec_corrected_cw_inc(), // output
    .stat_rx_rsfec_cw_inc(), // output
    .stat_rx_rsfec_err_count0_inc(), // output [2:0]
    .stat_rx_rsfec_err_count1_inc(), // output [2:0]
    .stat_rx_rsfec_err_count2_inc(), // output [2:0]
    .stat_rx_rsfec_err_count3_inc(), // output [2:0]
    .stat_rx_rsfec_hi_ser(), // output
    .stat_rx_rsfec_lane_alignment_status(), // output
    .stat_rx_rsfec_lane_fill_0(), // output [13:0]
    .stat_rx_rsfec_lane_fill_1(), // output [13:0]
    .stat_rx_rsfec_lane_fill_2(), // output [13:0]
    .stat_rx_rsfec_lane_fill_3(), // output [13:0]
    .stat_rx_rsfec_lane_mapping(), // output [7:0]
    .stat_rx_rsfec_uncorrected_cw_inc(), // output

    .stat_tx_bad_fcs(), // output
    .stat_tx_broadcast(), // output
    .stat_tx_frame_error(), // output
    .stat_tx_local_fault(), // output
    .stat_tx_multicast(), // output
    .stat_tx_packet_1024_1518_bytes(), // output
    .stat_tx_packet_128_255_bytes(), // output
    .stat_tx_packet_1519_1522_bytes(), // output
    .stat_tx_packet_1523_1548_bytes(), // output
    .stat_tx_packet_1549_2047_bytes(), // output
    .stat_tx_packet_2048_4095_bytes(), // output
    .stat_tx_packet_256_511_bytes(), // output
    .stat_tx_packet_4096_8191_bytes(), // output
    .stat_tx_packet_512_1023_bytes(), // output
    .stat_tx_packet_64_bytes(), // output
    .stat_tx_packet_65_127_bytes(), // output
    .stat_tx_packet_8192_9215_bytes(), // output
    .stat_tx_packet_large(), // output
    .stat_tx_packet_small(), // output
    .stat_tx_total_bytes(), // output [5:0]
    .stat_tx_total_good_bytes(), // output [13:0]
    .stat_tx_total_good_packets(), // output
    .stat_tx_total_packets(), // output
    .stat_tx_unicast(), // output
    .stat_tx_vlan(), // output

    .ctl_tx_enable(1'b1), // input
    .ctl_tx_test_pattern(1'b0), // input
    .ctl_tx_rsfec_enable(1'b1), // input
    .ctl_tx_send_idle(1'b0), // input
    .ctl_tx_send_rfi(1'b0), // input
    .ctl_tx_send_lfi(1'b0), // input
    .core_tx_reset(1'b0), // input

    .tx_axis_tready(qsfp2_mac_tx_axis_tready), // output
    .tx_axis_tvalid(qsfp2_mac_tx_axis_tvalid), // input
    .tx_axis_tdata(qsfp2_mac_tx_axis_tdata), // input [511:0]
    .tx_axis_tlast(qsfp2_mac_tx_axis_tlast), // input
    .tx_axis_tkeep(qsfp2_mac_tx_axis_tkeep), // input [63:0]
    .tx_axis_tuser(qsfp2_mac_tx_axis_tuser), // input

    .tx_ovfout(), // output
    .tx_unfout(), // output
    .tx_preamblein(56'd0), // input [55:0]
    .usr_tx_reset(qsfp2_tx_rst_int), // output

    .core_drp_reset(1'b0), // input
    .drp_clk(1'b0), // input
    .drp_addr(10'd0), // input [9:0]
    .drp_di(16'd0), // input [15:0]
    .drp_en(1'b0), // input
    .drp_do(), // output [15:0]
    .drp_rdy(), // output
    .drp_we(1'b0) // input
);

fpga_core #(
    .AXIS_PCIE_DATA_WIDTH(AXIS_PCIE_DATA_WIDTH),
    .AXIS_PCIE_KEEP_WIDTH(AXIS_PCIE_KEEP_WIDTH),
    .AXIS_PCIE_RC_USER_WIDTH(AXIS_PCIE_RC_USER_WIDTH),
    .AXIS_PCIE_RQ_USER_WIDTH(AXIS_PCIE_RQ_USER_WIDTH),
    .AXIS_PCIE_CQ_USER_WIDTH(AXIS_PCIE_CQ_USER_WIDTH),
    .AXIS_PCIE_CC_USER_WIDTH(AXIS_PCIE_CC_USER_WIDTH),
    .RQ_SEQ_NUM_WIDTH(RQ_SEQ_NUM_WIDTH),
    .BAR0_APERTURE(BAR0_APERTURE)
)
core_inst (
    /*
     * Clock: 250 MHz
     * Synchronous reset
     */
    .clk_250mhz(clk_250mhz),
    .rst_250mhz(clk_250mhz_rst),

    /*
     * GPIO
     */
    .btnu(btnu_int),
    .btnl(btnl_int),
    .btnd(btnd_int),
    .btnr(btnr_int),
    .btnc(btnc_int),
    .sw(sw_int),

    /*
     * I2C
     */
    .i2c_scl_i(i2c_scl_i),
    .i2c_scl_o(i2c_scl_o),
    .i2c_scl_t(i2c_scl_t),
    .i2c_sda_i(i2c_sda_i),
    .i2c_sda_o(i2c_sda_o),
    .i2c_sda_t(i2c_sda_t),

    /*
     * Ethernet: QSFP28
     */
    .qsfp1_tx_clk(qsfp1_tx_clk_int),
    .qsfp1_tx_rst(qsfp1_tx_rst_int),

    .qsfp1_tx_axis_tdata(qsfp1_tx_axis_tdata_int),
    .qsfp1_tx_axis_tkeep(qsfp1_tx_axis_tkeep_int),
    .qsfp1_tx_axis_tvalid(qsfp1_tx_axis_tvalid_int),
    .qsfp1_tx_axis_tready(qsfp1_tx_axis_tready_int),
    .qsfp1_tx_axis_tlast(qsfp1_tx_axis_tlast_int),
    .qsfp1_tx_axis_tuser(qsfp1_tx_axis_tuser_int),

    .qsfp1_rx_clk(qsfp1_rx_clk_int),
    .qsfp1_rx_rst(qsfp1_rx_rst_int),

    .qsfp1_rx_axis_tdata(qsfp1_rx_axis_tdata_int),
    .qsfp1_rx_axis_tkeep(qsfp1_rx_axis_tkeep_int),
    .qsfp1_rx_axis_tvalid(qsfp1_rx_axis_tvalid_int),
    .qsfp1_rx_axis_tlast(qsfp1_rx_axis_tlast_int),
    .qsfp1_rx_axis_tuser(qsfp1_rx_axis_tuser_int),

    .qsfp1_modprsl(qsfp1_modprsl_int),
    .qsfp1_modsell(qsfp1_modsell),
    .qsfp1_resetl(qsfp1_resetl),
    .qsfp1_intl(qsfp1_intl_int),
    .qsfp1_lpmode(qsfp1_lpmode_int),

    /*
     * Ethernet: QSFP28
     */
    .qsfp2_tx_clk(qsfp2_tx_clk_int),
    .qsfp2_tx_rst(qsfp2_tx_rst_int),

    .qsfp2_tx_axis_tdata(qsfp2_tx_axis_tdata_int),
    .qsfp2_tx_axis_tkeep(qsfp2_tx_axis_tkeep_int),
    .qsfp2_tx_axis_tvalid(qsfp2_tx_axis_tvalid_int),
    .qsfp2_tx_axis_tready(qsfp2_tx_axis_tready_int),
    .qsfp2_tx_axis_tlast(qsfp2_tx_axis_tlast_int),
    .qsfp2_tx_axis_tuser(qsfp2_tx_axis_tuser_int),

    .qsfp2_rx_clk(qsfp2_rx_clk_int),
    .qsfp2_rx_rst(qsfp2_rx_rst_int),

    .qsfp2_rx_axis_tdata(qsfp2_rx_axis_tdata_int),
    .qsfp2_rx_axis_tkeep(qsfp2_rx_axis_tkeep_int),
    .qsfp2_rx_axis_tvalid(qsfp2_rx_axis_tvalid_int),
    .qsfp2_rx_axis_tlast(qsfp2_rx_axis_tlast_int),
    .qsfp2_rx_axis_tuser(qsfp2_rx_axis_tuser_int),

    .qsfp2_modprsl(qsfp2_modprsl_int),
    .qsfp2_modsell(qsfp2_modsell),
    .qsfp2_resetl(qsfp2_resetl),
    .qsfp2_intl(qsfp2_intl_int),
    .qsfp2_lpmode(qsfp2_lpmode_int)
);

endmodule
