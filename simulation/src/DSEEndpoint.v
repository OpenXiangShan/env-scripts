`include "DSEMacro.v"

module DSEEndpoint(
  input wire clock,
  input wire reset,
  `INPUT_HARDEN_PERFCNT
  input wire dse_reset_valid,
  input wire [35:0] dse_reset_vector,
  input wire [63:0] dse_epoch
);

import "DPI-C" function byte dse_init(byte dse_reset_valid);
import "DPI-C" function byte update_deg();
import "DPI-C" function void do_dse_reset(longint dse_epoch);
import "DPI-C" function byte update_deg_record(byte doDSEReset, longint reset_vector, byte deg_record, longint dse_epoch);
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
 * push reset signal & performance counter
 */
reg [3:0] nr_commit;
reg lastCycleDSEReset;
reg doDSEReset;
reg deg_record;

always @(posedge clock) begin
  if (reset) begin
    lastCycleDSEReset <= 1'b0;
    doDSEReset <= 1'b0;
    deg_record <= 1'b0;
    nr_commit <= 1'b0;
  end
  else begin
    if (dse_reset_valid && !lastCycleDSEReset) begin
      lastCycleDSEReset <= 1'b1;
      do_dse_reset(dse_epoch);
      $display("DSE RESET");
    end
    if (lastCycleDSEReset && !dse_reset_valid) begin
      lastCycleDSEReset <= 1'b0;
      doDSEReset <= 1'b1;
    end
    if (doDSEReset) begin
      doDSEReset <= 1'b0;
    end
    
    deg_record <= update_deg_record(doDSEReset, dse_reset_vector, deg_record, dse_epoch);
    
    if (deg_record) begin
      `PUSH_HARDEN_PERFCNT
      nr_commit <= update_deg();
    end
  end
end

endmodule