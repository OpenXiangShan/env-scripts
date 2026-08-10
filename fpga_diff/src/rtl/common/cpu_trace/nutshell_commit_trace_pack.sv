`timescale 1ns/1ps

// Stable 692-bit schema for NutShell's single-issue in-order WBU snapshot.
// This is intentionally not called a ROB record: NutShell has no ROB.
//
//   [0]       commit_valid
//   [64:1]    sign-extended commit PC
//   [96:65]   instruction
//   [97]      MMIO/skip
//   [98]      RVC
//   [99]      integer RF write enable
//   [104:100] integer RF destination
//   [168:105] integer RF write data
//   [169]     redirect valid
//   [208:170] redirect target
//   [211:209] functional-unit type
//   [275:212] commit payload 0
//   [339:276] commit payload 1
//   [403:340] commit payload 2
//   [467:404] commit payload 3
//   [531:468] sampled CPU-cycle sequence
//   [595:532] sampled committed-instruction sequence
//   [627:596] magic "NUTS"
//   [635:628] schema version (1)
//   [691:636] reserved (zero)
module nutshell_commit_trace_pack (
    input  wire         clk,
    input  wire         resetn,
    input  wire         commit_valid,
    input  wire [38:0]  commit_pc,
    input  wire [31:0]  commit_instr,
    input  wire         commit_skip,
    input  wire         commit_rfwen,
    input  wire [4:0]   commit_rfdest,
    input  wire [63:0]  commit_rfdata,
    input  wire         redirect_valid,
    input  wire [38:0]  redirect_target,
    input  wire [2:0]   fu_type,
    input  wire [63:0]  commit_payload_0,
    input  wire [63:0]  commit_payload_1,
    input  wire [63:0]  commit_payload_2,
    input  wire [63:0]  commit_payload_3,
    output wire [691:0] trace_data,
    output wire         trace_valid
);
    localparam [31:0] TRACE_MAGIC = 32'h4e55_5453; // "NUTS"
    localparam [7:0]  TRACE_VERSION = 8'd1;

    reg [63:0] cycle_sequence;
    reg [63:0] commit_sequence;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            cycle_sequence  <= 64'd0;
            commit_sequence <= 64'd0;
        end else begin
            cycle_sequence <= cycle_sequence + 64'd1;
            if (commit_valid)
                commit_sequence <= commit_sequence + 64'd1;
        end
    end

    assign trace_data[0]       = commit_valid;
    assign trace_data[64:1]    = {{25{commit_pc[38]}}, commit_pc};
    assign trace_data[96:65]   = commit_instr;
    assign trace_data[97]      = commit_skip;
    assign trace_data[98]      = commit_instr[1:0] != 2'b11;
    assign trace_data[99]      = commit_rfwen;
    assign trace_data[104:100] = commit_rfdest;
    assign trace_data[168:105] = commit_rfdata;
    assign trace_data[169]     = redirect_valid;
    assign trace_data[208:170] = redirect_target;
    assign trace_data[211:209] = fu_type;
    assign trace_data[275:212] = commit_payload_0;
    assign trace_data[339:276] = commit_payload_1;
    assign trace_data[403:340] = commit_payload_2;
    assign trace_data[467:404] = commit_payload_3;
    assign trace_data[531:468] = cycle_sequence;
    assign trace_data[595:532] = commit_sequence;
    assign trace_data[627:596] = TRACE_MAGIC;
    assign trace_data[635:628] = TRACE_VERSION;
    assign trace_data[691:636] = 56'd0;
    // NutShell exposes a single-issue commit stream, not a cycle snapshot.
    // Writing idle WBU state every cycle would fill the passive trace FIFO
    // before DiffTest enables CPU execution. Emit exactly one trace record per
    // real commit; the transport may drop records but never stalls the CPU.
    assign trace_valid         = resetn && commit_valid;
endmodule
