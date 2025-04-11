`include "DSEMacro.v"

module DSEEndpoint(
  input wire clock,
  input wire reset,
  input wire dse_reset_valid,
  input wire [35:0] dse_reset_vector,
  input wire [63:0] dse_epoch,
  input wire deg_out_enable,
  input wire [5:0] deg_valids,
  input wire [`DEG_DATA_WIDTH-1:0] deg_out_data,
  input wire [`PERF_DATA_WIDTH-1:0] perf_out_data,
  output wire out_enable,
  output wire [`DEG_DATA_WIDTH+`MAGIC_NUM_WIDTH-1:0] out_data
);

parameter DEG_RECORD_THRES = 200;

import "DPI-C" function byte dse_init(byte dse_reset_valid);

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
    if (!n_cycles) begin
`ifndef SYNTHESIS  // simulation
      if (dse_init(dse_reset_valid)) begin
        $display("DSE INIT FAILED");
        $fatal;
      end
`endif
    end
  end
end

/*
 * push reset signal & performance counter
 */
reg [31:0] deg_record_num;
reg lastCycleDSEReset;
reg new_phase;
reg deg_record;
reg deg_record_latch;
wire dse_reset_to_workload;
wire dse_reset_to_driver;
wire out_emulate_trigger;
wire out_deg_trigger;
wire out_degdone_trigger;
wire out_finish_trigger;
wire [`MAGIC_NUM_WIDTH-1:0] magic_num;
wire [`DEG_DATA_WIDTH+`MAGIC_NUM_WIDTH-1:0] out_emulate_data, out_deg_data, out_degdone_data, out_finish_data;


assign dse_reset_to_workload = dse_reset_valid && !lastCycleDSEReset && (dse_reset_vector == 36'h80000000);
assign dse_reset_to_driver = dse_reset_valid && !lastCycleDSEReset && (dse_reset_vector == 36'h10000000);

assign out_emulate_trigger = dse_reset_to_workload;
assign out_deg_trigger = deg_record && deg_out_enable;
assign out_degdone_trigger = deg_record_latch && !deg_record;
assign out_finish_trigger = dse_reset_to_driver;

parameter DEG_PERF_MARGIN = `DEG_DATA_WIDTH - `PERF_DATA_WIDTH;

assign out_emulate_data = {magic_num, `DEG_DATA_WIDTH'b0};
assign out_deg_data = {magic_num, deg_out_data};
assign out_degdone_data = {magic_num, `DEG_DATA_WIDTH'b0};
assign out_finish_data = {magic_num, {DEG_PERF_MARGIN{1'b0}}, perf_out_data};

assign magic_num =
  out_emulate_trigger ? `MAGIC_NUM_WIDTH'h1 :
    out_deg_trigger ? `MAGIC_NUM_WIDTH'h2 :
      out_degdone_trigger? `MAGIC_NUM_WIDTH'h3 :
        out_finish_trigger ? `MAGIC_NUM_WIDTH'h4 : `MAGIC_NUM_WIDTH'h0;

assign out_enable = out_emulate_trigger | out_deg_trigger | out_degdone_trigger | out_finish_trigger;
assign out_data =
  out_emulate_trigger ? out_emulate_data :
    out_deg_trigger ? out_deg_data :
      out_degdone_trigger ? out_degdone_data :
        out_finish_trigger ? out_finish_data : 0;

always @(posedge clock) begin
  if (reset) begin
    lastCycleDSEReset <= 1'b0;
    new_phase <= 1'b0;
    deg_record <= 1'b0;
    deg_record_num <= 1'b0;
    deg_record_latch <= 1'b0;
  end
  else begin
    /* figure out whether a new running phase is started */
    if (dse_reset_valid && !lastCycleDSEReset) begin
      lastCycleDSEReset <= 1'b1;
    end
    if (lastCycleDSEReset && !dse_reset_valid) begin
      lastCycleDSEReset <= 1'b0;
      new_phase <= 1'b1;
    end
    if (new_phase) begin
      new_phase <= 1'b0;
    end

    /* do some initializaiton when DSE resets to the workload */
    if (dse_reset_to_workload) begin
      deg_record_num <= 32'h0;
    end
    
    /* decide whether to record and push the DEG information */
    if (new_phase && dse_reset_vector == 36'h80000000) begin
      deg_record <= 1'b1;
      $display("=== do DEG record ===");
    end else if (new_phase && dse_reset_vector == 36'h10000000) begin
      deg_record <= 1'b0;
      $display("=== end DEG record by DSE reset ===");
    end else if (deg_record && deg_record_num >= DEG_RECORD_THRES) begin
      deg_record <= 1'b0;
      $display("=== end DEG record by record num limit ===");
    end
    deg_record_latch <= deg_record;
    // deg_record <= update_deg_record(new_phase, dse_reset_vector, deg_record, dse_epoch);

    /* update deg_record_num */
    if (deg_record) begin
      if (deg_out_enable) begin
        deg_record_num <= deg_record_num + deg_valids[0] + deg_valids[1] + deg_valids[2] + deg_valids[3] + deg_valids[4] + deg_valids[5];
        if (deg_valids == 0) begin
          $display("Error: deg_valids is 0 when deg_out is enabled, maybe timeout?");
        end
      end
    end
  end
end

endmodule
