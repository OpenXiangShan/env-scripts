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

  // 1536MB memory
  `define RAM_SIZE (1536 * 1024 * 1024)

  // memory array
  reg [63:0] memory [0 : `RAM_SIZE/8 - 1];

  // memory read
  assign rdata = memory[rIdx];

  // memory write
  always @(posedge clk) begin
    if (wen && en) begin
      memory[wIdx] <= (wdata & wmask) | (memory[wIdx] & ~wmask);
    end
  end

`ifdef MEMORY_IMAGE
  integer memory_image, n_read;
  reg [7:0] word [7:0];
  // Create string-type MEMORY_IMAGE
  `define STRINGIFY(x) `"x`"
  `define MEMORY_IMAGE_S `STRINGIFY(`MEMORY_IMAGE)
`endif // MEMORY_IMAGE

  initial begin
    for (integer i = 0; i < `RAM_SIZE/8; i++) begin
      memory[i] = 64'h0;
    end
`ifdef MEMORY_IMAGE
    memory_image = $fopen(`MEMORY_IMAGE_S, "rb");
    for (integer j = 0; j < `RAM_SIZE/8; j++) begin
      if (!$feof(memory_image)) begin
        n_read = $fread(word, memory_image);
        memory[j] = {word[7],word[6],word[5],word[4],word[3],word[2],word[1],word[0]};
      end else begin
        $display("memory[0]:%h",memory[0]);
        break;
      end
    end
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
