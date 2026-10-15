module uvhs_async_status_sync #(
  parameter INIT = 1'b1
) (
  input  wire clk,
  input  wire rstn,
  input  wire async_in,
  output wire sync_out
);

  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] sync_reg;

  always @(posedge clk or negedge rstn) begin
    if (!rstn)
      sync_reg <= {2{INIT}};
    else
      sync_reg <= {sync_reg[0], async_in};
  end

  assign sync_out = sync_reg[1];

endmodule
