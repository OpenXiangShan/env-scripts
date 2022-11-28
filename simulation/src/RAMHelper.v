/***************************************************************************************
* Copyright (c) 2020-2021 Institute of Computing Technology, Chinese Academy of Sciences
* Copyright (c) 2020-2021 Peng Cheng Laboratory
*
* XiangShan is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/
`ifdef SIM_USE_DPIC
import "DPI-C" function void ram_write_helper
(
  input  longint    wIdx,
  input  longint    wdata,
  input  longint    wmask,
  input  bit        wen
);
import "DPI-C" function longint ram_read_helper
(
  input  bit        en,
  input  longint    rIdx
);
`endif // SIM_USE_DPIC

module RAMHelper(
  input         clk,
  input         en,
  input  [63:0] rIdx,
  output [63:0] rdata,
  input  [63:0] wIdx,
  input  [63:0] wdata,
  input  [63:0] wmask,
  input         wen
);

`ifdef SIM_USE_DPIC

  assign rdata = ram_read_helper(en, rIdx);

  always @(posedge clk) begin
    ram_write_helper(wIdx, wdata, wmask, wen && en);
  end

`else

  // 256MB memory
  `define RAM_SIZE (256 * 1024 * 1024)

  // memory array
  reg [7:0] memory [0 : `RAM_SIZE - 1];

  // memory read
  wire [63:0] raddr = rIdx << 3;
  for (genvar i = 0; i < 8; i++) begin
    assign rdata[8 * i + 7 : 8 * i] = memory[raddr + i];
  end

  // memory write
  wire [63:0] waddr = wIdx << 3;
  for (genvar i = 0; i < 8; i++) begin
    always @(posedge clk) begin
      if (wen && en) begin
        memory[waddr + i] <=
          (wdata [8 * i + 7 : 8 * i] &   wmask[8 * i + 7 : 8 * i]) |
          (memory[waddr + i]         & (~wmask[8 * i + 7 : 8 * i]));
      end
    end
  end

`ifdef MEMORY_IMAGE
  integer memory_image, n_read;
  // Create string-type MEMORY_IMAGE
  `define STRINGIFY(x) `"x`"
  `define MEMORY_IMAGE_S `STRINGIFY(`MEMORY_IMAGE)
`endif // MEMORY_IMAGE

  initial begin
    for (integer i = 0; i < `RAM_SIZE; i++) begin
      memory[i] = 8'h0;
    end
`ifdef MEMORY_IMAGE
    memory_image = $fopen(`MEMORY_IMAGE_S, "rb");
    n_read = $fread(memory, memory_image);
    $fclose(memory_image);
    if (!n_read) begin
      $fatal(1, "Memory: cannot load image from %s.", `MEMORY_IMAGE_S);
    end
    else begin
      $display("Memory: load %d bytes from %s.", n_read, `MEMORY_IMAGE_S);
    end
`else
    $fatal(1, "You must specify the MEMORY_IMAGE macro.");
`endif // MEMORY_IMAGE
  end

`endif // SIM_USE_DPIC

endmodule
