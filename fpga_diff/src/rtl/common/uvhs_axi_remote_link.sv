`timescale 1ns/1ps

// Fixed-size packet transport used to keep a full AXI interface below the
// physical UVHS inter-FPGA channel width.  A packet is held until every flit
// has been accepted, so ordinary ready/valid backpressure is preserved.
module uvhs_axi_packet_tx #(
    parameter int unsigned PACKET_WIDTH = 320,
    parameter int unsigned FLIT_WIDTH = 80
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [PACKET_WIDTH-1:0] packet_data,
    input  wire                    packet_valid,
    output wire                    packet_ready,
    output wire [FLIT_WIDTH-1:0]   tx_data,
    output wire                    tx_valid,
    input  wire                    tx_ready
);
    localparam int unsigned NUM_FLITS = PACKET_WIDTH / FLIT_WIDTH;
    localparam int unsigned COUNT_WIDTH = $clog2(NUM_FLITS + 1);

    reg [PACKET_WIDTH-1:0] shift_reg;
    reg [COUNT_WIDTH-1:0] flits_left;

    assign packet_ready = (flits_left == 0);
    assign tx_valid = (flits_left != 0);
    assign tx_data = shift_reg[FLIT_WIDTH-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {PACKET_WIDTH{1'b0}};
            flits_left <= {COUNT_WIDTH{1'b0}};
        end else begin
            if (tx_valid && tx_ready) begin
                shift_reg <= shift_reg >> FLIT_WIDTH;
                flits_left <= flits_left - COUNT_WIDTH'(1);
            end
            if (packet_valid && packet_ready) begin
                shift_reg <= packet_data;
                flits_left <= COUNT_WIDTH'(NUM_FLITS);
            end
        end
    end
endmodule

module uvhs_axi_packet_rx #(
    parameter int unsigned PACKET_WIDTH = 320,
    parameter int unsigned FLIT_WIDTH = 80
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [FLIT_WIDTH-1:0]   rx_data,
    input  wire                    rx_valid,
    output wire                    rx_ready,
    output wire [PACKET_WIDTH-1:0] packet_data,
    output wire                    packet_valid,
    input  wire                    packet_ready
);
    localparam int unsigned NUM_FLITS = PACKET_WIDTH / FLIT_WIDTH;
    localparam int unsigned INDEX_WIDTH = $clog2(NUM_FLITS);

    reg [PACKET_WIDTH-1:0] assembly;
    reg [PACKET_WIDTH-1:0] packet_reg;
    reg [INDEX_WIDTH-1:0] flit_index;
    reg packet_valid_reg;
    reg [PACKET_WIDTH-1:0] assembly_next;
    integer i;

    wire last_flit = (flit_index == INDEX_WIDTH'(NUM_FLITS - 1));
    wire rx_fire = rx_valid && rx_ready;

    always @(*) begin
        assembly_next = assembly;
        for (i = 0; i < NUM_FLITS; i = i + 1) begin
            if (flit_index == INDEX_WIDTH'(i))
                assembly_next[i*FLIT_WIDTH +: FLIT_WIDTH] = rx_data;
        end
    end

    // Do not let the downstream packet_ready path feed combinationally back
    // into the inter-FPGA flit link.  In particular, when source and sink are
    // placed on different UVHS FPGAs, that shortcut creates a full ready path
    // through TDM in both directions.  Hold the final flit for one extra cycle
    // while the previous packet is consumed instead.  The one-cycle bubble is
    // lossless and keeps every inter-FPGA ready/valid boundary registered.
    assign rx_ready = !last_flit || !packet_valid_reg;
    assign packet_data = packet_reg;
    assign packet_valid = packet_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            assembly <= {PACKET_WIDTH{1'b0}};
            packet_reg <= {PACKET_WIDTH{1'b0}};
            flit_index <= {INDEX_WIDTH{1'b0}};
            packet_valid_reg <= 1'b0;
        end else begin
            if (packet_valid_reg && packet_ready)
                packet_valid_reg <= 1'b0;
            if (rx_fire) begin
                if (last_flit) begin
                    packet_reg <= assembly_next;
                    packet_valid_reg <= 1'b1;
                    assembly <= {PACKET_WIDTH{1'b0}};
                    flit_index <= {INDEX_WIDTH{1'b0}};
                end else begin
                    assembly <= assembly_next;
                    flit_index <= flit_index + INDEX_WIDTH'(1);
                end
            end
        end
    end
endmodule

// CPU-side AXI slave and request packet source.  One entry per AXI channel
// permits independent AW/W/AR handshakes while a round-robin mux prevents
// starvation on the shared forward link.
module uvhs_axi_remote_source #(
    parameter int unsigned DATA_WIDTH = 256,
    parameter int unsigned ADDR_WIDTH = 34,
    parameter int unsigned ID_WIDTH = 14,
    parameter int unsigned FLIT_WIDTH = 80,
    parameter int unsigned PACKET_WIDTH = 320
) (
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire [ID_WIDTH-1:0]        s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]      s_axi_awaddr,
    input  wire [7:0]                 s_axi_awlen,
    input  wire [2:0]                 s_axi_awsize,
    input  wire [1:0]                 s_axi_awburst,
    input  wire                       s_axi_awlock,
    input  wire [3:0]                 s_axi_awcache,
    input  wire [2:0]                 s_axi_awprot,
    input  wire [3:0]                 s_axi_awqos,
    input  wire [3:0]                 s_axi_awregion,
    input  wire                       s_axi_awvalid,
    output wire                       s_axi_awready,
    input  wire [DATA_WIDTH-1:0]      s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0]    s_axi_wstrb,
    input  wire                       s_axi_wlast,
    input  wire                       s_axi_wvalid,
    output wire                       s_axi_wready,
    output wire [ID_WIDTH-1:0]        s_axi_bid,
    output wire [1:0]                 s_axi_bresp,
    output wire                       s_axi_bvalid,
    input  wire                       s_axi_bready,
    input  wire [ID_WIDTH-1:0]        s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]      s_axi_araddr,
    input  wire [7:0]                 s_axi_arlen,
    input  wire [2:0]                 s_axi_arsize,
    input  wire [1:0]                 s_axi_arburst,
    input  wire                       s_axi_arlock,
    input  wire [3:0]                 s_axi_arcache,
    input  wire [2:0]                 s_axi_arprot,
    input  wire [3:0]                 s_axi_arqos,
    input  wire [3:0]                 s_axi_arregion,
    input  wire                       s_axi_arvalid,
    output wire                       s_axi_arready,
    output wire [ID_WIDTH-1:0]        s_axi_rid,
    output wire [DATA_WIDTH-1:0]      s_axi_rdata,
    output wire [1:0]                 s_axi_rresp,
    output wire                       s_axi_rlast,
    output wire                       s_axi_rvalid,
    input  wire                       s_axi_rready,
    output wire [FLIT_WIDTH-1:0]      req_tx_data,
    output wire                       req_tx_valid,
    input  wire                       req_tx_ready,
    input  wire [FLIT_WIDTH-1:0]      rsp_rx_data,
    input  wire                       rsp_rx_valid,
    output wire                       rsp_rx_ready
);
    localparam [1:0] TYPE_AW = 2'd0;
    localparam [1:0] TYPE_W  = 2'd1;
    localparam [1:0] TYPE_AR = 2'd2;
    localparam       TYPE_R  = 1'b1;
    localparam int unsigned AW_PAYLOAD_WIDTH = ID_WIDTH + ADDR_WIDTH + 29;
    localparam int unsigned W_PAYLOAD_WIDTH = DATA_WIDTH + DATA_WIDTH/8 + 1;

    reg [PACKET_WIDTH-1:0] aw_packet, w_packet, ar_packet;
    reg aw_valid, w_valid, ar_valid;
    reg [8:0] write_beats_credit;
    reg [1:0] rr_select;
    reg [1:0] selected;
    reg selected_valid;
    reg [PACKET_WIDTH-1:0] selected_packet;
    wire packet_tx_ready;
    wire packet_tx_fire = selected_valid && packet_tx_ready;

    wire [AW_PAYLOAD_WIDTH-1:0] aw_payload = {
        s_axi_awregion, s_axi_awqos, s_axi_awprot, s_axi_awcache,
        s_axi_awlock, s_axi_awburst, s_axi_awsize, s_axi_awlen,
        s_axi_awaddr, s_axi_awid
    };
    wire [W_PAYLOAD_WIDTH-1:0] w_payload =
        {s_axi_wlast, s_axi_wstrb, s_axi_wdata};
    wire [AW_PAYLOAD_WIDTH-1:0] ar_payload = {
        s_axi_arregion, s_axi_arqos, s_axi_arprot, s_axi_arcache,
        s_axi_arlock, s_axi_arburst, s_axi_arsize, s_axi_arlen,
        s_axi_araddr, s_axi_arid
    };

    // Only one write burst is admitted at a time.  AXI permits W to arrive
    // before AW, but many DDR slaves keep WREADY low until AW is accepted.
    // Buffer such an early W beat locally and never put it on the shared link
    // until the matching AW packet has reached the sink.
    assign s_axi_awready = !aw_valid && (write_beats_credit == 0);
    assign s_axi_wready = !w_valid;
    assign s_axi_arready = !ar_valid;

    always @(*) begin
        selected = 2'd0;
        selected_valid = 1'b0;
        selected_packet = {PACKET_WIDTH{1'b0}};
        case (rr_select)
            2'd0: begin
                if (aw_valid) begin selected=2'd0; selected_valid=1'b1; selected_packet=aw_packet; end
                else if (w_valid && write_beats_credit != 0) begin selected=2'd1; selected_valid=1'b1; selected_packet=w_packet; end
                else if (ar_valid) begin selected=2'd2; selected_valid=1'b1; selected_packet=ar_packet; end
            end
            2'd1: begin
                if (w_valid && write_beats_credit != 0) begin selected=2'd1; selected_valid=1'b1; selected_packet=w_packet; end
                else if (ar_valid) begin selected=2'd2; selected_valid=1'b1; selected_packet=ar_packet; end
                else if (aw_valid) begin selected=2'd0; selected_valid=1'b1; selected_packet=aw_packet; end
            end
            default: begin
                if (ar_valid) begin selected=2'd2; selected_valid=1'b1; selected_packet=ar_packet; end
                else if (aw_valid) begin selected=2'd0; selected_valid=1'b1; selected_packet=aw_packet; end
                else if (w_valid && write_beats_credit != 0) begin selected=2'd1; selected_valid=1'b1; selected_packet=w_packet; end
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_packet <= {PACKET_WIDTH{1'b0}};
            w_packet <= {PACKET_WIDTH{1'b0}};
            ar_packet <= {PACKET_WIDTH{1'b0}};
            aw_valid <= 1'b0;
            w_valid <= 1'b0;
            ar_valid <= 1'b0;
            write_beats_credit <= 9'd0;
            rr_select <= 2'd0;
        end else begin
            if (packet_tx_fire) begin
                case (selected)
                    2'd0: begin
                        aw_valid <= 1'b0;
                        write_beats_credit <= {1'b0, aw_packet[2+ID_WIDTH+ADDR_WIDTH +: 8]} + 9'd1;
                    end
                    2'd1: begin
                        w_valid <= 1'b0;
                        write_beats_credit <= write_beats_credit - 9'd1;
                    end
                    default: ar_valid <= 1'b0;
                endcase
                rr_select <= (selected == 2'd2) ? 2'd0 : selected + 2'd1;
            end
            if (s_axi_awvalid && s_axi_awready) begin
                aw_packet <= {PACKET_WIDTH{1'b0}};
                aw_packet[1:0] <= TYPE_AW;
                aw_packet[2 +: AW_PAYLOAD_WIDTH] <= aw_payload;
                aw_valid <= 1'b1;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                w_packet <= {PACKET_WIDTH{1'b0}};
                w_packet[1:0] <= TYPE_W;
                w_packet[2 +: W_PAYLOAD_WIDTH] <= w_payload;
                w_valid <= 1'b1;
            end
            if (s_axi_arvalid && s_axi_arready) begin
                ar_packet <= {PACKET_WIDTH{1'b0}};
                ar_packet[1:0] <= TYPE_AR;
                ar_packet[2 +: AW_PAYLOAD_WIDTH] <= ar_payload;
                ar_valid <= 1'b1;
            end
        end
    end

    uvhs_axi_packet_tx #(.PACKET_WIDTH(PACKET_WIDTH), .FLIT_WIDTH(FLIT_WIDTH))
    u_req_tx (
        .clk(clk), .rst_n(rst_n), .packet_data(selected_packet),
        .packet_valid(selected_valid), .packet_ready(packet_tx_ready),
        .tx_data(req_tx_data), .tx_valid(req_tx_valid), .tx_ready(req_tx_ready)
    );

    wire [PACKET_WIDTH-1:0] rsp_packet;
    wire rsp_packet_valid;
    wire rsp_is_r = rsp_packet[0] == TYPE_R;
    assign s_axi_bid = rsp_packet[1 +: ID_WIDTH];
    assign s_axi_bresp = rsp_packet[1+ID_WIDTH +: 2];
    assign s_axi_bvalid = rsp_packet_valid && !rsp_is_r;
    assign s_axi_rid = rsp_packet[1 +: ID_WIDTH];
    assign s_axi_rdata = rsp_packet[1+ID_WIDTH +: DATA_WIDTH];
    assign s_axi_rresp = rsp_packet[1+ID_WIDTH+DATA_WIDTH +: 2];
    assign s_axi_rlast = rsp_packet[1+ID_WIDTH+DATA_WIDTH+2];
    assign s_axi_rvalid = rsp_packet_valid && rsp_is_r;
    wire rsp_packet_ready = rsp_is_r ? s_axi_rready : s_axi_bready;

    uvhs_axi_packet_rx #(.PACKET_WIDTH(PACKET_WIDTH), .FLIT_WIDTH(FLIT_WIDTH))
    u_rsp_rx (
        .clk(clk), .rst_n(rst_n), .rx_data(rsp_rx_data),
        .rx_valid(rsp_rx_valid), .rx_ready(rsp_rx_ready),
        .packet_data(rsp_packet), .packet_valid(rsp_packet_valid),
        .packet_ready(rsp_packet_ready)
    );
endmodule

// DDR-side request packet sink and AXI master.  B/R responses are buffered
// independently before round-robin serialization onto the reverse link.
module uvhs_axi_remote_sink #(
    parameter int unsigned DATA_WIDTH = 256,
    parameter int unsigned ADDR_WIDTH = 34,
    parameter int unsigned ID_WIDTH = 14,
    parameter int unsigned FLIT_WIDTH = 80,
    parameter int unsigned PACKET_WIDTH = 320
) (
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire [FLIT_WIDTH-1:0]      req_rx_data,
    input  wire                       req_rx_valid,
    output wire                       req_rx_ready,
    output wire [FLIT_WIDTH-1:0]      rsp_tx_data,
    output wire                       rsp_tx_valid,
    input  wire                       rsp_tx_ready,
    output wire [ID_WIDTH-1:0]        m_axi_awid,
    output wire [ADDR_WIDTH-1:0]      m_axi_awaddr,
    output wire [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output wire                       m_axi_awlock,
    output wire [3:0]                 m_axi_awcache,
    output wire [2:0]                 m_axi_awprot,
    output wire [3:0]                 m_axi_awqos,
    output wire [3:0]                 m_axi_awregion,
    output wire                       m_axi_awvalid,
    input  wire                       m_axi_awready,
    output wire [DATA_WIDTH-1:0]      m_axi_wdata,
    output wire [DATA_WIDTH/8-1:0]    m_axi_wstrb,
    output wire                       m_axi_wlast,
    output wire                       m_axi_wvalid,
    input  wire                       m_axi_wready,
    input  wire [ID_WIDTH-1:0]        m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output wire                       m_axi_bready,
    output wire [ID_WIDTH-1:0]        m_axi_arid,
    output wire [ADDR_WIDTH-1:0]      m_axi_araddr,
    output wire [7:0]                 m_axi_arlen,
    output wire [2:0]                 m_axi_arsize,
    output wire [1:0]                 m_axi_arburst,
    output wire                       m_axi_arlock,
    output wire [3:0]                 m_axi_arcache,
    output wire [2:0]                 m_axi_arprot,
    output wire [3:0]                 m_axi_arqos,
    output wire [3:0]                 m_axi_arregion,
    output wire                       m_axi_arvalid,
    input  wire                       m_axi_arready,
    input  wire [ID_WIDTH-1:0]        m_axi_rid,
    input  wire [DATA_WIDTH-1:0]      m_axi_rdata,
    input  wire [1:0]                 m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output wire                       m_axi_rready
);
    localparam [1:0] TYPE_AW = 2'd0;
    localparam [1:0] TYPE_W  = 2'd1;
    localparam [1:0] TYPE_AR = 2'd2;
    localparam       TYPE_B  = 1'b0;
    localparam       TYPE_R  = 1'b1;
    localparam int unsigned AW_PAYLOAD_WIDTH = ID_WIDTH + ADDR_WIDTH + 29;
    localparam int unsigned W_PAYLOAD_WIDTH = DATA_WIDTH + DATA_WIDTH/8 + 1;
    localparam int unsigned R_PAYLOAD_WIDTH = ID_WIDTH + DATA_WIDTH + 3;

    wire [PACKET_WIDTH-1:0] req_packet;
    wire req_packet_valid;
    wire [1:0] req_type = req_packet[1:0];
    wire [AW_PAYLOAD_WIDTH-1:0] req_aw_payload =
        req_packet[2 +: AW_PAYLOAD_WIDTH];
    wire [W_PAYLOAD_WIDTH-1:0] req_w_payload =
        req_packet[2 +: W_PAYLOAD_WIDTH];

    assign m_axi_awid = req_aw_payload[0 +: ID_WIDTH];
    assign m_axi_awaddr = req_aw_payload[ID_WIDTH +: ADDR_WIDTH];
    assign m_axi_awlen = req_aw_payload[ID_WIDTH+ADDR_WIDTH +: 8];
    assign m_axi_awsize = req_aw_payload[ID_WIDTH+ADDR_WIDTH+8 +: 3];
    assign m_axi_awburst = req_aw_payload[ID_WIDTH+ADDR_WIDTH+11 +: 2];
    assign m_axi_awlock = req_aw_payload[ID_WIDTH+ADDR_WIDTH+13];
    assign m_axi_awcache = req_aw_payload[ID_WIDTH+ADDR_WIDTH+14 +: 4];
    assign m_axi_awprot = req_aw_payload[ID_WIDTH+ADDR_WIDTH+18 +: 3];
    assign m_axi_awqos = req_aw_payload[ID_WIDTH+ADDR_WIDTH+21 +: 4];
    assign m_axi_awregion = req_aw_payload[ID_WIDTH+ADDR_WIDTH+25 +: 4];
    assign m_axi_awvalid = req_packet_valid && req_type == TYPE_AW;
    assign m_axi_wdata = req_w_payload[0 +: DATA_WIDTH];
    assign m_axi_wstrb = req_w_payload[DATA_WIDTH +: DATA_WIDTH/8];
    assign m_axi_wlast = req_w_payload[DATA_WIDTH+DATA_WIDTH/8];
    assign m_axi_wvalid = req_packet_valid && req_type == TYPE_W;
    assign m_axi_arid = m_axi_awid;
    assign m_axi_araddr = m_axi_awaddr;
    assign m_axi_arlen = m_axi_awlen;
    assign m_axi_arsize = m_axi_awsize;
    assign m_axi_arburst = m_axi_awburst;
    assign m_axi_arlock = m_axi_awlock;
    assign m_axi_arcache = m_axi_awcache;
    assign m_axi_arprot = m_axi_awprot;
    assign m_axi_arqos = m_axi_awqos;
    assign m_axi_arregion = m_axi_awregion;
    assign m_axi_arvalid = req_packet_valid && req_type == TYPE_AR;
    wire req_packet_ready = (req_type == TYPE_AW) ? m_axi_awready :
                            (req_type == TYPE_W)  ? m_axi_wready  : m_axi_arready;

    uvhs_axi_packet_rx #(.PACKET_WIDTH(PACKET_WIDTH), .FLIT_WIDTH(FLIT_WIDTH))
    u_req_rx (
        .clk(clk), .rst_n(rst_n), .rx_data(req_rx_data),
        .rx_valid(req_rx_valid), .rx_ready(req_rx_ready),
        .packet_data(req_packet), .packet_valid(req_packet_valid),
        .packet_ready(req_packet_ready)
    );

    reg [PACKET_WIDTH-1:0] b_packet, r_packet;
    reg b_valid, r_valid, rr_select;
    wire selected_is_r = rr_select ? r_valid : !b_valid;
    wire selected_valid = selected_is_r ? r_valid : b_valid;
    wire [PACKET_WIDTH-1:0] selected_packet = selected_is_r ? r_packet : b_packet;
    wire packet_tx_ready;
    wire packet_tx_fire = selected_valid && packet_tx_ready;
    wire [R_PAYLOAD_WIDTH-1:0] r_payload =
        {m_axi_rlast, m_axi_rresp, m_axi_rdata, m_axi_rid};

    assign m_axi_bready = !b_valid;
    assign m_axi_rready = !r_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_packet <= {PACKET_WIDTH{1'b0}};
            r_packet <= {PACKET_WIDTH{1'b0}};
            b_valid <= 1'b0;
            r_valid <= 1'b0;
            rr_select <= 1'b0;
        end else begin
            if (packet_tx_fire) begin
                if (selected_is_r) r_valid <= 1'b0;
                else b_valid <= 1'b0;
                rr_select <= !selected_is_r;
            end
            if (m_axi_bvalid && m_axi_bready) begin
                b_packet <= {PACKET_WIDTH{1'b0}};
                b_packet[0] <= TYPE_B;
                b_packet[1 +: ID_WIDTH+2] <= {m_axi_bresp, m_axi_bid};
                b_valid <= 1'b1;
            end
            if (m_axi_rvalid && m_axi_rready) begin
                r_packet <= {PACKET_WIDTH{1'b0}};
                r_packet[0] <= TYPE_R;
                r_packet[1 +: R_PAYLOAD_WIDTH] <= r_payload;
                r_valid <= 1'b1;
            end
        end
    end

    uvhs_axi_packet_tx #(.PACKET_WIDTH(PACKET_WIDTH), .FLIT_WIDTH(FLIT_WIDTH))
    u_rsp_tx (
        .clk(clk), .rst_n(rst_n), .packet_data(selected_packet),
        .packet_valid(selected_valid), .packet_ready(packet_tx_ready),
        .tx_data(rsp_tx_data), .tx_valid(rsp_tx_valid), .tx_ready(rsp_tx_ready)
    );
endmodule
