// AXI register adapter around the UVFC simple_uart uart_tx/tx_rate behavior.
module uvhs_simple_uart_axi #(
  parameter integer CLOCK_FREQ_HZ = 25_000_000,
  parameter integer BAUD_RATE = 9_600
) (
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET s_axi_aresetn, FREQ_HZ 25000000" *)
  input  wire        s_axi_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire        s_axi_aresetn,

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI, PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 31, FREQ_HZ 25000000, HAS_BRESP 1, HAS_RRESP 1, HAS_WSTRB 1, SUPPORTS_NARROW_BURST 1" *)
  input  wire [30:0] s_axi_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
  input  wire [2:0]  s_axi_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
  input  wire        s_axi_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
  output wire        s_axi_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
  input  wire [31:0] s_axi_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
  input  wire [3:0]  s_axi_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
  input  wire        s_axi_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
  output wire        s_axi_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
  output wire [1:0]  s_axi_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
  output reg         s_axi_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
  input  wire        s_axi_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
  input  wire [30:0] s_axi_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
  input  wire [2:0]  s_axi_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
  input  wire        s_axi_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
  output wire        s_axi_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
  output reg  [31:0] s_axi_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
  output wire [1:0]  s_axi_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
  output reg         s_axi_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
  input  wire        s_axi_rready,

  (* X_INTERFACE_INFO = "xilinx.com:interface:uart:1.0 UART RxD" *)
  input  wire        uart_rxd,
  (* X_INTERFACE_INFO = "xilinx.com:interface:uart:1.0 UART TxD" *)
  output wire        uart_txd,
  output wire        uart_interrupt
);
  localparam [3:0] UART_RX_FIFO = 4'h0;
  localparam [3:0] UART_TX_FIFO = 4'h4;
  localparam [3:0] UART_STATUS  = 4'h8;
  localparam [3:0] UART_CONTROL = 4'hc;

  reg        aw_pending;
  reg [30:0] awaddr_q;
  reg        w_pending;
  reg [31:0] wdata_q;
  reg [3:0]  wstrb_q;
  reg [7:0]  tx_data;
  reg        tx_start;
  reg        tx_busy;
  wire       tx_done;

  wire write_is_tx = awaddr_q[3:0] == UART_TX_FIFO;
  wire write_can_complete = aw_pending && w_pending &&
                            (!write_is_tx || !tx_busy);

  assign s_axi_awready = !aw_pending && !s_axi_bvalid;
  assign s_axi_wready  = !w_pending && !s_axi_bvalid;
  assign s_axi_bresp   = 2'b00;
  assign s_axi_arready = !s_axi_rvalid;
  assign s_axi_rresp   = 2'b00;
  assign uart_interrupt = 1'b0;

  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      aw_pending  <= 1'b0;
      awaddr_q    <= 31'b0;
      w_pending   <= 1'b0;
      wdata_q     <= 32'b0;
      wstrb_q     <= 4'b0;
      s_axi_bvalid <= 1'b0;
      s_axi_rvalid <= 1'b0;
      s_axi_rdata  <= 32'b0;
      tx_data     <= 8'b0;
      tx_start    <= 1'b0;
      tx_busy     <= 1'b0;
    end else begin
      tx_start <= 1'b0;
      if (tx_done)
        tx_busy <= 1'b0;

      if (s_axi_awvalid && s_axi_awready) begin
        aw_pending <= 1'b1;
        awaddr_q   <= s_axi_awaddr;
      end
      if (s_axi_wvalid && s_axi_wready) begin
        w_pending <= 1'b1;
        wdata_q   <= s_axi_wdata;
        wstrb_q   <= s_axi_wstrb;
      end

      if (write_can_complete) begin
        aw_pending   <= 1'b0;
        w_pending    <= 1'b0;
        s_axi_bvalid <= 1'b1;
        if (write_is_tx && wstrb_q[0]) begin
          tx_data  <= wdata_q[7:0];
          tx_start <= 1'b1;
          tx_busy  <= 1'b1;
        end
      end else if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 1'b0;
      end

      if (s_axi_arvalid && s_axi_arready) begin
        s_axi_rvalid <= 1'b1;
        case (s_axi_araddr[3:0])
          UART_RX_FIFO: s_axi_rdata <= 32'b0;
          UART_STATUS:  s_axi_rdata <= {28'b0, tx_busy, 3'b0};
          UART_CONTROL: s_axi_rdata <= 32'b0;
          default:      s_axi_rdata <= 32'b0;
        endcase
      end else if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end

  uvhs_uart_tx #(
    .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
    .BAUD_RATE(BAUD_RATE)
  ) u_uart_tx (
    .clk      (s_axi_aclk),
    .rstn     (s_axi_aresetn),
    .tx_start (tx_start),
    .tx_data  (tx_data),
    .tx_done  (tx_done),
    .uart_tx  (uart_txd)
  );

  wire unused = &{1'b0, s_axi_awprot, s_axi_arprot, uart_rxd,
                  s_axi_araddr[30:4], awaddr_q[30:4],
                  wdata_q[31:8], wstrb_q[3:1]};
endmodule

module uvhs_uart_tx #(
  parameter integer CLOCK_FREQ_HZ = 25_000_000,
  parameter integer BAUD_RATE = 9_600
) (
  input  wire       clk,
  input  wire       rstn,
  input  wire       tx_start,
  input  wire [7:0] tx_data,
  output reg        tx_done,
  output reg        uart_tx
);
  localparam [5:0] S_IDLE       = 6'b00_0000;
  localparam [5:0] S_READY      = 6'b00_0001;
  localparam [5:0] S_START_BIT  = 6'b00_0010;
  localparam [5:0] S_SHIFT      = 6'b00_0100;
  localparam [5:0] S_PARITY_BIT = 6'b00_1000;
  localparam [5:0] S_STOP_BIT   = 6'b01_0000;
  localparam [5:0] S_DONE       = 6'b10_0000;

  wire baud_tick;
  reg [7:0] data_q;
  reg [2:0] bit_count;
  reg [5:0] state;
  reg [5:0] next_state;

  uvhs_uart_tx_rate #(
    .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
    .BAUD_RATE(BAUD_RATE)
  ) u_tx_rate (
    .clk      (clk),
    .rstn     (rstn),
    .tx_start (tx_start),
    .tx_done  (tx_done),
    .baud_tick(baud_tick)
  );

  always @(posedge clk or negedge rstn) begin
    if (!rstn)
      bit_count <= 3'b0;
    else if (state == S_SHIFT && baud_tick)
      bit_count <= bit_count == 3'd7 ? 3'b0 : bit_count + 3'b1;
  end

  always @(posedge clk or negedge rstn) begin
    if (!rstn)
      state <= S_IDLE;
    else
      state <= next_state;
  end

  always @(*) begin
    case (state)
      S_IDLE:       next_state = tx_start ? S_READY : S_IDLE;
      S_READY:      next_state = baud_tick ? S_START_BIT : S_READY;
      S_START_BIT:  next_state = baud_tick ? S_SHIFT : S_START_BIT;
      S_SHIFT:      next_state = bit_count == 3'd7 && baud_tick ? S_PARITY_BIT : S_SHIFT;
      S_PARITY_BIT: next_state = baud_tick ? S_STOP_BIT : S_PARITY_BIT;
      S_STOP_BIT:   next_state = baud_tick ? S_DONE : S_STOP_BIT;
      S_DONE:       next_state = S_IDLE;
      default:      next_state = S_IDLE;
    endcase
  end

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      data_q  <= 8'b0;
      tx_done <= 1'b0;
      uart_tx <= 1'b1;
    end else begin
      case (next_state)
        S_IDLE, S_READY: begin
          data_q  <= 8'b0;
          tx_done <= 1'b0;
          uart_tx <= 1'b1;
        end
        S_START_BIT: begin
          data_q  <= tx_data;
          tx_done <= 1'b0;
          uart_tx <= 1'b0;
        end
        S_SHIFT: begin
          tx_done <= 1'b0;
          if (baud_tick) begin
            data_q  <= {1'b0, data_q[7:1]};
            uart_tx <= data_q[0];
          end
        end
        S_PARITY_BIT: begin
          tx_done <= 1'b0;
          uart_tx <= 1'b1;
        end
        S_STOP_BIT: uart_tx <= 1'b1;
        S_DONE:     tx_done <= 1'b1;
        default: begin
          data_q  <= 8'b0;
          tx_done <= 1'b0;
          uart_tx <= 1'b1;
        end
      endcase
    end
  end
endmodule

module uvhs_uart_tx_rate #(
  parameter integer CLOCK_FREQ_HZ = 25_000_000,
  parameter integer BAUD_RATE = 9_600,
  parameter integer DIVISOR = CLOCK_FREQ_HZ / BAUD_RATE,
  parameter integer COUNTER_WIDTH = $clog2(DIVISOR)
) (
  input  wire clk,
  input  wire rstn,
  input  wire tx_start,
  input  wire tx_done,
  output reg  baud_tick
);
  reg [COUNTER_WIDTH-1:0] count;
  reg running;
  localparam integer DIVISOR_MINUS_ONE = DIVISOR - 1;

  always @(posedge clk or negedge rstn) begin
    if (!rstn)
      running <= 1'b0;
    else if (!running)
      running <= tx_start;
    else if (tx_done)
      running <= 1'b0;
  end

  always @(posedge clk or negedge rstn) begin
    if (!rstn || !running)
      count <= {COUNTER_WIDTH{1'b0}};
    else if (count == DIVISOR_MINUS_ONE[COUNTER_WIDTH-1:0])
      count <= {COUNTER_WIDTH{1'b0}};
    else
      count <= count + 1'b1;
  end

  always @(posedge clk or negedge rstn) begin
    if (!rstn)
      baud_tick <= 1'b0;
    else
      baud_tick <= running && count == 1;
  end
endmodule
