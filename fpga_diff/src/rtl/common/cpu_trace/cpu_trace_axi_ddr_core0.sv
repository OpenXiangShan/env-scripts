`timescale 1ns/1ps

// Passive 692-bit CPU trace writer for the UVHS trace-DDR target.
// One trace record becomes two 512-bit ingress beats, then four 256-bit
// chunks striped CH0/CH1/CH0/CH1.  Strobe metadata is stored in CH0 DDR.
module cpu_trace_axi_ddr_core0 #(
    parameter integer ADDR_WIDTH = 34,
    parameter integer ID_WIDTH = 14,
    parameter [ADDR_WIDTH-1:0] META_BASE_ADDR = 34'h2_0000_0000
) (
    input  wire                    cpu_clk,
    input  wire                    cpu_ctrl_clk,
    input  wire                    trace_clk,
    input  wire                    resetn,
    input  wire [691:0]            trace_data,
    input  wire                    trace_valid,
    output wire                    trace_ready,

    output wire [ID_WIDTH-1:0]     m0_axi_awid,
    output wire [ADDR_WIDTH-1:0]   m0_axi_awaddr,
    output wire [7:0]              m0_axi_awlen,
    output wire [2:0]              m0_axi_awsize,
    output wire [1:0]              m0_axi_awburst,
    output wire                    m0_axi_awlock,
    output wire [3:0]              m0_axi_awcache,
    output wire [2:0]              m0_axi_awprot,
    output wire [3:0]              m0_axi_awqos,
    output wire                    m0_axi_awvalid,
    input  wire                    m0_axi_awready,
    output wire [255:0]            m0_axi_wdata,
    output wire [31:0]             m0_axi_wstrb,
    output wire                    m0_axi_wlast,
    output wire                    m0_axi_wvalid,
    input  wire                    m0_axi_wready,
    input  wire [ID_WIDTH-1:0]     m0_axi_bid,
    input  wire [1:0]              m0_axi_bresp,
    input  wire                    m0_axi_bvalid,
    output wire                    m0_axi_bready,

    output wire [ID_WIDTH-1:0]     m1_axi_awid,
    output wire [ADDR_WIDTH-1:0]   m1_axi_awaddr,
    output wire [7:0]              m1_axi_awlen,
    output wire [2:0]              m1_axi_awsize,
    output wire [1:0]              m1_axi_awburst,
    output wire                    m1_axi_awlock,
    output wire [3:0]              m1_axi_awcache,
    output wire [2:0]              m1_axi_awprot,
    output wire [3:0]              m1_axi_awqos,
    output wire                    m1_axi_awvalid,
    input  wire                    m1_axi_awready,
    output wire [255:0]            m1_axi_wdata,
    output wire [31:0]             m1_axi_wstrb,
    output wire                    m1_axi_wlast,
    output wire                    m1_axi_wvalid,
    input  wire                    m1_axi_wready,
    input  wire [ID_WIDTH-1:0]     m1_axi_bid,
    input  wire [1:0]              m1_axi_bresp,
    input  wire                    m1_axi_bvalid,
    output wire                    m1_axi_bready
);

    wire [ID_WIDTH-1:0] cvt_awid;
    wire [ADDR_WIDTH-1:0] cvt_awaddr;
    wire [7:0] cvt_awlen;
    wire [2:0] cvt_awsize;
    wire [1:0] cvt_awburst;
    wire cvt_awlock;
    wire [3:0] cvt_awcache;
    wire [2:0] cvt_awprot;
    wire [3:0] cvt_awqos;
    wire cvt_awvalid;
    wire cvt_awready;
    wire [511:0] cvt_wdata;
    wire [63:0] cvt_wstrb;
    wire cvt_wlast;
    wire cvt_wvalid;
    wire cvt_wready;
    wire [ID_WIDTH-1:0] cvt_bid;
    wire [1:0] cvt_bresp;
    wire cvt_bvalid;
    wire cvt_bready;
    wire cvt_in_ready;

    // This port is informational only: trace capture is deliberately passive.
    // Accept a snapshot only when the async ingress FIFO has room; otherwise
    // drop it instead of backpressuring or clock-gating the observed CPU.
    assign trace_ready = cvt_in_ready;

    Difftest2AXI4 #(
        .INPUT_WIDTH    (692),
        .AXI_DATA_WIDTH (512),
        .AXI_ADDR_WIDTH (ADDR_WIDTH),
        .AXI_ID_WIDTH   (ID_WIDTH),
        .BASE_ADDR      ({ADDR_WIDTH{1'b0}}),
        .FIFO_DEPTH     (128),
        .MAX_BURST_LEN  (2)
    ) u_trace_to_axi (
        .in_clk         (cpu_clk),
        .in_ctrl_clk    (cpu_ctrl_clk),
        .in_resetn      (resetn),
        .in_data        (trace_data),
        .in_valid       (trace_valid),
        .in_ready       (cvt_in_ready),
        .axi_clk        (trace_clk),
        .axi_resetn     (resetn),
        .m_axi_awid     (cvt_awid),
        .m_axi_awaddr   (cvt_awaddr),
        .m_axi_awlen    (cvt_awlen),
        .m_axi_awsize   (cvt_awsize),
        .m_axi_awburst  (cvt_awburst),
        .m_axi_awlock   (cvt_awlock),
        .m_axi_awcache  (cvt_awcache),
        .m_axi_awprot   (cvt_awprot),
        .m_axi_awqos    (cvt_awqos),
        .m_axi_awvalid  (cvt_awvalid),
        .m_axi_awready  (cvt_awready),
        .m_axi_wdata    (cvt_wdata),
        .m_axi_wstrb    (cvt_wstrb),
        .m_axi_wlast    (cvt_wlast),
        .m_axi_wvalid   (cvt_wvalid),
        .m_axi_wready   (cvt_wready),
        .m_axi_bid      (cvt_bid),
        .m_axi_bresp    (cvt_bresp),
        .m_axi_bvalid   (cvt_bvalid),
        .m_axi_bready   (cvt_bready)
    );

    ddr_memtest_cpu_axi_passive_top #(
        .AXI_DATA_WIDTH          (256),
        .CPU_AXI_DATA_WIDTH      (512),
        .ADDR_WIDTH              (ADDR_WIDTH),
        .ID_WIDTH                (ID_WIDTH),
        .FIFO_DEPTH              (1024),
        .BURST_LEN               (16),
        .FLUSH_IDLE_CYCLES       (32),
        .CPU_OUTSTANDING_BURSTS  (8),
        .DDR_OUTSTANDING_BURSTS  (8),
        .CH0_BASE_ADDR           ({ADDR_WIDTH{1'b0}}),
        .CH1_BASE_ADDR           ({ADDR_WIDTH{1'b0}}),
        .STROBE_META_BASE_ADDR   (META_BASE_ADDR),
        .CH0_AXI_ID              ({ID_WIDTH{1'b0}}),
        .CH1_AXI_ID              (ID_WIDTH'(1)),
        .STROBE_META_AXI_ID      (ID_WIDTH'(2))
    ) u_passive_backend (
        .clk1                         (trace_clk),
        .rst1_n                       (resetn),
        .clk2                         (trace_clk),
        .rst2_n                       (resetn),
        .enable                       (1'b1),
        .cfg_partial_wstrb            (64'h0000_0000_007f_ffff),
        .cfg_base_addr_load           (1'b0),
        .cfg_ch0_base_addr            ({ADDR_WIDTH{1'b0}}),
        .cfg_ch1_base_addr            ({ADDR_WIDTH{1'b0}}),
        .cfg_strobe_meta_base_addr    (META_BASE_ADDR),
        .s_cpu_axi_awid               (cvt_awid),
        .s_cpu_axi_awaddr             (cvt_awaddr),
        .s_cpu_axi_awlen              (cvt_awlen),
        .s_cpu_axi_awsize             (cvt_awsize),
        .s_cpu_axi_awburst            (cvt_awburst),
        .s_cpu_axi_awvalid            (cvt_awvalid),
        .s_cpu_axi_awready            (cvt_awready),
        .s_cpu_axi_wdata              (cvt_wdata),
        .s_cpu_axi_wstrb              (cvt_wstrb),
        .s_cpu_axi_wlast              (cvt_wlast),
        .s_cpu_axi_wvalid             (cvt_wvalid),
        .s_cpu_axi_wready             (cvt_wready),
        .s_cpu_axi_bid                (cvt_bid),
        .s_cpu_axi_bresp              (cvt_bresp),
        .s_cpu_axi_bvalid             (cvt_bvalid),
        .s_cpu_axi_bready             (cvt_bready),
        .m0_axi_awid                  (m0_axi_awid),
        .m0_axi_awaddr                (m0_axi_awaddr),
        .m0_axi_awlen                 (m0_axi_awlen),
        .m0_axi_awsize                (m0_axi_awsize),
        .m0_axi_awburst               (m0_axi_awburst),
        .m0_axi_awlock                (m0_axi_awlock),
        .m0_axi_awcache               (m0_axi_awcache),
        .m0_axi_awprot                (m0_axi_awprot),
        .m0_axi_awqos                 (m0_axi_awqos),
        .m0_axi_awvalid               (m0_axi_awvalid),
        .m0_axi_awready               (m0_axi_awready),
        .m0_axi_wdata                 (m0_axi_wdata),
        .m0_axi_wstrb                 (m0_axi_wstrb),
        .m0_axi_wlast                 (m0_axi_wlast),
        .m0_axi_wvalid                (m0_axi_wvalid),
        .m0_axi_wready                (m0_axi_wready),
        .m0_axi_bid                   (m0_axi_bid),
        .m0_axi_bresp                 (m0_axi_bresp),
        .m0_axi_bvalid                (m0_axi_bvalid),
        .m0_axi_bready                (m0_axi_bready),
        .m1_axi_awid                  (m1_axi_awid),
        .m1_axi_awaddr                (m1_axi_awaddr),
        .m1_axi_awlen                 (m1_axi_awlen),
        .m1_axi_awsize                (m1_axi_awsize),
        .m1_axi_awburst               (m1_axi_awburst),
        .m1_axi_awlock                (m1_axi_awlock),
        .m1_axi_awcache               (m1_axi_awcache),
        .m1_axi_awprot                (m1_axi_awprot),
        .m1_axi_awqos                 (m1_axi_awqos),
        .m1_axi_awvalid               (m1_axi_awvalid),
        .m1_axi_awready               (m1_axi_awready),
        .m1_axi_wdata                 (m1_axi_wdata),
        .m1_axi_wstrb                 (m1_axi_wstrb),
        .m1_axi_wlast                 (m1_axi_wlast),
        .m1_axi_wvalid                (m1_axi_wvalid),
        .m1_axi_wready                (m1_axi_wready),
        .m1_axi_bid                   (m1_axi_bid),
        .m1_axi_bresp                 (m1_axi_bresp),
        .m1_axi_bvalid                (m1_axi_bvalid),
        .m1_axi_bready                (m1_axi_bready)
    );

    wire _unused_converter_sideband = &{1'b0, cvt_awlock, cvt_awcache,
                                         cvt_awprot, cvt_awqos};
endmodule
