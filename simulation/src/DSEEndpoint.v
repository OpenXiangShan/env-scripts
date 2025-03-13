`include "DSEMacro.v"

module DSEEndpoint(
  input wire clock,
  input wire reset,
  `INPUT_HARDEN_PERFCNT
  input wire dse_reset_valid
);

import "DPI-C" function byte dse_init(byte dse_reset_valid);
import "DPI-C" function byte update_deg();
`DECLEAR_PUSH_HARDEN_PERFCNT

/*
 * cycle counter
 */
reg [63:0] n_cycles;
always @(posedge clock) begin
  if (reset) begin
    n_cycles <= 64'h0;
  end
  else begin
    n_cycles <= n_cycles + 64'h1;
  end
end

/*
 * DSE initialization
 */
always @(posedge clock) begin
  if (!reset) begin
    // dse
    if (!n_cycles) begin
      if (dse_init(dse_reset_valid)) begin
        $display("DSE INIT FAILED");
        $fatal;
      end
    end
  end
end

/*
 * push performance counter
 */
reg [3:0] nr_commit;
always @(posedge clock) begin
  if (!reset) begin
    if (n_cycles > 64'h10) begin
      `PUSH_HARDEN_PERFCNT
      nr_commit <= update_deg();
    end
  end
end

endmodule