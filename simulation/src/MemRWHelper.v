module MemRWHelper(
  
input             r_enable,
input      [63:0] r_index,
output reg [63:0] r_data,

  
input         w_enable,
input  [63:0] w_index,
input  [63:0] w_data,
input  [63:0] w_mask,

  input enable,
  input clock
);
  
// 1536MB memory
  `define RAM_SIZE (1536 * 1024 * 1024)

  // memory array
  reg [63:0] memory [0 : `RAM_SIZE/8 - 1];

  // memory read
  always @(posedge clock) begin
    if (enable) begin    
      if (r_enable) begin
        r_data <= memory[r_index];
      end
    end
  end

  // memory write
  always @(posedge clock) begin
    if (w_enable && enable) begin
      memory[w_index] <= (w_data & w_mask) | (memory[w_index] & ~w_mask);
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
        if (n_read < 8) begin
          for (integer k = n_read; k < 8; k++) begin
            word[k] = 8'h0;
          end
        end
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

endmodule
     