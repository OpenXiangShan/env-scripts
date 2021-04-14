#! /usr/bin/env python3

class VerilogModuleGenerator(object):
  def __init__(self, name):
    self.name = name
    self.port_spec = []
    self.decl = []
    self.combinational = []
    self.sequential = []

  def __format_width(self, width):
    return "[{}:0] ".format(width-1) if width > 1 else ""

  def __format_depth(self, depth):
    return " [{}:0]".format(depth-1) if depth > 1 else ""

  def add_io(self, io_type, width, name):
    width_str = self.__format_width(width)
    self.port_spec.append(f'{io_type} {width_str}{name}')

  def add_input(self, width, name):
    self.add_io("input", width, name)

  def add_output(self, width, name):
    self.add_io("output", width, name)

  def add_decl(self, decl_type, width, name, depth=1):
    width_str = self.__format_width(width)
    depth_str = self.__format_depth(depth)
    self.decl.append(f"{decl_type} {width_str}{name}{depth_str};")

  def add_decl_reg(self, width, name, depth=1):
    self.add_decl("reg", width, name, depth)

  def add_decl_wire(self, width, name, depth=1):
    self.add_decl("wire", width, name, depth)

  def add_decl_line(self, line):
    self.decl.append(line)

  def add_assign(self, signal, value):
    self.add_combinational(f"assign {signal} = {value};")

  def add_sequential(self, line):
    self.sequential.append(line)

  def add_combinational(self, line):
    self.combinational.append(line)

  def generate(self, blackbox=""):
    body = "\
  %s\n\
  %s\n\
  %s\n" % ('\n  '.join(self.decl), '\n  '.join(self.sequential), '\n  '.join(self.combinational))

    s = "\nmodule %s(\n\
  %s\n\
);\n\
\n\
%s\
\n\
endmodule\n" % (self.name, ',\n  '.join(self.port_spec), body if not blackbox else blackbox)
    return s
