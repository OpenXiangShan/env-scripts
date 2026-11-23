"""Check the packaged DDR wrapper against the selected Vivado checkpoint."""

import re
import sys
from pathlib import Path
from zipfile import BadZipFile, ZipFile


def ecc_mode(stub):
    match = re.search(r'\bp_ecc_en\s*=\s*"([^"]+)"', stub)
    return match[1] if match else None


def ports(stub):
    return {
        name: (direction, re.sub(r"\s+", "", width or ""))
        for direction, width, name in re.findall(
            r"^\s*(input|output|inout)\s*(\[[^\]]+\])?\s*(\w+)\s*;",
            stub,
            re.MULTILINE,
        )
    }


def verify(mode, wrapper, checkpoint):
    wrapper_text = Path(wrapper).read_text()
    if ecc_mode(wrapper_text) not in ({None, "0"} if mode == "0" else {"1"}):
        raise ValueError(f"{wrapper} does not match DDR_ECC={mode}")

    with ZipFile(checkpoint) as archive:
        stubs = [
            name for name in archive.namelist()
            if Path(name).name == "uvw_axi4_to_ddr4_stub.v"
        ]
        if mode == "0" and not stubs:
            return
        if len(stubs) != 1:
            raise ValueError(f"{checkpoint} needs one embedded DDR Verilog stub")
        embedded = archive.read(stubs[0]).decode()

    if ecc_mode(embedded) not in ({None, "0"} if mode == "0" else {"1"}):
        raise ValueError(f"{checkpoint} does not match DDR_ECC={mode}")
    if mode == "1":
        wrapper_ports = ports(wrapper_text)
        if not wrapper_ports or wrapper_ports != ports(embedded):
            raise ValueError("DDR ECC Stub port declarations differ from the DCP")
        if not re.search(
            r"`pragma protect begin_protected.*?`pragma protect end_protected",
            wrapper_text,
            re.DOTALL,
        ):
            raise ValueError("DDR ECC Stub is missing the vendor registration block")


if __name__ == "__main__":
    try:
        mode, wrapper, checkpoint = sys.argv[1:]
        if mode not in {"0", "1"}:
            raise ValueError("DDR_ECC must be 0 or 1")
        verify(mode, wrapper, checkpoint)
    except (BadZipFile, OSError, ValueError) as error:
        sys.exit(f"ERROR: {error}. Supply a matching UVHS DDR package.")
    print(f"INFO: verified UVHS DDR package (DDR_ECC={mode})")
