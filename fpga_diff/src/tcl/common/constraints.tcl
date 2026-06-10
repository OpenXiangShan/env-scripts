set constr_files [list \
  [file normalize ${constr_dir}/ddr.xdc] \
  [file normalize ${constr_dir}/fpga.xdc] \
  [file normalize ${constr_dir}/gmac_j5.xdc] \
  [file normalize ${constr_dir}/debug.xdc] \
]

set enable_ila 0
if {[info exists ::env(ENABLE_ILA)]} {
  set enable_ila_value [string tolower [string trim $::env(ENABLE_ILA)]]
  if {[lsearch -exact {1 true yes on} $enable_ila_value] >= 0} {
    set enable_ila 1
  }
}

if {$enable_ila} {
  puts "INFO: ENABLE_ILA=$::env(ENABLE_ILA); adding host-trigger ILA XDC"
  lappend constr_files [file normalize ${constr_dir}/xdma_ila.xdc]
} else {
  puts "INFO: ENABLE_ILA disabled; skipping host-trigger ILA XDC"
}
