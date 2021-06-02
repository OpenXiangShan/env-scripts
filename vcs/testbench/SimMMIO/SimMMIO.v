module SimMMIO(
  input          clock,
  input          reset,
  output         io_axi4_0_aw_ready,
  input          io_axi4_0_aw_valid,
  input  [1:0]   io_axi4_0_aw_bits_id,
  input  [30:0]  io_axi4_0_aw_bits_addr,
  input  [7:0]   io_axi4_0_aw_bits_len,
  input  [2:0]   io_axi4_0_aw_bits_size,
  input  [1:0]   io_axi4_0_aw_bits_burst,
  input          io_axi4_0_aw_bits_lock,
  input  [3:0]   io_axi4_0_aw_bits_cache,
  input  [2:0]   io_axi4_0_aw_bits_prot,
  input  [3:0]   io_axi4_0_aw_bits_qos,
  output         io_axi4_0_w_ready,
  input          io_axi4_0_w_valid,
  input  [63:0]  io_axi4_0_w_bits_data,
  input  [7:0]   io_axi4_0_w_bits_strb,
  input          io_axi4_0_w_bits_last,
  input          io_axi4_0_b_ready,
  output         io_axi4_0_b_valid,
  output [1:0]   io_axi4_0_b_bits_id,
  output [1:0]   io_axi4_0_b_bits_resp,
  output         io_axi4_0_ar_ready,
  input          io_axi4_0_ar_valid,
  input  [1:0]   io_axi4_0_ar_bits_id,
  input  [30:0]  io_axi4_0_ar_bits_addr,
  input  [7:0]   io_axi4_0_ar_bits_len,
  input  [2:0]   io_axi4_0_ar_bits_size,
  input  [1:0]   io_axi4_0_ar_bits_burst,
  input          io_axi4_0_ar_bits_lock,
  input  [3:0]   io_axi4_0_ar_bits_cache,
  input  [2:0]   io_axi4_0_ar_bits_prot,
  input  [3:0]   io_axi4_0_ar_bits_qos,
  input          io_axi4_0_r_ready,
  output         io_axi4_0_r_valid,
  output [1:0]   io_axi4_0_r_bits_id,
  output [63:0]  io_axi4_0_r_bits_data,
  output [1:0]   io_axi4_0_r_bits_resp,
  output         io_axi4_0_r_bits_last,
  output         io_uart_out_valid,
  output [7:0]   io_uart_out_ch,
  output         io_uart_in_valid,
  input  [7:0]   io_uart_in_ch,
  output [255:0] io_interrupt_intrVec
);
  wire  flash_clock; // @[SimMMIO.scala 13:25]
  wire  flash_reset; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_aw_ready; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_aw_valid; // @[SimMMIO.scala 13:25]
  wire [1:0] flash_auto_in_aw_bits_id; // @[SimMMIO.scala 13:25]
  wire [28:0] flash_auto_in_aw_bits_addr; // @[SimMMIO.scala 13:25]
  wire [7:0] flash_auto_in_aw_bits_len; // @[SimMMIO.scala 13:25]
  wire [2:0] flash_auto_in_aw_bits_size; // @[SimMMIO.scala 13:25]
  wire [1:0] flash_auto_in_aw_bits_burst; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_aw_bits_lock; // @[SimMMIO.scala 13:25]
  wire [3:0] flash_auto_in_aw_bits_cache; // @[SimMMIO.scala 13:25]
  wire [2:0] flash_auto_in_aw_bits_prot; // @[SimMMIO.scala 13:25]
  wire [3:0] flash_auto_in_aw_bits_qos; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_w_ready; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_w_valid; // @[SimMMIO.scala 13:25]
  wire [63:0] flash_auto_in_w_bits_data; // @[SimMMIO.scala 13:25]
  wire [7:0] flash_auto_in_w_bits_strb; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_w_bits_last; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_b_ready; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_b_valid; // @[SimMMIO.scala 13:25]
  wire [1:0] flash_auto_in_b_bits_id; // @[SimMMIO.scala 13:25]
  wire [1:0] flash_auto_in_b_bits_resp; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_ar_ready; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_ar_valid; // @[SimMMIO.scala 13:25]
  wire [1:0] flash_auto_in_ar_bits_id; // @[SimMMIO.scala 13:25]
  wire [28:0] flash_auto_in_ar_bits_addr; // @[SimMMIO.scala 13:25]
  wire [7:0] flash_auto_in_ar_bits_len; // @[SimMMIO.scala 13:25]
  wire [2:0] flash_auto_in_ar_bits_size; // @[SimMMIO.scala 13:25]
  wire [1:0] flash_auto_in_ar_bits_burst; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_ar_bits_lock; // @[SimMMIO.scala 13:25]
  wire [3:0] flash_auto_in_ar_bits_cache; // @[SimMMIO.scala 13:25]
  wire [2:0] flash_auto_in_ar_bits_prot; // @[SimMMIO.scala 13:25]
  wire [3:0] flash_auto_in_ar_bits_qos; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_r_ready; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_r_valid; // @[SimMMIO.scala 13:25]
  wire [1:0] flash_auto_in_r_bits_id; // @[SimMMIO.scala 13:25]
  wire [63:0] flash_auto_in_r_bits_data; // @[SimMMIO.scala 13:25]
  wire [1:0] flash_auto_in_r_bits_resp; // @[SimMMIO.scala 13:25]
  wire  flash_auto_in_r_bits_last; // @[SimMMIO.scala 13:25]
  wire  uart_clock; // @[SimMMIO.scala 14:24]
  wire  uart_reset; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_aw_ready; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_aw_valid; // @[SimMMIO.scala 14:24]
  wire [1:0] uart_auto_in_aw_bits_id; // @[SimMMIO.scala 14:24]
  wire [30:0] uart_auto_in_aw_bits_addr; // @[SimMMIO.scala 14:24]
  wire [7:0] uart_auto_in_aw_bits_len; // @[SimMMIO.scala 14:24]
  wire [2:0] uart_auto_in_aw_bits_size; // @[SimMMIO.scala 14:24]
  wire [1:0] uart_auto_in_aw_bits_burst; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_aw_bits_lock; // @[SimMMIO.scala 14:24]
  wire [3:0] uart_auto_in_aw_bits_cache; // @[SimMMIO.scala 14:24]
  wire [2:0] uart_auto_in_aw_bits_prot; // @[SimMMIO.scala 14:24]
  wire [3:0] uart_auto_in_aw_bits_qos; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_w_ready; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_w_valid; // @[SimMMIO.scala 14:24]
  wire [63:0] uart_auto_in_w_bits_data; // @[SimMMIO.scala 14:24]
  wire [7:0] uart_auto_in_w_bits_strb; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_w_bits_last; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_b_ready; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_b_valid; // @[SimMMIO.scala 14:24]
  wire [1:0] uart_auto_in_b_bits_id; // @[SimMMIO.scala 14:24]
  wire [1:0] uart_auto_in_b_bits_resp; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_ar_ready; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_ar_valid; // @[SimMMIO.scala 14:24]
  wire [1:0] uart_auto_in_ar_bits_id; // @[SimMMIO.scala 14:24]
  wire [30:0] uart_auto_in_ar_bits_addr; // @[SimMMIO.scala 14:24]
  wire [7:0] uart_auto_in_ar_bits_len; // @[SimMMIO.scala 14:24]
  wire [2:0] uart_auto_in_ar_bits_size; // @[SimMMIO.scala 14:24]
  wire [1:0] uart_auto_in_ar_bits_burst; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_ar_bits_lock; // @[SimMMIO.scala 14:24]
  wire [3:0] uart_auto_in_ar_bits_cache; // @[SimMMIO.scala 14:24]
  wire [2:0] uart_auto_in_ar_bits_prot; // @[SimMMIO.scala 14:24]
  wire [3:0] uart_auto_in_ar_bits_qos; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_r_ready; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_r_valid; // @[SimMMIO.scala 14:24]
  wire [1:0] uart_auto_in_r_bits_id; // @[SimMMIO.scala 14:24]
  wire [63:0] uart_auto_in_r_bits_data; // @[SimMMIO.scala 14:24]
  wire [1:0] uart_auto_in_r_bits_resp; // @[SimMMIO.scala 14:24]
  wire  uart_auto_in_r_bits_last; // @[SimMMIO.scala 14:24]
  wire  uart_io_extra_out_valid; // @[SimMMIO.scala 14:24]
  wire [7:0] uart_io_extra_out_ch; // @[SimMMIO.scala 14:24]
  wire  uart_io_extra_in_valid; // @[SimMMIO.scala 14:24]
  wire [7:0] uart_io_extra_in_ch; // @[SimMMIO.scala 14:24]
  wire  vga_clock; // @[SimMMIO.scala 15:23]
  wire  vga_reset; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_aw_ready; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_aw_valid; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_1_aw_bits_id; // @[SimMMIO.scala 15:23]
  wire [30:0] vga_auto_in_1_aw_bits_addr; // @[SimMMIO.scala 15:23]
  wire [7:0] vga_auto_in_1_aw_bits_len; // @[SimMMIO.scala 15:23]
  wire [2:0] vga_auto_in_1_aw_bits_size; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_1_aw_bits_burst; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_aw_bits_lock; // @[SimMMIO.scala 15:23]
  wire [3:0] vga_auto_in_1_aw_bits_cache; // @[SimMMIO.scala 15:23]
  wire [2:0] vga_auto_in_1_aw_bits_prot; // @[SimMMIO.scala 15:23]
  wire [3:0] vga_auto_in_1_aw_bits_qos; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_w_ready; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_w_valid; // @[SimMMIO.scala 15:23]
  wire [63:0] vga_auto_in_1_w_bits_data; // @[SimMMIO.scala 15:23]
  wire [7:0] vga_auto_in_1_w_bits_strb; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_w_bits_last; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_b_ready; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_b_valid; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_1_b_bits_id; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_1_b_bits_resp; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_ar_ready; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_ar_valid; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_1_ar_bits_id; // @[SimMMIO.scala 15:23]
  wire [30:0] vga_auto_in_1_ar_bits_addr; // @[SimMMIO.scala 15:23]
  wire [7:0] vga_auto_in_1_ar_bits_len; // @[SimMMIO.scala 15:23]
  wire [2:0] vga_auto_in_1_ar_bits_size; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_1_ar_bits_burst; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_ar_bits_lock; // @[SimMMIO.scala 15:23]
  wire [3:0] vga_auto_in_1_ar_bits_cache; // @[SimMMIO.scala 15:23]
  wire [2:0] vga_auto_in_1_ar_bits_prot; // @[SimMMIO.scala 15:23]
  wire [3:0] vga_auto_in_1_ar_bits_qos; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_r_ready; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_r_valid; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_1_r_bits_id; // @[SimMMIO.scala 15:23]
  wire [63:0] vga_auto_in_1_r_bits_data; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_1_r_bits_resp; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_1_r_bits_last; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_aw_ready; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_aw_valid; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_0_aw_bits_id; // @[SimMMIO.scala 15:23]
  wire [30:0] vga_auto_in_0_aw_bits_addr; // @[SimMMIO.scala 15:23]
  wire [7:0] vga_auto_in_0_aw_bits_len; // @[SimMMIO.scala 15:23]
  wire [2:0] vga_auto_in_0_aw_bits_size; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_0_aw_bits_burst; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_aw_bits_lock; // @[SimMMIO.scala 15:23]
  wire [3:0] vga_auto_in_0_aw_bits_cache; // @[SimMMIO.scala 15:23]
  wire [2:0] vga_auto_in_0_aw_bits_prot; // @[SimMMIO.scala 15:23]
  wire [3:0] vga_auto_in_0_aw_bits_qos; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_w_ready; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_w_valid; // @[SimMMIO.scala 15:23]
  wire [63:0] vga_auto_in_0_w_bits_data; // @[SimMMIO.scala 15:23]
  wire [7:0] vga_auto_in_0_w_bits_strb; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_w_bits_last; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_b_ready; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_b_valid; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_0_b_bits_id; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_0_b_bits_resp; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_ar_valid; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_0_ar_bits_id; // @[SimMMIO.scala 15:23]
  wire [7:0] vga_auto_in_0_ar_bits_len; // @[SimMMIO.scala 15:23]
  wire [2:0] vga_auto_in_0_ar_bits_size; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_0_ar_bits_burst; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_ar_bits_lock; // @[SimMMIO.scala 15:23]
  wire [3:0] vga_auto_in_0_ar_bits_cache; // @[SimMMIO.scala 15:23]
  wire [3:0] vga_auto_in_0_ar_bits_qos; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_r_ready; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_r_valid; // @[SimMMIO.scala 15:23]
  wire [1:0] vga_auto_in_0_r_bits_id; // @[SimMMIO.scala 15:23]
  wire  vga_auto_in_0_r_bits_last; // @[SimMMIO.scala 15:23]
  wire  sd_clock; // @[SimMMIO.scala 20:22]
  wire  sd_reset; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_aw_ready; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_aw_valid; // @[SimMMIO.scala 20:22]
  wire [1:0] sd_auto_in_aw_bits_id; // @[SimMMIO.scala 20:22]
  wire [30:0] sd_auto_in_aw_bits_addr; // @[SimMMIO.scala 20:22]
  wire [7:0] sd_auto_in_aw_bits_len; // @[SimMMIO.scala 20:22]
  wire [2:0] sd_auto_in_aw_bits_size; // @[SimMMIO.scala 20:22]
  wire [1:0] sd_auto_in_aw_bits_burst; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_aw_bits_lock; // @[SimMMIO.scala 20:22]
  wire [3:0] sd_auto_in_aw_bits_cache; // @[SimMMIO.scala 20:22]
  wire [2:0] sd_auto_in_aw_bits_prot; // @[SimMMIO.scala 20:22]
  wire [3:0] sd_auto_in_aw_bits_qos; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_w_ready; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_w_valid; // @[SimMMIO.scala 20:22]
  wire [63:0] sd_auto_in_w_bits_data; // @[SimMMIO.scala 20:22]
  wire [7:0] sd_auto_in_w_bits_strb; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_w_bits_last; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_b_ready; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_b_valid; // @[SimMMIO.scala 20:22]
  wire [1:0] sd_auto_in_b_bits_id; // @[SimMMIO.scala 20:22]
  wire [1:0] sd_auto_in_b_bits_resp; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_ar_ready; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_ar_valid; // @[SimMMIO.scala 20:22]
  wire [1:0] sd_auto_in_ar_bits_id; // @[SimMMIO.scala 20:22]
  wire [30:0] sd_auto_in_ar_bits_addr; // @[SimMMIO.scala 20:22]
  wire [7:0] sd_auto_in_ar_bits_len; // @[SimMMIO.scala 20:22]
  wire [2:0] sd_auto_in_ar_bits_size; // @[SimMMIO.scala 20:22]
  wire [1:0] sd_auto_in_ar_bits_burst; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_ar_bits_lock; // @[SimMMIO.scala 20:22]
  wire [3:0] sd_auto_in_ar_bits_cache; // @[SimMMIO.scala 20:22]
  wire [2:0] sd_auto_in_ar_bits_prot; // @[SimMMIO.scala 20:22]
  wire [3:0] sd_auto_in_ar_bits_qos; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_r_ready; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_r_valid; // @[SimMMIO.scala 20:22]
  wire [1:0] sd_auto_in_r_bits_id; // @[SimMMIO.scala 20:22]
  wire [63:0] sd_auto_in_r_bits_data; // @[SimMMIO.scala 20:22]
  wire [1:0] sd_auto_in_r_bits_resp; // @[SimMMIO.scala 20:22]
  wire  sd_auto_in_r_bits_last; // @[SimMMIO.scala 20:22]
  wire  intrGen_clock; // @[SimMMIO.scala 21:27]
  wire  intrGen_reset; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_aw_ready; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_aw_valid; // @[SimMMIO.scala 21:27]
  wire [1:0] intrGen_auto_in_aw_bits_id; // @[SimMMIO.scala 21:27]
  wire [30:0] intrGen_auto_in_aw_bits_addr; // @[SimMMIO.scala 21:27]
  wire [7:0] intrGen_auto_in_aw_bits_len; // @[SimMMIO.scala 21:27]
  wire [2:0] intrGen_auto_in_aw_bits_size; // @[SimMMIO.scala 21:27]
  wire [1:0] intrGen_auto_in_aw_bits_burst; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_aw_bits_lock; // @[SimMMIO.scala 21:27]
  wire [3:0] intrGen_auto_in_aw_bits_cache; // @[SimMMIO.scala 21:27]
  wire [2:0] intrGen_auto_in_aw_bits_prot; // @[SimMMIO.scala 21:27]
  wire [3:0] intrGen_auto_in_aw_bits_qos; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_w_ready; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_w_valid; // @[SimMMIO.scala 21:27]
  wire [63:0] intrGen_auto_in_w_bits_data; // @[SimMMIO.scala 21:27]
  wire [7:0] intrGen_auto_in_w_bits_strb; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_w_bits_last; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_b_ready; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_b_valid; // @[SimMMIO.scala 21:27]
  wire [1:0] intrGen_auto_in_b_bits_id; // @[SimMMIO.scala 21:27]
  wire [1:0] intrGen_auto_in_b_bits_resp; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_ar_ready; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_ar_valid; // @[SimMMIO.scala 21:27]
  wire [1:0] intrGen_auto_in_ar_bits_id; // @[SimMMIO.scala 21:27]
  wire [30:0] intrGen_auto_in_ar_bits_addr; // @[SimMMIO.scala 21:27]
  wire [7:0] intrGen_auto_in_ar_bits_len; // @[SimMMIO.scala 21:27]
  wire [2:0] intrGen_auto_in_ar_bits_size; // @[SimMMIO.scala 21:27]
  wire [1:0] intrGen_auto_in_ar_bits_burst; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_ar_bits_lock; // @[SimMMIO.scala 21:27]
  wire [3:0] intrGen_auto_in_ar_bits_cache; // @[SimMMIO.scala 21:27]
  wire [2:0] intrGen_auto_in_ar_bits_prot; // @[SimMMIO.scala 21:27]
  wire [3:0] intrGen_auto_in_ar_bits_qos; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_r_ready; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_r_valid; // @[SimMMIO.scala 21:27]
  wire [1:0] intrGen_auto_in_r_bits_id; // @[SimMMIO.scala 21:27]
  wire [63:0] intrGen_auto_in_r_bits_data; // @[SimMMIO.scala 21:27]
  wire [1:0] intrGen_auto_in_r_bits_resp; // @[SimMMIO.scala 21:27]
  wire  intrGen_auto_in_r_bits_last; // @[SimMMIO.scala 21:27]
  wire [255:0] intrGen_io_extra_intrVec; // @[SimMMIO.scala 21:27]
  wire  axi4xbar_clock; // @[Xbar.scala 218:30]
  wire  axi4xbar_reset; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_aw_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_aw_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_aw_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_in_aw_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_in_aw_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_in_aw_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_aw_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_aw_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_in_aw_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_in_aw_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_in_aw_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_w_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_w_valid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_in_w_bits_data; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_in_w_bits_strb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_w_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_b_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_b_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_b_bits_id; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_b_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_ar_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_ar_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_ar_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_in_ar_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_in_ar_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_in_ar_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_ar_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_ar_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_in_ar_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_in_ar_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_in_ar_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_r_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_r_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_r_bits_id; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_in_r_bits_data; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_r_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_r_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_aw_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_aw_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_aw_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_5_aw_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_5_aw_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_5_aw_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_aw_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_aw_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_5_aw_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_5_aw_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_5_aw_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_w_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_w_valid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_5_w_bits_data; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_5_w_bits_strb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_w_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_b_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_b_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_b_bits_id; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_b_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_ar_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_ar_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_ar_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_5_ar_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_5_ar_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_5_ar_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_ar_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_ar_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_5_ar_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_5_ar_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_5_ar_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_r_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_r_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_r_bits_id; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_5_r_bits_data; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_r_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_r_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_aw_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_aw_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_aw_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_4_aw_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_4_aw_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_4_aw_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_aw_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_aw_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_4_aw_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_4_aw_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_4_aw_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_w_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_w_valid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_4_w_bits_data; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_4_w_bits_strb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_w_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_b_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_b_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_b_bits_id; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_b_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_ar_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_ar_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_ar_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_4_ar_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_4_ar_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_4_ar_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_ar_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_ar_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_4_ar_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_4_ar_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_4_ar_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_r_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_r_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_r_bits_id; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_4_r_bits_data; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_r_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_r_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_aw_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_aw_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_aw_bits_id; // @[Xbar.scala 218:30]
  wire [28:0] axi4xbar_auto_out_3_aw_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_3_aw_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_3_aw_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_aw_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_aw_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_3_aw_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_3_aw_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_3_aw_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_w_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_w_valid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_3_w_bits_data; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_3_w_bits_strb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_w_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_b_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_b_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_b_bits_id; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_b_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_ar_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_ar_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_ar_bits_id; // @[Xbar.scala 218:30]
  wire [28:0] axi4xbar_auto_out_3_ar_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_3_ar_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_3_ar_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_ar_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_ar_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_3_ar_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_3_ar_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_3_ar_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_r_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_r_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_r_bits_id; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_3_r_bits_data; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_r_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_r_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_aw_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_aw_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_aw_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_2_aw_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_2_aw_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_2_aw_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_aw_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_aw_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_2_aw_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_2_aw_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_2_aw_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_w_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_w_valid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_2_w_bits_data; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_2_w_bits_strb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_w_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_b_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_b_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_b_bits_id; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_b_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_ar_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_ar_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_ar_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_2_ar_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_2_ar_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_2_ar_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_ar_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_ar_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_2_ar_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_2_ar_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_2_ar_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_r_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_r_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_r_bits_id; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_2_r_bits_data; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_r_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_r_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_aw_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_aw_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_aw_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_1_aw_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_1_aw_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_1_aw_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_aw_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_aw_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_1_aw_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_1_aw_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_1_aw_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_w_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_w_valid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_1_w_bits_data; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_1_w_bits_strb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_w_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_b_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_b_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_b_bits_id; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_b_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_ar_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_ar_bits_id; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_1_ar_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_1_ar_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_ar_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_ar_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_1_ar_bits_cache; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_1_ar_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_r_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_r_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_r_bits_id; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_r_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_aw_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_aw_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_aw_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_0_aw_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_0_aw_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_0_aw_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_aw_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_aw_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_0_aw_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_0_aw_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_0_aw_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_w_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_w_valid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_0_w_bits_data; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_0_w_bits_strb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_w_bits_last; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_b_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_b_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_b_bits_id; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_b_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_ar_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_ar_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_ar_bits_id; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_0_ar_bits_addr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_0_ar_bits_len; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_0_ar_bits_size; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_ar_bits_burst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_ar_bits_lock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_0_ar_bits_cache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_0_ar_bits_prot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_0_ar_bits_qos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_r_ready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_r_valid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_r_bits_id; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_0_r_bits_data; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_r_bits_resp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_r_bits_last; // @[Xbar.scala 218:30]
  AXI4Flash flash ( // @[SimMMIO.scala 13:25]
    .clock(flash_clock),
    .reset(flash_reset),
    .auto_in_aw_ready(flash_auto_in_aw_ready),
    .auto_in_aw_valid(flash_auto_in_aw_valid),
    .auto_in_aw_bits_id(flash_auto_in_aw_bits_id),
    .auto_in_aw_bits_addr(flash_auto_in_aw_bits_addr),
    .auto_in_aw_bits_len(flash_auto_in_aw_bits_len),
    .auto_in_aw_bits_size(flash_auto_in_aw_bits_size),
    .auto_in_aw_bits_burst(flash_auto_in_aw_bits_burst),
    .auto_in_aw_bits_lock(flash_auto_in_aw_bits_lock),
    .auto_in_aw_bits_cache(flash_auto_in_aw_bits_cache),
    .auto_in_aw_bits_prot(flash_auto_in_aw_bits_prot),
    .auto_in_aw_bits_qos(flash_auto_in_aw_bits_qos),
    .auto_in_w_ready(flash_auto_in_w_ready),
    .auto_in_w_valid(flash_auto_in_w_valid),
    .auto_in_w_bits_data(flash_auto_in_w_bits_data),
    .auto_in_w_bits_strb(flash_auto_in_w_bits_strb),
    .auto_in_w_bits_last(flash_auto_in_w_bits_last),
    .auto_in_b_ready(flash_auto_in_b_ready),
    .auto_in_b_valid(flash_auto_in_b_valid),
    .auto_in_b_bits_id(flash_auto_in_b_bits_id),
    .auto_in_b_bits_resp(flash_auto_in_b_bits_resp),
    .auto_in_ar_ready(flash_auto_in_ar_ready),
    .auto_in_ar_valid(flash_auto_in_ar_valid),
    .auto_in_ar_bits_id(flash_auto_in_ar_bits_id),
    .auto_in_ar_bits_addr(flash_auto_in_ar_bits_addr),
    .auto_in_ar_bits_len(flash_auto_in_ar_bits_len),
    .auto_in_ar_bits_size(flash_auto_in_ar_bits_size),
    .auto_in_ar_bits_burst(flash_auto_in_ar_bits_burst),
    .auto_in_ar_bits_lock(flash_auto_in_ar_bits_lock),
    .auto_in_ar_bits_cache(flash_auto_in_ar_bits_cache),
    .auto_in_ar_bits_prot(flash_auto_in_ar_bits_prot),
    .auto_in_ar_bits_qos(flash_auto_in_ar_bits_qos),
    .auto_in_r_ready(flash_auto_in_r_ready),
    .auto_in_r_valid(flash_auto_in_r_valid),
    .auto_in_r_bits_id(flash_auto_in_r_bits_id),
    .auto_in_r_bits_data(flash_auto_in_r_bits_data),
    .auto_in_r_bits_resp(flash_auto_in_r_bits_resp),
    .auto_in_r_bits_last(flash_auto_in_r_bits_last)
  );
  AXI4UART uart ( // @[SimMMIO.scala 14:24]
    .clock(uart_clock),
    .reset(uart_reset),
    .auto_in_aw_ready(uart_auto_in_aw_ready),
    .auto_in_aw_valid(uart_auto_in_aw_valid),
    .auto_in_aw_bits_id(uart_auto_in_aw_bits_id),
    .auto_in_aw_bits_addr(uart_auto_in_aw_bits_addr),
    .auto_in_aw_bits_len(uart_auto_in_aw_bits_len),
    .auto_in_aw_bits_size(uart_auto_in_aw_bits_size),
    .auto_in_aw_bits_burst(uart_auto_in_aw_bits_burst),
    .auto_in_aw_bits_lock(uart_auto_in_aw_bits_lock),
    .auto_in_aw_bits_cache(uart_auto_in_aw_bits_cache),
    .auto_in_aw_bits_prot(uart_auto_in_aw_bits_prot),
    .auto_in_aw_bits_qos(uart_auto_in_aw_bits_qos),
    .auto_in_w_ready(uart_auto_in_w_ready),
    .auto_in_w_valid(uart_auto_in_w_valid),
    .auto_in_w_bits_data(uart_auto_in_w_bits_data),
    .auto_in_w_bits_strb(uart_auto_in_w_bits_strb),
    .auto_in_w_bits_last(uart_auto_in_w_bits_last),
    .auto_in_b_ready(uart_auto_in_b_ready),
    .auto_in_b_valid(uart_auto_in_b_valid),
    .auto_in_b_bits_id(uart_auto_in_b_bits_id),
    .auto_in_b_bits_resp(uart_auto_in_b_bits_resp),
    .auto_in_ar_ready(uart_auto_in_ar_ready),
    .auto_in_ar_valid(uart_auto_in_ar_valid),
    .auto_in_ar_bits_id(uart_auto_in_ar_bits_id),
    .auto_in_ar_bits_addr(uart_auto_in_ar_bits_addr),
    .auto_in_ar_bits_len(uart_auto_in_ar_bits_len),
    .auto_in_ar_bits_size(uart_auto_in_ar_bits_size),
    .auto_in_ar_bits_burst(uart_auto_in_ar_bits_burst),
    .auto_in_ar_bits_lock(uart_auto_in_ar_bits_lock),
    .auto_in_ar_bits_cache(uart_auto_in_ar_bits_cache),
    .auto_in_ar_bits_prot(uart_auto_in_ar_bits_prot),
    .auto_in_ar_bits_qos(uart_auto_in_ar_bits_qos),
    .auto_in_r_ready(uart_auto_in_r_ready),
    .auto_in_r_valid(uart_auto_in_r_valid),
    .auto_in_r_bits_id(uart_auto_in_r_bits_id),
    .auto_in_r_bits_data(uart_auto_in_r_bits_data),
    .auto_in_r_bits_resp(uart_auto_in_r_bits_resp),
    .auto_in_r_bits_last(uart_auto_in_r_bits_last),
    .io_extra_out_valid(uart_io_extra_out_valid),
    .io_extra_out_ch(uart_io_extra_out_ch),
    .io_extra_in_valid(uart_io_extra_in_valid),
    .io_extra_in_ch(uart_io_extra_in_ch)
  );
  AXI4VGA vga ( // @[SimMMIO.scala 15:23]
    .clock(vga_clock),
    .reset(vga_reset),
    .auto_in_1_aw_ready(vga_auto_in_1_aw_ready),
    .auto_in_1_aw_valid(vga_auto_in_1_aw_valid),
    .auto_in_1_aw_bits_id(vga_auto_in_1_aw_bits_id),
    .auto_in_1_aw_bits_addr(vga_auto_in_1_aw_bits_addr),
    .auto_in_1_aw_bits_len(vga_auto_in_1_aw_bits_len),
    .auto_in_1_aw_bits_size(vga_auto_in_1_aw_bits_size),
    .auto_in_1_aw_bits_burst(vga_auto_in_1_aw_bits_burst),
    .auto_in_1_aw_bits_lock(vga_auto_in_1_aw_bits_lock),
    .auto_in_1_aw_bits_cache(vga_auto_in_1_aw_bits_cache),
    .auto_in_1_aw_bits_prot(vga_auto_in_1_aw_bits_prot),
    .auto_in_1_aw_bits_qos(vga_auto_in_1_aw_bits_qos),
    .auto_in_1_w_ready(vga_auto_in_1_w_ready),
    .auto_in_1_w_valid(vga_auto_in_1_w_valid),
    .auto_in_1_w_bits_data(vga_auto_in_1_w_bits_data),
    .auto_in_1_w_bits_strb(vga_auto_in_1_w_bits_strb),
    .auto_in_1_w_bits_last(vga_auto_in_1_w_bits_last),
    .auto_in_1_b_ready(vga_auto_in_1_b_ready),
    .auto_in_1_b_valid(vga_auto_in_1_b_valid),
    .auto_in_1_b_bits_id(vga_auto_in_1_b_bits_id),
    .auto_in_1_b_bits_resp(vga_auto_in_1_b_bits_resp),
    .auto_in_1_ar_ready(vga_auto_in_1_ar_ready),
    .auto_in_1_ar_valid(vga_auto_in_1_ar_valid),
    .auto_in_1_ar_bits_id(vga_auto_in_1_ar_bits_id),
    .auto_in_1_ar_bits_addr(vga_auto_in_1_ar_bits_addr),
    .auto_in_1_ar_bits_len(vga_auto_in_1_ar_bits_len),
    .auto_in_1_ar_bits_size(vga_auto_in_1_ar_bits_size),
    .auto_in_1_ar_bits_burst(vga_auto_in_1_ar_bits_burst),
    .auto_in_1_ar_bits_lock(vga_auto_in_1_ar_bits_lock),
    .auto_in_1_ar_bits_cache(vga_auto_in_1_ar_bits_cache),
    .auto_in_1_ar_bits_prot(vga_auto_in_1_ar_bits_prot),
    .auto_in_1_ar_bits_qos(vga_auto_in_1_ar_bits_qos),
    .auto_in_1_r_ready(vga_auto_in_1_r_ready),
    .auto_in_1_r_valid(vga_auto_in_1_r_valid),
    .auto_in_1_r_bits_id(vga_auto_in_1_r_bits_id),
    .auto_in_1_r_bits_data(vga_auto_in_1_r_bits_data),
    .auto_in_1_r_bits_resp(vga_auto_in_1_r_bits_resp),
    .auto_in_1_r_bits_last(vga_auto_in_1_r_bits_last),
    .auto_in_0_aw_ready(vga_auto_in_0_aw_ready),
    .auto_in_0_aw_valid(vga_auto_in_0_aw_valid),
    .auto_in_0_aw_bits_id(vga_auto_in_0_aw_bits_id),
    .auto_in_0_aw_bits_addr(vga_auto_in_0_aw_bits_addr),
    .auto_in_0_aw_bits_len(vga_auto_in_0_aw_bits_len),
    .auto_in_0_aw_bits_size(vga_auto_in_0_aw_bits_size),
    .auto_in_0_aw_bits_burst(vga_auto_in_0_aw_bits_burst),
    .auto_in_0_aw_bits_lock(vga_auto_in_0_aw_bits_lock),
    .auto_in_0_aw_bits_cache(vga_auto_in_0_aw_bits_cache),
    .auto_in_0_aw_bits_prot(vga_auto_in_0_aw_bits_prot),
    .auto_in_0_aw_bits_qos(vga_auto_in_0_aw_bits_qos),
    .auto_in_0_w_ready(vga_auto_in_0_w_ready),
    .auto_in_0_w_valid(vga_auto_in_0_w_valid),
    .auto_in_0_w_bits_data(vga_auto_in_0_w_bits_data),
    .auto_in_0_w_bits_strb(vga_auto_in_0_w_bits_strb),
    .auto_in_0_w_bits_last(vga_auto_in_0_w_bits_last),
    .auto_in_0_b_ready(vga_auto_in_0_b_ready),
    .auto_in_0_b_valid(vga_auto_in_0_b_valid),
    .auto_in_0_b_bits_id(vga_auto_in_0_b_bits_id),
    .auto_in_0_b_bits_resp(vga_auto_in_0_b_bits_resp),
    .auto_in_0_ar_valid(vga_auto_in_0_ar_valid),
    .auto_in_0_ar_bits_id(vga_auto_in_0_ar_bits_id),
    .auto_in_0_ar_bits_len(vga_auto_in_0_ar_bits_len),
    .auto_in_0_ar_bits_size(vga_auto_in_0_ar_bits_size),
    .auto_in_0_ar_bits_burst(vga_auto_in_0_ar_bits_burst),
    .auto_in_0_ar_bits_lock(vga_auto_in_0_ar_bits_lock),
    .auto_in_0_ar_bits_cache(vga_auto_in_0_ar_bits_cache),
    .auto_in_0_ar_bits_qos(vga_auto_in_0_ar_bits_qos),
    .auto_in_0_r_ready(vga_auto_in_0_r_ready),
    .auto_in_0_r_valid(vga_auto_in_0_r_valid),
    .auto_in_0_r_bits_id(vga_auto_in_0_r_bits_id),
    .auto_in_0_r_bits_last(vga_auto_in_0_r_bits_last)
  );
  AXI4DummySD sd ( // @[SimMMIO.scala 20:22]
    .clock(sd_clock),
    .reset(sd_reset),
    .auto_in_aw_ready(sd_auto_in_aw_ready),
    .auto_in_aw_valid(sd_auto_in_aw_valid),
    .auto_in_aw_bits_id(sd_auto_in_aw_bits_id),
    .auto_in_aw_bits_addr(sd_auto_in_aw_bits_addr),
    .auto_in_aw_bits_len(sd_auto_in_aw_bits_len),
    .auto_in_aw_bits_size(sd_auto_in_aw_bits_size),
    .auto_in_aw_bits_burst(sd_auto_in_aw_bits_burst),
    .auto_in_aw_bits_lock(sd_auto_in_aw_bits_lock),
    .auto_in_aw_bits_cache(sd_auto_in_aw_bits_cache),
    .auto_in_aw_bits_prot(sd_auto_in_aw_bits_prot),
    .auto_in_aw_bits_qos(sd_auto_in_aw_bits_qos),
    .auto_in_w_ready(sd_auto_in_w_ready),
    .auto_in_w_valid(sd_auto_in_w_valid),
    .auto_in_w_bits_data(sd_auto_in_w_bits_data),
    .auto_in_w_bits_strb(sd_auto_in_w_bits_strb),
    .auto_in_w_bits_last(sd_auto_in_w_bits_last),
    .auto_in_b_ready(sd_auto_in_b_ready),
    .auto_in_b_valid(sd_auto_in_b_valid),
    .auto_in_b_bits_id(sd_auto_in_b_bits_id),
    .auto_in_b_bits_resp(sd_auto_in_b_bits_resp),
    .auto_in_ar_ready(sd_auto_in_ar_ready),
    .auto_in_ar_valid(sd_auto_in_ar_valid),
    .auto_in_ar_bits_id(sd_auto_in_ar_bits_id),
    .auto_in_ar_bits_addr(sd_auto_in_ar_bits_addr),
    .auto_in_ar_bits_len(sd_auto_in_ar_bits_len),
    .auto_in_ar_bits_size(sd_auto_in_ar_bits_size),
    .auto_in_ar_bits_burst(sd_auto_in_ar_bits_burst),
    .auto_in_ar_bits_lock(sd_auto_in_ar_bits_lock),
    .auto_in_ar_bits_cache(sd_auto_in_ar_bits_cache),
    .auto_in_ar_bits_prot(sd_auto_in_ar_bits_prot),
    .auto_in_ar_bits_qos(sd_auto_in_ar_bits_qos),
    .auto_in_r_ready(sd_auto_in_r_ready),
    .auto_in_r_valid(sd_auto_in_r_valid),
    .auto_in_r_bits_id(sd_auto_in_r_bits_id),
    .auto_in_r_bits_data(sd_auto_in_r_bits_data),
    .auto_in_r_bits_resp(sd_auto_in_r_bits_resp),
    .auto_in_r_bits_last(sd_auto_in_r_bits_last)
  );
  AXI4IntrGenerator intrGen ( // @[SimMMIO.scala 21:27]
    .clock(intrGen_clock),
    .reset(intrGen_reset),
    .auto_in_aw_ready(intrGen_auto_in_aw_ready),
    .auto_in_aw_valid(intrGen_auto_in_aw_valid),
    .auto_in_aw_bits_id(intrGen_auto_in_aw_bits_id),
    .auto_in_aw_bits_addr(intrGen_auto_in_aw_bits_addr),
    .auto_in_aw_bits_len(intrGen_auto_in_aw_bits_len),
    .auto_in_aw_bits_size(intrGen_auto_in_aw_bits_size),
    .auto_in_aw_bits_burst(intrGen_auto_in_aw_bits_burst),
    .auto_in_aw_bits_lock(intrGen_auto_in_aw_bits_lock),
    .auto_in_aw_bits_cache(intrGen_auto_in_aw_bits_cache),
    .auto_in_aw_bits_prot(intrGen_auto_in_aw_bits_prot),
    .auto_in_aw_bits_qos(intrGen_auto_in_aw_bits_qos),
    .auto_in_w_ready(intrGen_auto_in_w_ready),
    .auto_in_w_valid(intrGen_auto_in_w_valid),
    .auto_in_w_bits_data(intrGen_auto_in_w_bits_data),
    .auto_in_w_bits_strb(intrGen_auto_in_w_bits_strb),
    .auto_in_w_bits_last(intrGen_auto_in_w_bits_last),
    .auto_in_b_ready(intrGen_auto_in_b_ready),
    .auto_in_b_valid(intrGen_auto_in_b_valid),
    .auto_in_b_bits_id(intrGen_auto_in_b_bits_id),
    .auto_in_b_bits_resp(intrGen_auto_in_b_bits_resp),
    .auto_in_ar_ready(intrGen_auto_in_ar_ready),
    .auto_in_ar_valid(intrGen_auto_in_ar_valid),
    .auto_in_ar_bits_id(intrGen_auto_in_ar_bits_id),
    .auto_in_ar_bits_addr(intrGen_auto_in_ar_bits_addr),
    .auto_in_ar_bits_len(intrGen_auto_in_ar_bits_len),
    .auto_in_ar_bits_size(intrGen_auto_in_ar_bits_size),
    .auto_in_ar_bits_burst(intrGen_auto_in_ar_bits_burst),
    .auto_in_ar_bits_lock(intrGen_auto_in_ar_bits_lock),
    .auto_in_ar_bits_cache(intrGen_auto_in_ar_bits_cache),
    .auto_in_ar_bits_prot(intrGen_auto_in_ar_bits_prot),
    .auto_in_ar_bits_qos(intrGen_auto_in_ar_bits_qos),
    .auto_in_r_ready(intrGen_auto_in_r_ready),
    .auto_in_r_valid(intrGen_auto_in_r_valid),
    .auto_in_r_bits_id(intrGen_auto_in_r_bits_id),
    .auto_in_r_bits_data(intrGen_auto_in_r_bits_data),
    .auto_in_r_bits_resp(intrGen_auto_in_r_bits_resp),
    .auto_in_r_bits_last(intrGen_auto_in_r_bits_last),
    .io_extra_intrVec(intrGen_io_extra_intrVec)
  );
  AXI4Xbar axi4xbar ( // @[Xbar.scala 218:30]
    .clock(axi4xbar_clock),
    .reset(axi4xbar_reset),
    .auto_in_aw_ready(axi4xbar_auto_in_aw_ready),
    .auto_in_aw_valid(axi4xbar_auto_in_aw_valid),
    .auto_in_aw_bits_id(axi4xbar_auto_in_aw_bits_id),
    .auto_in_aw_bits_addr(axi4xbar_auto_in_aw_bits_addr),
    .auto_in_aw_bits_len(axi4xbar_auto_in_aw_bits_len),
    .auto_in_aw_bits_size(axi4xbar_auto_in_aw_bits_size),
    .auto_in_aw_bits_burst(axi4xbar_auto_in_aw_bits_burst),
    .auto_in_aw_bits_lock(axi4xbar_auto_in_aw_bits_lock),
    .auto_in_aw_bits_cache(axi4xbar_auto_in_aw_bits_cache),
    .auto_in_aw_bits_prot(axi4xbar_auto_in_aw_bits_prot),
    .auto_in_aw_bits_qos(axi4xbar_auto_in_aw_bits_qos),
    .auto_in_w_ready(axi4xbar_auto_in_w_ready),
    .auto_in_w_valid(axi4xbar_auto_in_w_valid),
    .auto_in_w_bits_data(axi4xbar_auto_in_w_bits_data),
    .auto_in_w_bits_strb(axi4xbar_auto_in_w_bits_strb),
    .auto_in_w_bits_last(axi4xbar_auto_in_w_bits_last),
    .auto_in_b_ready(axi4xbar_auto_in_b_ready),
    .auto_in_b_valid(axi4xbar_auto_in_b_valid),
    .auto_in_b_bits_id(axi4xbar_auto_in_b_bits_id),
    .auto_in_b_bits_resp(axi4xbar_auto_in_b_bits_resp),
    .auto_in_ar_ready(axi4xbar_auto_in_ar_ready),
    .auto_in_ar_valid(axi4xbar_auto_in_ar_valid),
    .auto_in_ar_bits_id(axi4xbar_auto_in_ar_bits_id),
    .auto_in_ar_bits_addr(axi4xbar_auto_in_ar_bits_addr),
    .auto_in_ar_bits_len(axi4xbar_auto_in_ar_bits_len),
    .auto_in_ar_bits_size(axi4xbar_auto_in_ar_bits_size),
    .auto_in_ar_bits_burst(axi4xbar_auto_in_ar_bits_burst),
    .auto_in_ar_bits_lock(axi4xbar_auto_in_ar_bits_lock),
    .auto_in_ar_bits_cache(axi4xbar_auto_in_ar_bits_cache),
    .auto_in_ar_bits_prot(axi4xbar_auto_in_ar_bits_prot),
    .auto_in_ar_bits_qos(axi4xbar_auto_in_ar_bits_qos),
    .auto_in_r_ready(axi4xbar_auto_in_r_ready),
    .auto_in_r_valid(axi4xbar_auto_in_r_valid),
    .auto_in_r_bits_id(axi4xbar_auto_in_r_bits_id),
    .auto_in_r_bits_data(axi4xbar_auto_in_r_bits_data),
    .auto_in_r_bits_resp(axi4xbar_auto_in_r_bits_resp),
    .auto_in_r_bits_last(axi4xbar_auto_in_r_bits_last),
    .auto_out_5_aw_ready(axi4xbar_auto_out_5_aw_ready),
    .auto_out_5_aw_valid(axi4xbar_auto_out_5_aw_valid),
    .auto_out_5_aw_bits_id(axi4xbar_auto_out_5_aw_bits_id),
    .auto_out_5_aw_bits_addr(axi4xbar_auto_out_5_aw_bits_addr),
    .auto_out_5_aw_bits_len(axi4xbar_auto_out_5_aw_bits_len),
    .auto_out_5_aw_bits_size(axi4xbar_auto_out_5_aw_bits_size),
    .auto_out_5_aw_bits_burst(axi4xbar_auto_out_5_aw_bits_burst),
    .auto_out_5_aw_bits_lock(axi4xbar_auto_out_5_aw_bits_lock),
    .auto_out_5_aw_bits_cache(axi4xbar_auto_out_5_aw_bits_cache),
    .auto_out_5_aw_bits_prot(axi4xbar_auto_out_5_aw_bits_prot),
    .auto_out_5_aw_bits_qos(axi4xbar_auto_out_5_aw_bits_qos),
    .auto_out_5_w_ready(axi4xbar_auto_out_5_w_ready),
    .auto_out_5_w_valid(axi4xbar_auto_out_5_w_valid),
    .auto_out_5_w_bits_data(axi4xbar_auto_out_5_w_bits_data),
    .auto_out_5_w_bits_strb(axi4xbar_auto_out_5_w_bits_strb),
    .auto_out_5_w_bits_last(axi4xbar_auto_out_5_w_bits_last),
    .auto_out_5_b_ready(axi4xbar_auto_out_5_b_ready),
    .auto_out_5_b_valid(axi4xbar_auto_out_5_b_valid),
    .auto_out_5_b_bits_id(axi4xbar_auto_out_5_b_bits_id),
    .auto_out_5_b_bits_resp(axi4xbar_auto_out_5_b_bits_resp),
    .auto_out_5_ar_ready(axi4xbar_auto_out_5_ar_ready),
    .auto_out_5_ar_valid(axi4xbar_auto_out_5_ar_valid),
    .auto_out_5_ar_bits_id(axi4xbar_auto_out_5_ar_bits_id),
    .auto_out_5_ar_bits_addr(axi4xbar_auto_out_5_ar_bits_addr),
    .auto_out_5_ar_bits_len(axi4xbar_auto_out_5_ar_bits_len),
    .auto_out_5_ar_bits_size(axi4xbar_auto_out_5_ar_bits_size),
    .auto_out_5_ar_bits_burst(axi4xbar_auto_out_5_ar_bits_burst),
    .auto_out_5_ar_bits_lock(axi4xbar_auto_out_5_ar_bits_lock),
    .auto_out_5_ar_bits_cache(axi4xbar_auto_out_5_ar_bits_cache),
    .auto_out_5_ar_bits_prot(axi4xbar_auto_out_5_ar_bits_prot),
    .auto_out_5_ar_bits_qos(axi4xbar_auto_out_5_ar_bits_qos),
    .auto_out_5_r_ready(axi4xbar_auto_out_5_r_ready),
    .auto_out_5_r_valid(axi4xbar_auto_out_5_r_valid),
    .auto_out_5_r_bits_id(axi4xbar_auto_out_5_r_bits_id),
    .auto_out_5_r_bits_data(axi4xbar_auto_out_5_r_bits_data),
    .auto_out_5_r_bits_resp(axi4xbar_auto_out_5_r_bits_resp),
    .auto_out_5_r_bits_last(axi4xbar_auto_out_5_r_bits_last),
    .auto_out_4_aw_ready(axi4xbar_auto_out_4_aw_ready),
    .auto_out_4_aw_valid(axi4xbar_auto_out_4_aw_valid),
    .auto_out_4_aw_bits_id(axi4xbar_auto_out_4_aw_bits_id),
    .auto_out_4_aw_bits_addr(axi4xbar_auto_out_4_aw_bits_addr),
    .auto_out_4_aw_bits_len(axi4xbar_auto_out_4_aw_bits_len),
    .auto_out_4_aw_bits_size(axi4xbar_auto_out_4_aw_bits_size),
    .auto_out_4_aw_bits_burst(axi4xbar_auto_out_4_aw_bits_burst),
    .auto_out_4_aw_bits_lock(axi4xbar_auto_out_4_aw_bits_lock),
    .auto_out_4_aw_bits_cache(axi4xbar_auto_out_4_aw_bits_cache),
    .auto_out_4_aw_bits_prot(axi4xbar_auto_out_4_aw_bits_prot),
    .auto_out_4_aw_bits_qos(axi4xbar_auto_out_4_aw_bits_qos),
    .auto_out_4_w_ready(axi4xbar_auto_out_4_w_ready),
    .auto_out_4_w_valid(axi4xbar_auto_out_4_w_valid),
    .auto_out_4_w_bits_data(axi4xbar_auto_out_4_w_bits_data),
    .auto_out_4_w_bits_strb(axi4xbar_auto_out_4_w_bits_strb),
    .auto_out_4_w_bits_last(axi4xbar_auto_out_4_w_bits_last),
    .auto_out_4_b_ready(axi4xbar_auto_out_4_b_ready),
    .auto_out_4_b_valid(axi4xbar_auto_out_4_b_valid),
    .auto_out_4_b_bits_id(axi4xbar_auto_out_4_b_bits_id),
    .auto_out_4_b_bits_resp(axi4xbar_auto_out_4_b_bits_resp),
    .auto_out_4_ar_ready(axi4xbar_auto_out_4_ar_ready),
    .auto_out_4_ar_valid(axi4xbar_auto_out_4_ar_valid),
    .auto_out_4_ar_bits_id(axi4xbar_auto_out_4_ar_bits_id),
    .auto_out_4_ar_bits_addr(axi4xbar_auto_out_4_ar_bits_addr),
    .auto_out_4_ar_bits_len(axi4xbar_auto_out_4_ar_bits_len),
    .auto_out_4_ar_bits_size(axi4xbar_auto_out_4_ar_bits_size),
    .auto_out_4_ar_bits_burst(axi4xbar_auto_out_4_ar_bits_burst),
    .auto_out_4_ar_bits_lock(axi4xbar_auto_out_4_ar_bits_lock),
    .auto_out_4_ar_bits_cache(axi4xbar_auto_out_4_ar_bits_cache),
    .auto_out_4_ar_bits_prot(axi4xbar_auto_out_4_ar_bits_prot),
    .auto_out_4_ar_bits_qos(axi4xbar_auto_out_4_ar_bits_qos),
    .auto_out_4_r_ready(axi4xbar_auto_out_4_r_ready),
    .auto_out_4_r_valid(axi4xbar_auto_out_4_r_valid),
    .auto_out_4_r_bits_id(axi4xbar_auto_out_4_r_bits_id),
    .auto_out_4_r_bits_data(axi4xbar_auto_out_4_r_bits_data),
    .auto_out_4_r_bits_resp(axi4xbar_auto_out_4_r_bits_resp),
    .auto_out_4_r_bits_last(axi4xbar_auto_out_4_r_bits_last),
    .auto_out_3_aw_ready(axi4xbar_auto_out_3_aw_ready),
    .auto_out_3_aw_valid(axi4xbar_auto_out_3_aw_valid),
    .auto_out_3_aw_bits_id(axi4xbar_auto_out_3_aw_bits_id),
    .auto_out_3_aw_bits_addr(axi4xbar_auto_out_3_aw_bits_addr),
    .auto_out_3_aw_bits_len(axi4xbar_auto_out_3_aw_bits_len),
    .auto_out_3_aw_bits_size(axi4xbar_auto_out_3_aw_bits_size),
    .auto_out_3_aw_bits_burst(axi4xbar_auto_out_3_aw_bits_burst),
    .auto_out_3_aw_bits_lock(axi4xbar_auto_out_3_aw_bits_lock),
    .auto_out_3_aw_bits_cache(axi4xbar_auto_out_3_aw_bits_cache),
    .auto_out_3_aw_bits_prot(axi4xbar_auto_out_3_aw_bits_prot),
    .auto_out_3_aw_bits_qos(axi4xbar_auto_out_3_aw_bits_qos),
    .auto_out_3_w_ready(axi4xbar_auto_out_3_w_ready),
    .auto_out_3_w_valid(axi4xbar_auto_out_3_w_valid),
    .auto_out_3_w_bits_data(axi4xbar_auto_out_3_w_bits_data),
    .auto_out_3_w_bits_strb(axi4xbar_auto_out_3_w_bits_strb),
    .auto_out_3_w_bits_last(axi4xbar_auto_out_3_w_bits_last),
    .auto_out_3_b_ready(axi4xbar_auto_out_3_b_ready),
    .auto_out_3_b_valid(axi4xbar_auto_out_3_b_valid),
    .auto_out_3_b_bits_id(axi4xbar_auto_out_3_b_bits_id),
    .auto_out_3_b_bits_resp(axi4xbar_auto_out_3_b_bits_resp),
    .auto_out_3_ar_ready(axi4xbar_auto_out_3_ar_ready),
    .auto_out_3_ar_valid(axi4xbar_auto_out_3_ar_valid),
    .auto_out_3_ar_bits_id(axi4xbar_auto_out_3_ar_bits_id),
    .auto_out_3_ar_bits_addr(axi4xbar_auto_out_3_ar_bits_addr),
    .auto_out_3_ar_bits_len(axi4xbar_auto_out_3_ar_bits_len),
    .auto_out_3_ar_bits_size(axi4xbar_auto_out_3_ar_bits_size),
    .auto_out_3_ar_bits_burst(axi4xbar_auto_out_3_ar_bits_burst),
    .auto_out_3_ar_bits_lock(axi4xbar_auto_out_3_ar_bits_lock),
    .auto_out_3_ar_bits_cache(axi4xbar_auto_out_3_ar_bits_cache),
    .auto_out_3_ar_bits_prot(axi4xbar_auto_out_3_ar_bits_prot),
    .auto_out_3_ar_bits_qos(axi4xbar_auto_out_3_ar_bits_qos),
    .auto_out_3_r_ready(axi4xbar_auto_out_3_r_ready),
    .auto_out_3_r_valid(axi4xbar_auto_out_3_r_valid),
    .auto_out_3_r_bits_id(axi4xbar_auto_out_3_r_bits_id),
    .auto_out_3_r_bits_data(axi4xbar_auto_out_3_r_bits_data),
    .auto_out_3_r_bits_resp(axi4xbar_auto_out_3_r_bits_resp),
    .auto_out_3_r_bits_last(axi4xbar_auto_out_3_r_bits_last),
    .auto_out_2_aw_ready(axi4xbar_auto_out_2_aw_ready),
    .auto_out_2_aw_valid(axi4xbar_auto_out_2_aw_valid),
    .auto_out_2_aw_bits_id(axi4xbar_auto_out_2_aw_bits_id),
    .auto_out_2_aw_bits_addr(axi4xbar_auto_out_2_aw_bits_addr),
    .auto_out_2_aw_bits_len(axi4xbar_auto_out_2_aw_bits_len),
    .auto_out_2_aw_bits_size(axi4xbar_auto_out_2_aw_bits_size),
    .auto_out_2_aw_bits_burst(axi4xbar_auto_out_2_aw_bits_burst),
    .auto_out_2_aw_bits_lock(axi4xbar_auto_out_2_aw_bits_lock),
    .auto_out_2_aw_bits_cache(axi4xbar_auto_out_2_aw_bits_cache),
    .auto_out_2_aw_bits_prot(axi4xbar_auto_out_2_aw_bits_prot),
    .auto_out_2_aw_bits_qos(axi4xbar_auto_out_2_aw_bits_qos),
    .auto_out_2_w_ready(axi4xbar_auto_out_2_w_ready),
    .auto_out_2_w_valid(axi4xbar_auto_out_2_w_valid),
    .auto_out_2_w_bits_data(axi4xbar_auto_out_2_w_bits_data),
    .auto_out_2_w_bits_strb(axi4xbar_auto_out_2_w_bits_strb),
    .auto_out_2_w_bits_last(axi4xbar_auto_out_2_w_bits_last),
    .auto_out_2_b_ready(axi4xbar_auto_out_2_b_ready),
    .auto_out_2_b_valid(axi4xbar_auto_out_2_b_valid),
    .auto_out_2_b_bits_id(axi4xbar_auto_out_2_b_bits_id),
    .auto_out_2_b_bits_resp(axi4xbar_auto_out_2_b_bits_resp),
    .auto_out_2_ar_ready(axi4xbar_auto_out_2_ar_ready),
    .auto_out_2_ar_valid(axi4xbar_auto_out_2_ar_valid),
    .auto_out_2_ar_bits_id(axi4xbar_auto_out_2_ar_bits_id),
    .auto_out_2_ar_bits_addr(axi4xbar_auto_out_2_ar_bits_addr),
    .auto_out_2_ar_bits_len(axi4xbar_auto_out_2_ar_bits_len),
    .auto_out_2_ar_bits_size(axi4xbar_auto_out_2_ar_bits_size),
    .auto_out_2_ar_bits_burst(axi4xbar_auto_out_2_ar_bits_burst),
    .auto_out_2_ar_bits_lock(axi4xbar_auto_out_2_ar_bits_lock),
    .auto_out_2_ar_bits_cache(axi4xbar_auto_out_2_ar_bits_cache),
    .auto_out_2_ar_bits_prot(axi4xbar_auto_out_2_ar_bits_prot),
    .auto_out_2_ar_bits_qos(axi4xbar_auto_out_2_ar_bits_qos),
    .auto_out_2_r_ready(axi4xbar_auto_out_2_r_ready),
    .auto_out_2_r_valid(axi4xbar_auto_out_2_r_valid),
    .auto_out_2_r_bits_id(axi4xbar_auto_out_2_r_bits_id),
    .auto_out_2_r_bits_data(axi4xbar_auto_out_2_r_bits_data),
    .auto_out_2_r_bits_resp(axi4xbar_auto_out_2_r_bits_resp),
    .auto_out_2_r_bits_last(axi4xbar_auto_out_2_r_bits_last),
    .auto_out_1_aw_ready(axi4xbar_auto_out_1_aw_ready),
    .auto_out_1_aw_valid(axi4xbar_auto_out_1_aw_valid),
    .auto_out_1_aw_bits_id(axi4xbar_auto_out_1_aw_bits_id),
    .auto_out_1_aw_bits_addr(axi4xbar_auto_out_1_aw_bits_addr),
    .auto_out_1_aw_bits_len(axi4xbar_auto_out_1_aw_bits_len),
    .auto_out_1_aw_bits_size(axi4xbar_auto_out_1_aw_bits_size),
    .auto_out_1_aw_bits_burst(axi4xbar_auto_out_1_aw_bits_burst),
    .auto_out_1_aw_bits_lock(axi4xbar_auto_out_1_aw_bits_lock),
    .auto_out_1_aw_bits_cache(axi4xbar_auto_out_1_aw_bits_cache),
    .auto_out_1_aw_bits_prot(axi4xbar_auto_out_1_aw_bits_prot),
    .auto_out_1_aw_bits_qos(axi4xbar_auto_out_1_aw_bits_qos),
    .auto_out_1_w_ready(axi4xbar_auto_out_1_w_ready),
    .auto_out_1_w_valid(axi4xbar_auto_out_1_w_valid),
    .auto_out_1_w_bits_data(axi4xbar_auto_out_1_w_bits_data),
    .auto_out_1_w_bits_strb(axi4xbar_auto_out_1_w_bits_strb),
    .auto_out_1_w_bits_last(axi4xbar_auto_out_1_w_bits_last),
    .auto_out_1_b_ready(axi4xbar_auto_out_1_b_ready),
    .auto_out_1_b_valid(axi4xbar_auto_out_1_b_valid),
    .auto_out_1_b_bits_id(axi4xbar_auto_out_1_b_bits_id),
    .auto_out_1_b_bits_resp(axi4xbar_auto_out_1_b_bits_resp),
    .auto_out_1_ar_valid(axi4xbar_auto_out_1_ar_valid),
    .auto_out_1_ar_bits_id(axi4xbar_auto_out_1_ar_bits_id),
    .auto_out_1_ar_bits_len(axi4xbar_auto_out_1_ar_bits_len),
    .auto_out_1_ar_bits_size(axi4xbar_auto_out_1_ar_bits_size),
    .auto_out_1_ar_bits_burst(axi4xbar_auto_out_1_ar_bits_burst),
    .auto_out_1_ar_bits_lock(axi4xbar_auto_out_1_ar_bits_lock),
    .auto_out_1_ar_bits_cache(axi4xbar_auto_out_1_ar_bits_cache),
    .auto_out_1_ar_bits_qos(axi4xbar_auto_out_1_ar_bits_qos),
    .auto_out_1_r_ready(axi4xbar_auto_out_1_r_ready),
    .auto_out_1_r_valid(axi4xbar_auto_out_1_r_valid),
    .auto_out_1_r_bits_id(axi4xbar_auto_out_1_r_bits_id),
    .auto_out_1_r_bits_last(axi4xbar_auto_out_1_r_bits_last),
    .auto_out_0_aw_ready(axi4xbar_auto_out_0_aw_ready),
    .auto_out_0_aw_valid(axi4xbar_auto_out_0_aw_valid),
    .auto_out_0_aw_bits_id(axi4xbar_auto_out_0_aw_bits_id),
    .auto_out_0_aw_bits_addr(axi4xbar_auto_out_0_aw_bits_addr),
    .auto_out_0_aw_bits_len(axi4xbar_auto_out_0_aw_bits_len),
    .auto_out_0_aw_bits_size(axi4xbar_auto_out_0_aw_bits_size),
    .auto_out_0_aw_bits_burst(axi4xbar_auto_out_0_aw_bits_burst),
    .auto_out_0_aw_bits_lock(axi4xbar_auto_out_0_aw_bits_lock),
    .auto_out_0_aw_bits_cache(axi4xbar_auto_out_0_aw_bits_cache),
    .auto_out_0_aw_bits_prot(axi4xbar_auto_out_0_aw_bits_prot),
    .auto_out_0_aw_bits_qos(axi4xbar_auto_out_0_aw_bits_qos),
    .auto_out_0_w_ready(axi4xbar_auto_out_0_w_ready),
    .auto_out_0_w_valid(axi4xbar_auto_out_0_w_valid),
    .auto_out_0_w_bits_data(axi4xbar_auto_out_0_w_bits_data),
    .auto_out_0_w_bits_strb(axi4xbar_auto_out_0_w_bits_strb),
    .auto_out_0_w_bits_last(axi4xbar_auto_out_0_w_bits_last),
    .auto_out_0_b_ready(axi4xbar_auto_out_0_b_ready),
    .auto_out_0_b_valid(axi4xbar_auto_out_0_b_valid),
    .auto_out_0_b_bits_id(axi4xbar_auto_out_0_b_bits_id),
    .auto_out_0_b_bits_resp(axi4xbar_auto_out_0_b_bits_resp),
    .auto_out_0_ar_ready(axi4xbar_auto_out_0_ar_ready),
    .auto_out_0_ar_valid(axi4xbar_auto_out_0_ar_valid),
    .auto_out_0_ar_bits_id(axi4xbar_auto_out_0_ar_bits_id),
    .auto_out_0_ar_bits_addr(axi4xbar_auto_out_0_ar_bits_addr),
    .auto_out_0_ar_bits_len(axi4xbar_auto_out_0_ar_bits_len),
    .auto_out_0_ar_bits_size(axi4xbar_auto_out_0_ar_bits_size),
    .auto_out_0_ar_bits_burst(axi4xbar_auto_out_0_ar_bits_burst),
    .auto_out_0_ar_bits_lock(axi4xbar_auto_out_0_ar_bits_lock),
    .auto_out_0_ar_bits_cache(axi4xbar_auto_out_0_ar_bits_cache),
    .auto_out_0_ar_bits_prot(axi4xbar_auto_out_0_ar_bits_prot),
    .auto_out_0_ar_bits_qos(axi4xbar_auto_out_0_ar_bits_qos),
    .auto_out_0_r_ready(axi4xbar_auto_out_0_r_ready),
    .auto_out_0_r_valid(axi4xbar_auto_out_0_r_valid),
    .auto_out_0_r_bits_id(axi4xbar_auto_out_0_r_bits_id),
    .auto_out_0_r_bits_data(axi4xbar_auto_out_0_r_bits_data),
    .auto_out_0_r_bits_resp(axi4xbar_auto_out_0_r_bits_resp),
    .auto_out_0_r_bits_last(axi4xbar_auto_out_0_r_bits_last)
  );
  assign io_axi4_0_aw_ready = axi4xbar_auto_in_aw_ready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_w_ready = axi4xbar_auto_in_w_ready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_b_valid = axi4xbar_auto_in_b_valid; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_b_bits_id = axi4xbar_auto_in_b_bits_id; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_b_bits_resp = axi4xbar_auto_in_b_bits_resp; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_ar_ready = axi4xbar_auto_in_ar_ready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_r_valid = axi4xbar_auto_in_r_valid; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_r_bits_id = axi4xbar_auto_in_r_bits_id; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_r_bits_data = axi4xbar_auto_in_r_bits_data; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_r_bits_resp = axi4xbar_auto_in_r_bits_resp; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_r_bits_last = axi4xbar_auto_in_r_bits_last; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_uart_out_valid = uart_io_extra_out_valid; // @[SimMMIO.scala 46:13]
  assign io_uart_out_ch = uart_io_extra_out_ch; // @[SimMMIO.scala 46:13]
  assign io_uart_in_valid = uart_io_extra_in_valid; // @[SimMMIO.scala 46:13]
  assign io_interrupt_intrVec = intrGen_io_extra_intrVec; // @[SimMMIO.scala 47:18]
  assign flash_clock = clock;
  assign flash_reset = reset;
  assign flash_auto_in_aw_valid = axi4xbar_auto_out_3_aw_valid; // @[LazyModule.scala 296:16]
  assign flash_auto_in_aw_bits_id = axi4xbar_auto_out_3_aw_bits_id; // @[LazyModule.scala 296:16]
  assign flash_auto_in_aw_bits_addr = axi4xbar_auto_out_3_aw_bits_addr; // @[LazyModule.scala 296:16]
  assign flash_auto_in_aw_bits_len = axi4xbar_auto_out_3_aw_bits_len; // @[LazyModule.scala 296:16]
  assign flash_auto_in_aw_bits_size = axi4xbar_auto_out_3_aw_bits_size; // @[LazyModule.scala 296:16]
  assign flash_auto_in_aw_bits_burst = axi4xbar_auto_out_3_aw_bits_burst; // @[LazyModule.scala 296:16]
  assign flash_auto_in_aw_bits_lock = axi4xbar_auto_out_3_aw_bits_lock; // @[LazyModule.scala 296:16]
  assign flash_auto_in_aw_bits_cache = axi4xbar_auto_out_3_aw_bits_cache; // @[LazyModule.scala 296:16]
  assign flash_auto_in_aw_bits_prot = axi4xbar_auto_out_3_aw_bits_prot; // @[LazyModule.scala 296:16]
  assign flash_auto_in_aw_bits_qos = axi4xbar_auto_out_3_aw_bits_qos; // @[LazyModule.scala 296:16]
  assign flash_auto_in_w_valid = axi4xbar_auto_out_3_w_valid; // @[LazyModule.scala 296:16]
  assign flash_auto_in_w_bits_data = axi4xbar_auto_out_3_w_bits_data; // @[LazyModule.scala 296:16]
  assign flash_auto_in_w_bits_strb = axi4xbar_auto_out_3_w_bits_strb; // @[LazyModule.scala 296:16]
  assign flash_auto_in_w_bits_last = axi4xbar_auto_out_3_w_bits_last; // @[LazyModule.scala 296:16]
  assign flash_auto_in_b_ready = axi4xbar_auto_out_3_b_ready; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_valid = axi4xbar_auto_out_3_ar_valid; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_bits_id = axi4xbar_auto_out_3_ar_bits_id; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_bits_addr = axi4xbar_auto_out_3_ar_bits_addr; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_bits_len = axi4xbar_auto_out_3_ar_bits_len; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_bits_size = axi4xbar_auto_out_3_ar_bits_size; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_bits_burst = axi4xbar_auto_out_3_ar_bits_burst; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_bits_lock = axi4xbar_auto_out_3_ar_bits_lock; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_bits_cache = axi4xbar_auto_out_3_ar_bits_cache; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_bits_prot = axi4xbar_auto_out_3_ar_bits_prot; // @[LazyModule.scala 296:16]
  assign flash_auto_in_ar_bits_qos = axi4xbar_auto_out_3_ar_bits_qos; // @[LazyModule.scala 296:16]
  assign flash_auto_in_r_ready = axi4xbar_auto_out_3_r_ready; // @[LazyModule.scala 296:16]
  assign uart_clock = clock;
  assign uart_reset = reset;
  assign uart_auto_in_aw_valid = axi4xbar_auto_out_0_aw_valid; // @[LazyModule.scala 296:16]
  assign uart_auto_in_aw_bits_id = axi4xbar_auto_out_0_aw_bits_id; // @[LazyModule.scala 296:16]
  assign uart_auto_in_aw_bits_addr = axi4xbar_auto_out_0_aw_bits_addr; // @[LazyModule.scala 296:16]
  assign uart_auto_in_aw_bits_len = axi4xbar_auto_out_0_aw_bits_len; // @[LazyModule.scala 296:16]
  assign uart_auto_in_aw_bits_size = axi4xbar_auto_out_0_aw_bits_size; // @[LazyModule.scala 296:16]
  assign uart_auto_in_aw_bits_burst = axi4xbar_auto_out_0_aw_bits_burst; // @[LazyModule.scala 296:16]
  assign uart_auto_in_aw_bits_lock = axi4xbar_auto_out_0_aw_bits_lock; // @[LazyModule.scala 296:16]
  assign uart_auto_in_aw_bits_cache = axi4xbar_auto_out_0_aw_bits_cache; // @[LazyModule.scala 296:16]
  assign uart_auto_in_aw_bits_prot = axi4xbar_auto_out_0_aw_bits_prot; // @[LazyModule.scala 296:16]
  assign uart_auto_in_aw_bits_qos = axi4xbar_auto_out_0_aw_bits_qos; // @[LazyModule.scala 296:16]
  assign uart_auto_in_w_valid = axi4xbar_auto_out_0_w_valid; // @[LazyModule.scala 296:16]
  assign uart_auto_in_w_bits_data = axi4xbar_auto_out_0_w_bits_data; // @[LazyModule.scala 296:16]
  assign uart_auto_in_w_bits_strb = axi4xbar_auto_out_0_w_bits_strb; // @[LazyModule.scala 296:16]
  assign uart_auto_in_w_bits_last = axi4xbar_auto_out_0_w_bits_last; // @[LazyModule.scala 296:16]
  assign uart_auto_in_b_ready = axi4xbar_auto_out_0_b_ready; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_valid = axi4xbar_auto_out_0_ar_valid; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_bits_id = axi4xbar_auto_out_0_ar_bits_id; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_bits_addr = axi4xbar_auto_out_0_ar_bits_addr; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_bits_len = axi4xbar_auto_out_0_ar_bits_len; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_bits_size = axi4xbar_auto_out_0_ar_bits_size; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_bits_burst = axi4xbar_auto_out_0_ar_bits_burst; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_bits_lock = axi4xbar_auto_out_0_ar_bits_lock; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_bits_cache = axi4xbar_auto_out_0_ar_bits_cache; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_bits_prot = axi4xbar_auto_out_0_ar_bits_prot; // @[LazyModule.scala 296:16]
  assign uart_auto_in_ar_bits_qos = axi4xbar_auto_out_0_ar_bits_qos; // @[LazyModule.scala 296:16]
  assign uart_auto_in_r_ready = axi4xbar_auto_out_0_r_ready; // @[LazyModule.scala 296:16]
  assign uart_io_extra_in_ch = io_uart_in_ch; // @[SimMMIO.scala 46:13]
  assign vga_clock = clock;
  assign vga_reset = reset;
  assign vga_auto_in_1_aw_valid = axi4xbar_auto_out_2_aw_valid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_aw_bits_id = axi4xbar_auto_out_2_aw_bits_id; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_aw_bits_addr = axi4xbar_auto_out_2_aw_bits_addr; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_aw_bits_len = axi4xbar_auto_out_2_aw_bits_len; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_aw_bits_size = axi4xbar_auto_out_2_aw_bits_size; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_aw_bits_burst = axi4xbar_auto_out_2_aw_bits_burst; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_aw_bits_lock = axi4xbar_auto_out_2_aw_bits_lock; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_aw_bits_cache = axi4xbar_auto_out_2_aw_bits_cache; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_aw_bits_prot = axi4xbar_auto_out_2_aw_bits_prot; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_aw_bits_qos = axi4xbar_auto_out_2_aw_bits_qos; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_w_valid = axi4xbar_auto_out_2_w_valid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_w_bits_data = axi4xbar_auto_out_2_w_bits_data; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_w_bits_strb = axi4xbar_auto_out_2_w_bits_strb; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_w_bits_last = axi4xbar_auto_out_2_w_bits_last; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_b_ready = axi4xbar_auto_out_2_b_ready; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_valid = axi4xbar_auto_out_2_ar_valid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_bits_id = axi4xbar_auto_out_2_ar_bits_id; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_bits_addr = axi4xbar_auto_out_2_ar_bits_addr; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_bits_len = axi4xbar_auto_out_2_ar_bits_len; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_bits_size = axi4xbar_auto_out_2_ar_bits_size; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_bits_burst = axi4xbar_auto_out_2_ar_bits_burst; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_bits_lock = axi4xbar_auto_out_2_ar_bits_lock; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_bits_cache = axi4xbar_auto_out_2_ar_bits_cache; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_bits_prot = axi4xbar_auto_out_2_ar_bits_prot; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_ar_bits_qos = axi4xbar_auto_out_2_ar_bits_qos; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_r_ready = axi4xbar_auto_out_2_r_ready; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_valid = axi4xbar_auto_out_1_aw_valid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_bits_id = axi4xbar_auto_out_1_aw_bits_id; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_bits_addr = axi4xbar_auto_out_1_aw_bits_addr; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_bits_len = axi4xbar_auto_out_1_aw_bits_len; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_bits_size = axi4xbar_auto_out_1_aw_bits_size; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_bits_burst = axi4xbar_auto_out_1_aw_bits_burst; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_bits_lock = axi4xbar_auto_out_1_aw_bits_lock; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_bits_cache = axi4xbar_auto_out_1_aw_bits_cache; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_bits_prot = axi4xbar_auto_out_1_aw_bits_prot; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_aw_bits_qos = axi4xbar_auto_out_1_aw_bits_qos; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_w_valid = axi4xbar_auto_out_1_w_valid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_w_bits_data = axi4xbar_auto_out_1_w_bits_data; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_w_bits_strb = axi4xbar_auto_out_1_w_bits_strb; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_w_bits_last = axi4xbar_auto_out_1_w_bits_last; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_b_ready = axi4xbar_auto_out_1_b_ready; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_ar_valid = axi4xbar_auto_out_1_ar_valid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_ar_bits_id = axi4xbar_auto_out_1_ar_bits_id; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_ar_bits_len = axi4xbar_auto_out_1_ar_bits_len; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_ar_bits_size = axi4xbar_auto_out_1_ar_bits_size; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_ar_bits_burst = axi4xbar_auto_out_1_ar_bits_burst; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_ar_bits_lock = axi4xbar_auto_out_1_ar_bits_lock; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_ar_bits_cache = axi4xbar_auto_out_1_ar_bits_cache; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_ar_bits_qos = axi4xbar_auto_out_1_ar_bits_qos; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_r_ready = axi4xbar_auto_out_1_r_ready; // @[LazyModule.scala 296:16]
  assign sd_clock = clock;
  assign sd_reset = reset;
  assign sd_auto_in_aw_valid = axi4xbar_auto_out_4_aw_valid; // @[LazyModule.scala 296:16]
  assign sd_auto_in_aw_bits_id = axi4xbar_auto_out_4_aw_bits_id; // @[LazyModule.scala 296:16]
  assign sd_auto_in_aw_bits_addr = axi4xbar_auto_out_4_aw_bits_addr; // @[LazyModule.scala 296:16]
  assign sd_auto_in_aw_bits_len = axi4xbar_auto_out_4_aw_bits_len; // @[LazyModule.scala 296:16]
  assign sd_auto_in_aw_bits_size = axi4xbar_auto_out_4_aw_bits_size; // @[LazyModule.scala 296:16]
  assign sd_auto_in_aw_bits_burst = axi4xbar_auto_out_4_aw_bits_burst; // @[LazyModule.scala 296:16]
  assign sd_auto_in_aw_bits_lock = axi4xbar_auto_out_4_aw_bits_lock; // @[LazyModule.scala 296:16]
  assign sd_auto_in_aw_bits_cache = axi4xbar_auto_out_4_aw_bits_cache; // @[LazyModule.scala 296:16]
  assign sd_auto_in_aw_bits_prot = axi4xbar_auto_out_4_aw_bits_prot; // @[LazyModule.scala 296:16]
  assign sd_auto_in_aw_bits_qos = axi4xbar_auto_out_4_aw_bits_qos; // @[LazyModule.scala 296:16]
  assign sd_auto_in_w_valid = axi4xbar_auto_out_4_w_valid; // @[LazyModule.scala 296:16]
  assign sd_auto_in_w_bits_data = axi4xbar_auto_out_4_w_bits_data; // @[LazyModule.scala 296:16]
  assign sd_auto_in_w_bits_strb = axi4xbar_auto_out_4_w_bits_strb; // @[LazyModule.scala 296:16]
  assign sd_auto_in_w_bits_last = axi4xbar_auto_out_4_w_bits_last; // @[LazyModule.scala 296:16]
  assign sd_auto_in_b_ready = axi4xbar_auto_out_4_b_ready; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_valid = axi4xbar_auto_out_4_ar_valid; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_bits_id = axi4xbar_auto_out_4_ar_bits_id; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_bits_addr = axi4xbar_auto_out_4_ar_bits_addr; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_bits_len = axi4xbar_auto_out_4_ar_bits_len; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_bits_size = axi4xbar_auto_out_4_ar_bits_size; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_bits_burst = axi4xbar_auto_out_4_ar_bits_burst; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_bits_lock = axi4xbar_auto_out_4_ar_bits_lock; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_bits_cache = axi4xbar_auto_out_4_ar_bits_cache; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_bits_prot = axi4xbar_auto_out_4_ar_bits_prot; // @[LazyModule.scala 296:16]
  assign sd_auto_in_ar_bits_qos = axi4xbar_auto_out_4_ar_bits_qos; // @[LazyModule.scala 296:16]
  assign sd_auto_in_r_ready = axi4xbar_auto_out_4_r_ready; // @[LazyModule.scala 296:16]
  assign intrGen_clock = clock;
  assign intrGen_reset = reset;
  assign intrGen_auto_in_aw_valid = axi4xbar_auto_out_5_aw_valid; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_aw_bits_id = axi4xbar_auto_out_5_aw_bits_id; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_aw_bits_addr = axi4xbar_auto_out_5_aw_bits_addr; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_aw_bits_len = axi4xbar_auto_out_5_aw_bits_len; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_aw_bits_size = axi4xbar_auto_out_5_aw_bits_size; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_aw_bits_burst = axi4xbar_auto_out_5_aw_bits_burst; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_aw_bits_lock = axi4xbar_auto_out_5_aw_bits_lock; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_aw_bits_cache = axi4xbar_auto_out_5_aw_bits_cache; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_aw_bits_prot = axi4xbar_auto_out_5_aw_bits_prot; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_aw_bits_qos = axi4xbar_auto_out_5_aw_bits_qos; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_w_valid = axi4xbar_auto_out_5_w_valid; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_w_bits_data = axi4xbar_auto_out_5_w_bits_data; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_w_bits_strb = axi4xbar_auto_out_5_w_bits_strb; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_w_bits_last = axi4xbar_auto_out_5_w_bits_last; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_b_ready = axi4xbar_auto_out_5_b_ready; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_valid = axi4xbar_auto_out_5_ar_valid; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_bits_id = axi4xbar_auto_out_5_ar_bits_id; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_bits_addr = axi4xbar_auto_out_5_ar_bits_addr; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_bits_len = axi4xbar_auto_out_5_ar_bits_len; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_bits_size = axi4xbar_auto_out_5_ar_bits_size; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_bits_burst = axi4xbar_auto_out_5_ar_bits_burst; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_bits_lock = axi4xbar_auto_out_5_ar_bits_lock; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_bits_cache = axi4xbar_auto_out_5_ar_bits_cache; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_bits_prot = axi4xbar_auto_out_5_ar_bits_prot; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_ar_bits_qos = axi4xbar_auto_out_5_ar_bits_qos; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_r_ready = axi4xbar_auto_out_5_r_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_clock = clock;
  assign axi4xbar_reset = reset;
  assign axi4xbar_auto_in_aw_valid = io_axi4_0_aw_valid; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_aw_bits_id = io_axi4_0_aw_bits_id; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_aw_bits_addr = io_axi4_0_aw_bits_addr; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_aw_bits_len = io_axi4_0_aw_bits_len; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_aw_bits_size = io_axi4_0_aw_bits_size; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_aw_bits_burst = io_axi4_0_aw_bits_burst; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_aw_bits_lock = io_axi4_0_aw_bits_lock; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_aw_bits_cache = io_axi4_0_aw_bits_cache; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_aw_bits_prot = io_axi4_0_aw_bits_prot; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_aw_bits_qos = io_axi4_0_aw_bits_qos; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_w_valid = io_axi4_0_w_valid; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_w_bits_data = io_axi4_0_w_bits_data; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_w_bits_strb = io_axi4_0_w_bits_strb; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_w_bits_last = io_axi4_0_w_bits_last; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_b_ready = io_axi4_0_b_ready; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_valid = io_axi4_0_ar_valid; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_bits_id = io_axi4_0_ar_bits_id; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_bits_addr = io_axi4_0_ar_bits_addr; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_bits_len = io_axi4_0_ar_bits_len; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_bits_size = io_axi4_0_ar_bits_size; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_bits_burst = io_axi4_0_ar_bits_burst; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_bits_lock = io_axi4_0_ar_bits_lock; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_bits_cache = io_axi4_0_ar_bits_cache; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_bits_prot = io_axi4_0_ar_bits_prot; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_ar_bits_qos = io_axi4_0_ar_bits_qos; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_in_r_ready = io_axi4_0_r_ready; // @[Nodes.scala 1207:84 Nodes.scala 1630:60]
  assign axi4xbar_auto_out_5_aw_ready = intrGen_auto_in_aw_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_w_ready = intrGen_auto_in_w_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_b_valid = intrGen_auto_in_b_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_b_bits_id = intrGen_auto_in_b_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_b_bits_resp = intrGen_auto_in_b_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_ar_ready = intrGen_auto_in_ar_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_r_valid = intrGen_auto_in_r_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_r_bits_id = intrGen_auto_in_r_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_r_bits_data = intrGen_auto_in_r_bits_data; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_r_bits_resp = intrGen_auto_in_r_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_r_bits_last = intrGen_auto_in_r_bits_last; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_aw_ready = sd_auto_in_aw_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_w_ready = sd_auto_in_w_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_b_valid = sd_auto_in_b_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_b_bits_id = sd_auto_in_b_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_b_bits_resp = sd_auto_in_b_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_ar_ready = sd_auto_in_ar_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_r_valid = sd_auto_in_r_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_r_bits_id = sd_auto_in_r_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_r_bits_data = sd_auto_in_r_bits_data; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_r_bits_resp = sd_auto_in_r_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_r_bits_last = sd_auto_in_r_bits_last; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_aw_ready = flash_auto_in_aw_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_w_ready = flash_auto_in_w_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_b_valid = flash_auto_in_b_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_b_bits_id = flash_auto_in_b_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_b_bits_resp = flash_auto_in_b_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_ar_ready = flash_auto_in_ar_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_r_valid = flash_auto_in_r_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_r_bits_id = flash_auto_in_r_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_r_bits_data = flash_auto_in_r_bits_data; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_r_bits_resp = flash_auto_in_r_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_r_bits_last = flash_auto_in_r_bits_last; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_aw_ready = vga_auto_in_1_aw_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_w_ready = vga_auto_in_1_w_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_b_valid = vga_auto_in_1_b_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_b_bits_id = vga_auto_in_1_b_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_b_bits_resp = vga_auto_in_1_b_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_ar_ready = vga_auto_in_1_ar_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_r_valid = vga_auto_in_1_r_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_r_bits_id = vga_auto_in_1_r_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_r_bits_data = vga_auto_in_1_r_bits_data; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_r_bits_resp = vga_auto_in_1_r_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_r_bits_last = vga_auto_in_1_r_bits_last; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_aw_ready = vga_auto_in_0_aw_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_w_ready = vga_auto_in_0_w_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_b_valid = vga_auto_in_0_b_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_b_bits_id = vga_auto_in_0_b_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_b_bits_resp = vga_auto_in_0_b_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_r_valid = vga_auto_in_0_r_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_r_bits_id = vga_auto_in_0_r_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_r_bits_last = vga_auto_in_0_r_bits_last; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_aw_ready = uart_auto_in_aw_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_w_ready = uart_auto_in_w_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_b_valid = uart_auto_in_b_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_b_bits_id = uart_auto_in_b_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_b_bits_resp = uart_auto_in_b_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_ar_ready = uart_auto_in_ar_ready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_r_valid = uart_auto_in_r_valid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_r_bits_id = uart_auto_in_r_bits_id; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_r_bits_data = uart_auto_in_r_bits_data; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_r_bits_resp = uart_auto_in_r_bits_resp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_r_bits_last = uart_auto_in_r_bits_last; // @[LazyModule.scala 296:16]
endmodule

