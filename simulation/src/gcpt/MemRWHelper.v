import "DPI-C" function void ram_load_bin_file(string s);
import "DPI-C" function void ram_load_gcpt_file(string s);
import "DPI-C" function void ram_read_data(input longint addr,output longint data);
import "DPI-C" function void ram_write_data(input longint addr,input longint w_mask,
                                            input longint data);
import "DPI-C" function void init_ram(input longint size);
module MemRWHelper(

input             r_enable,
input      [63:0] r_index,
output reg [63:0] r_data,


input         w_enable,
input  [63:0] w_index,
input  [63:0] w_data,
input  [63:0] w_mask,

  input enable,
  input clock
);

`ifndef GCPT_IMAGE
// 2G memory
  `define RAM_SIZE (2 * 1024 * 1024 * 1024)
`else
// 8GB memory
  `define RAM_SIZE (8 * 1024 * 1024 * 1024)
`endif // GCPT_IMAGE
  // memory read
  always @(posedge clock) begin
    if (enable) begin    
      if (r_enable) begin
        ram_read_data(r_index, r_data);
      end
    end
  end

  // memory write
  always @(posedge clock) begin
    if (w_enable && enable) begin
      ram_write_data(w_index, w_mask, w_data);
    end
  end

`ifdef MEMORY_IMAGE
  integer memory_image;
  // Create string-type MEMORY_IMAGE
  `define STRINGIFY(x) `"x`"
  `define MEMORY_IMAGE_S `STRINGIFY(`MEMORY_IMAGE)
`ifdef GCPT_IMAGE
  integer gcpt_image;
  `define GCPT_IMAGE_S `STRINGIFY(`GCPT_IMAGE)
`endif // GCPT_IMAGE
`endif // MEMORY_IMAGE

  initial begin
`ifdef MEMORY_IMAGE
  ram_load_bin_file(`MEMORY_IMAGE_S);
`else
  $fatal(1, "You must specify the MEMORY_IMAGE macro.");
`endif // MEMORY_IMAGE

`ifdef GCPT_IMAGE
  ram_load_gcpt_file(`GCPT_IMAGE_S);
`else
  $display("gcpt restore is not covered");
`endif // GCPT_IMAGE

  init_ram(`RAM_SIZE);
 end
endmodule
     