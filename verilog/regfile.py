import math

from generator import VerilogModuleGenerator


def generate_cmp(addr_width, nw):
  addr_cmp_name = f"addr_cmp_{nw}w_{addr_width}b"
  gen = VerilogModuleGenerator(addr_cmp_name)
  gen.add_input(addr_width, f"ra")
  gen.add_output(nw, "by")
  for i in range(nw):
    gen.add_input(1, f"we{i}")
    gen.add_input(addr_width, f"wa{i}")
    if nw > 1:
      gen.add_assign(f"by[{i}]", f"we{i} && (ra == wa{i})")
    else:
      gen.add_assign(f"by", f"we{i} && (ra == wa{i})")
  return addr_cmp_name, gen.generate()

def generate_addr_dec(addr_width):
  depth = 2 ** addr_width
  addr_dec_name = f"addr_dec_{addr_width}x{depth}_with_en"
  gen = VerilogModuleGenerator(addr_dec_name)
  gen.add_input(1, "en")
  gen.add_input(addr_width, "addr")
  gen.add_output(depth, "dec")
  gen.add_decl_reg(depth, "dec_0")
  gen.add_sequential(f"always @(addr) begin")
  gen.add_sequential(f"  case(addr) // synopsys full_case parallel_case")
  for i in range(depth):
    msb = f"{depth-(i+1)}'b0, " if i != depth - 1 else ""
    lsb = f", {i}'b0" if i != 0 else ""
    gen.add_sequential(f"    {addr_width}'d{i}: dec_0 = {{{msb}1'b1{lsb}}};")
  gen.add_sequential(f"    default: dec_0 = {depth}'b1;")
  gen.add_sequential(f"  endcase")
  gen.add_sequential(f"end")
  gen.add_assign("dec", f"{{{depth}{{en}}}} & dec_0")
  return addr_dec_name, gen.generate()

def generate_regfile(width, depth, nw, nr):
  addr_width = math.ceil(math.log2(depth))
  full_depth = 2 ** addr_width
  regfile_name = f"sregfile_{depth}x{width}_{nw}w{nr}r"
  addr_dec_name = f"addr_dec_{addr_width}x{full_depth}_with_en"
  addr_cmp_name = f"addr_cmp_{nw}w_{addr_width}b"

  gen = VerilogModuleGenerator(regfile_name)
  # generate IOs
  gen.add_input(1, "clock")        
  for i in range(nw):
    gen.add_input(1, f"wen{i}")
    gen.add_input(addr_width, f"waddr{i}")
    gen.add_input(width, f"wdata{i}")
  for i in range(nr):
    gen.add_input(addr_width, f"raddr{i}")
    gen.add_output(width, f"rdata{i}")

  # generate signals
  gen.add_decl_reg(width, "reg_MEM", depth)
  for i in range(nw):
    gen.add_decl_reg(1, f"reg_wen{i}")
    gen.add_decl_reg(addr_width, f"reg_waddr{i}")
    gen.add_decl_reg(width, f"reg_wdata{i}")
    gen.add_decl_wire(full_depth, f"wdec{i}")
    gen.add_combinational(f"{addr_dec_name} u_wad{i}_dec ( .en(reg_wen{i}), .addr(reg_waddr{i}), .dec(wdec{i}) );")
  for i in range(nr):
    gen.add_decl_reg(addr_width, f"reg_raddr{i}")
    gen.add_decl_wire(width, f"rdata_{i}")
    gen.add_decl_wire(nw, f"by{i}")
    gen.add_decl_wire(width, f"by_data{i}")
    we = ", ".join(map(lambda j: f".we{j}(reg_wen{j})", range(nw)))
    wa = ", ".join(map(lambda j: f".wa{j}(reg_waddr{j})", range(nw)))
    gen.add_combinational(f"{addr_cmp_name} u_rad{i}_cmp ( .by(by{i}), .ra(reg_raddr{i}), {we}, {wa} );")
    gen.add_assign(f"rdata_{i}", f"reg_MEM[reg_raddr{i}]")
    if nw > 1:
      by_data = " | ".join(map(lambda j: f"{{{width}{{by{i}[{j}]}}}} & reg_wdata{j}", range(nw)))
    else:
      by_data = " | ".join(map(lambda j: f"{{{width}{{by{i}}}}} & reg_wdata{j}", range(nw)))
    gen.add_assign(f"by_data{i}", by_data)
    gen.add_assign(f"rdata{i}", f"(|by{i}) ? by_data{i} : rdata_{i}")
  # sequential circuits
  gen.add_sequential("always @(posedge clock) begin")
  for i in range(nw):
    gen.add_sequential(f"  if (wen{i}) reg_waddr{i} <= waddr{i};")
    gen.add_sequential(f"  reg_wen{i} <= wen{i};")
    gen.add_sequential(f"  reg_wdata{i} <= wdata{i};")
  for i in range(nr):
    gen.add_sequential(f"  reg_raddr{i} <= raddr{i};")
  gen.add_sequential("end")
  gen.add_sequential("always @(negedge clock) begin")
  for i in range(depth):
    wen = " || ".join(map(lambda j : f"wdec{j}[{i}]", range(nw)))
    wdata = " | ".join(map(lambda j: f"{{{width}{{wdec{j}[{i}]}}}} & reg_wdata{j}", range(nw)))
    gen.add_sequential(f"  if ({wen}) begin")
    gen.add_sequential(f"    reg_MEM[{i}] <= {wdata};")
    gen.add_sequential(f"  end")
  gen.add_sequential("end")
  return regfile_name, gen.generate(), (addr_dec_name, addr_cmp_name)

if __name__ == "__main__":
  print(generate_cmp(8, 19))
  print(generate_addr_dec(8))
  print(generate_regfile(17, 192, 19, 6))

