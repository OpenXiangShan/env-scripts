#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

import cpu_rtl_interface as rtl_if

IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_$]*")
MODULE_RE = re.compile(r"(?m)^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\b")
ENDMODULE_RE = re.compile(r"(?m)^\s*endmodule\b")

strip_comments = rtl_if.strip_comments
strip_comments_preserve_offsets = rtl_if.strip_comments_preserve_offsets
normalize_ws = rtl_if.normalize_ws
line_no = rtl_if.line_no
find_matching_paren = rtl_if.find_matching_paren
split_top_level_commas = rtl_if.split_top_level_commas
parse_width = rtl_if.parse_width
stable_json_hash = rtl_if.stable_json_hash


def locate_simtop(path_arg: str, module_name: str) -> tuple[Path, Path | None]:
    path = Path(path_arg).resolve()
    candidates: list[Path] = []
    release_root: Path | None = None

    if path.is_file():
        candidates.append(path)
        release_root = None
    elif (path / "build" / "rtl" / f"{module_name}.sv").is_file():
        release_root = path
        candidates.append(path / "build" / "rtl" / f"{module_name}.sv")
    elif (path / f"{module_name}.sv").is_file():
        candidates.append(path / f"{module_name}.sv")
        release_root = path.parent.parent if path.name == "rtl" else None
    else:
        candidates.extend(path.rglob(f"{module_name}.sv") if path.is_dir() else [])

    if not candidates:
        raise SystemExit(f"ERROR: cannot find {module_name}.sv under {path}")
    simtop_path = sorted(candidates, key=lambda p: len(p.as_posix()))[0]
    return simtop_path, release_root


def module_region(text: str, module_name: str) -> tuple[int, int, int, int]:
    match = re.search(rf"(?m)^\s*module\s+{re.escape(module_name)}\b", text)
    if not match:
        raise SystemExit(f"ERROR: module not found: {module_name}")

    open_idx = text.find("(", match.end())
    if open_idx < 0:
        raise SystemExit(f"ERROR: module header has no port list: {module_name}")
    close_idx = find_matching_paren(text, open_idx)
    semi_idx = text.find(";", close_idx)
    if semi_idx < 0:
        raise SystemExit(f"ERROR: module header has no terminating semicolon: {module_name}")

    end_match = ENDMODULE_RE.search(text, semi_idx)
    if not end_match:
        raise SystemExit(f"ERROR: module has no endmodule: {module_name}")
    return match.start(), open_idx, semi_idx, end_match.end()


def module_header_text(text: str, module_name: str) -> str:
    module_start, _open_idx, header_end, _module_end = module_region(text, module_name)
    return text[module_start:header_end]


def locate_module_rtl(release_root: Path | None, simtop_path: Path, module_name: str) -> Path | None:
    candidates: list[Path] = []
    if release_root:
        candidates.append(release_root / "build" / "rtl" / f"{module_name}.sv")
    candidates.append(simtop_path.parent / f"{module_name}.sv")
    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()
    return None


def parse_header_ports(header_text: str) -> list[dict]:
    body = header_text[header_text.find("(") + 1: header_text.rfind(")")]
    body = strip_comments(body)
    ports: list[dict] = []
    current_direction = ""
    current_range = ""
    current_kind = ""

    for raw in split_top_level_commas(body):
        item = normalize_ws(raw)
        if not item:
            continue

        direction_match = re.match(r"^(input|output|inout)\b\s*(.*)$", item)
        if direction_match:
            current_direction = direction_match.group(1)
            item = direction_match.group(2).strip()
            current_range = ""
            current_kind = ""

        kind_match = re.match(r"^(wire|reg|logic)\b\s*(.*)$", item)
        if kind_match:
            current_kind = kind_match.group(1)
            item = kind_match.group(2).strip()

        range_match = re.match(r"^(\[[^\]]+\])\s*(.*)$", item)
        if range_match:
            current_range = normalize_ws(range_match.group(1))
            item = range_match.group(2).strip()

        name_match = re.search(r"([A-Za-z_][A-Za-z0-9_$]*)\s*$", item)
        if not name_match:
            continue
        name = name_match.group(1)
        ports.append({
            "name": name,
            "direction": current_direction,
            "kind": current_kind,
            "range": current_range,
            "width": parse_width(current_range) or 1,
            "area": classify_port(name),
            "family": port_family(name),
        })
    return ports


def parse_declared_signals(body_text: str) -> dict[str, dict]:
    clean = strip_comments(body_text)
    signals: dict[str, dict] = {}
    decl_re = re.compile(r"(?m)^\s*(wire|reg|logic)\s+([^;]+);")

    for match in decl_re.finditer(clean):
        kind = match.group(1)
        rest = normalize_ws(match.group(2))
        range_text = ""
        range_match = re.match(r"^(\[[^\]]+\])\s*(.*)$", rest)
        if range_match:
            range_text = normalize_ws(range_match.group(1))
            rest = range_match.group(2)
        for raw_name in split_top_level_commas(rest):
            name_part = raw_name.split("=", 1)[0].strip()
            name_match = re.match(r"([A-Za-z_][A-Za-z0-9_$]*)", name_part)
            if not name_match:
                continue
            name = name_match.group(1)
            signals[name] = {
                "name": name,
                "kind": kind,
                "range": range_text,
                "width": parse_width(range_text) or 1,
            }
    return signals


def parse_connection_list(text: str) -> dict[str, str]:
    conns: dict[str, str] = {}
    idx = 0
    while idx < len(text):
        match = re.search(r"\.\s*([A-Za-z_][A-Za-z0-9_$]*)\s*\(", text[idx:])
        if not match:
            break
        port = match.group(1)
        open_idx = idx + match.end() - 1
        close_idx = find_matching_paren(text, open_idx)
        expr = normalize_ws(text[open_idx + 1:close_idx])
        conns[port] = expr
        idx = close_idx + 1
    return conns


def parse_instances(text: str, body_start: int, body_end: int) -> list[dict]:
    body = text[body_start:body_end]
    clean = strip_comments_preserve_offsets(body)
    inst_re = re.compile(
        r"(?m)^\s*([A-Za-z_][A-Za-z0-9_$]*)\s+"
        r"(?:#\s*\((?:.|\n)*?\)\s*)?"
        r"([A-Za-z_][A-Za-z0-9_$]*)\s*\("
    )
    instances: list[dict] = []
    search_idx = 0
    while True:
        match = inst_re.search(clean, search_idx)
        if not match:
            break
        module = match.group(1)
        name = match.group(2)
        if module in {"if", "else", "for", "while", "always", "assign", "initial"}:
            search_idx = match.end()
            continue
        open_idx = match.end() - 1
        try:
            close_idx = find_matching_paren(clean, open_idx)
        except ValueError:
            search_idx = match.end()
            continue
        semi_idx = clean.find(";", close_idx)
        if semi_idx < 0:
            search_idx = close_idx + 1
            continue
        conn_text = clean[open_idx + 1:close_idx]
        start_offset = body_start + match.start()
        instances.append({
            "module": module,
            "name": name,
            "area": classify_instance(module, name),
            "line": line_no(text, start_offset),
            "connections": parse_connection_list(conn_text),
        })
        search_idx = semi_idx + 1
    return instances


def classify_instance(module: str, name: str) -> str:
    haystack = f"{module} {name}"
    if name == "cpu" or re.search(r"\b(NutShell|XSTop|XSCore|XSTile|Nanhu|XiangShan)\b", haystack):
        return "cpu"
    if re.search(r"\b(Gateway|GatewayEndpoint|Endpoint)\b", haystack):
        return "difftest_gateway"
    if "DifftestMemCtrl" in haystack:
        return "difftest_memory_transport"
    if re.search(r"XDMA|HostEndpoint|ConfigBar", haystack):
        return "difftest_transport"
    if re.search(r"\b(Difftest|DiffTest|Batch|Delta|ClockGate)\b", haystack):
        return "difftest"
    return "unknown"


def port_family(name: str) -> str:
    if name in {"clock", "reset"} or name.endswith("_clock") or name.endswith("_clk"):
        return "clock_reset"
    if name.startswith("difftest_cfg_axilite_"):
        return "difftest_cfg_axilite"
    if name.startswith("difftest_to_host_axis_"):
        return "difftest_to_host_axis"
    if name.startswith("difftest_from_host_axis_"):
        return "difftest_from_host_axis"
    if name.startswith("difftest_hostCtrl_"):
        return "difftest_host_control"
    if name.startswith("difftest_mem_"):
        return "difftest_external_memory_axi"
    if name.startswith("difftest_") and name in {
        "difftest_ref_clock",
        "difftest_ref_reset",
        "difftest_pcie_clock",
        "difftest_clock_enable",
    }:
        return "difftest_clock_control"
    if name.startswith("difftest_"):
        return "difftest_status_control"
    if name.startswith("io_"):
        return "cpu_soc_io"
    return "top_other"


def classify_port(name: str) -> str:
    family = port_family(name)
    if family in {"clock_reset", "cpu_soc_io", "top_other"}:
        return "cpu_or_top"
    if family in {
        "difftest_cfg_axilite",
        "difftest_to_host_axis",
        "difftest_from_host_axis",
        "difftest_host_control",
        "difftest_clock_control",
    }:
        return "difftest_transport"
    if family == "difftest_external_memory_axi":
        return "difftest_memory_transport"
    return "difftest_status_control"


def signal_refs(expr: str) -> list[str]:
    refs = []
    for token in IDENT_RE.findall(expr):
        if token in {"h", "b", "d", "x", "z"}:
            continue
        if re.fullmatch(r"[0-9]+", token):
            continue
        refs.append(token)
    return refs


def count_by(items: list[dict], key: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for item in items:
        value = item.get(key, "unknown") or "unknown"
        counts[value] = counts.get(value, 0) + 1
    return counts


def port_lookup(ports: list[dict]) -> dict[str, dict]:
    return {port["name"]: port for port in ports}


def first_instance(instances: list[dict], area: str) -> dict | None:
    for inst in instances:
        if inst["area"] == area:
            return inst
    return None


def instances_by_area(instances: list[dict], area: str) -> list[dict]:
    return [inst for inst in instances if inst["area"] == area]


def public_instance(inst: dict) -> dict:
    return {
        "name": inst["name"],
        "module": inst["module"],
        "area": inst["area"],
        "line": inst["line"],
        "connection_count": len(inst["connections"]),
    }


def enrich_connection_with_cpu_port(
    row: dict,
    cpu_ports: dict[str, dict],
) -> dict:
    enriched = dict(row)
    cpu_port = cpu_ports.get(row["port"], {})
    if cpu_port:
        enriched["cpu_direction"] = cpu_port.get("direction", "")
        enriched["cpu_range"] = cpu_port.get("range", "")
        enriched["cpu_width"] = cpu_port.get("width")
    return enriched


def canonical_partition_port(row: dict, role: str) -> dict:
    direction = row.get("cpu_direction", "")
    if role == "difftest_probe_output":
        direction = "output"
    return {
        "name": row["port"],
        "role": role,
        "direction": direction,
        "width": row.get("cpu_width") or row.get("width") or 1,
        "range": row.get("cpu_range") or "",
        "expr": row.get("expr", ""),
    }


def build_cpu_partition_manifest(
    simtop_path: Path,
    release_root: Path | None,
    interfaces: dict,
    instances: list[dict],
) -> dict:
    cpu = first_instance(instances, "cpu")
    if not cpu:
        return {}

    cpu_rtl = locate_module_rtl(release_root, simtop_path, cpu["module"])
    cpu_ports: dict[str, dict] = {}
    cpu_header_hash = ""
    if cpu_rtl:
        cpu_text = cpu_rtl.read_text(errors="replace")
        cpu_header = module_header_text(cpu_text, cpu["module"])
        cpu_ports = port_lookup(parse_header_ports(cpu_header))
        cpu_header_hash = stable_json_hash(port_summary(list(cpu_ports.values())))

    def enrich(rows: list[dict]) -> list[dict]:
        return [enrich_connection_with_cpu_port(row, cpu_ports) for row in rows]

    clock_reset = enrich(interfaces["cpu_clock_reset_connections"])
    soc = enrich(interfaces["cpu_soc_top_port_connections"])
    memory = enrich(interfaces["cpu_memory_connections"])
    probes = enrich(interfaces["cpu_gateway_probe_outputs"])

    partition_ports = (
        [canonical_partition_port(row, "clock_reset") for row in clock_reset]
        + [canonical_partition_port(row, "soc_top_port") for row in soc]
        + [canonical_partition_port(row, "memory_axi_cpu_side") for row in memory]
        + [canonical_partition_port(row, "difftest_probe_output") for row in probes]
    )
    interface_payload = {
        "cpu_module": cpu["module"],
        "cpu_instance": cpu["name"],
        "partition_ports": partition_ports,
    }

    return {
        "schema_version": 1,
        "purpose": "source-level CpuDcpTop boundary seed for CPU-DCP reuse",
        "cpu_module": cpu["module"],
        "cpu_instance": cpu["name"],
        "cpu_rtl": str(cpu_rtl) if cpu_rtl else "",
        "cpu_header_hash": cpu_header_hash,
        "interface_hash": stable_json_hash(interface_payload),
        "port_counts": {
            "clock_reset": len(clock_reset),
            "soc_top_ports": len(soc),
            "memory_axi_cpu_side": len(memory),
            "difftest_probe_outputs": len(probes),
            "total": len(partition_ports),
        },
        "partition_ports": partition_ports,
        "source_level_requirements": [
            "CPU elaboration must export these partition ports from CpuDcpTop.",
            "FPGA shell elaboration must consume the same interface hash without elaborating CPU internals.",
            "Gateway bundle order, widths, delays, and generated DiffTest metadata must be persisted with this manifest.",
        ],
    }


def port_summary(ports: list[dict], family: str | None = None) -> list[dict]:
    selected = ports if family is None else [port for port in ports if port["family"] == family]
    return [
        {
            "name": port["name"],
            "direction": port["direction"],
            "range": port["range"],
            "width": port["width"],
            "family": port["family"],
        }
        for port in selected
    ]


def annotate_connection(port_name: str, expr: str, signals: dict[str, dict], top_ports: dict[str, dict]) -> dict:
    refs = signal_refs(expr)
    primary = refs[0] if len(refs) == 1 else ""
    width = None
    if primary and primary in signals:
        width = signals[primary].get("width")
    elif primary and primary in top_ports:
        width = top_ports[primary].get("width")
    return {
        "port": port_name,
        "expr": expr,
        "signal_refs": refs,
        "primary_signal": primary,
        "width": width,
    }


def build_interface_contract(ports: list[dict], instances: list[dict], signals: dict[str, dict]) -> dict:
    top_ports = port_lookup(ports)
    cpu = first_instance(instances, "cpu")
    gateway = first_instance(instances, "difftest_gateway")
    memctrl = first_instance(instances, "difftest_memory_transport")

    cpu_memory: list[dict] = []
    cpu_probes: list[dict] = []
    cpu_soc_ports: list[dict] = []
    cpu_clocks_resets: list[dict] = []
    cpu_other: list[dict] = []

    if cpu:
        for port_name, expr in sorted(cpu["connections"].items()):
            row = annotate_connection(port_name, expr, signals, top_ports)
            if port_name.startswith("io_mem_"):
                cpu_memory.append(row)
            elif "gatewayIn_packed" in port_name or any("gatewayIn_packed" in ref for ref in row["signal_refs"]):
                cpu_probes.append(row)
            elif expr in top_ports and top_ports[expr]["family"] == "cpu_soc_io":
                cpu_soc_ports.append(row)
            elif port_name in {"clock", "reset"}:
                cpu_clocks_resets.append(row)
            else:
                cpu_other.append(row)

    memctrl_cpu_side: list[dict] = []
    memctrl_external_side: list[dict] = []
    if memctrl:
        for port_name, expr in sorted(memctrl["connections"].items()):
            row = annotate_connection(port_name, expr, signals, top_ports)
            if port_name.startswith("io_cpu_"):
                memctrl_cpu_side.append(row)
            elif port_name.startswith("io_mem_"):
                memctrl_external_side.append(row)

    gateway_inputs: list[dict] = []
    gateway_outputs: list[dict] = []
    if gateway:
        for port_name, expr in sorted(gateway["connections"].items()):
            row = annotate_connection(port_name, expr, signals, top_ports)
            if port_name in {"clock", "reset", "in", "fpgaIO_ready"}:
                gateway_inputs.append(row)
            else:
                gateway_outputs.append(row)

    memory_links: list[dict] = []
    memctrl_by_expr = {row["expr"]: row for row in memctrl_cpu_side}
    for row in cpu_memory:
        link = {
            "cpu_port": row["port"],
            "cpu_expr": row["expr"],
            "width": row["width"],
        }
        peer = memctrl_by_expr.get(row["expr"])
        if peer:
            link["memctrl_port"] = peer["port"]
        memory_links.append(link)

    return {
        "cpu_clock_reset_connections": cpu_clocks_resets,
        "cpu_soc_top_port_connections": cpu_soc_ports,
        "cpu_memory_connections": cpu_memory,
        "cpu_memory_to_difftest_memctrl_links": memory_links,
        "cpu_gateway_probe_outputs": cpu_probes,
        "cpu_other_connections": cpu_other,
        "gateway_inputs": gateway_inputs,
        "gateway_outputs": gateway_outputs,
        "memctrl_cpu_side_connections": memctrl_cpu_side,
        "memctrl_external_memory_connections": memctrl_external_side,
        "top_level_ports": {
            "clock_reset": port_summary(ports, "clock_reset"),
            "cpu_soc_io": port_summary(ports, "cpu_soc_io"),
            "difftest_status_control": port_summary(ports, "difftest_status_control"),
            "difftest_clock_control": port_summary(ports, "difftest_clock_control"),
            "difftest_cfg_axilite": port_summary(ports, "difftest_cfg_axilite"),
            "difftest_to_host_axis": port_summary(ports, "difftest_to_host_axis"),
            "difftest_from_host_axis": port_summary(ports, "difftest_from_host_axis"),
            "difftest_host_control": port_summary(ports, "difftest_host_control"),
            "difftest_external_memory_axi": port_summary(ports, "difftest_external_memory_axi"),
        },
    }


def build_candidates(instances: list[dict], interfaces: dict) -> dict:
    cpu = first_instance(instances, "cpu")
    gateway = first_instance(instances, "difftest_gateway")
    transport = (
        instances_by_area(instances, "difftest_transport")
        + instances_by_area(instances, "difftest_memory_transport")
    )
    cpu_name = cpu["name"] if cpu else ""
    gateway_name = gateway["name"] if gateway else ""
    transport_names = [inst["name"] for inst in transport]

    cpu_only_ports = {
        "clock_reset": interfaces["cpu_clock_reset_connections"],
        "soc_top_ports": interfaces["cpu_soc_top_port_connections"],
        "memory_axi_cpu_side": interfaces["cpu_memory_connections"],
        "difftest_probe_packed_outputs": interfaces["cpu_gateway_probe_outputs"],
    }
    cpu_plus_gateway_ports = {
        "clock_reset": interfaces["cpu_clock_reset_connections"],
        "gateway_clock_reset": interfaces["gateway_inputs"],
        "soc_top_ports": interfaces["cpu_soc_top_port_connections"],
        "memory_axi_cpu_side": interfaces["cpu_memory_connections"],
        "gateway_fpga_stream": interfaces["gateway_outputs"],
    }

    return {
        "cpu_only": {
            "goal": "Maximize CPU DCP reuse when DiffTest/Gateway/transport implementation changes but probe layout and CPU RTL stay unchanged.",
            "include_instances": [name for name in [cpu_name] if name],
            "exclude_instances": [name for name in [gateway_name] if name] + transport_names,
            "boundary_ports": cpu_only_ports,
            "invalidated_by": [
                "CPU RTL or CPU config changes",
                "gatewayIn_packed probe count/width/layout changes",
                "CPU memory AXI shape changes",
                "CPU clock/reset semantics at the partition boundary change",
            ],
        },
        "cpu_plus_gateway": {
            "goal": "Smaller first prototype for transport-only edits; Gateway changes invalidate this checkpoint.",
            "include_instances": [name for name in [cpu_name, gateway_name] if name],
            "exclude_instances": transport_names,
            "boundary_ports": cpu_plus_gateway_ports,
            "invalidated_by": [
                "CPU RTL or CPU config changes",
                "GatewayEndpoint implementation changes",
                "Gateway fpgaIO stream width or ready/valid semantics change",
                "CPU memory AXI shape changes",
            ],
        },
    }


def build_checks(instances: list[dict], interfaces: dict) -> list[dict]:
    cpu_instances = instances_by_area(instances, "cpu")
    gateway_instances = instances_by_area(instances, "difftest_gateway")
    transport_instances = (
        instances_by_area(instances, "difftest_transport")
        + instances_by_area(instances, "difftest_memory_transport")
    )
    checks = [
        {
            "name": "single_cpu_instance",
            "passed": len(cpu_instances) == 1,
            "detail": f"cpu_instances={[inst['name'] for inst in cpu_instances]}",
        },
        {
            "name": "gateway_present",
            "passed": len(gateway_instances) >= 1,
            "detail": f"gateway_instances={[inst['name'] for inst in gateway_instances]}",
        },
        {
            "name": "transport_present_in_current_simtop",
            "passed": len(transport_instances) > 0,
            "detail": f"transport_instances={[inst['name'] for inst in transport_instances]}",
        },
        {
            "name": "current_simtop_is_not_cpu_only_checkpoint",
            "passed": len(transport_instances) == 0 and len(gateway_instances) == 0,
            "detail": (
                "Current SimTop still contains DiffTest/Gateway transport logic; "
                "a new CpuDcpTop boundary is required before cell-level CPU DCP reuse."
            ),
        },
        {
            "name": "cpu_memory_links_detected",
            "passed": len(interfaces["cpu_memory_to_difftest_memctrl_links"]) > 0,
            "detail": f"links={len(interfaces['cpu_memory_to_difftest_memctrl_links'])}",
        },
        {
            "name": "cpu_probe_outputs_detected",
            "passed": len(interfaces["cpu_gateway_probe_outputs"]) > 0,
            "detail": f"probe_ports={len(interfaces['cpu_gateway_probe_outputs'])}",
        },
    ]
    return checks


def extract_contract(simtop_path: Path, release_root: Path | None, module_name: str) -> dict:
    text = simtop_path.read_text(errors="replace")
    module_start, open_idx, header_end, module_end = module_region(text, module_name)
    header = text[module_start:header_end]
    body_start = header_end + 1
    body = text[body_start:module_end]

    ports = parse_header_ports(header)
    signals = parse_declared_signals(body)
    instances = parse_instances(text, body_start, module_end)
    interfaces = build_interface_contract(ports, instances, signals)
    cpu_partition_manifest = build_cpu_partition_manifest(
        simtop_path,
        release_root,
        interfaces,
        instances,
    )
    checks = build_checks(instances, interfaces)

    transport_instances = (
        instances_by_area(instances, "difftest_transport")
        + instances_by_area(instances, "difftest_memory_transport")
    )
    gateway_instances = instances_by_area(instances, "difftest_gateway")
    cpu_instances = instances_by_area(instances, "cpu")

    return {
        "schema_version": 1,
        "release": str(release_root) if release_root else "",
        "simtop_path": str(simtop_path),
        "module": {
            "name": module_name,
            "line": line_no(text, module_start),
            "ports": len(ports),
            "declared_signals": len(signals),
            "instances": len(instances),
        },
        "counts": {
            "ports_by_family": count_by(ports, "family"),
            "ports_by_area": count_by(ports, "area"),
            "instances_by_area": count_by(instances, "area"),
        },
        "instances": [public_instance(inst) for inst in instances],
        "cpu_instances": [public_instance(inst) for inst in cpu_instances],
        "gateway_instances": [public_instance(inst) for inst in gateway_instances],
        "transport_instances": [public_instance(inst) for inst in transport_instances],
        "current_boundary": {
            "simtop_contains_cpu": bool(cpu_instances),
            "simtop_contains_gateway": bool(gateway_instances),
            "simtop_contains_difftest_transport": bool(transport_instances),
            "cpu_only_checkpoint_candidate": bool(cpu_instances) and not gateway_instances and not transport_instances,
            "conclusion": (
                "mixed-simtop-needs-cpudcptop"
                if gateway_instances or transport_instances
                else "simtop-may-be-cpu-only"
            ),
        },
        "interfaces": interfaces,
        "cpu_partition_manifest": cpu_partition_manifest,
        "candidate_boundaries": build_candidates(instances, interfaces),
        "checks": checks,
    }


def print_summary(contract: dict) -> None:
    current = contract["current_boundary"]
    counts = contract["counts"]
    print(f"SimTop: {contract['simtop_path']}")
    print(f"Instances by area: {counts['instances_by_area']}")
    print(f"Ports by family: {counts['ports_by_family']}")
    print(f"Current boundary: {current['conclusion']}")
    print(f"CPU-only checkpoint candidate: {current['cpu_only_checkpoint_candidate']}")
    for check in contract["checks"]:
        state = "PASS" if check["passed"] else "FAIL"
        print(f"{state}: {check['name']} - {check['detail']}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Extract a machine-readable SimTop CPU/DiffTest partition contract from generated RTL")
    parser.add_argument(
        "release_or_rtl",
        help="FpgaDiff release directory, build/rtl directory, or SimTop.sv path")
    parser.add_argument("--module", default="SimTop", help="Generated top module name")
    parser.add_argument("--json-out", help="Write contract JSON to this path")
    parser.add_argument(
        "--require-cpu-only",
        action="store_true",
        help="Return non-zero if the current module still contains Gateway/transport instances")
    args = parser.parse_args()

    simtop_path, release_root = locate_simtop(args.release_or_rtl, args.module)
    contract = extract_contract(simtop_path, release_root, args.module)

    if args.json_out:
        out = Path(args.json_out).resolve()
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(contract, indent=2, sort_keys=True) + "\n")

    print_summary(contract)
    if args.require_cpu_only and not contract["current_boundary"]["cpu_only_checkpoint_candidate"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
