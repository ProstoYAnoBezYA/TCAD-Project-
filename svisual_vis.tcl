# Берём список .tdr, переданных SWB текущему узлу
set tdr_files [list @tdr@]

# Ищем среди них именно "fps"-файл
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

# защита от пробелов и кривых символов
regsub -all {[^a-zA-Z0-9._+-]} $tag "_" tag

set out_dir @pwd@
set p_plx   "$out_dir/n@node@_${tag}_PActive.plx"
set b_plx   "$out_dir/n@node@_${tag}_BActive.plx"

load_file $tdr_path
create_plot -dataset $dataset
select_plots [list $plot]

set_field_prop -plot $plot -geom $dataset NetActive -hide_bands
set_field_prop -plot $plot -geom $dataset BActive   -show_bands

create_cutline -plot $plot -type y -at @CutlineY@
create_plot    -dataset $cut -1d
select_plots   [list $cutplot]
set_axis_prop  -plot $cutplot -axis y -type log


proc cleanup_plx { path new_curve_name } {
    set fh [open $path r]
    set raw [read $fh]
    close $fh

    set out_lines [list "\"$new_curve_name\""]
    set first_y   ""
    set last_y    ""

    foreach line [split $raw "\n"] {
        set line [string trim $line]
        if { $line eq "" } { continue }
        if { [string index $line 0] eq "\"" } { continue }
        if { [scan $line "%f %f" y val] != 2 } { continue }
        if { $val == 0.0 } { break }
        if { $first_y eq "" } { set first_y $y }
        set last_y $y
        lappend out_lines $line
    }

    set fh [open $path w]
    puts $fh [join $out_lines "\n"]
    close $fh

    return [list $first_y $last_y]
}

# PActive
create_curve  -plot $cutplot -dataset [list $cut] -axisX X -axisY PActive
export_curves {Curve_1} -plot $cutplot -filename $p_plx -format plx
remove_curves -plot $cutplot {Curve_1}

set p_bounds [cleanup_plx $p_plx "PhosphorusActiveConcentration"]
set PhosTop  [lindex $p_bounds 0]
set PhosBot  [lindex $p_bounds 1]

# BActive
create_curve  -plot $cutplot -dataset [list $cut] -axisX X -axisY BActive
export_curves {Curve_1} -plot $cutplot -filename $b_plx -format plx
remove_curves -plot $cutplot {Curve_1}

set b_bounds [cleanup_plx $b_plx "BoronActiveConcentration"]
set BorTop   [lindex $b_bounds 0]
set BorBot   [lindex $b_bounds 1]

# Передача в SWB

puts "DOE: PhosTop $PhosTop"
puts "DOE: PhosBot $PhosBot"
puts "DOE: BorTop  $BorTop"
puts "DOE: BorBot  $BorBot"

exit