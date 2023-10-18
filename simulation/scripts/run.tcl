debug .
host bjos_emu
#run 1ns
xc zt0 xt0 on -tbrun
date
run
date
xc off
date
exit