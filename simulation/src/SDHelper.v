`ifdef SIM_USE_DPIC
import "DPI-C" function void sd_setaddr(input int addr);
import "DPI-C" function void sd_read(output int data);
`endif

module SDHelper (
  input clk,
  input setAddr,
  input [31:0] addr,
  input ren,
  output reg [31:0] data
);

`ifdef SIM_USE_DPIC
  always @(negedge clk) begin
    if (ren) sd_read(data);
  end
  always@(posedge clk) begin
    if (setAddr) sd_setaddr(addr);
  end
`else
  always @(negedge clk) begin
    if (ren) data <= 0;
  end
`endif // SIM_USE_DPIC

endmodule

