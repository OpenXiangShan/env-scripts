`timescale 1ns/1ps

// Converts the local bus emitted by the UVHS generalBD IP into the existing
// DiffTest AXI-Lite config BAR.  The local bus has no ready signal; one command
// is held until the AXI-Lite response completes.
module uvhs_generalbd_axilite_bridge (
    input wire clk,
    input wire rstn,
    input wire gbd_wr_en,
    input wire [15:0] gbd_wr_addr,
    input wire [31:0] gbd_wdata,
    input wire gbd_rd_en,
    input wire [15:0] gbd_rd_addr,
    output reg [31:0] gbd_rdata,
    output reg gbd_rdata_vld,
    output reg [31:0] axil_awaddr,
    output reg axil_awvalid,
    input wire axil_awready,
    output reg [31:0] axil_wdata,
    output reg [3:0] axil_wstrb,
    output reg axil_wvalid,
    input wire axil_wready,
    input wire [1:0] axil_bresp,
    input wire axil_bvalid,
    output reg axil_bready,
    output reg [31:0] axil_araddr,
    output reg axil_arvalid,
    input wire axil_arready,
    input wire [31:0] axil_rdata,
    input wire [1:0] axil_rresp,
    input wire axil_rvalid,
    output reg axil_rready,
    output reg h2c_active
);
    localparam S_IDLE = 3'd0, S_AW_W = 3'd1, S_B = 3'd2,
               S_AR = 3'd3, S_R = 3'd4;
    reg [2:0] state;
    reg aw_done, w_done;
    reg [15:0] pending_addr;
    reg [31:0] pending_data;
    reg pending_read;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= S_IDLE;
            aw_done <= 1'b0; w_done <= 1'b0;
            pending_addr <= 16'b0; pending_data <= 32'b0;
            pending_read <= 1'b0; gbd_rdata <= 32'b0;
            gbd_rdata_vld <= 1'b0; h2c_active <= 1'b0;
        end else begin
            gbd_rdata_vld <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (gbd_wr_en) begin
                        pending_addr <= gbd_wr_addr;
                        pending_data <= gbd_wdata;
                        pending_read <= 1'b0;
                        aw_done <= 1'b0; w_done <= 1'b0;
                        state <= S_AW_W;
                        if (gbd_wr_addr == 16'h24)
                            h2c_active <= (gbd_wdata[0]);
                    end else if (gbd_rd_en) begin
                        pending_addr <= gbd_rd_addr;
                        pending_read <= 1'b1;
                        state <= S_AR;
                    end
                end
                S_AW_W: begin
                    if (axil_awvalid && axil_awready) aw_done <= 1'b1;
                    if (axil_wvalid && axil_wready) w_done <= 1'b1;
                    if ((aw_done || (axil_awvalid && axil_awready)) &&
                        (w_done || (axil_wvalid && axil_wready))) state <= S_B;
                end
                S_B: if (axil_bvalid) state <= S_IDLE;
                S_AR: if (axil_arvalid && axil_arready) state <= S_R;
                S_R: if (axil_rvalid) begin
                    gbd_rdata <= axil_rdata;
                    gbd_rdata_vld <= 1'b1;
                    state <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

    always @(*) begin
        axil_awaddr = {16'b0, pending_addr};
        axil_awvalid = (state == S_AW_W) && !aw_done;
        axil_wdata = pending_data;
        axil_wstrb = 4'hf;
        axil_wvalid = (state == S_AW_W) && !w_done;
        axil_bready = (state == S_B);
        axil_araddr = {16'b0, pending_addr};
        axil_arvalid = (state == S_AR);
        axil_rready = (state == S_R);
    end

    wire _unused = &{1'b0, pending_read, axil_bresp, axil_rresp};
endmodule
