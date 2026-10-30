# YuQuan Simulation Adapter

This directory contains the simulation-only adapter between XiangShan, YuQuan, and difftest. The YuQuan source repository remains an external, read-only dependency.

Contents:

- `rtl/`: AXI and DFI wrapper RTL.
- `include/` and `src/dfi/`: DFI model and DPI integration.
- `config/`: virtual-memory address mappings.
- `tests/`: standalone DFI unit tests.

The difftest build loads `Makefile.difftest.mk` through its generic `EXTERNAL_MEMORY_BACKEND_MK` hook. The normal XiangShan build sets that hook and `YUQUAN_ADAPTER_HOME` automatically when env-scripts is checked out at `XiangShan/env-scripts`. The functional YuQuan RTL adapter is maintained in XiangShan under `scripts/yuquan/rtl`.

Run the standalone tests from this directory:

```bash
make test
```
