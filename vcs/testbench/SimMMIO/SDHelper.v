import "DPI-C" function void sd_setaddr(input int addr);
import "DPI-C" function void sd_read(output int data);
module SDHelper(
  input clk,
  input setAddr,
  input [31:0] addr,
  input ren,
  output reg [31:0] data
);

  always @(negedge clk) begin
    if (ren) sd_read(data);
  end
  always@(posedge clk) begin
    if (setAddr) sd_setaddr(addr);
  end

endmodule
