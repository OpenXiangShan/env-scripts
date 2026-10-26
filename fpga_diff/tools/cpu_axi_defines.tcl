set cpu [lindex $argv 0]
source [file join [file dirname [info script]] .. src tcl common cpu_axi.tcl]
foreach define $cpu_axi_defines { puts "+define+$define" }
