`include "DSEMacro.v"

module DPIC(
  input wire clock,
  input wire reset,
  input wire out_enable,
  input wire [`DEG_DATA_WIDTH+`MAGIC_NUM_WIDTH-1:0] out_data
);

import "DPI-C" function byte update_deg();
import "DPI-C" function byte update_deg_record(byte doDSEReset, longint reset_vector, byte deg_record, longint dse_epoch);
import "DPI-C" function void process_long_vector(input bit [`DEG_DATA_WIDTH+`MAGIC_NUM_WIDTH-1:0] data, longint deg_data_width, longint magic_num_width);

always @(posedge clock) begin
  if (reset) begin
    // Nop
  end else begin
    if (out_enable) begin
      process_long_vector(out_data, `DEG_DATA_WIDTH, `MAGIC_NUM_WIDTH);
    end
  end
end

endmodule
