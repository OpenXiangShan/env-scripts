import "DPI-C" function void flash_read
(
  input int addr,
  output longint data
);
module FlashHelper (
  input clk,
  input [31:0] addr,
  input ren,
  output reg [63:0] data
);

  always @(posedge clk) begin
    if (ren) flash_read(addr, data);
  end

endmodule

