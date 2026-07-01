`timescale 1ns/1ps

module uvhs_axi_to_mem_array #(
  parameter int AXI_ID_WIDTH = 18,
  parameter int AXI_ADDR_WIDTH = 40,
  parameter int AXI_DATA_WIDTH = 64
) (
  input  logic                         clk,
  input  logic                         rstn,

  input  logic [AXI_ID_WIDTH-1:0]      axi_awid,
  input  logic [AXI_ADDR_WIDTH-1:0]    axi_awaddr,
  input  logic [7:0]                   axi_awlen,
  input  logic [2:0]                   axi_awsize,
  input  logic [1:0]                   axi_awburst,
  input  logic                         axi_awlock,
  input  logic [3:0]                   axi_awcache,
  input  logic [2:0]                   axi_awprot,
  input  logic [3:0]                   axi_awqos,
  input  logic                         axi_awvalid,
  output logic                         axi_awready,
  input  logic [AXI_DATA_WIDTH-1:0]    axi_wdata,
  input  logic [AXI_DATA_WIDTH/8-1:0]  axi_wstrb,
  input  logic                         axi_wlast,
  input  logic                         axi_wvalid,
  output logic                         axi_wready,
  output logic [AXI_ID_WIDTH-1:0]      axi_bid,
  output logic [1:0]                   axi_bresp,
  output logic                         axi_bvalid,
  input  logic                         axi_bready,

  input  logic [AXI_ID_WIDTH-1:0]      axi_arid,
  input  logic [AXI_ADDR_WIDTH-1:0]    axi_araddr,
  input  logic [7:0]                   axi_arlen,
  input  logic [2:0]                   axi_arsize,
  input  logic [1:0]                   axi_arburst,
  input  logic                         axi_arlock,
  input  logic [3:0]                   axi_arcache,
  input  logic [2:0]                   axi_arprot,
  input  logic [3:0]                   axi_arqos,
  input  logic                         axi_arvalid,
  output logic                         axi_arready,
  output logic [AXI_ID_WIDTH-1:0]      axi_rid,
  output logic [AXI_DATA_WIDTH-1:0]    axi_rdata,
  output logic [1:0]                   axi_rresp,
  output logic                         axi_rlast,
  output logic                         axi_rvalid,
  input  logic                         axi_rready,

  output logic                         mem_en,
  output logic                         mem_wen,
  output logic [34:0]                  mem_addr,
  output logic [AXI_DATA_WIDTH-1:0]    mem_wdata,
  output logic [AXI_DATA_WIDTH/8-1:0]  mem_wbe,
  input  logic [AXI_DATA_WIDTH-1:0]    mem_rdata,
  input  logic                         mem_rvalid
);

  localparam int ADDR_LSB = (AXI_DATA_WIDTH == 64) ? 3 :
                            (AXI_DATA_WIDTH == 128) ? 4 :
                            (AXI_DATA_WIDTH == 256) ? 5 : 6;

  typedef enum logic [1:0] {
    W_IDLE,
    W_DATA,
    W_RESP
  } write_state_t;

  typedef enum logic [1:0] {
    R_IDLE,
    R_REQ,
    R_WAIT,
    R_RESP
  } read_state_t;

  write_state_t write_state;
  read_state_t  read_state;

  logic [AXI_ID_WIDTH-1:0]   write_id;
  logic [AXI_ADDR_WIDTH-1:0] write_addr;
  logic [7:0]                write_left;
  logic [2:0]                write_size;
  logic [1:0]                write_burst;

  logic [AXI_ID_WIDTH-1:0]   read_id;
  logic [AXI_ADDR_WIDTH-1:0] read_addr;
  logic [7:0]                read_left;
  logic [2:0]                read_size;
  logic [1:0]                read_burst;

  logic                      write_mem_en;
  logic                      read_mem_en;

  function automatic [AXI_ADDR_WIDTH-1:0] next_addr(
    input [AXI_ADDR_WIDTH-1:0] addr,
    input [2:0] size,
    input [1:0] burst
  );
    if (burst == 2'b01) begin
      next_addr = addr + ({{(AXI_ADDR_WIDTH-1){1'b0}}, 1'b1} << size);
    end else begin
      next_addr = addr;
    end
  endfunction

  assign axi_awready = (write_state == W_IDLE);
  assign axi_wready  = (write_state == W_DATA);
  assign axi_bresp   = 2'b00;

  assign axi_arready = (read_state == R_IDLE);
  assign axi_rresp   = 2'b00;

  assign mem_en    = write_mem_en | read_mem_en;
  assign mem_wen   = write_mem_en;
  assign mem_addr  = write_mem_en ? write_addr[ADDR_LSB +: 35] : read_addr[ADDR_LSB +: 35];
  assign mem_wdata = axi_wdata;
  assign mem_wbe   = axi_wstrb;

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      write_state <= W_IDLE;
      write_id    <= '0;
      write_addr  <= '0;
      write_left  <= '0;
      write_size  <= '0;
      write_burst <= '0;
      axi_bid     <= '0;
      axi_bvalid  <= 1'b0;
      write_mem_en <= 1'b0;
    end else begin
      write_mem_en <= 1'b0;
      case (write_state)
        W_IDLE: begin
          axi_bvalid <= 1'b0;
          if (axi_awvalid && axi_awready) begin
            write_id    <= axi_awid;
            write_addr  <= axi_awaddr;
            write_left  <= axi_awlen;
            write_size  <= axi_awsize;
            write_burst <= axi_awburst;
            write_state <= W_DATA;
          end
        end
        W_DATA: begin
          if (axi_wvalid && axi_wready) begin
            write_mem_en <= 1'b1;
            if (write_left == 8'd0 || axi_wlast) begin
              axi_bid     <= write_id;
              axi_bvalid  <= 1'b1;
              write_state <= W_RESP;
            end else begin
              write_left <= write_left - 8'd1;
              write_addr <= next_addr(write_addr, write_size, write_burst);
            end
          end
        end
        W_RESP: begin
          if (axi_bready && axi_bvalid) begin
            axi_bvalid  <= 1'b0;
            write_state <= W_IDLE;
          end
        end
        default: write_state <= W_IDLE;
      endcase
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      read_state <= R_IDLE;
      read_id    <= '0;
      read_addr  <= '0;
      read_left  <= '0;
      read_size  <= '0;
      read_burst <= '0;
      axi_rid    <= '0;
      axi_rdata  <= '0;
      axi_rlast  <= 1'b0;
      axi_rvalid <= 1'b0;
      read_mem_en <= 1'b0;
    end else begin
      read_mem_en <= 1'b0;
      case (read_state)
        R_IDLE: begin
          axi_rvalid <= 1'b0;
          if (axi_arvalid && axi_arready) begin
            read_id    <= axi_arid;
            read_addr  <= axi_araddr;
            read_left  <= axi_arlen;
            read_size  <= axi_arsize;
            read_burst <= axi_arburst;
            read_state <= R_REQ;
          end
        end
        R_REQ: begin
          read_mem_en <= 1'b1;
          read_state  <= R_WAIT;
        end
        R_WAIT: begin
          if (mem_rvalid) begin
            axi_rid    <= read_id;
            axi_rdata  <= mem_rdata;
            axi_rlast  <= (read_left == 8'd0);
            axi_rvalid <= 1'b1;
            read_state <= R_RESP;
          end
        end
        R_RESP: begin
          if (axi_rready && axi_rvalid) begin
            axi_rvalid <= 1'b0;
            if (read_left == 8'd0) begin
              read_state <= R_IDLE;
            end else begin
              read_left <= read_left - 8'd1;
              read_addr <= next_addr(read_addr, read_size, read_burst);
              read_state <= R_REQ;
            end
          end
        end
        default: read_state <= R_IDLE;
      endcase
    end
  end

endmodule

module uvhs_mem_array_ddr_wrapper #(
  parameter int AXI_ID_WIDTH = 18,
  parameter int AXI_ADDR_WIDTH = 40,
  parameter int AXI_DATA_WIDTH = 64
) (
  input  logic                         SOC_CLK,
  input  logic                         soc_rstn,
  input  logic                         ddr_rstn,

  input  logic [AXI_ID_WIDTH-1:0]      SOC_M_AXI_awid,
  input  logic [AXI_ADDR_WIDTH-1:0]    SOC_M_AXI_awaddr,
  input  logic [7:0]                   SOC_M_AXI_awlen,
  input  logic [2:0]                   SOC_M_AXI_awsize,
  input  logic [1:0]                   SOC_M_AXI_awburst,
  input  logic                         SOC_M_AXI_awlock,
  input  logic [3:0]                   SOC_M_AXI_awcache,
  input  logic [2:0]                   SOC_M_AXI_awprot,
  input  logic [3:0]                   SOC_M_AXI_awqos,
  input  logic                         SOC_M_AXI_awvalid,
  output logic                         SOC_M_AXI_awready,
  input  logic [AXI_DATA_WIDTH-1:0]    SOC_M_AXI_wdata,
  input  logic [AXI_DATA_WIDTH/8-1:0]  SOC_M_AXI_wstrb,
  input  logic                         SOC_M_AXI_wlast,
  input  logic                         SOC_M_AXI_wvalid,
  output logic                         SOC_M_AXI_wready,
  output logic [AXI_ID_WIDTH-1:0]      SOC_M_AXI_bid,
  output logic [1:0]                   SOC_M_AXI_bresp,
  output logic                         SOC_M_AXI_bvalid,
  input  logic                         SOC_M_AXI_bready,

  input  logic [AXI_ID_WIDTH-1:0]      SOC_M_AXI_arid,
  input  logic [AXI_ADDR_WIDTH-1:0]    SOC_M_AXI_araddr,
  input  logic [7:0]                   SOC_M_AXI_arlen,
  input  logic [2:0]                   SOC_M_AXI_arsize,
  input  logic [1:0]                   SOC_M_AXI_arburst,
  input  logic                         SOC_M_AXI_arlock,
  input  logic [3:0]                   SOC_M_AXI_arcache,
  input  logic [2:0]                   SOC_M_AXI_arprot,
  input  logic [3:0]                   SOC_M_AXI_arqos,
  input  logic                         SOC_M_AXI_arvalid,
  output logic                         SOC_M_AXI_arready,
  output logic [AXI_ID_WIDTH-1:0]      SOC_M_AXI_rid,
  output logic [AXI_DATA_WIDTH-1:0]    SOC_M_AXI_rdata,
  output logic [1:0]                   SOC_M_AXI_rresp,
  output logic                         SOC_M_AXI_rlast,
  output logic                         SOC_M_AXI_rvalid,
  input  logic                         SOC_M_AXI_rready,

  output logic                         calib_complete,

  input  logic                         uvw_mem_array_tdm_ref_clk_p,
  input  logic                         uvw_mem_array_tdm_ref_clk_n,
  inout  wire [137:0]                  uvw_mem_array_tdm_pin
);

  logic        mem_en;
  logic        mem_wen;
  logic [34:0] mem_addr;
  logic [AXI_DATA_WIDTH-1:0] mem_wdata;
  logic [AXI_DATA_WIDTH/8-1:0] mem_wbe;
  logic [AXI_DATA_WIDTH-1:0] mem_rdata;
  logic        mem_rvalid;

  wire [3:0]   uvw_channel_clk;
  wire [3:0]   uvw_channel_clk_en;
  wire [3:0]   uvw_channel_rstn;
  wire [139:0] uvw_channel_addr;
  wire [2303:0] uvw_channel_din;
  wire [3:0]   uvw_channel_en;
  wire [287:0] uvw_channel_wbe;
  wire [3:0]   uvw_channel_wen;
  wire [2303:0] uvw_channel_rdata;
  wire [3:0]   uvw_channel_rvalid;

  assign calib_complete = soc_rstn & ddr_rstn;

  assign uvw_channel_clk    = {4{SOC_CLK}};
  assign uvw_channel_clk_en = 4'b0001;
  assign uvw_channel_rstn   = {4{soc_rstn & ddr_rstn}};
  assign uvw_channel_addr   = {105'b0, mem_addr};
  assign uvw_channel_din    = {{(2304-AXI_DATA_WIDTH){1'b0}}, mem_wdata};
  assign uvw_channel_en     = {3'b0, mem_en};
  assign uvw_channel_wbe    = {{(288-(AXI_DATA_WIDTH/8)){1'b0}}, mem_wbe};
  assign uvw_channel_wen    = {3'b0, mem_wen};
  assign mem_rdata          = uvw_channel_rdata[AXI_DATA_WIDTH-1:0];
  assign mem_rvalid         = uvw_channel_rvalid[0];

  uvhs_axi_to_mem_array #(
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) u_axi_to_mem_array (
    .clk(SOC_CLK),
    .rstn(soc_rstn & ddr_rstn),
    .axi_awid(SOC_M_AXI_awid),
    .axi_awaddr(SOC_M_AXI_awaddr),
    .axi_awlen(SOC_M_AXI_awlen),
    .axi_awsize(SOC_M_AXI_awsize),
    .axi_awburst(SOC_M_AXI_awburst),
    .axi_awlock(SOC_M_AXI_awlock),
    .axi_awcache(SOC_M_AXI_awcache),
    .axi_awprot(SOC_M_AXI_awprot),
    .axi_awqos(SOC_M_AXI_awqos),
    .axi_awvalid(SOC_M_AXI_awvalid),
    .axi_awready(SOC_M_AXI_awready),
    .axi_wdata(SOC_M_AXI_wdata),
    .axi_wstrb(SOC_M_AXI_wstrb),
    .axi_wlast(SOC_M_AXI_wlast),
    .axi_wvalid(SOC_M_AXI_wvalid),
    .axi_wready(SOC_M_AXI_wready),
    .axi_bid(SOC_M_AXI_bid),
    .axi_bresp(SOC_M_AXI_bresp),
    .axi_bvalid(SOC_M_AXI_bvalid),
    .axi_bready(SOC_M_AXI_bready),
    .axi_arid(SOC_M_AXI_arid),
    .axi_araddr(SOC_M_AXI_araddr),
    .axi_arlen(SOC_M_AXI_arlen),
    .axi_arsize(SOC_M_AXI_arsize),
    .axi_arburst(SOC_M_AXI_arburst),
    .axi_arlock(SOC_M_AXI_arlock),
    .axi_arcache(SOC_M_AXI_arcache),
    .axi_arprot(SOC_M_AXI_arprot),
    .axi_arqos(SOC_M_AXI_arqos),
    .axi_arvalid(SOC_M_AXI_arvalid),
    .axi_arready(SOC_M_AXI_arready),
    .axi_rid(SOC_M_AXI_rid),
    .axi_rdata(SOC_M_AXI_rdata),
    .axi_rresp(SOC_M_AXI_rresp),
    .axi_rlast(SOC_M_AXI_rlast),
    .axi_rvalid(SOC_M_AXI_rvalid),
    .axi_rready(SOC_M_AXI_rready),
    .mem_en(mem_en),
    .mem_wen(mem_wen),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_wbe(mem_wbe),
    .mem_rdata(mem_rdata),
    .mem_rvalid(mem_rvalid)
  );

  uvw_mem_array_wrapper #(
    .BRING_UP(0),
    .UVW_PORT_NUM(4),
    .UVW_USE_DATA_WIDTH({10'd64, 10'd64, 10'd64, 10'd64}),
    .UVW_DATA_WIDTH({10'd64, 10'd64, 10'd64, 10'd64}),
    .UVW_ADDR_WIDTH({10'd35, 10'd35, 10'd35, 10'd35})
  ) u_uvw_mem_array_wrapper (
    .uvw_channel_clk(uvw_channel_clk),
    .uvw_channel_clk_en(uvw_channel_clk_en),
    .uvw_channel_rstn(uvw_channel_rstn),
    .uvw_channel_addr(uvw_channel_addr),
    .uvw_channel_din(uvw_channel_din),
    .uvw_channel_en(uvw_channel_en),
    .uvw_channel_wbe(uvw_channel_wbe),
    .uvw_channel_wen(uvw_channel_wen),
    .uvw_channel_rdata(uvw_channel_rdata),
    .uvw_channel_rvalid(uvw_channel_rvalid),
    .uvw_mem_array_tdm_ref_clk_p(uvw_mem_array_tdm_ref_clk_p),
    .uvw_mem_array_tdm_ref_clk_n(uvw_mem_array_tdm_ref_clk_n),
    .uvw_mem_array_tdm_pin(uvw_mem_array_tdm_pin),
    .sysbus_ghbd_i(256'b0),
    .sysbus_ghbd_o()
  );

endmodule
