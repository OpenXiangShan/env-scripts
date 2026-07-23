module uvhs_cpu_liveness_gbd (
    input  wire        clk,
    input  wire        rstn,
    input  wire        cpu_rstn,
    input  wire        host_reset,
    input  wire        host_diff_enable,
    input  wire        ddr_init_done,
    input  wire        mem_arvalid,
    input  wire        mem_arready,
    input  wire [63:0] mem_araddr,
    input  wire        mem_rvalid,
    input  wire        mem_rready,
    input  wire        axis_valid,
    input  wire        axis_ready,
    input  wire        backend_valid,
    input  wire [63:0] backend_pc
);

    wire [31:0] gbd_force_bus;

    wire mem_ar_fire = mem_arvalid & mem_arready;
    wire mem_r_fire = mem_rvalid & mem_rready;
    wire axis_fire = axis_valid & axis_ready;

    reg [31:0] status_seen;
    reg [31:0] mem_ar_count;
    reg [31:0] mem_r_count;
    reg [31:0] axis_valid_count;
    reg [31:0] backend_valid_count;
    reg [63:0] last_mem_araddr;
    reg [63:0] last_backend_pc;

    always @(posedge clk) begin
        if (!rstn || !cpu_rstn) begin
            status_seen <= 32'b0;
            mem_ar_count <= 32'b0;
            mem_r_count <= 32'b0;
            axis_valid_count <= 32'b0;
            backend_valid_count <= 32'b0;
            last_mem_araddr <= 64'b0;
            last_backend_pc <= 64'b0;
        end else begin
            status_seen[0] <= status_seen[0] | mem_ar_fire;
            status_seen[1] <= status_seen[1] | mem_r_fire;
            status_seen[2] <= status_seen[2] | axis_valid;
            status_seen[3] <= status_seen[3] | axis_fire;
            status_seen[4] <= status_seen[4] | backend_valid;
            if (mem_ar_fire) begin
                mem_ar_count <= mem_ar_count + 32'b1;
                last_mem_araddr <= mem_araddr;
            end
            if (mem_r_fire) begin
                mem_r_count <= mem_r_count + 32'b1;
            end
            if (axis_valid) begin
                axis_valid_count <= axis_valid_count + 32'b1;
            end
            if (backend_valid) begin
                backend_valid_count <= backend_valid_count + 32'b1;
                last_backend_pc <= backend_pc;
            end
        end
    end

    wire [31:0] live_reset_counts = {
        8'b0,
        host_diff_enable,
        host_reset,
        cpu_rstn,
        rstn,
        ddr_init_done,
        backend_valid,
        axis_ready,
        axis_valid,
        mem_rready,
        mem_rvalid,
        mem_arready,
        mem_arvalid,
        |gbd_force_bus,
        mem_r_count[7:0],
        mem_ar_count[7:0]
    };

    wire [159:0] monitor_bus = {
        last_backend_pc[31:0],
        backend_valid_count,
        axis_valid_count,
        status_seen,
        live_reset_counts
    };

    gBD_force_monitor U_GBD_FORCE_MONITOR (
        .monitor_bus (monitor_bus),
        .force_bus   (gbd_force_bus),
        .dut_rst     (~rstn),
        .dut_clk     (clk),
        .dut_clk_en  (1'b1)
    );
endmodule

module gBD_force_monitor (
    input  wire [159:0] monitor_bus,
    output reg  [31:0]  force_bus,
    input  wire         dut_rst,
    input  wire         dut_clk,
    input  wire         dut_clk_en
);

    (* KEEP = "true" *) reg  [31:0] wtob_data;
    (* KEEP = "true" *) wire [15:0] wtob_addr;
    (* KEEP = "true" *) wire        wtod_en;
    (* KEEP = "true" *) wire [15:0] wtod_addr;
    (* KEEP = "true" *) wire [31:0] wtod_data;
    (* KEEP = "true" *) reg  [2:0]  monitor_cnt;

    wire dut_rstn = ~dut_rst;
    wire [159:0] monitor_bus_sync;

    uvhs_gbd_sync #(.WIDTH(160)) i_monitor_bus_sync (
        .clk   (dut_clk),
        .rst_n (dut_rstn),
        .din   (monitor_bus),
        .dout  (monitor_bus_sync)
    );

    always @(posedge dut_clk or negedge dut_rstn) begin
        if (!dut_rstn) begin
            monitor_cnt <= 3'h0;
        end else if (monitor_cnt == 3'h5) begin
            monitor_cnt <= 3'h0;
        end else begin
            monitor_cnt <= monitor_cnt + 3'h1;
        end
    end

    always @(*) begin
        case (monitor_cnt)
            3'h0: wtob_data = monitor_bus_sync[31:0];
            3'h1: wtob_data = monitor_bus_sync[63:32];
            3'h2: wtob_data = monitor_bus_sync[95:64];
            3'h3: wtob_data = monitor_bus_sync[127:96];
            3'h4: wtob_data = monitor_bus_sync[159:128];
            3'h5: wtob_data = 32'h5a5a_5a5a;
            default: wtob_data = 32'h0;
        endcase
    end

    assign wtob_addr = 16'h0040 + (monitor_cnt << 2);

    always @(posedge dut_clk or negedge dut_rstn) begin
        if (!dut_rstn) begin
            force_bus <= 32'h0;
        end else if (wtod_en && (wtod_addr == 16'h0080)) begin
            force_bus <= wtod_data;
        end
    end

    generalBD gBD_inst (
        .dut_rst       (dut_rst),
        .dut_clk       (dut_clk),
        .dut_clk_en    (dut_clk_en),
        .tosysbus_data (wtob_data),
        .tosysbus_addr (wtob_addr),
        .todut_data    (wtod_data),
        .todut_addr    (wtod_addr),
        .todut_en      (wtod_en)
    );
endmodule

module uvhs_gbd_sync #(parameter WIDTH = 128) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] sync1;
    reg [WIDTH-1:0] sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync1 <= {WIDTH{1'b0}};
            sync2 <= {WIDTH{1'b0}};
        end else begin
            sync1 <= din;
            sync2 <= sync1;
        end
    end

    assign dout = sync2;
endmodule
