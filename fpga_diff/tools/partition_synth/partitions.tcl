########################################################################
# Partition declarations for this design.
#
#   {module  <partition> <top-module>}
#   {without <partition> <parent-module> <child-modules>}
#
# without accepts one or more immediate child modules. Each child is
# replaced with an automatically generated blackbox stub for that partition.
########################################################################

set ps_partition_specs {
  {module  external_llc_wrapper      ExternalLLCWrapper}
  {without external_llc_shell        ExternalLLC        {ExternalLLCWrapper}}
  {module  openncb                   OpenNCB}
  {module  memmisc                   MemMisc}
  {without xstop_shell               XSTop              {XSTile ExternalLLC OpenNCB MemMisc}}
  {without xstile_shell              XSTile             {XSCore L2Top}}
  {without xscore_shell              XSCore             {Frontend Backend MemBlock}}
  {module  frontend                  Frontend}
  {module  memblock                  MemBlock}
  {module  l2top                     L2Top}
  {without backend_without_ctrlblock Backend            {CtrlBlock}}
  {module  backend_ctrlblock         CtrlBlock}
}

# OOC clock mapping: {<shared-clock-name> <partition-top-port>}.
# Clock periods and global top-level ports stay in src/constr/common/clock_defs.tcl.
set ps_partition_clock_ports {
  external_llc_wrapper {{DEBUG_CLK_IN clock}}
  external_llc_shell   {{DEBUG_CLK_IN clock}}
  openncb              {{DEBUG_CLK_IN clock}}
  memmisc              {{DEBUG_CLK_IN clock}}
  xstop_shell          {{DEBUG_CLK_IN io_clock}}
  xstile_shell         {{DEBUG_CLK_IN clock}}
  xscore_shell         {{DEBUG_CLK_IN clock}}
  frontend             {{DEBUG_CLK_IN clock}}
  memblock             {{DEBUG_CLK_IN clock}}
  l2top                {{DEBUG_CLK_IN clock}}
  backend_without_ctrlblock {{DEBUG_CLK_IN clock}}
  backend_ctrlblock         {{DEBUG_CLK_IN clock}}
}
