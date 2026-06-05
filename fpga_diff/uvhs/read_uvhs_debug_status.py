#!/usr/bin/env python3
"""Read the non-UHD CPU liveness debug window from /dev/xdma0_user."""

from __future__ import annotations

import argparse
import mmap
import os
import struct
import time


REGS = [
    (0x100, "magic"),
    (0x104, "status0_latched"),
    (0x108, "status1_live"),
    (0x10C, "startup_wait"),
    (0x110, "mem_ar_count"),
    (0x114, "mem_r_count"),
    (0x118, "axis_valid_count"),
    (0x11C, "last_mem_araddr"),
]

STATUS0_BITS = [
    (0, "sys_rstn_io"),
    (1, "cpu_rstn_io"),
    (2, "xdma_link_up"),
    (3, "io_host_reset"),
    (4, "io_host_diff_enable"),
    (5, "difftest_startup_done"),
    (6, "difftest_c2h_rstn"),
    (7, "difftest_stream_enable"),
    (8, "axis_valid_io_live"),
    (9, "axis_ready_io_live"),
    (10, "axis_last_live"),
    (11, "mem_ar_seen"),
    (12, "mem_r_seen"),
    (13, "mem_aw_seen"),
    (14, "mem_w_seen"),
    (15, "mem_b_seen"),
    (16, "axis_valid_seen"),
    (17, "axis_last_seen"),
]

STATUS1_BITS = [
    (0, "axis_valid_io"),
    (1, "axis_valid_raw"),
    (2, "axis_ready_gated"),
    (3, "axis_last"),
    (4, "io_host_ila_trigger"),
    (5, "difftest_clock_enable"),
    (6, "mem_arvalid"),
    (7, "mem_arready"),
    (8, "mem_rvalid"),
    (9, "mem_rready"),
    (10, "mem_awready"),
    (11, "mem_awvalid"),
    (12, "mem_wready"),
    (13, "mem_wvalid"),
    (14, "mem_bready"),
    (15, "mem_bvalid"),
]


def read32(mm: mmap.mmap, addr: int) -> int:
    mm.seek(addr)
    return struct.unpack_from("<I", mm.read(4))[0]


def fmt_bits(value: int, bits: list[tuple[int, str]]) -> str:
    names = [name for bit, name in bits if value & (1 << bit)]
    return ", ".join(names) if names else "none"


def dump_once(mm: mmap.mmap) -> dict[str, int]:
    values = {name: read32(mm, addr) for addr, name in REGS}
    if values["magic"] != 0x55484442:
        print(f"magic=0x{values['magic']:08x} (unexpected, expected 0x55484442)")
    else:
        print("magic=0x55484442")
    print(f"status0=0x{values['status0_latched']:08x} [{fmt_bits(values['status0_latched'], STATUS0_BITS)}]")
    print(f"status1=0x{values['status1_live']:08x} [{fmt_bits(values['status1_live'], STATUS1_BITS)}]")
    print(
        "startup_wait=0x{startup_wait:05x} mem_ar={mem_ar_count} mem_r={mem_r_count} "
        "axis_valid={axis_valid_count} last_araddr=0x{last_mem_araddr:08x}".format(**values)
    )
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dev", default="/dev/xdma0_user")
    parser.add_argument("--interval", type=float, default=0.0, help="repeat interval in seconds")
    parser.add_argument("--count", type=int, default=1, help="number of samples; 0 means forever")
    args = parser.parse_args()

    fd = os.open(args.dev, os.O_RDWR | os.O_SYNC)
    try:
        with mmap.mmap(fd, 0x1000, mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE, offset=0) as mm:
            sample = 0
            while args.count == 0 or sample < args.count:
                if sample:
                    print()
                print(f"sample={sample}")
                dump_once(mm)
                sample += 1
                if args.interval <= 0 or (args.count != 0 and sample >= args.count):
                    break
                time.sleep(args.interval)
    finally:
        os.close(fd)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
