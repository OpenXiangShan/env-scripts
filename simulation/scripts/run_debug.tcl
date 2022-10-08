database -open -vcd -maxsize 5G xs
probe -create -all -depth all -database xs
xc xt0 zt0 run
run 100000
database -upload
xc off
exit
