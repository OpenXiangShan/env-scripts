function simtop_has_port(path, port, line, in_simtop) {
    while ((getline line < path) > 0) {
        if (!in_simtop && line ~ /^[[:space:]]*module[[:space:]]+/) {
            if (line !~ ("^[[:space:]]*module[[:space:]]+" top_module "([[:space:]#(]|$)")) {
                close(path)
                return 0
            }
            in_simtop = 1
        }
        if (in_simtop && line ~ port) {
            close(path)
            return 1
        }
        if (in_simtop && line ~ /^[[:space:]]*\);/) {
            break
        }
    }
    close(path)
    return 0
}

BEGIN{
    if (var == "") var = "cpu_files"
    if (top_module == "") top_module = "SimTop"
    printf "set %s [list \\\n", var
}
{
    if (detect_simtop_dma && !has_simtop_dma &&
        simtop_has_port($0, "dma_awready")) {
        has_simtop_dma = 1
    }
    if (detect_simtop_riscv_halt && !has_simtop_riscv_halt &&
        simtop_has_port($0, "io_riscv_halt_0")) {
        has_simtop_riscv_halt = 1
    }
    printf " [file normalize \"%s\" ]\\\n", $0
}
END{
    printf "]\n"
    if (detect_simtop_dma) {
        printf "set cpu_files_has_dma %d\n", has_simtop_dma
    }
    if (detect_simtop_riscv_halt) {
        printf "set cpu_files_has_riscv_halt %d\n", has_simtop_riscv_halt
    }
}
