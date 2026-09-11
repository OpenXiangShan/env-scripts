#!/usr/bin/env python3
"""Exercise live core_def GeneralBD wiring without touching build RTL.

Default (DMA disabled): --functional-only checks legacy GBS1 FIFO/drain behavior.
Omitting --functional-only also runs the legacy strict hole sweep, which reports
its known disagreement with the core's reserved decoded-zero range.

--dma selects GBD1 and extracts the real config, router, endpoint and complete
AXI3-to-AXI4 adapter instances. The test drives the protected-IP host interfaces
and models the BAR/DDR slaves. It checks 1024+512-byte banks from two frames,
ACK semantics, aperture isolation, and DDR metadata/response wiring.

Both modes reject an old raw-address decode mutation; DMA additionally rejects
an adapter metadata wiring mutation. --skip-mutation runs just the baseline.
All mutations and generated sources live in a temporary directory.
"""
import argparse
import hashlib
import os
from pathlib import Path
import re
import resource
import subprocess
import tempfile


def resolve_conditionals(source, defines=()):
    """Resolve the small preprocessor subset around the extracted top block.

    core_def_xdma.sv contains mutually exclusive DMA and legacy endpoint/router
    branches.  Python extraction must select one branch before checking instance
    counts; otherwise both textual instances appear in the temporary snippet.
    """
    enabled = set(defines)
    out = []
    stack = [True]
    taken = []
    for line in source.splitlines(keepends=True):
        directive = re.match(r"\s*`(ifdef|ifndef|else|elsif|endif)\b(?:\s+(\w+))?", line)
        if not directive:
            if all(stack):
                out.append(line)
            continue
        kind, symbol = directive.groups()
        if kind in ("ifdef", "ifndef"):
            parent = all(stack)
            condition = (symbol in enabled) if kind == "ifdef" else (symbol not in enabled)
            stack.append(parent and condition)
            taken.append(parent and condition)
        elif kind == "else":
            if len(stack) == 1 or not taken:
                raise ValueError("unbalanced conditional in extraction source")
            parent = all(stack[:-1])
            stack[-1] = parent and not taken[-1]
            taken[-1] = True
        elif kind == "elsif":
            parent = all(stack[:-1])
            stack[-1] = parent and not taken[-1] and symbol in enabled
            taken[-1] = taken[-1] or stack[-1]
        else:
            if len(stack) == 1:
                raise ValueError("unbalanced `endif in extraction source")
            stack.pop()
            taken.pop()
    if len(stack) != 1:
        raise ValueError("unterminated conditional in extraction source")
    return "".join(out)


def extract(source, dma=False):
    # Slice a balanced region first: resolving the entire core would require
    # evaluating unrelated build macros and could erase the GBus branch.
    start = "  assign gbus_cfg_local_wr_addr ="
    end = "  assign gbus_cfg_rdata_vld ="
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError("GeneralBD extraction anchors changed; review the test adapter")
    first = source.index(start)
    last = source.index(";", source.index(end, first)) + 1
    defines = ("UVHS_GBUS_C2H_DMA",) if dma else ()
    block = resolve_conditionals(source[first:last], defines)
    instances = ["U_GBUS_C2H_FIFO", "U_GBUS_CONFIG_BRIDGE"]
    if dma:
        instances.append("U_GBUS_C2H_READ_ROUTER")
        # Instantiate the actual complete adapter, including its live routed
        # AR/R wiring and untouched write wiring; do not reconstruct connections.
        anchor = "  uvhs_axi3_to_axi4_adapter #"
        if source.count(anchor) != 1:
            raise ValueError("Missing/ambiguous actual AXI adapter")
        first = source.index(anchor)
        last = source.index("\n  );", first) + len("\n  );")
        block += "\n" + resolve_conditionals(source[first:last], defines)
        instances.append("U_GBUS_AXI_ADAPTER")
    elif "U_GBUS_C2H_READ_ROUTER" in block or "uvhs_gbus_c2h_dma #" in block:
        raise ValueError("Default extraction unexpectedly contains DMA RTL")
    for instance in instances:
        if block.count(instance) != 1:
            raise ValueError(f"Missing/ambiguous actual instance: {instance}")
    return block


def old_raw_decode(block):
    # Deliberately mutate ONLY the temporary C2H enable expressions. Keep the
    # downstream local-address wiring intact, reproducing the raw/local bug.
    for direction in ("wr", "rd"):
        pattern = rf"wire gbus_c2h_cfg_{direction}_en\s*=.*?;"
        matches = list(re.finditer(pattern, block, flags=re.S))
        if len(matches) != 1:
            raise ValueError("C2H enable declaration changed; cannot apply mutation")
        match = matches[0]
        original = match.group()
        mutated = original.replace(f"gbus_cfg_local_{direction}_addr",
                                   f"gbus_cfg_{direction}_addr")
        if original == mutated:
            raise ValueError("Expected local address absent from C2H enable")
        block = block[:match.start()] + mutated + block[match.end():]
    return block


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dma", action="store_true",
                        help="test live DMA decode/router/endpoint/AXI adapter integration")
    parser.add_argument("--skip-mutation", action="store_true")
    parser.add_argument("--functional-only", action="store_true",
                        help="skip strict hole sweep; reserved decoded-zero range remains unverified")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    rtl = root / "src/rtl/common"
    source = rtl / "core_def_xdma.sv"
    original = source.read_bytes()
    block = extract(original.decode(), dma=args.dma)
    top = "uvhs_gbus_c2h_dma_top_tb" if args.dma else "uvhs_generalbd_decode_tb"
    print(f"Decode source: {source}\nSHA256: {hashlib.sha256(original).hexdigest()}", flush=True)
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    results = {}
    variants = {"actual": block}
    if not args.skip_mutation:
        variants["old-raw-mutation"] = old_raw_decode(block)
        if args.dma:
            connection = ".s_arcache(gbus_routed_arcache)"
            if block.count(connection) != 1:
                raise ValueError("Actual adapter cache connection changed")
            variants["adapter-metadata-mutation"] = block.replace(connection, ".s_arcache(4'b0)")
    with tempfile.TemporaryDirectory(prefix="uvhs_generalbd_decode_") as tmp:
        for name, code in variants.items():
            work = Path(tmp) / name
            work.mkdir()
            (work / "core_generalbd_under_test.svh").write_text(code + "\n")
            command = ["/usr/local/bin/verilator", "--binary", "--timing", "--assert", "-Wall", "-Wno-fatal",
                       "--top-module", top, "--Mdir", str(work / "obj"),
                       f"-I{work}", str(rtl / "uvhs_gbus_axi_read_router.sv"),
                       str(rtl / "uvhs_gbus_c2h_dma.sv"),
                       str(rtl / "uvhs_gbus_c2h_fifo.sv"),
                       str(rtl / "uvhs_axis_async_fifo.sv"),
                       str(rtl / "uvhs_generalbd_axilite_bridge.sv"),
                       str(rtl / "uvhs_axi3_to_axi4_adapter.sv"),
                       str(root / "tests" / f"{top}.sv")]
            # Cached clang PCH embeds the previous TemporaryDirectory path.
            # Disable ccache only for this subprocess to keep reruns independent.
            build = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, timeout=180,
                                   env={**os.environ, "CCACHE_DISABLE": "1", "OBJCACHE": ""})
            if build.returncode:
                print(build.stdout)
                return 1
            simulation = [str(work / "obj" / f"V{top}")]
            if args.functional_only:
                simulation.append("+functional_only")
            run = subprocess.run(simulation,
                                 cwd=work, text=True, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, timeout=60)
            print(f"\n=== {name}: simulator exit {run.returncode} ===\n{run.stdout}", flush=True)
            results[name] = run
    if source.read_bytes() != original:
        print("ERROR: synthesis source changed during regression (test runner never writes it)")
        return 1
    mutation_ok = True
    if not args.skip_mutation:
        mutation = results["old-raw-mutation"]
        # In the historical bug raw 0x2208 accidentally hits the overly broad
        # data branch, so even the ID still passes. Require functional failures.
        mutation_ok = (mutation.returncode != 0
                       and "FAIL raw read 3000 responses=0 expected=1" in mutation.stdout
                       and "FAIL fill word count got=0 expected=256" in mutation.stdout)
        print("PASS old raw-address mutation rejected by fill AND data-window checks" if mutation_ok
              else "FAIL mutation was not rejected by the required functional assertions")
        if args.dma:
            wiring = results["adapter-metadata-mutation"]
            wiring_ok = wiring.returncode != 0 and "FAIL DDR AR metadata" in wiring.stdout
            mutation_ok &= wiring_ok
            print("PASS actual adapter metadata mutation rejected" if wiring_ok
                  else "FAIL adapter wiring mutation escaped integration checks")
    return 0 if results["actual"].returncode == 0 and mutation_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
