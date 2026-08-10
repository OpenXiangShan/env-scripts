`timescale 1ns/1ps

module ddr_memtest_cpu_axi_passive_top #(
    parameter int unsigned AXI_DATA_WIDTH      = 256,
    parameter int unsigned CPU_AXI_DATA_WIDTH  = 4096,
    parameter int unsigned ADDR_WIDTH          = 32,
    parameter int unsigned ID_WIDTH            = 4,
    parameter int unsigned FIFO_DEPTH          = 1024,
    parameter int unsigned BURST_LEN           = 16,
    parameter int unsigned FLUSH_IDLE_CYCLES   = 32,
    parameter int unsigned CPU_OUTSTANDING_BURSTS = 8,
    parameter int unsigned DDR_OUTSTANDING_BURSTS = 8,
    parameter [ADDR_WIDTH-1:0] CH0_BASE_ADDR   = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0] CH1_BASE_ADDR   = {ADDR_WIDTH{1'b0}},
    parameter [ADDR_WIDTH-1:0] STROBE_META_BASE_ADDR = 32'h0001_0000,
    parameter [ID_WIDTH-1:0]   CH0_AXI_ID      = {ID_WIDTH{1'b0}},
    parameter [ID_WIDTH-1:0]   CH1_AXI_ID      = 1,
    parameter [ID_WIDTH-1:0]   STROBE_META_AXI_ID = 2
) (
    input  wire                           clk1,
    input  wire                           rst1_n,
    input  wire                           clk2,
    input  wire                           rst2_n,
    input  wire                           enable,
    input  wire [CPU_AXI_DATA_WIDTH/8-1:0] cfg_partial_wstrb,
    input  wire                           cfg_base_addr_load,
    input  wire [ADDR_WIDTH-1:0]          cfg_ch0_base_addr,
    input  wire [ADDR_WIDTH-1:0]          cfg_ch1_base_addr,
    input  wire [ADDR_WIDTH-1:0]          cfg_strobe_meta_base_addr,

    // CPU AXI4 write slave
    input  wire [ID_WIDTH-1:0]            s_cpu_axi_awid,
    input  wire [ADDR_WIDTH-1:0]          s_cpu_axi_awaddr,
    input  wire [7:0]                     s_cpu_axi_awlen,
    input  wire [2:0]                     s_cpu_axi_awsize,
    input  wire [1:0]                     s_cpu_axi_awburst,
    input  wire                           s_cpu_axi_awvalid,
    output wire                           s_cpu_axi_awready,
    input  wire [CPU_AXI_DATA_WIDTH-1:0]  s_cpu_axi_wdata,
    input  wire [CPU_AXI_DATA_WIDTH/8-1:0] s_cpu_axi_wstrb,
    input  wire                           s_cpu_axi_wlast,
    input  wire                           s_cpu_axi_wvalid,
    output wire                           s_cpu_axi_wready,
    output wire [ID_WIDTH-1:0]            s_cpu_axi_bid,
    output wire [1:0]                     s_cpu_axi_bresp,
    output wire                           s_cpu_axi_bvalid,
    input  wire                           s_cpu_axi_bready,

    // AXI master 0 (DDR0 data + strobe metadata)
    output wire [ID_WIDTH-1:0]            m0_axi_awid,
    output wire [ADDR_WIDTH-1:0]          m0_axi_awaddr,
    output wire [7:0]                     m0_axi_awlen,
    output wire [2:0]                     m0_axi_awsize,
    output wire [1:0]                     m0_axi_awburst,
    output wire                           m0_axi_awlock,
    output wire [3:0]                     m0_axi_awcache,
    output wire [2:0]                     m0_axi_awprot,
    output wire [3:0]                     m0_axi_awqos,
    output wire                           m0_axi_awvalid,
    input  wire                           m0_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]      m0_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0]    m0_axi_wstrb,
    output wire                           m0_axi_wlast,
    output wire                           m0_axi_wvalid,
    input  wire                           m0_axi_wready,
    input  wire [ID_WIDTH-1:0]            m0_axi_bid,
    input  wire [1:0]                     m0_axi_bresp,
    input  wire                           m0_axi_bvalid,
    output wire                           m0_axi_bready,

    // AXI master 1 (DDR1 data)
    output wire [ID_WIDTH-1:0]            m1_axi_awid,
    output wire [ADDR_WIDTH-1:0]          m1_axi_awaddr,
    output wire [7:0]                     m1_axi_awlen,
    output wire [2:0]                     m1_axi_awsize,
    output wire [1:0]                     m1_axi_awburst,
    output wire                           m1_axi_awlock,
    output wire [3:0]                     m1_axi_awcache,
    output wire [2:0]                     m1_axi_awprot,
    output wire [3:0]                     m1_axi_awqos,
    output wire                           m1_axi_awvalid,
    input  wire                           m1_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]      m1_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0]    m1_axi_wstrb,
    output wire                           m1_axi_wlast,
    output wire                           m1_axi_wvalid,
    input  wire                           m1_axi_wready,
    input  wire [ID_WIDTH-1:0]            m1_axi_bid,
    input  wire [1:0]                     m1_axi_bresp,
    input  wire                           m1_axi_bvalid,
    output wire                           m1_axi_bready
);

    localparam int unsigned CPU_FIFO_WIDTH  = CPU_AXI_DATA_WIDTH + 2;
    localparam int unsigned CHUNK_STRB_WIDTH = AXI_DATA_WIDTH / 8;
    localparam int unsigned CHUNK_FIFO_WIDTH = AXI_DATA_WIDTH + CHUNK_STRB_WIDTH;

    wire enable_clk1;
    wire enable_clk2;
    reg [1:0] enable_clk1_sync;
    reg [1:0] enable_clk2_sync;
    reg [CPU_AXI_DATA_WIDTH/8-1:0] cfg_partial_wstrb_clk1_sync_0;
    reg [CPU_AXI_DATA_WIDTH/8-1:0] cfg_partial_wstrb_clk1_sync_1;
    reg [CPU_AXI_DATA_WIDTH/8-1:0] cfg_partial_wstrb_clk2_sync_0;
    reg [CPU_AXI_DATA_WIDTH/8-1:0] cfg_partial_wstrb_clk2_sync_1;
    reg [2:0] cfg_base_addr_load_clk2_sync;
    reg [ADDR_WIDTH-1:0] cfg_ch0_base_addr_clk2_sync_0;
    reg [ADDR_WIDTH-1:0] cfg_ch0_base_addr_clk2_sync_1;
    reg [ADDR_WIDTH-1:0] cfg_ch1_base_addr_clk2_sync_0;
    reg [ADDR_WIDTH-1:0] cfg_ch1_base_addr_clk2_sync_1;
    reg [ADDR_WIDTH-1:0] cfg_strobe_meta_base_addr_clk2_sync_0;
    reg [ADDR_WIDTH-1:0] cfg_strobe_meta_base_addr_clk2_sync_1;
    reg [ADDR_WIDTH-1:0] cfg_ch0_base_addr_run;
    reg [ADDR_WIDTH-1:0] cfg_ch1_base_addr_run;
    reg [ADDR_WIDTH-1:0] cfg_strobe_meta_base_addr_run;

    wire [CPU_AXI_DATA_WIDTH/8-1:0] cfg_partial_wstrb_clk1;
    wire [CPU_AXI_DATA_WIDTH/8-1:0] cfg_partial_wstrb_clk2;
    wire cfg_base_addr_load_clk2_pulse;
    wire [ADDR_WIDTH-1:0] cfg_ch0_base_addr_clk2;
    wire [ADDR_WIDTH-1:0] cfg_ch1_base_addr_clk2;
    wire [ADDR_WIDTH-1:0] cfg_strobe_meta_base_addr_clk2;

    wire [CPU_FIFO_WIDTH-1:0] cpu_fifo_wr_data;
    wire cpu_fifo_wr_en;
    wire cpu_fifo_wr_full;
    wire [CPU_FIFO_WIDTH-1:0] cpu_fifo_rd_data;
    wire cpu_fifo_rd_valid;
    wire cpu_fifo_empty;
    wire cpu_fifo_rd_en;

    wire [AXI_DATA_WIDTH-1:0] ch0_chunk_fifo_rd_data;
    wire [CHUNK_STRB_WIDTH-1:0] ch0_chunk_fifo_rd_strb;
    wire ch0_chunk_fifo_rd_valid;
    wire ch0_chunk_fifo_empty;
    wire ch0_chunk_fifo_rd_en;
    wire ch0_chunk_fifo_wr_en;
    wire [AXI_DATA_WIDTH-1:0] ch0_chunk_fifo_wr_data;
    wire [CHUNK_STRB_WIDTH-1:0] ch0_chunk_fifo_wr_strb;
    wire ch0_chunk_fifo_full;
    wire [CHUNK_FIFO_WIDTH-1:0] ch0_chunk_fifo_wr_payload;
    wire [CHUNK_FIFO_WIDTH-1:0] ch0_chunk_fifo_rd_payload;

    wire ch1_chunk_fifo_wr_en;
    wire [AXI_DATA_WIDTH-1:0] ch1_chunk_fifo_wr_data;
    wire [CHUNK_STRB_WIDTH-1:0] ch1_chunk_fifo_wr_strb;
    wire ch1_chunk_fifo_full;
    wire [CHUNK_FIFO_WIDTH-1:0] ch1_chunk_fifo_wr_payload;
    wire [127:0] ch1_remote_data;
    wire ch1_remote_valid;
    wire ch1_remote_ready;

    wire strobe_code_valid;
    wire [1:0] strobe_code;
    wire strobe_code_ready;
    wire meta_fifo_wr_en;
    wire [AXI_DATA_WIDTH-1:0] meta_fifo_wr_data;
    wire meta_fifo_wr_full;
    wire [CHUNK_FIFO_WIDTH-1:0] meta_fifo_wr_payload;
    wire [CHUNK_FIFO_WIDTH-1:0] meta_fifo_rd_payload;
    wire [AXI_DATA_WIDTH-1:0] meta_fifo_rd_data;
    wire [CHUNK_STRB_WIDTH-1:0] meta_fifo_rd_strb;
    wire meta_fifo_rd_valid;
    wire meta_fifo_empty;
    wire meta_fifo_rd_en;

    wire [ID_WIDTH-1:0] m0_data_axi_awid;
    wire [ADDR_WIDTH-1:0] m0_data_axi_awaddr;
    wire [7:0] m0_data_axi_awlen;
    wire [2:0] m0_data_axi_awsize;
    wire [1:0] m0_data_axi_awburst;
    wire m0_data_axi_awlock;
    wire [3:0] m0_data_axi_awcache;
    wire [2:0] m0_data_axi_awprot;
    wire [3:0] m0_data_axi_awqos;
    wire m0_data_axi_awvalid;
    wire m0_data_axi_awready;
    wire [AXI_DATA_WIDTH-1:0] m0_data_axi_wdata;
    wire [CHUNK_STRB_WIDTH-1:0] m0_data_axi_wstrb;
    wire m0_data_axi_wlast;
    wire m0_data_axi_wvalid;
    wire m0_data_axi_wready;
    wire [ID_WIDTH-1:0] m0_data_axi_bid;
    wire [1:0] m0_data_axi_bresp;
    wire m0_data_axi_bvalid;
    wire m0_data_axi_bready;

    wire [ID_WIDTH-1:0] m0_meta_axi_awid;
    wire [ADDR_WIDTH-1:0] m0_meta_axi_awaddr;
    wire [7:0] m0_meta_axi_awlen;
    wire [2:0] m0_meta_axi_awsize;
    wire [1:0] m0_meta_axi_awburst;
    wire m0_meta_axi_awlock;
    wire [3:0] m0_meta_axi_awcache;
    wire [2:0] m0_meta_axi_awprot;
    wire [3:0] m0_meta_axi_awqos;
    wire m0_meta_axi_awvalid;
    wire m0_meta_axi_awready;
    wire [AXI_DATA_WIDTH-1:0] m0_meta_axi_wdata;
    wire [CHUNK_STRB_WIDTH-1:0] m0_meta_axi_wstrb;
    wire m0_meta_axi_wlast;
    wire m0_meta_axi_wvalid;
    wire m0_meta_axi_wready;
    wire [ID_WIDTH-1:0] m0_meta_axi_bid;
    wire [1:0] m0_meta_axi_bresp;
    wire m0_meta_axi_bvalid;
    wire m0_meta_axi_bready;

    assign enable_clk1 = enable_clk1_sync[1];
    assign enable_clk2 = enable_clk2_sync[1];
    assign cfg_partial_wstrb_clk1 = cfg_partial_wstrb_clk1_sync_1;
    assign cfg_partial_wstrb_clk2 = cfg_partial_wstrb_clk2_sync_1;
    assign cfg_base_addr_load_clk2_pulse =
        cfg_base_addr_load_clk2_sync[1] && !cfg_base_addr_load_clk2_sync[2];
    assign cfg_ch0_base_addr_clk2 = cfg_ch0_base_addr_run;
    assign cfg_ch1_base_addr_clk2 = cfg_ch1_base_addr_run;
    assign cfg_strobe_meta_base_addr_clk2 = cfg_strobe_meta_base_addr_run;

    assign ch0_chunk_fifo_wr_payload = {ch0_chunk_fifo_wr_strb, ch0_chunk_fifo_wr_data};
    assign ch0_chunk_fifo_rd_data = ch0_chunk_fifo_rd_payload[AXI_DATA_WIDTH-1:0];
    assign ch0_chunk_fifo_rd_strb = ch0_chunk_fifo_rd_payload[AXI_DATA_WIDTH +: CHUNK_STRB_WIDTH];
    assign ch1_chunk_fifo_wr_payload = {ch1_chunk_fifo_wr_strb, ch1_chunk_fifo_wr_data};
    assign meta_fifo_wr_payload = {{CHUNK_STRB_WIDTH{1'b1}}, meta_fifo_wr_data};
    assign meta_fifo_rd_data = meta_fifo_rd_payload[AXI_DATA_WIDTH-1:0];
    assign meta_fifo_rd_strb = meta_fifo_rd_payload[AXI_DATA_WIDTH +: CHUNK_STRB_WIDTH];

    always @(posedge clk1 or negedge rst1_n) begin
        if (!rst1_n) begin
            enable_clk1_sync <= 2'b00;
            cfg_partial_wstrb_clk1_sync_0 <= {(CPU_AXI_DATA_WIDTH/8){1'b0}};
            cfg_partial_wstrb_clk1_sync_1 <= {(CPU_AXI_DATA_WIDTH/8){1'b0}};
        end else begin
            enable_clk1_sync <= {enable_clk1_sync[0], enable};
            cfg_partial_wstrb_clk1_sync_0 <= cfg_partial_wstrb;
            cfg_partial_wstrb_clk1_sync_1 <= cfg_partial_wstrb_clk1_sync_0;
        end
    end

    always @(posedge clk2 or negedge rst2_n) begin
        if (!rst2_n) begin
            enable_clk2_sync <= 2'b00;
            cfg_partial_wstrb_clk2_sync_0 <= {(CPU_AXI_DATA_WIDTH/8){1'b0}};
            cfg_partial_wstrb_clk2_sync_1 <= {(CPU_AXI_DATA_WIDTH/8){1'b0}};
            cfg_base_addr_load_clk2_sync <= 3'b000;
            cfg_ch0_base_addr_clk2_sync_0 <= CH0_BASE_ADDR;
            cfg_ch0_base_addr_clk2_sync_1 <= CH0_BASE_ADDR;
            cfg_ch1_base_addr_clk2_sync_0 <= CH1_BASE_ADDR;
            cfg_ch1_base_addr_clk2_sync_1 <= CH1_BASE_ADDR;
            cfg_strobe_meta_base_addr_clk2_sync_0 <= STROBE_META_BASE_ADDR;
            cfg_strobe_meta_base_addr_clk2_sync_1 <= STROBE_META_BASE_ADDR;
            cfg_ch0_base_addr_run <= CH0_BASE_ADDR;
            cfg_ch1_base_addr_run <= CH1_BASE_ADDR;
            cfg_strobe_meta_base_addr_run <= STROBE_META_BASE_ADDR;
        end else begin
            enable_clk2_sync <= {enable_clk2_sync[0], enable};
            cfg_partial_wstrb_clk2_sync_0 <= cfg_partial_wstrb;
            cfg_partial_wstrb_clk2_sync_1 <= cfg_partial_wstrb_clk2_sync_0;
            cfg_base_addr_load_clk2_sync <=
                {cfg_base_addr_load_clk2_sync[1:0], cfg_base_addr_load};
            cfg_ch0_base_addr_clk2_sync_0 <= cfg_ch0_base_addr;
            cfg_ch0_base_addr_clk2_sync_1 <= cfg_ch0_base_addr_clk2_sync_0;
            cfg_ch1_base_addr_clk2_sync_0 <= cfg_ch1_base_addr;
            cfg_ch1_base_addr_clk2_sync_1 <= cfg_ch1_base_addr_clk2_sync_0;
            cfg_strobe_meta_base_addr_clk2_sync_0 <= cfg_strobe_meta_base_addr;
            cfg_strobe_meta_base_addr_clk2_sync_1 <= cfg_strobe_meta_base_addr_clk2_sync_0;

            if (cfg_base_addr_load_clk2_pulse) begin
                cfg_ch0_base_addr_run <= cfg_ch0_base_addr_clk2_sync_1;
                cfg_ch1_base_addr_run <= cfg_ch1_base_addr_clk2_sync_1;
                cfg_strobe_meta_base_addr_run <= cfg_strobe_meta_base_addr_clk2_sync_1;
            end
        end
    end

    ddr_memtest_cpu_axi_passive_ingress #(
        .CPU_AXI_DATA_WIDTH (CPU_AXI_DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .OUTSTANDING_BURSTS (CPU_OUTSTANDING_BURSTS)
    ) u_cpu_axi_ingress (
        .clk               (clk1),
        .rst_n             (rst1_n),
        .enable            (enable_clk1),
        .cfg_partial_wstrb (cfg_partial_wstrb_clk1),
        .s_axi_awid        (s_cpu_axi_awid),
        .s_axi_awaddr      (s_cpu_axi_awaddr),
        .s_axi_awlen       (s_cpu_axi_awlen),
        .s_axi_awsize      (s_cpu_axi_awsize),
        .s_axi_awburst     (s_cpu_axi_awburst),
        .s_axi_awvalid     (s_cpu_axi_awvalid),
        .s_axi_awready     (s_cpu_axi_awready),
        .s_axi_wdata       (s_cpu_axi_wdata),
        .s_axi_wstrb       (s_cpu_axi_wstrb),
        .s_axi_wlast       (s_cpu_axi_wlast),
        .s_axi_wvalid      (s_cpu_axi_wvalid),
        .s_axi_wready      (s_cpu_axi_wready),
        .s_axi_bid         (s_cpu_axi_bid),
        .s_axi_bresp       (s_cpu_axi_bresp),
        .s_axi_bvalid      (s_cpu_axi_bvalid),
        .s_axi_bready      (s_cpu_axi_bready),
        .fifo_wr_en        (cpu_fifo_wr_en),
        .fifo_wr_data      (cpu_fifo_wr_data),
        .fifo_wr_full      (cpu_fifo_wr_full)
    );

    ddr_memtest_async_fifo #(
        .DATA_WIDTH (CPU_FIFO_WIDTH),
        .DEPTH      (FIFO_DEPTH)
    ) u_cpu_async_fifo (
        .wr_clk   (clk1),
        .wr_rst_n (rst1_n),
        .wr_en    (cpu_fifo_wr_en),
        .wr_data  (cpu_fifo_wr_data),
        .wr_full  (cpu_fifo_wr_full),
        .rd_clk   (clk2),
        .rd_rst_n (rst2_n),
        .rd_en    (cpu_fifo_rd_en),
        .rd_data  (cpu_fifo_rd_data),
        .rd_valid (cpu_fifo_rd_valid),
        .rd_empty (cpu_fifo_empty)
    );

    ddr_memtest_cpu_axi_passive_stripe_dispatch #(
        .AXI_DATA_WIDTH     (AXI_DATA_WIDTH),
        .MAX_CPU_DATA_WIDTH (CPU_AXI_DATA_WIDTH)
    ) u_cpu_stripe_dispatch (
        .clk                 (clk2),
        .rst_n               (rst2_n),
        .enable              (enable_clk2),
        .cfg_partial_wstrb   (cfg_partial_wstrb_clk2),
        .cpu_fifo_rd_en      (cpu_fifo_rd_en),
        .cpu_fifo_rd_data    (cpu_fifo_rd_data),
        .cpu_fifo_rd_valid   (cpu_fifo_rd_valid),
        .cpu_fifo_empty      (cpu_fifo_empty),
        .ch0_fifo_wr_en      (ch0_chunk_fifo_wr_en),
        .ch0_fifo_wr_data    (ch0_chunk_fifo_wr_data),
        .ch0_fifo_wr_strb    (ch0_chunk_fifo_wr_strb),
        .ch0_fifo_wr_full    (ch0_chunk_fifo_full),
        .ch1_fifo_wr_en      (ch1_chunk_fifo_wr_en),
        .ch1_fifo_wr_data    (ch1_chunk_fifo_wr_data),
        .ch1_fifo_wr_strb    (ch1_chunk_fifo_wr_strb),
        .ch1_fifo_wr_full    (ch1_chunk_fifo_full),
        .strobe_code_valid   (strobe_code_valid),
        .strobe_code         (strobe_code),
        .strobe_code_ready   (strobe_code_ready)
    );

    ddr_memtest_sync_fifo #(
        .DATA_WIDTH (CHUNK_FIFO_WIDTH),
        .DEPTH      (FIFO_DEPTH)
    ) u_ch0_chunk_fifo (
        .clk      (clk2),
        .rst_n    (rst2_n),
        .wr_en    (ch0_chunk_fifo_wr_en),
        .wr_data  (ch0_chunk_fifo_wr_payload),
        .wr_full  (ch0_chunk_fifo_full),
        .rd_en    (ch0_chunk_fifo_rd_en),
        .rd_data  (ch0_chunk_fifo_rd_payload),
        .rd_valid (ch0_chunk_fifo_rd_valid),
        .rd_empty (ch0_chunk_fifo_empty)
    );

    ddr_memtest_remote_chunk_source #(
        .DATA_WIDTH (AXI_DATA_WIDTH),
        .STRB_WIDTH (CHUNK_STRB_WIDTH),
        .FLIT_WIDTH (128)
    ) u_ch1_remote_source (
        .clk           (clk2),
        .rst_n         (rst2_n),
        .chunk_wr_en   (ch1_chunk_fifo_wr_en),
        .chunk_wr_data (ch1_chunk_fifo_wr_data),
        .chunk_wr_strb (ch1_chunk_fifo_wr_strb),
        .chunk_wr_full (ch1_chunk_fifo_full),
        .tx_data       (ch1_remote_data),
        .tx_valid      (ch1_remote_valid),
        .tx_ready      (ch1_remote_ready)
    );

    ddr_memtest_strobe_code_packer #(
        .AXI_DATA_WIDTH    (AXI_DATA_WIDTH),
        .FLUSH_IDLE_CYCLES (FLUSH_IDLE_CYCLES)
    ) u_strobe_code_packer (
        .clk               (clk2),
        .rst_n             (rst2_n),
        .enable            (enable_clk2),
        .code_valid        (strobe_code_valid),
        .code              (strobe_code),
        .code_ready        (strobe_code_ready),
        .meta_fifo_wr_en   (meta_fifo_wr_en),
        .meta_fifo_wr_data (meta_fifo_wr_data),
        .meta_fifo_wr_full (meta_fifo_wr_full)
    );

    ddr_memtest_sync_fifo #(
        .DATA_WIDTH (CHUNK_FIFO_WIDTH),
        .DEPTH      (FIFO_DEPTH)
    ) u_strobe_meta_fifo (
        .clk      (clk2),
        .rst_n    (rst2_n),
        .wr_en    (meta_fifo_wr_en),
        .wr_data  (meta_fifo_wr_payload),
        .wr_full  (meta_fifo_wr_full),
        .rd_en    (meta_fifo_rd_en),
        .rd_data  (meta_fifo_rd_payload),
        .rd_valid (meta_fifo_rd_valid),
        .rd_empty (meta_fifo_empty)
    );

    ddr_memtest_axi_write_stream #(
        .AXI_DATA_WIDTH    (AXI_DATA_WIDTH),
        .ADDR_WIDTH        (ADDR_WIDTH),
        .ID_WIDTH          (ID_WIDTH),
        .BURST_LEN         (BURST_LEN),
        .FLUSH_IDLE_CYCLES (FLUSH_IDLE_CYCLES),
        .OUTSTANDING_BURSTS(DDR_OUTSTANDING_BURSTS),
        .BASE_ADDR         (CH0_BASE_ADDR),
        .AXI_ID            (CH0_AXI_ID)
    ) u_ch0_write_stream (
        .clk          (clk2),
        .rst_n        (rst2_n),
        .enable       (enable_clk2),
        .cfg_base_addr (cfg_ch0_base_addr_clk2),
        .fifo_rd_en   (ch0_chunk_fifo_rd_en),
        .fifo_rd_data (ch0_chunk_fifo_rd_data),
        .fifo_rd_strb (ch0_chunk_fifo_rd_strb),
        .fifo_rd_valid(ch0_chunk_fifo_rd_valid),
        .fifo_empty   (ch0_chunk_fifo_empty),
        .m_axi_awid   (m0_data_axi_awid),
        .m_axi_awaddr (m0_data_axi_awaddr),
        .m_axi_awlen  (m0_data_axi_awlen),
        .m_axi_awsize (m0_data_axi_awsize),
        .m_axi_awburst(m0_data_axi_awburst),
        .m_axi_awlock (m0_data_axi_awlock),
        .m_axi_awcache(m0_data_axi_awcache),
        .m_axi_awprot (m0_data_axi_awprot),
        .m_axi_awqos  (m0_data_axi_awqos),
        .m_axi_awvalid(m0_data_axi_awvalid),
        .m_axi_awready(m0_data_axi_awready),
        .m_axi_wdata  (m0_data_axi_wdata),
        .m_axi_wstrb  (m0_data_axi_wstrb),
        .m_axi_wlast  (m0_data_axi_wlast),
        .m_axi_wvalid (m0_data_axi_wvalid),
        .m_axi_wready (m0_data_axi_wready),
        .m_axi_bid    (m0_data_axi_bid),
        .m_axi_bresp  (m0_data_axi_bresp),
        .m_axi_bvalid (m0_data_axi_bvalid),
        .m_axi_bready (m0_data_axi_bready)
    );

    ddr_memtest_axi_write_stream #(
        .AXI_DATA_WIDTH    (AXI_DATA_WIDTH),
        .ADDR_WIDTH        (ADDR_WIDTH),
        .ID_WIDTH          (ID_WIDTH),
        .BURST_LEN         (BURST_LEN),
        .FLUSH_IDLE_CYCLES (FLUSH_IDLE_CYCLES),
        .OUTSTANDING_BURSTS(DDR_OUTSTANDING_BURSTS),
        .BASE_ADDR         (STROBE_META_BASE_ADDR),
        .AXI_ID            (STROBE_META_AXI_ID)
    ) u_strobe_meta_write_stream (
        .clk          (clk2),
        .rst_n        (rst2_n),
        .enable       (enable_clk2),
        .cfg_base_addr (cfg_strobe_meta_base_addr_clk2),
        .fifo_rd_en   (meta_fifo_rd_en),
        .fifo_rd_data (meta_fifo_rd_data),
        .fifo_rd_strb (meta_fifo_rd_strb),
        .fifo_rd_valid(meta_fifo_rd_valid),
        .fifo_empty   (meta_fifo_empty),
        .m_axi_awid   (m0_meta_axi_awid),
        .m_axi_awaddr (m0_meta_axi_awaddr),
        .m_axi_awlen  (m0_meta_axi_awlen),
        .m_axi_awsize (m0_meta_axi_awsize),
        .m_axi_awburst(m0_meta_axi_awburst),
        .m_axi_awlock (m0_meta_axi_awlock),
        .m_axi_awcache(m0_meta_axi_awcache),
        .m_axi_awprot (m0_meta_axi_awprot),
        .m_axi_awqos  (m0_meta_axi_awqos),
        .m_axi_awvalid(m0_meta_axi_awvalid),
        .m_axi_awready(m0_meta_axi_awready),
        .m_axi_wdata  (m0_meta_axi_wdata),
        .m_axi_wstrb  (m0_meta_axi_wstrb),
        .m_axi_wlast  (m0_meta_axi_wlast),
        .m_axi_wvalid (m0_meta_axi_wvalid),
        .m_axi_wready (m0_meta_axi_wready),
        .m_axi_bid    (m0_meta_axi_bid),
        .m_axi_bresp  (m0_meta_axi_bresp),
        .m_axi_bvalid (m0_meta_axi_bvalid),
        .m_axi_bready (m0_meta_axi_bready)
    );

    ddr_memtest_axi_write_arbiter2 #(
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .RESP_QUEUE_DEPTH(DDR_OUTSTANDING_BURSTS * 2)
    ) u_m0_write_arbiter (
        .clk            (clk2),
        .rst_n          (rst2_n),
        .s0_axi_awid    (m0_data_axi_awid),
        .s0_axi_awaddr  (m0_data_axi_awaddr),
        .s0_axi_awlen   (m0_data_axi_awlen),
        .s0_axi_awsize  (m0_data_axi_awsize),
        .s0_axi_awburst (m0_data_axi_awburst),
        .s0_axi_awlock  (m0_data_axi_awlock),
        .s0_axi_awcache (m0_data_axi_awcache),
        .s0_axi_awprot  (m0_data_axi_awprot),
        .s0_axi_awqos   (m0_data_axi_awqos),
        .s0_axi_awvalid (m0_data_axi_awvalid),
        .s0_axi_awready (m0_data_axi_awready),
        .s0_axi_wdata   (m0_data_axi_wdata),
        .s0_axi_wstrb   (m0_data_axi_wstrb),
        .s0_axi_wlast   (m0_data_axi_wlast),
        .s0_axi_wvalid  (m0_data_axi_wvalid),
        .s0_axi_wready  (m0_data_axi_wready),
        .s0_axi_bid     (m0_data_axi_bid),
        .s0_axi_bresp   (m0_data_axi_bresp),
        .s0_axi_bvalid  (m0_data_axi_bvalid),
        .s0_axi_bready  (m0_data_axi_bready),
        .s1_axi_awid    (m0_meta_axi_awid),
        .s1_axi_awaddr  (m0_meta_axi_awaddr),
        .s1_axi_awlen   (m0_meta_axi_awlen),
        .s1_axi_awsize  (m0_meta_axi_awsize),
        .s1_axi_awburst (m0_meta_axi_awburst),
        .s1_axi_awlock  (m0_meta_axi_awlock),
        .s1_axi_awcache (m0_meta_axi_awcache),
        .s1_axi_awprot  (m0_meta_axi_awprot),
        .s1_axi_awqos   (m0_meta_axi_awqos),
        .s1_axi_awvalid (m0_meta_axi_awvalid),
        .s1_axi_awready (m0_meta_axi_awready),
        .s1_axi_wdata   (m0_meta_axi_wdata),
        .s1_axi_wstrb   (m0_meta_axi_wstrb),
        .s1_axi_wlast   (m0_meta_axi_wlast),
        .s1_axi_wvalid  (m0_meta_axi_wvalid),
        .s1_axi_wready  (m0_meta_axi_wready),
        .s1_axi_bid     (m0_meta_axi_bid),
        .s1_axi_bresp   (m0_meta_axi_bresp),
        .s1_axi_bvalid  (m0_meta_axi_bvalid),
        .s1_axi_bready  (m0_meta_axi_bready),
        .m_axi_awid     (m0_axi_awid),
        .m_axi_awaddr   (m0_axi_awaddr),
        .m_axi_awlen    (m0_axi_awlen),
        .m_axi_awsize   (m0_axi_awsize),
        .m_axi_awburst  (m0_axi_awburst),
        .m_axi_awlock   (m0_axi_awlock),
        .m_axi_awcache  (m0_axi_awcache),
        .m_axi_awprot   (m0_axi_awprot),
        .m_axi_awqos    (m0_axi_awqos),
        .m_axi_awvalid  (m0_axi_awvalid),
        .m_axi_awready  (m0_axi_awready),
        .m_axi_wdata    (m0_axi_wdata),
        .m_axi_wstrb    (m0_axi_wstrb),
        .m_axi_wlast    (m0_axi_wlast),
        .m_axi_wvalid   (m0_axi_wvalid),
        .m_axi_wready   (m0_axi_wready),
        .m_axi_bid      (m0_axi_bid),
        .m_axi_bresp    (m0_axi_bresp),
        .m_axi_bvalid   (m0_axi_bvalid),
        .m_axi_bready   (m0_axi_bready)
    );

    ddr_memtest_remote_chunk_sink #(
        .AXI_DATA_WIDTH    (AXI_DATA_WIDTH),
        .ADDR_WIDTH        (ADDR_WIDTH),
        .ID_WIDTH          (ID_WIDTH),
        .BURST_LEN         (BURST_LEN),
        .FLUSH_IDLE_CYCLES (FLUSH_IDLE_CYCLES),
        .OUTSTANDING_BURSTS(DDR_OUTSTANDING_BURSTS),
        .FIFO_DEPTH        (FIFO_DEPTH),
        .FLIT_WIDTH        (128),
        .BASE_ADDR         (CH1_BASE_ADDR),
        .AXI_ID            (CH1_AXI_ID)
    ) u_ch1_remote_sink (
        .clk          (clk2),
        .rst_n        (rst2_n),
        .enable       (enable_clk2),
        .cfg_base_addr (cfg_ch1_base_addr_clk2),
        .rx_data      (ch1_remote_data),
        .rx_valid     (ch1_remote_valid),
        .rx_ready     (ch1_remote_ready),
        .m_axi_awid   (m1_axi_awid),
        .m_axi_awaddr (m1_axi_awaddr),
        .m_axi_awlen  (m1_axi_awlen),
        .m_axi_awsize (m1_axi_awsize),
        .m_axi_awburst(m1_axi_awburst),
        .m_axi_awlock (m1_axi_awlock),
        .m_axi_awcache(m1_axi_awcache),
        .m_axi_awprot (m1_axi_awprot),
        .m_axi_awqos  (m1_axi_awqos),
        .m_axi_awvalid(m1_axi_awvalid),
        .m_axi_awready(m1_axi_awready),
        .m_axi_wdata  (m1_axi_wdata),
        .m_axi_wstrb  (m1_axi_wstrb),
        .m_axi_wlast  (m1_axi_wlast),
        .m_axi_wvalid (m1_axi_wvalid),
        .m_axi_wready (m1_axi_wready),
        .m_axi_bid    (m1_axi_bid),
        .m_axi_bresp  (m1_axi_bresp),
        .m_axi_bvalid (m1_axi_bvalid),
        .m_axi_bready (m1_axi_bready)
    );

endmodule
