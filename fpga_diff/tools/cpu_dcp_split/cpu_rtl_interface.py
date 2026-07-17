#!/usr/bin/env python3
import hashlib
import json
import re
from pathlib import Path


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8", errors="replace")).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def stable_json_hash(value: object) -> str:
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def skip_line_comment(text: str, idx: int) -> int:
    end = text.find("\n", idx)
    return len(text) if end < 0 else end + 1


def skip_block_comment(text: str, idx: int) -> int:
    end = text.find("*/", idx + 2)
    return len(text) if end < 0 else end + 2


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//.*", "", text)


def strip_comments_preserve_offsets(text: str) -> str:
    def blank(match: re.Match) -> str:
        value = match.group(0)
        return "".join("\n" if char == "\n" else " " for char in value)

    text = re.sub(r"/\*.*?\*/", blank, text, flags=re.S)
    return re.sub(r"//.*", blank, text)


def normalize_ws(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def line_no(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def find_matching_paren(text: str, open_idx: int) -> int:
    depth = 0
    idx = open_idx
    while idx < len(text):
        if text.startswith("//", idx):
            idx = skip_line_comment(text, idx)
            continue
        if text.startswith("/*", idx):
            idx = skip_block_comment(text, idx)
            continue
        char = text[idx]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return idx
        idx += 1
    raise ValueError(f"unmatched '(' at offset {open_idx}")


def find_header_port_open(text: str, module_match_end: int) -> int:
    idx = module_match_end
    while idx < len(text):
        if text.startswith("//", idx):
            idx = skip_line_comment(text, idx)
            continue
        if text.startswith("/*", idx):
            idx = skip_block_comment(text, idx)
            continue
        if text[idx].isspace():
            idx += 1
            continue
        if text[idx] == "#":
            param_open = text.find("(", idx)
            if param_open < 0:
                raise ValueError("parameter list has no opening parenthesis")
            idx = find_matching_paren(text, param_open) + 1
            continue
        if text[idx] == "(":
            return idx
        raise ValueError(f"unexpected token before port list at offset {idx}")
    raise ValueError("module has no ANSI port list")


def find_header_semicolon(text: str, close_idx: int) -> int:
    idx = close_idx + 1
    while idx < len(text):
        if text.startswith("//", idx):
            idx = skip_line_comment(text, idx)
            continue
        if text.startswith("/*", idx):
            idx = skip_block_comment(text, idx)
            continue
        if text[idx] == ";":
            return idx
        idx += 1
    raise ValueError("module header has no terminating semicolon")


def extract_module_header(text: str, module_name: str) -> str:
    match = re.search(rf"(?m)^\s*module\s+{re.escape(module_name)}\b", text)
    if not match:
        raise ValueError(f"module not found: {module_name}")

    try:
        open_idx = find_header_port_open(text, match.end())
        close_idx = find_matching_paren(text, open_idx)
        semi_idx = find_header_semicolon(text, close_idx)
    except ValueError as exc:
        raise ValueError(f"cannot parse module header for {module_name}: {exc}") from exc

    return text[match.start():semi_idx + 1].strip()


def rename_module_header(header: str, old_name: str, new_name: str) -> str:
    pattern = re.compile(rf"(?m)^(\s*module\s+){re.escape(old_name)}(\b)")
    renamed, count = pattern.subn(rf"\1{new_name}\2", header, count=1)
    if count != 1:
        raise ValueError(f"cannot rename module header {old_name} -> {new_name}")
    return renamed


def split_top_level_commas(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    parens = 0
    brackets = 0
    braces = 0
    for idx, char in enumerate(text):
        if char == "(":
            parens += 1
        elif char == ")":
            parens -= 1
        elif char == "[":
            brackets += 1
        elif char == "]":
            brackets -= 1
        elif char == "{":
            braces += 1
        elif char == "}":
            braces -= 1
        elif char == "," and parens == 0 and brackets == 0 and braces == 0:
            parts.append(text[start:idx].strip())
            start = idx + 1
    tail = text[start:].strip()
    if tail:
        parts.append(tail)
    return parts


def parse_width(range_text: str) -> int | None:
    match = re.fullmatch(r"\[\s*([0-9]+)\s*:\s*([0-9]+)\s*\]", range_text)
    if not match:
        return None
    left = int(match.group(1))
    right = int(match.group(2))
    return abs(left - right) + 1


def parse_header_ports(header_text: str) -> list[dict]:
    open_idx = header_text.find("(")
    close_idx = header_text.rfind(")")
    if open_idx < 0 or close_idx < open_idx:
        raise ValueError("module header has no port list")

    body = strip_comments(header_text[open_idx + 1:close_idx])
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

        kinds: list[str] = []
        while True:
            kind_match = re.match(r"^(wire|reg|logic|bit|tri|signed|unsigned)\b\s*(.*)$", item)
            if not kind_match:
                break
            kinds.append(kind_match.group(1))
            item = kind_match.group(2).strip()
        if kinds:
            current_kind = " ".join(kinds)

        range_match = re.match(r"^(\[[^\]]+\])\s*(.*)$", item)
        if range_match:
            current_range = normalize_ws(range_match.group(1))
            item = range_match.group(2).strip()

        name_match = re.search(r"([A-Za-z_][A-Za-z0-9_$]*)\s*(?:=.*)?$", item)
        if not name_match:
            continue
        name = name_match.group(1)
        ports.append({
            "index": len(ports),
            "name": name,
            "direction": current_direction,
            "kind": current_kind,
            "range": current_range,
            "width": parse_width(current_range) or 1,
        })
    return ports


def port_signature(ports: list[dict]) -> list[dict]:
    return [
        {
            "name": port.get("name", ""),
            "direction": port.get("direction", ""),
            "range": port.get("range", ""),
            "width": port.get("width", 1),
        }
        for port in ports
    ]


def interface_hash_from_ports(ports: list[dict]) -> str:
    return stable_json_hash(port_signature(ports))


def make_wrapper(header: str, cpu_module: str, partition_module: str, source: Path) -> str:
    partition_header = rename_module_header(header, cpu_module, partition_module)
    return "\n".join([
        f"// Generated from {source}",
        "// CPU partition wrapper. The port contract matches the source CPU RTL.",
        "(* keep_hierarchy = \"yes\" *)",
        partition_header,
        f"  (* keep_hierarchy = \"yes\" *) {cpu_module} cpu_impl (.*);",
        "endmodule",
        "",
    ])


def make_stub(header: str, cpu_module: str, partition_module: str, source: Path) -> str:
    partition_header = rename_module_header(header, cpu_module, partition_module)
    return "\n".join([
        f"// Generated from {source}",
        "// CPU partition stub for read_checkpoint -cell.",
        "(* black_box = \"yes\", syn_black_box = 1, keep_hierarchy = \"yes\" *)",
        partition_header,
        "endmodule",
        "",
    ])


def read_cpu_interface(cpu_rtl: Path, cpu_module: str) -> dict:
    text = cpu_rtl.read_text(encoding="utf-8", errors="replace")
    header = extract_module_header(text, cpu_module)
    ports = parse_header_ports(header)
    return {
        "cpu_module": cpu_module,
        "source_cpu_rtl": str(cpu_rtl),
        "source_cpu_rtl_sha256": sha256_file(cpu_rtl),
        "header": header,
        "header_line_count": len(header.splitlines()),
        "port_count": len(ports),
        "ports": ports,
        "port_signature": port_signature(ports),
        "interface_hash": interface_hash_from_ports(ports),
    }


def make_partition_rtl(
    interface: dict,
    partition_module: str,
    mode: str,
) -> str:
    cpu_module = str(interface["cpu_module"])
    cpu_rtl = Path(str(interface["source_cpu_rtl"]))
    header = str(interface["header"])
    if mode == "wrapper":
        return make_wrapper(header, cpu_module, partition_module, cpu_rtl)
    if mode == "stub":
        return make_stub(header, cpu_module, partition_module, cpu_rtl)
    raise ValueError(f"unsupported partition RTL mode: {mode}")


def read_module_interface(module_rtl: Path, module_name: str) -> dict:
    text = module_rtl.read_text(encoding="utf-8", errors="replace")
    header = extract_module_header(text, module_name)
    ports = parse_header_ports(header)
    return {
        "module": module_name,
        "source_rtl": str(module_rtl),
        "source_rtl_sha256": sha256_file(module_rtl),
        "header": header,
        "header_line_count": len(header.splitlines()),
        "port_count": len(ports),
        "ports": ports,
        "port_signature": port_signature(ports),
        "interface_hash": interface_hash_from_ports(ports),
    }
