`timescale 1ns / 1ps

module clock_gating(
    input sys_clk,
    input enable,
    input rstn,
    output gated_clk
    );
    
  reg clk_en_reg;
  always @(sys_clk or enable) begin
    if (sys_clk == 1'b0)
      clk_en_reg <= enable;
  end

  assign gated_clk = sys_clk & clk_en_reg;
    
endmodule
