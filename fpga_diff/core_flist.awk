function simtop_has_dma(path, line, in_simtop) {
    while ((getline line < path) > 0) {
        if (!in_simtop && line ~ /^[[:space:]]*module[[:space:]]+/) {
            if (line !~ /^[[:space:]]*module[[:space:]]+SimTop([[:space:]#(]|$)/) {
                close(path)
                return 0
            }
            in_simtop = 1
        }
        if (in_simtop && line ~ /dma_awready/) {
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
    printf "set %s [list \\\n", var
}
{
    if (detect_simtop_dma && !has_simtop_dma && simtop_has_dma($0)) {
        has_simtop_dma = 1
    }
    printf " [file normalize \""
    printf $0
    printf "\" ]\\\n"
}
END{
    printf "]\n"
    if (detect_simtop_dma) {
        printf "set cpu_files_has_dma %d\n", has_simtop_dma
    }
}
