`timescale 1ns/1ps
module uvhs_gbus_axi_read_router_tb;
  reg clk=0,rstn=0; always #5 clk=~clk;
  reg [7:0] s_arid=0; reg [31:0] s_araddr=0; reg [3:0] s_arlen=0; reg [2:0] s_arsize=3; reg [1:0] s_arburst=1,s_arlock=0; reg [3:0] s_arcache=0,s_arqos=0; reg [2:0] s_arprot=5; reg s_arvalid=0,s_rready=0;
  wire s_arready; wire [7:0] s_rid; wire [255:0] s_rdata; wire [1:0] s_rresp; wire s_rlast,s_rvalid;
  wire [7:0] d_arid,c_arid; wire [31:0] d_araddr,c_araddr; wire [3:0] d_arlen,c_arlen; wire [2:0] d_arsize,c_arsize; wire [1:0] d_arburst,d_arlock,c_arburst; wire [3:0] d_arcache,d_arqos; wire [2:0] d_arprot; wire d_arvalid,c_arvalid,d_rready,c_rready; reg d_arready=0,c_arready=0;
  reg [7:0] d_rid=0,c_rid=0; reg [255:0] d_rdata=0,c_rdata=0; reg [1:0] d_rresp=0,c_rresp=0; reg d_rlast=0,c_rlast=0,d_rvalid=0,c_rvalid=0;
  uvhs_gbus_axi_read_router dut(.*);
  integer beat; integer cycle_count=0; integer seed=32'h6319;
  task automatic do_read(input [31:0] a,input integer n,input bit loc);
    begin
      @(negedge clk); s_arid=8'h5a;s_araddr=a;s_arlen=n-1;s_arvalid=1;d_arready=0;c_arready=0;
      repeat(2) begin #1; if(s_arready) $fatal(1,"ready during target stall"); if(loc ? (d_arvalid!==0) : (c_arvalid!==0)) $fatal(1,"wrong target valid"); @(negedge clk); end
      // Target ARVALID remains asserted while its READY is stalled.
      if(loc)c_arready=1;else d_arready=1;
      #1; if(!s_arready || (loc ? (c_arvalid!==1 || d_arvalid!==0) : (d_arvalid!==1 || c_arvalid!==0))) $fatal(1,"AR route");
      @(posedge clk); @(negedge clk); s_arvalid=0;d_arready=0;c_arready=0;
      beat=0;
      while(beat<n) begin
        cycle_count=cycle_count+1; if(cycle_count>1000)$fatal(1,"response timeout");
        cycle_count=cycle_count+1; if(cycle_count>1000)$fatal(1,"response timeout"); s_rready=(cycle_count%4)!=1;
        if(loc) begin c_rvalid=1;c_rid=8'h5a;c_rdata=256'hc000+beat;c_rresp=2'b00;c_rlast=(beat==n-1);d_rvalid=0; end
        else begin d_rvalid=1;d_rid=8'h5a;d_rdata=256'hd000+beat;d_rresp=2'b01;d_rlast=(beat==n-1);c_rvalid=0; end
        #1; if(loc ? (d_rready!==0) : (c_rready!==0))$fatal(1,"RREADY leakage");
        if(s_rvalid&&s_rready) begin
          if(s_rid!==8'h5a||s_rlast!==(beat==n-1))$fatal(1,"bad response");
          beat=beat+1;
        end
        @(posedge clk); @(negedge clk); c_rvalid=0; d_rvalid=0;
      end
      s_rready=0;
    end
  endtask
  initial begin
    repeat(2)@(negedge clk); #1; if(s_arready)$fatal(1,"ready in reset"); rstn=1;
    do_read(32'h10000000,1,1); do_read(32'h10000fff,16,1); do_read(32'h0fffffff,2,0); do_read(32'h10001000,3,0);
    // Hold local response back while a spurious DDR response is presented.
    @(negedge clk); s_arid=8'ha6;s_araddr=32'h10000080;s_arlen=0;s_arvalid=1;c_arready=1;d_arready=1; #1; @(posedge clk); @(negedge clk); s_arvalid=0;c_arready=0;d_arready=0;
    d_rvalid=1;d_rid=8'ha6;d_rlast=1;s_rready=0;#1;if(s_rvalid||d_rready)$fatal(1,"cross-target response leakage");
    c_rvalid=1;c_rid=8'ha6;c_rlast=1;s_rready=1;#1;if(!s_rvalid||!c_rready||d_rready)$fatal(1,"latched local response failure");@(posedge clk);
    $display("PASS uvhs_gbus_axi_read_router target_latch_no_leakage");$finish;
  end
endmodule
