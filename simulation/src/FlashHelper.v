`ifdef SIM_USE_DPIC
import "DPI-C" function void flash_read
(
  input int addr,
  output longint data
);
`endif

module FlashHelper (
  input clk,
  input [31:0] addr,
  input ren,
  output reg [63:0] data
);

`ifdef SIM_USE_DPIC

  always @(posedge clk) begin
    if (ren) flash_read(addr, data);
  end

`else

  // 1K entries. 8KB size.
  `define FLASH_SIZE (8 * 1024)
  reg [7:0] flash_mem [0 : `FLASH_SIZE - 1];

  for (genvar i = 0; i < 8; i++) begin
    always @(posedge clk) begin
      if (ren) data[8 * i + 7 : 8 * i] <= flash_mem[addr + i];
    end
  end

`ifdef FLASH_IMAGE
  integer flash_image, n_read;
  // Create string-type FLASH_IMAGE
  `define STRINGIFY(x) `"x`"
  `define FLASH_IMAGE_S `STRINGIFY(`FLASH_IMAGE)
`endif // FLASH_IMAGE

  initial begin
    for (integer i = 0; i < `FLASH_SIZE; i++) begin
      flash_mem[i] = 8'h0;
    end
`ifdef FLASH_IMAGE
    flash_image = $fopen(`FLASH_IMAGE_S, "rb");
    n_read = $fread(flash_mem, flash_image);
    $fclose(flash_image);
    if (!n_read) begin
      $fatal(1, "Flash: cannot load image from %s.", `FLASH_IMAGE_S));
    end
    else begin
      $display("Flash: load %d bytes from %s.", n_read, `FLASH_IMAGE_S);
    end
`else
    // Used for pc = 0x8000_0000
    // flash_mem[0] = 64'h01f292930010029b;
    // Used for pc = 0x20_0000_0000
    flash_mem[ 0] = 8'h9b;
    flash_mem[ 1] = 8'h02;
    flash_mem[ 2] = 8'h10;
    flash_mem[ 3] = 8'h00;
    flash_mem[ 4] = 8'h93;
    flash_mem[ 5] = 8'h92;
    flash_mem[ 6] = 8'h52;
    flash_mem[ 7] = 8'h02;
    flash_mem[ 8] = 8'h67;
    flash_mem[ 9] = 8'h80;
    flash_mem[10] = 8'h02;
    flash_mem[11] = 8'h00;
`endif // FLASH_IMAGE
  end

`endif // SIM_USE_DPIC

endmodule
