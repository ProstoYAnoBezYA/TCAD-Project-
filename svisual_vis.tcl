#find *_fps.tdr 
set tdr_files [list @tdr@]
set tdr_path ""
foreach f $tdr_files {
    if { [string match "*_fps.tdr" $f] || [string match "*fps*" $f] } {
        set tdr_path $f
        break
    }
}
if { $tdr_path eq "" } {
    set tdr_path [lindex $tdr_files 0]
}
set dataset [file rootname [file tail $tdr_path]]
set plot    "Plot_$dataset"
set cut     "C1($dataset)"
set cutplot "Plot_$cut"
set diff_model       "@DiffModel@"
set diff_model_boron "@DiffModel_Boron@"
set tag "${diff_model}_${diff_model_boron}"
regsub -all {[^a-zA-Z0-9._+-]} $tag "_" tag
set out_dir @pwd@
set p_plx   "$out_dir/n@node@_${tag}_PActive.plx"
set b_plx   "$out_dir/n@node@_${tag}_BActive.plx"
set scm_out "$out_dir/n@node@_${tag}_profiles.scm"
set report  "$out_dir/n@node@_${tag}_profiles.report"
#cutline
load_file $tdr_path
create_plot -dataset $dataset
select_plots [list $plot]
set_field_prop -plot $plot -geom $dataset NetActive -hide_bands
set_field_prop -plot $plot -geom $dataset BActive   -show_bands
create_cutline -plot $plot -type y -at @CutlineY@
create_plot    -dataset $cut -1d
select_plots   [list $cutplot]
set_axis_prop  -plot $cutplot -axis y -type log
#clear
proc cleanup_plx { path new_curve_name } {
    set fh [open $path r]
    set raw [read $fh]
    close $fh
    set out_lines [list "\"$new_curve_name\""]
    set first_y "" ; set last_y ""
    set started 0
    foreach line [split $raw "\n"] {
        set line [string trim $line]
        if { $line eq "" }                          { continue }
        if { [string index $line 0] eq "\"" }       { continue }
        if { [scan $line "%f %f" y val] != 2 }      { continue }
        if { $val == 0.0 } {
            if { $started } { break }
            continue
        }
        if { !$started } { set first_y $y; set started 1 }
        set last_y $y
        lappend out_lines $line
    }
    set fh [open $path w]
    puts $fh [join $out_lines "\n"]
    close $fh
    return [list $first_y $last_y]
}
#exp PActive
create_curve  -plot $cutplot -dataset [list $cut] -axisX X -axisY PActive
file delete -force $p_plx
export_curves {Curve_1} -plot $cutplot -filename $p_plx -format plx -overwrite
remove_curves -plot $cutplot {Curve_1}
set p_bounds [cleanup_plx $p_plx "PhosphorusActiveConcentration"]
set PhosTop  [lindex $p_bounds 0]
set PhosBot  [lindex $p_bounds 1]
#exp BActive
create_curve  -plot $cutplot -dataset [list $cut] -axisX X -axisY BActive
file delete -force $b_plx
export_curves {Curve_1} -plot $cutplot -filename $b_plx -format plx -overwrite
remove_curves -plot $cutplot {Curve_1}
set b_bounds [cleanup_plx $b_plx "BoronActiveConcentration"]
set BorTop   [lindex $b_bounds 0]
set BorBot   [lindex $b_bounds 1]
#python 
file delete -force $scm_out
file delete -force $report
set script_path "$out_dir/fit_plx_to_scm.py"
if { ![file exists $script_path] } {
    
    set script_path "[file dirname [info script]]/fit_plx_to_scm.py"
}
#Hfet
set z_sde_surface 1.4
set py_cmd [list /home/sentaurus/miniconda3/bin/python $script_path $p_plx $b_plx $scm_out \
                 --np @NgaussP@ --nb @NgaussB@ \
                 --pocket-window Pocket_Window \
                 --source-window Source_Window \
                 --drain-window  Drain_Window  \
                 --z-flip \
                 --report $report]
if { [catch {exec {*}$py_cmd} py_out] } {
    puts "ERR: fit_plx_to_scm.py failed: $py_out"
} else {
    puts "FIT OK:"
    puts $py_out
    puts "SCM written to: $scm_out"
}
#to SWB
puts "DOE: PhosTop $PhosTop"
puts "DOE: PhosBot $PhosBot"
puts "DOE: BorTop  $BorTop"
puts "DOE: BorBot  $BorBot"
#name .scm for sde
puts "DOE: ProfilesScm $scm_out"
exit