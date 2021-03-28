module sim_top(
  input clock,
  input reset,
  output uart_valid,
  output [7:0] uart_ch
);

wire         cpu_clock;
wire         cpu_reset;
wire         cpu_memory_0_aw_ready;
wire         cpu_memory_0_aw_valid;
wire [7:0]   cpu_memory_0_aw_bits_id;
wire [39:0]  cpu_memory_0_aw_bits_addr;
wire [7:0]   cpu_memory_0_aw_bits_len;
wire [2:0]   cpu_memory_0_aw_bits_size;
wire [1:0]   cpu_memory_0_aw_bits_burst;
wire         cpu_memory_0_aw_bits_lock;
wire [3:0]   cpu_memory_0_aw_bits_cache;
wire [2:0]   cpu_memory_0_aw_bits_prot;
wire [3:0]   cpu_memory_0_aw_bits_qos;
wire         cpu_memory_0_w_ready;
wire         cpu_memory_0_w_valid;
wire [255:0] cpu_memory_0_w_bits_data;
wire [31:0]  cpu_memory_0_w_bits_strb;
wire         cpu_memory_0_w_bits_last;
wire         cpu_memory_0_b_ready;
wire         cpu_memory_0_b_valid;
wire [7:0]   cpu_memory_0_b_bits_id;
wire [1:0]   cpu_memory_0_b_bits_resp;
wire         cpu_memory_0_ar_ready;
wire         cpu_memory_0_ar_valid;
wire [7:0]   cpu_memory_0_ar_bits_id;
wire [39:0]  cpu_memory_0_ar_bits_addr;
wire [7:0]   cpu_memory_0_ar_bits_len;
wire [2:0]   cpu_memory_0_ar_bits_size;
wire [1:0]   cpu_memory_0_ar_bits_burst;
wire         cpu_memory_0_ar_bits_lock;
wire [3:0]   cpu_memory_0_ar_bits_cache;
wire [2:0]   cpu_memory_0_ar_bits_prot;
wire [3:0]   cpu_memory_0_ar_bits_qos;
wire         cpu_memory_0_r_ready;
wire         cpu_memory_0_r_valid;
wire [7:0]   cpu_memory_0_r_bits_id;
wire [255:0] cpu_memory_0_r_bits_data;
wire [1:0]   cpu_memory_0_r_bits_resp;
wire         cpu_memory_0_r_bits_last;
wire         cpu_peripheral_0_aw_ready;
wire         cpu_peripheral_0_aw_valid;
wire [1:0]   cpu_peripheral_0_aw_bits_id;
wire [30:0]  cpu_peripheral_0_aw_bits_addr;
wire [7:0]   cpu_peripheral_0_aw_bits_len;
wire [2:0]   cpu_peripheral_0_aw_bits_size;
wire [1:0]   cpu_peripheral_0_aw_bits_burst;
wire         cpu_peripheral_0_aw_bits_lock;
wire [3:0]   cpu_peripheral_0_aw_bits_cache;
wire [2:0]   cpu_peripheral_0_aw_bits_prot;
wire [3:0]   cpu_peripheral_0_aw_bits_qos;
wire         cpu_peripheral_0_w_ready;
wire         cpu_peripheral_0_w_valid;
wire [63:0]  cpu_peripheral_0_w_bits_data;
wire [7:0]   cpu_peripheral_0_w_bits_strb;
wire         cpu_peripheral_0_w_bits_last;
wire         cpu_peripheral_0_b_ready;
wire         cpu_peripheral_0_b_valid;
wire [1:0]   cpu_peripheral_0_b_bits_id;
wire [1:0]   cpu_peripheral_0_b_bits_resp;
wire         cpu_peripheral_0_ar_ready;
wire         cpu_peripheral_0_ar_valid;
wire [1:0]   cpu_peripheral_0_ar_bits_id;
wire [30:0]  cpu_peripheral_0_ar_bits_addr;
wire [7:0]   cpu_peripheral_0_ar_bits_len;
wire [2:0]   cpu_peripheral_0_ar_bits_size;
wire [1:0]   cpu_peripheral_0_ar_bits_burst;
wire         cpu_peripheral_0_ar_bits_lock;
wire [3:0]   cpu_peripheral_0_ar_bits_cache;
wire [2:0]   cpu_peripheral_0_ar_bits_prot;
wire [3:0]   cpu_peripheral_0_ar_bits_qos;
wire         cpu_peripheral_0_r_ready;
wire         cpu_peripheral_0_r_valid;
wire [1:0]   cpu_peripheral_0_r_bits_id;
wire [63:0]  cpu_peripheral_0_r_bits_data;
wire [1:0]   cpu_peripheral_0_r_bits_resp;
wire         cpu_peripheral_0_r_bits_last;
wire         cpu_dma_0_aw_ready;
wire         cpu_dma_0_aw_valid;
wire [15:0]  cpu_dma_0_aw_bits_id;
wire [39:0]  cpu_dma_0_aw_bits_addr;
wire [7:0]   cpu_dma_0_aw_bits_len;
wire [2:0]   cpu_dma_0_aw_bits_size;
wire [1:0]   cpu_dma_0_aw_bits_burst;
wire         cpu_dma_0_aw_bits_lock;
wire [3:0]   cpu_dma_0_aw_bits_cache;
wire [2:0]   cpu_dma_0_aw_bits_prot;
wire [3:0]   cpu_dma_0_aw_bits_qos;
wire         cpu_dma_0_w_ready;
wire         cpu_dma_0_w_valid;
wire [255:0] cpu_dma_0_w_bits_data;
wire [31:0]  cpu_dma_0_w_bits_strb;
wire         cpu_dma_0_w_bits_last;
wire         cpu_dma_0_b_ready;
wire         cpu_dma_0_b_valid;
wire [15:0]  cpu_dma_0_b_bits_id;
wire [1:0]   cpu_dma_0_b_bits_resp;
wire         cpu_dma_0_ar_ready;
wire         cpu_dma_0_ar_valid;
wire [15:0]  cpu_dma_0_ar_bits_id;
wire [39:0]  cpu_dma_0_ar_bits_addr;
wire [7:0]   cpu_dma_0_ar_bits_len;
wire [2:0]   cpu_dma_0_ar_bits_size;
wire [1:0]   cpu_dma_0_ar_bits_burst;
wire         cpu_dma_0_ar_bits_lock;
wire [3:0]   cpu_dma_0_ar_bits_cache;
wire [2:0]   cpu_dma_0_ar_bits_prot;
wire [3:0]   cpu_dma_0_ar_bits_qos;
wire         cpu_dma_0_r_ready;
wire         cpu_dma_0_r_valid;
wire [15:0]  cpu_dma_0_r_bits_id;
wire [255:0] cpu_dma_0_r_bits_data;
wire [1:0]   cpu_dma_0_r_bits_resp;
wire         cpu_dma_0_r_bits_last;
wire [149:0] cpu_io_extIntrs;

wire        mmio_clock;
wire        mmio_reset;
wire        mmio_auto_axi4xbar_in_aw_ready;
wire        mmio_auto_axi4xbar_in_aw_valid;
wire [1:0]  mmio_auto_axi4xbar_in_aw_bits_id;
wire [30:0] mmio_auto_axi4xbar_in_aw_bits_addr;
wire [7:0]  mmio_auto_axi4xbar_in_aw_bits_len;
wire [2:0]  mmio_auto_axi4xbar_in_aw_bits_size;
wire [1:0]  mmio_auto_axi4xbar_in_aw_bits_burst;
wire        mmio_auto_axi4xbar_in_aw_bits_lock;
wire [3:0]  mmio_auto_axi4xbar_in_aw_bits_cache;
wire [2:0]  mmio_auto_axi4xbar_in_aw_bits_prot;
wire [3:0]  mmio_auto_axi4xbar_in_aw_bits_qos;
wire        mmio_auto_axi4xbar_in_w_ready;
wire        mmio_auto_axi4xbar_in_w_valid;
wire [63:0] mmio_auto_axi4xbar_in_w_bits_data;
wire [7:0]  mmio_auto_axi4xbar_in_w_bits_strb;
wire        mmio_auto_axi4xbar_in_w_bits_last;
wire        mmio_auto_axi4xbar_in_b_ready;
wire        mmio_auto_axi4xbar_in_b_valid;
wire [1:0]  mmio_auto_axi4xbar_in_b_bits_id;
wire [1:0]  mmio_auto_axi4xbar_in_b_bits_resp;
wire        mmio_auto_axi4xbar_in_ar_ready;
wire        mmio_auto_axi4xbar_in_ar_valid;
wire [1:0]  mmio_auto_axi4xbar_in_ar_bits_id;
wire [30:0] mmio_auto_axi4xbar_in_ar_bits_addr;
wire [7:0]  mmio_auto_axi4xbar_in_ar_bits_len;
wire [2:0]  mmio_auto_axi4xbar_in_ar_bits_size;
wire [1:0]  mmio_auto_axi4xbar_in_ar_bits_burst;
wire        mmio_auto_axi4xbar_in_ar_bits_lock;
wire [3:0]  mmio_auto_axi4xbar_in_ar_bits_cache;
wire [2:0]  mmio_auto_axi4xbar_in_ar_bits_prot;
wire [3:0]  mmio_auto_axi4xbar_in_ar_bits_qos;
wire        mmio_auto_axi4xbar_in_r_ready;
wire        mmio_auto_axi4xbar_in_r_valid;
wire [1:0]  mmio_auto_axi4xbar_in_r_bits_id;
wire [63:0] mmio_auto_axi4xbar_in_r_bits_data;
wire [1:0]  mmio_auto_axi4xbar_in_r_bits_resp;
wire        mmio_auto_axi4xbar_in_r_bits_last;
wire        mmio_io_uart_out_valid;
wire [7:0]  mmio_io_uart_out_ch;
wire        mmio_io_uart_in_valid;
wire [7:0]  mmio_io_uart_in_ch;

wire         ram_clock;
wire         ram_reset;
wire         ram_auto_in_aw_ready;
wire         ram_auto_in_aw_valid;
wire [7:0]   ram_auto_in_aw_bits_id;
wire [39:0]  ram_auto_in_aw_bits_addr;
wire [7:0]   ram_auto_in_aw_bits_len;
wire [2:0]   ram_auto_in_aw_bits_size;
wire [1:0]   ram_auto_in_aw_bits_burst;
wire         ram_auto_in_aw_bits_lock;
wire [3:0]   ram_auto_in_aw_bits_cache;
wire [2:0]   ram_auto_in_aw_bits_prot;
wire [3:0]   ram_auto_in_aw_bits_qos;
wire         ram_auto_in_w_ready;
wire         ram_auto_in_w_valid;
wire [255:0] ram_auto_in_w_bits_data;
wire [31:0]  ram_auto_in_w_bits_strb;
wire         ram_auto_in_w_bits_last;
wire         ram_auto_in_b_ready;
wire         ram_auto_in_b_valid;
wire [7:0]   ram_auto_in_b_bits_id;
wire [1:0]   ram_auto_in_b_bits_resp;
wire         ram_auto_in_ar_ready;
wire         ram_auto_in_ar_valid;
wire [7:0]   ram_auto_in_ar_bits_id;
wire [39:0]  ram_auto_in_ar_bits_addr;
wire [7:0]   ram_auto_in_ar_bits_len;
wire [2:0]   ram_auto_in_ar_bits_size;
wire [1:0]   ram_auto_in_ar_bits_burst;
wire         ram_auto_in_ar_bits_lock;
wire [3:0]   ram_auto_in_ar_bits_cache;
wire [2:0]   ram_auto_in_ar_bits_prot;
wire [3:0]   ram_auto_in_ar_bits_qos;
wire         ram_auto_in_r_ready;
wire         ram_auto_in_r_valid;
wire [7:0]   ram_auto_in_r_bits_id;
wire [255:0] ram_auto_in_r_bits_data;
wire [1:0]   ram_auto_in_r_bits_resp;
wire         ram_auto_in_r_bits_last;

assign cpu_clock = clock;
assign cpu_reset = reset;
assign cpu_memory_0_aw_ready = ram_auto_in_aw_ready;
assign cpu_memory_0_w_ready = ram_auto_in_w_ready;
assign cpu_memory_0_b_valid = ram_auto_in_b_valid;
assign cpu_memory_0_b_bits_id = ram_auto_in_b_bits_id;
assign cpu_memory_0_b_bits_resp = ram_auto_in_b_bits_resp;
assign cpu_memory_0_ar_ready = ram_auto_in_ar_ready;
assign cpu_memory_0_r_valid = ram_auto_in_r_valid;
assign cpu_memory_0_r_bits_id = ram_auto_in_r_bits_id;
assign cpu_memory_0_r_bits_data = ram_auto_in_r_bits_data;
assign cpu_memory_0_r_bits_resp = ram_auto_in_r_bits_resp;
assign cpu_memory_0_r_bits_last = ram_auto_in_r_bits_last;
assign cpu_peripheral_0_aw_ready = mmio_auto_axi4xbar_in_aw_ready;
assign cpu_peripheral_0_w_ready = mmio_auto_axi4xbar_in_w_ready;
assign cpu_peripheral_0_b_valid = mmio_auto_axi4xbar_in_b_valid;
assign cpu_peripheral_0_b_bits_id = mmio_auto_axi4xbar_in_b_bits_id;
assign cpu_peripheral_0_b_bits_resp = mmio_auto_axi4xbar_in_b_bits_resp;
assign cpu_peripheral_0_ar_ready = mmio_auto_axi4xbar_in_ar_ready;
assign cpu_peripheral_0_r_valid = mmio_auto_axi4xbar_in_r_valid;
assign cpu_peripheral_0_r_bits_id = mmio_auto_axi4xbar_in_r_bits_id;
assign cpu_peripheral_0_r_bits_data = mmio_auto_axi4xbar_in_r_bits_data;
assign cpu_peripheral_0_r_bits_resp = mmio_auto_axi4xbar_in_r_bits_resp;
assign cpu_peripheral_0_r_bits_last = mmio_auto_axi4xbar_in_r_bits_last;
assign cpu_dma_0_aw_valid = 0;
assign cpu_dma_0_aw_bits_id = 0;
assign cpu_dma_0_aw_bits_addr = 0;
assign cpu_dma_0_aw_bits_len = 0;
assign cpu_dma_0_aw_bits_size = 0;
assign cpu_dma_0_aw_bits_burst = 0;
assign cpu_dma_0_aw_bits_lock = 0;
assign cpu_dma_0_aw_bits_cache = 0;
assign cpu_dma_0_aw_bits_prot = 0;
assign cpu_dma_0_aw_bits_qos = 0;
assign cpu_dma_0_w_valid = 0;
assign cpu_dma_0_w_bits_data = 0;
assign cpu_dma_0_w_bits_strb = 0;
assign cpu_dma_0_w_bits_last = 0;
assign cpu_dma_0_b_ready = 0;
assign cpu_dma_0_ar_valid = 0;
assign cpu_dma_0_ar_bits_id = 0;
assign cpu_dma_0_ar_bits_addr = 0;
assign cpu_dma_0_ar_bits_len = 0;
assign cpu_dma_0_ar_bits_size = 0;
assign cpu_dma_0_ar_bits_burst = 0;
assign cpu_dma_0_ar_bits_lock = 0;
assign cpu_dma_0_ar_bits_cache = 0;
assign cpu_dma_0_ar_bits_prot = 0;
assign cpu_dma_0_ar_bits_qos = 0;
assign cpu_dma_0_r_ready = 0;
assign cpu_io_extIntrs = 0;

assign mmio_clock = clock;
assign mmio_reset = reset;
assign mmio_auto_axi4xbar_in_aw_valid = cpu_peripheral_0_aw_valid;
assign mmio_auto_axi4xbar_in_aw_bits_id = cpu_peripheral_0_aw_bits_id;
assign mmio_auto_axi4xbar_in_aw_bits_addr = cpu_peripheral_0_aw_bits_addr;
assign mmio_auto_axi4xbar_in_aw_bits_len = cpu_peripheral_0_aw_bits_len;
assign mmio_auto_axi4xbar_in_aw_bits_size = cpu_peripheral_0_aw_bits_size;
assign mmio_auto_axi4xbar_in_aw_bits_burst = cpu_peripheral_0_aw_bits_burst;
assign mmio_auto_axi4xbar_in_aw_bits_lock = cpu_peripheral_0_aw_bits_lock;
assign mmio_auto_axi4xbar_in_aw_bits_cache = cpu_peripheral_0_aw_bits_cache;
assign mmio_auto_axi4xbar_in_aw_bits_prot = cpu_peripheral_0_aw_bits_prot;
assign mmio_auto_axi4xbar_in_aw_bits_qos = cpu_peripheral_0_aw_bits_qos;
assign mmio_auto_axi4xbar_in_w_valid = cpu_peripheral_0_w_valid;
assign mmio_auto_axi4xbar_in_w_bits_data = cpu_peripheral_0_w_bits_data;
assign mmio_auto_axi4xbar_in_w_bits_strb = cpu_peripheral_0_w_bits_strb;
assign mmio_auto_axi4xbar_in_w_bits_last = cpu_peripheral_0_w_bits_last;
assign mmio_auto_axi4xbar_in_b_ready = cpu_peripheral_0_b_ready;
assign mmio_auto_axi4xbar_in_ar_valid = cpu_peripheral_0_ar_valid;
assign mmio_auto_axi4xbar_in_ar_bits_id = cpu_peripheral_0_ar_bits_id;
assign mmio_auto_axi4xbar_in_ar_bits_addr = cpu_peripheral_0_ar_bits_addr;
assign mmio_auto_axi4xbar_in_ar_bits_len = cpu_peripheral_0_ar_bits_len;
assign mmio_auto_axi4xbar_in_ar_bits_size = cpu_peripheral_0_ar_bits_size;
assign mmio_auto_axi4xbar_in_ar_bits_burst = cpu_peripheral_0_ar_bits_burst;
assign mmio_auto_axi4xbar_in_ar_bits_lock = cpu_peripheral_0_ar_bits_lock;
assign mmio_auto_axi4xbar_in_ar_bits_cache = cpu_peripheral_0_ar_bits_cache;
assign mmio_auto_axi4xbar_in_ar_bits_prot = cpu_peripheral_0_ar_bits_prot;
assign mmio_auto_axi4xbar_in_ar_bits_qos = cpu_peripheral_0_ar_bits_qos;
assign mmio_auto_axi4xbar_in_r_ready = cpu_peripheral_0_r_ready;
assign mmio_io_uart_in_ch = 0;

assign ram_clock = clock;
assign ram_reset = reset;
assign ram_auto_in_aw_valid = cpu_memory_0_aw_valid;
assign ram_auto_in_aw_bits_id = cpu_memory_0_aw_bits_id;
assign ram_auto_in_aw_bits_addr = cpu_memory_0_aw_bits_addr;
assign ram_auto_in_aw_bits_len = cpu_memory_0_aw_bits_len;
assign ram_auto_in_aw_bits_size = cpu_memory_0_aw_bits_size;
assign ram_auto_in_aw_bits_burst = cpu_memory_0_aw_bits_burst;
assign ram_auto_in_aw_bits_lock = cpu_memory_0_aw_bits_lock;
assign ram_auto_in_aw_bits_cache = cpu_memory_0_aw_bits_cache;
assign ram_auto_in_aw_bits_prot = cpu_memory_0_aw_bits_prot;
assign ram_auto_in_aw_bits_qos = cpu_memory_0_aw_bits_qos;
assign ram_auto_in_w_valid = cpu_memory_0_w_valid;
assign ram_auto_in_w_bits_data = cpu_memory_0_w_bits_data;
assign ram_auto_in_w_bits_strb = cpu_memory_0_w_bits_strb;
assign ram_auto_in_w_bits_last = cpu_memory_0_w_bits_last;
assign ram_auto_in_b_ready = cpu_memory_0_b_ready;
assign ram_auto_in_ar_valid = cpu_memory_0_ar_valid;
assign ram_auto_in_ar_bits_id = cpu_memory_0_ar_bits_id;
assign ram_auto_in_ar_bits_addr = cpu_memory_0_ar_bits_addr;
assign ram_auto_in_ar_bits_len = cpu_memory_0_ar_bits_len;
assign ram_auto_in_ar_bits_size = cpu_memory_0_ar_bits_size;
assign ram_auto_in_ar_bits_burst = cpu_memory_0_ar_bits_burst;
assign ram_auto_in_ar_bits_lock = cpu_memory_0_ar_bits_lock;
assign ram_auto_in_ar_bits_cache = cpu_memory_0_ar_bits_cache;
assign ram_auto_in_ar_bits_prot = cpu_memory_0_ar_bits_prot;
assign ram_auto_in_ar_bits_qos = cpu_memory_0_ar_bits_qos;
assign ram_auto_in_r_ready = cpu_memory_0_r_ready;

assign uart_valid = mmio_io_uart_out_valid;
assign uart_ch = mmio_io_uart_out_ch;

XSTop CPU(
  .clock(cpu_clock),
  .reset(cpu_reset),
  .memory_0_aw_ready(cpu_memory_0_aw_ready),
  .memory_0_aw_valid(cpu_memory_0_aw_valid),
  .memory_0_aw_bits_id(cpu_memory_0_aw_bits_id),
  .memory_0_aw_bits_addr(cpu_memory_0_aw_bits_addr),
  .memory_0_aw_bits_len(cpu_memory_0_aw_bits_len),
  .memory_0_aw_bits_size(cpu_memory_0_aw_bits_size),
  .memory_0_aw_bits_burst(cpu_memory_0_aw_bits_burst),
  .memory_0_aw_bits_lock(cpu_memory_0_aw_bits_lock),
  .memory_0_aw_bits_cache(cpu_memory_0_aw_bits_cache),
  .memory_0_aw_bits_prot(cpu_memory_0_aw_bits_prot),
  .memory_0_aw_bits_qos(cpu_memory_0_aw_bits_qos),
  .memory_0_w_ready(cpu_memory_0_w_ready),
  .memory_0_w_valid(cpu_memory_0_w_valid),
  .memory_0_w_bits_data(cpu_memory_0_w_bits_data),
  .memory_0_w_bits_strb(cpu_memory_0_w_bits_strb),
  .memory_0_w_bits_last(cpu_memory_0_w_bits_last),
  .memory_0_b_ready(cpu_memory_0_b_ready),
  .memory_0_b_valid(cpu_memory_0_b_valid),
  .memory_0_b_bits_id(cpu_memory_0_b_bits_id),
  .memory_0_b_bits_resp(cpu_memory_0_b_bits_resp),
  .memory_0_ar_ready(cpu_memory_0_ar_ready),
  .memory_0_ar_valid(cpu_memory_0_ar_valid),
  .memory_0_ar_bits_id(cpu_memory_0_ar_bits_id),
  .memory_0_ar_bits_addr(cpu_memory_0_ar_bits_addr),
  .memory_0_ar_bits_len(cpu_memory_0_ar_bits_len),
  .memory_0_ar_bits_size(cpu_memory_0_ar_bits_size),
  .memory_0_ar_bits_burst(cpu_memory_0_ar_bits_burst),
  .memory_0_ar_bits_lock(cpu_memory_0_ar_bits_lock),
  .memory_0_ar_bits_cache(cpu_memory_0_ar_bits_cache),
  .memory_0_ar_bits_prot(cpu_memory_0_ar_bits_prot),
  .memory_0_ar_bits_qos(cpu_memory_0_ar_bits_qos),
  .memory_0_r_ready(cpu_memory_0_r_ready),
  .memory_0_r_valid(cpu_memory_0_r_valid),
  .memory_0_r_bits_id(cpu_memory_0_r_bits_id),
  .memory_0_r_bits_data(cpu_memory_0_r_bits_data),
  .memory_0_r_bits_resp(cpu_memory_0_r_bits_resp),
  .memory_0_r_bits_last(cpu_memory_0_r_bits_last),
  .peripheral_0_aw_ready(cpu_peripheral_0_aw_ready),
  .peripheral_0_aw_valid(cpu_peripheral_0_aw_valid),
  .peripheral_0_aw_bits_id(cpu_peripheral_0_aw_bits_id),
  .peripheral_0_aw_bits_addr(cpu_peripheral_0_aw_bits_addr),
  .peripheral_0_aw_bits_len(cpu_peripheral_0_aw_bits_len),
  .peripheral_0_aw_bits_size(cpu_peripheral_0_aw_bits_size),
  .peripheral_0_aw_bits_burst(cpu_peripheral_0_aw_bits_burst),
  .peripheral_0_aw_bits_lock(cpu_peripheral_0_aw_bits_lock),
  .peripheral_0_aw_bits_cache(cpu_peripheral_0_aw_bits_cache),
  .peripheral_0_aw_bits_prot(cpu_peripheral_0_aw_bits_prot),
  .peripheral_0_aw_bits_qos(cpu_peripheral_0_aw_bits_qos),
  .peripheral_0_w_ready(cpu_peripheral_0_w_ready),
  .peripheral_0_w_valid(cpu_peripheral_0_w_valid),
  .peripheral_0_w_bits_data(cpu_peripheral_0_w_bits_data),
  .peripheral_0_w_bits_strb(cpu_peripheral_0_w_bits_strb),
  .peripheral_0_w_bits_last(cpu_peripheral_0_w_bits_last),
  .peripheral_0_b_ready(cpu_peripheral_0_b_ready),
  .peripheral_0_b_valid(cpu_peripheral_0_b_valid),
  .peripheral_0_b_bits_id(cpu_peripheral_0_b_bits_id),
  .peripheral_0_b_bits_resp(cpu_peripheral_0_b_bits_resp),
  .peripheral_0_ar_ready(cpu_peripheral_0_ar_ready),
  .peripheral_0_ar_valid(cpu_peripheral_0_ar_valid),
  .peripheral_0_ar_bits_id(cpu_peripheral_0_ar_bits_id),
  .peripheral_0_ar_bits_addr(cpu_peripheral_0_ar_bits_addr),
  .peripheral_0_ar_bits_len(cpu_peripheral_0_ar_bits_len),
  .peripheral_0_ar_bits_size(cpu_peripheral_0_ar_bits_size),
  .peripheral_0_ar_bits_burst(cpu_peripheral_0_ar_bits_burst),
  .peripheral_0_ar_bits_lock(cpu_peripheral_0_ar_bits_lock),
  .peripheral_0_ar_bits_cache(cpu_peripheral_0_ar_bits_cache),
  .peripheral_0_ar_bits_prot(cpu_peripheral_0_ar_bits_prot),
  .peripheral_0_ar_bits_qos(cpu_peripheral_0_ar_bits_qos),
  .peripheral_0_r_ready(cpu_peripheral_0_r_ready),
  .peripheral_0_r_valid(cpu_peripheral_0_r_valid),
  .peripheral_0_r_bits_id(cpu_peripheral_0_r_bits_id),
  .peripheral_0_r_bits_data(cpu_peripheral_0_r_bits_data),
  .peripheral_0_r_bits_resp(cpu_peripheral_0_r_bits_resp),
  .peripheral_0_r_bits_last(cpu_peripheral_0_r_bits_last),
  .dma_0_aw_ready(cpu_dma_0_aw_ready),
  .dma_0_aw_valid(cpu_dma_0_aw_valid),
  .dma_0_aw_bits_id(cpu_dma_0_aw_bits_id),
  .dma_0_aw_bits_addr(cpu_dma_0_aw_bits_addr),
  .dma_0_aw_bits_len(cpu_dma_0_aw_bits_len),
  .dma_0_aw_bits_size(cpu_dma_0_aw_bits_size),
  .dma_0_aw_bits_burst(cpu_dma_0_aw_bits_burst),
  .dma_0_aw_bits_lock(cpu_dma_0_aw_bits_lock),
  .dma_0_aw_bits_cache(cpu_dma_0_aw_bits_cache),
  .dma_0_aw_bits_prot(cpu_dma_0_aw_bits_prot),
  .dma_0_aw_bits_qos(cpu_dma_0_aw_bits_qos),
  .dma_0_w_ready(cpu_dma_0_w_ready),
  .dma_0_w_valid(cpu_dma_0_w_valid),
  .dma_0_w_bits_data(cpu_dma_0_w_bits_data),
  .dma_0_w_bits_strb(cpu_dma_0_w_bits_strb),
  .dma_0_w_bits_last(cpu_dma_0_w_bits_last),
  .dma_0_b_ready(cpu_dma_0_b_ready),
  .dma_0_b_valid(cpu_dma_0_b_valid),
  .dma_0_b_bits_id(cpu_dma_0_b_bits_id),
  .dma_0_b_bits_resp(cpu_dma_0_b_bits_resp),
  .dma_0_ar_ready(cpu_dma_0_ar_ready),
  .dma_0_ar_valid(cpu_dma_0_ar_valid),
  .dma_0_ar_bits_id(cpu_dma_0_ar_bits_id),
  .dma_0_ar_bits_addr(cpu_dma_0_ar_bits_addr),
  .dma_0_ar_bits_len(cpu_dma_0_ar_bits_len),
  .dma_0_ar_bits_size(cpu_dma_0_ar_bits_size),
  .dma_0_ar_bits_burst(cpu_dma_0_ar_bits_burst),
  .dma_0_ar_bits_lock(cpu_dma_0_ar_bits_lock),
  .dma_0_ar_bits_cache(cpu_dma_0_ar_bits_cache),
  .dma_0_ar_bits_prot(cpu_dma_0_ar_bits_prot),
  .dma_0_ar_bits_qos(cpu_dma_0_ar_bits_qos),
  .dma_0_r_ready(cpu_dma_0_r_ready),
  .dma_0_r_valid(cpu_dma_0_r_valid),
  .dma_0_r_bits_id(cpu_dma_0_r_bits_id),
  .dma_0_r_bits_data(cpu_dma_0_r_bits_data),
  .dma_0_r_bits_resp(cpu_dma_0_r_bits_resp),
  .dma_0_r_bits_last(cpu_dma_0_r_bits_last),
  .io_extIntrs(cpu_io_extIntrs)
);


always @(posedge clock) begin
   if (mmio_auto_axi4xbar_in_aw_valid) begin
    //$display("MMIO: waddr valid %x", mmio_auto_axi4xbar_in_aw_bits_addr);
  end
  if (mmio_auto_axi4xbar_in_w_valid) begin
    //$display("MMIO: wdata %x", mmio_auto_axi4xbar_in_w_bits_data);
  end

 if (mmio_auto_axi4xbar_in_aw_ready && mmio_auto_axi4xbar_in_aw_valid) begin
    //$display("MMIO: waddr %x", mmio_auto_axi4xbar_in_aw_bits_addr);
  end
  if (mmio_auto_axi4xbar_in_w_ready && mmio_auto_axi4xbar_in_w_valid) begin
    //$display("MMIO: wdata %x", mmio_auto_axi4xbar_in_w_bits_data);
  end

end


SimMMIO mmio(
  .clock(mmio_clock),
  .reset(mmio_reset),
  .auto_axi4xbar_in_aw_ready(mmio_auto_axi4xbar_in_aw_ready),
  .auto_axi4xbar_in_aw_valid(mmio_auto_axi4xbar_in_aw_valid),
  .auto_axi4xbar_in_aw_bits_id(mmio_auto_axi4xbar_in_aw_bits_id),
  .auto_axi4xbar_in_aw_bits_addr(mmio_auto_axi4xbar_in_aw_bits_addr),
  .auto_axi4xbar_in_aw_bits_len(mmio_auto_axi4xbar_in_aw_bits_len),
  .auto_axi4xbar_in_aw_bits_size(mmio_auto_axi4xbar_in_aw_bits_size),
  .auto_axi4xbar_in_aw_bits_burst(mmio_auto_axi4xbar_in_aw_bits_burst),
  .auto_axi4xbar_in_aw_bits_lock(mmio_auto_axi4xbar_in_aw_bits_lock),
  .auto_axi4xbar_in_aw_bits_cache(mmio_auto_axi4xbar_in_aw_bits_cache),
  .auto_axi4xbar_in_aw_bits_prot(mmio_auto_axi4xbar_in_aw_bits_prot),
  .auto_axi4xbar_in_aw_bits_qos(mmio_auto_axi4xbar_in_aw_bits_qos),
  .auto_axi4xbar_in_w_ready(mmio_auto_axi4xbar_in_w_ready),
  .auto_axi4xbar_in_w_valid(mmio_auto_axi4xbar_in_w_valid),
  .auto_axi4xbar_in_w_bits_data(mmio_auto_axi4xbar_in_w_bits_data),
  .auto_axi4xbar_in_w_bits_strb(mmio_auto_axi4xbar_in_w_bits_strb),
  .auto_axi4xbar_in_w_bits_last(mmio_auto_axi4xbar_in_w_bits_last),
  .auto_axi4xbar_in_b_ready(mmio_auto_axi4xbar_in_b_ready),
  .auto_axi4xbar_in_b_valid(mmio_auto_axi4xbar_in_b_valid),
  .auto_axi4xbar_in_b_bits_id(mmio_auto_axi4xbar_in_b_bits_id),
  .auto_axi4xbar_in_b_bits_resp(mmio_auto_axi4xbar_in_b_bits_resp),
  .auto_axi4xbar_in_ar_ready(mmio_auto_axi4xbar_in_ar_ready),
  .auto_axi4xbar_in_ar_valid(mmio_auto_axi4xbar_in_ar_valid),
  .auto_axi4xbar_in_ar_bits_id(mmio_auto_axi4xbar_in_ar_bits_id),
  .auto_axi4xbar_in_ar_bits_addr(mmio_auto_axi4xbar_in_ar_bits_addr),
  .auto_axi4xbar_in_ar_bits_len(mmio_auto_axi4xbar_in_ar_bits_len),
  .auto_axi4xbar_in_ar_bits_size(mmio_auto_axi4xbar_in_ar_bits_size),
  .auto_axi4xbar_in_ar_bits_burst(mmio_auto_axi4xbar_in_ar_bits_burst),
  .auto_axi4xbar_in_ar_bits_lock(mmio_auto_axi4xbar_in_ar_bits_lock),
  .auto_axi4xbar_in_ar_bits_cache(mmio_auto_axi4xbar_in_ar_bits_cache),
  .auto_axi4xbar_in_ar_bits_prot(mmio_auto_axi4xbar_in_ar_bits_prot),
  .auto_axi4xbar_in_ar_bits_qos(mmio_auto_axi4xbar_in_ar_bits_qos),
  .auto_axi4xbar_in_r_ready(mmio_auto_axi4xbar_in_r_ready),
  .auto_axi4xbar_in_r_valid(mmio_auto_axi4xbar_in_r_valid),
  .auto_axi4xbar_in_r_bits_id(mmio_auto_axi4xbar_in_r_bits_id),
  .auto_axi4xbar_in_r_bits_data(mmio_auto_axi4xbar_in_r_bits_data),
  .auto_axi4xbar_in_r_bits_resp(mmio_auto_axi4xbar_in_r_bits_resp),
  .auto_axi4xbar_in_r_bits_last(mmio_auto_axi4xbar_in_r_bits_last),
  .io_uart_out_valid(mmio_io_uart_out_valid),
  .io_uart_out_ch(mmio_io_uart_out_ch),
  .io_uart_in_valid(mmio_io_uart_in_valid),
  .io_uart_in_ch(mmio_io_uart_in_ch)
);
always @(posedge clock) begin
    if (ram_auto_in_aw_valid) begin
    //$display("waddr valid = %x", ram_auto_in_aw_bits_addr);
  end

if (ram_auto_in_ar_valid) begin
    //$display("raddr valid = %x", ram_auto_in_ar_bits_addr);
  end

  if (ram_auto_in_aw_valid && ram_auto_in_aw_ready) begin
    // $display("waddr = %x", ram_auto_in_aw_bits_addr);
  end

if (ram_auto_in_ar_valid && ram_auto_in_ar_ready) begin
    // $display("raddr = %x", ram_auto_in_ar_bits_addr);
  end

end

AXI4RAM ram(
  .clock(ram_clock),
  .reset(ram_reset),
  .auto_in_aw_ready(ram_auto_in_aw_ready),
  .auto_in_aw_valid(ram_auto_in_aw_valid),
  .auto_in_aw_bits_id(ram_auto_in_aw_bits_id),
  .auto_in_aw_bits_addr(ram_auto_in_aw_bits_addr),
  .auto_in_aw_bits_len(ram_auto_in_aw_bits_len),
  .auto_in_aw_bits_size(ram_auto_in_aw_bits_size),
  .auto_in_aw_bits_burst(ram_auto_in_aw_bits_burst),
  .auto_in_aw_bits_lock(ram_auto_in_aw_bits_lock),
  .auto_in_aw_bits_cache(ram_auto_in_aw_bits_cache),
  .auto_in_aw_bits_prot(ram_auto_in_aw_bits_prot),
  .auto_in_aw_bits_qos(ram_auto_in_aw_bits_qos),
  .auto_in_w_ready(ram_auto_in_w_ready),
  .auto_in_w_valid(ram_auto_in_w_valid),
  .auto_in_w_bits_data(ram_auto_in_w_bits_data),
  .auto_in_w_bits_strb(ram_auto_in_w_bits_strb),
  .auto_in_w_bits_last(ram_auto_in_w_bits_last),
  .auto_in_b_ready(ram_auto_in_b_ready),
  .auto_in_b_valid(ram_auto_in_b_valid),
  .auto_in_b_bits_id(ram_auto_in_b_bits_id),
  .auto_in_b_bits_resp(ram_auto_in_b_bits_resp),
  .auto_in_ar_ready(ram_auto_in_ar_ready),
  .auto_in_ar_valid(ram_auto_in_ar_valid),
  .auto_in_ar_bits_id(ram_auto_in_ar_bits_id),
  .auto_in_ar_bits_addr(ram_auto_in_ar_bits_addr),
  .auto_in_ar_bits_len(ram_auto_in_ar_bits_len),
  .auto_in_ar_bits_size(ram_auto_in_ar_bits_size),
  .auto_in_ar_bits_burst(ram_auto_in_ar_bits_burst),
  .auto_in_ar_bits_lock(ram_auto_in_ar_bits_lock),
  .auto_in_ar_bits_cache(ram_auto_in_ar_bits_cache),
  .auto_in_ar_bits_prot(ram_auto_in_ar_bits_prot),
  .auto_in_ar_bits_qos(ram_auto_in_ar_bits_qos),
  .auto_in_r_ready(ram_auto_in_r_ready),
  .auto_in_r_valid(ram_auto_in_r_valid),
  .auto_in_r_bits_id(ram_auto_in_r_bits_id),
  .auto_in_r_bits_data(ram_auto_in_r_bits_data),
  .auto_in_r_bits_resp(ram_auto_in_r_bits_resp),
  .auto_in_r_bits_last(ram_auto_in_r_bits_last)
);

endmodule

