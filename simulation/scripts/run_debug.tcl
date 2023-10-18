debug .
host bjos_emu
xc xt0 zt0 on -tbrun
date
run 680000000
date
database -open xs
probe -create -all -depth all tb_top -database xs
#xeset mtHost
xeset traceMemSize 10000
xeset triggerPos 100
run 10000
date
database -upload
date
xc off
exit