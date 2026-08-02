namespace eval uvhs {
    variable script_dir [file dirname [file normalize [info script]]]

    proc path {name} {
        variable script_dir
        return [file join $script_dir $name]
    }

    proc env_or_default {name default} {
        if {[info exists ::env($name)] && $::env($name) ne ""} {
            return $::env($name)
        }
        return $default
    }

    proc source_required {name} {
        set file [path $name]
        if {![file exists $file]} {
            error "required UVHS flow file not found: $file"
        }
        puts "INFO: source $file"
        uplevel #0 [list source $file]
    }
}
