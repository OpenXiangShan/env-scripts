# Simulation run on Palladium

## Run single XiangShan on Palladium:
1. Generate verilog of XiangShan
2. Copy code in build folder to env-scripts/simulation/src/build
3. Replace some file in build:
```
cp FlashHelper.v build & cp MemRWHelper.v build & cp SDHelper.v build & cp SimJTAG.v build
```
4. Generate filelist in src/build:
```
ls | grep .v > sim.f
```
5. Modify tb_top.v (if you change clock or reset signal)
6. Modify src/hw.f
```
tb_top.v
-F build/sim.f
```
7. Compile:  
  If you're using checkpoint to run it
```
copy gcpt.gz in ./images
make palladium-build-gcpt
```
  Else
```
make palladium-build
```
8. Run:
```
make palladium-run
```

## Run XiangShan with difftest on Palladium:
1. Generate verilog of XiangShan with basic-diff
2. Copy code in build and difftest folder to src/build, src/difftest
3. Replace some file in build:
```
cp FlashHelper.v build & cp MemRWHelper.v build & cp SDHelper.v build & cp SimJTAG.v build
```
4. Generate filelist in src/build:
```
ls | grep .v > sim.f
```
5. Modify tb_top.v  
  You should change tb_top.v according to difftest project you run, refer to difftest/src/test/vsrc/vcs/top.v, and modify parameters to use.
6. Compile:
```
make pldm-diff-build
```
7. Run:
```
make pldm-diff-run
```