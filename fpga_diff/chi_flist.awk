BEGIN{printf "set chi_files [list \\\n"}
{
    printf " [file normalize \""
    printf $0
    printf "\" ]\\\n"
}
END{printf "]\n"}