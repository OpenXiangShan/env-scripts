BEGIN{printf "set cpu_files [list \\\n"}
{
    printf " [file normalize \"${core_dir}/"
    printf $0
    printf "\" ]\\\n"
}
END{printf "]\n"}