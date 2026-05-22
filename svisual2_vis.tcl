#Config
set test_label   "Vthreshold"
set target_value 10e-6
set target_axis  "Y"
set unit         "V"
set use_log      1


set node        "@node@"
set prev_node   "@previous@"
set diff_model  "@DiffModel@"
set diff_boron  "@DiffModel_Boron@"
set sde_node    "@node|sde3D@"

#find .plt
set candidates [list \
    "Structure_n${prev_node}_${diff_model}_${diff_boron}_des_des.plt" \
    "n${prev_node}_${diff_model}_${diff_boron}_des_des.plt" \
]

set plt_file ""
foreach c $candidates {
    if {[file exists $c]} {
        set plt_file $c
        break
    }
}

if {$plt_file == ""} {
    puts "ERROR: no .plt file found for previous node $prev_node"
    puts "ERROR: tried: $candidates"
    exit 1
}

set dataset [file rootname [file tail $plt_file]]
puts "INFO: loading $plt_file"

#download
load_file $plt_file
create_plot -1d
select_plots {Plot_1}
create_curve -plot Plot_1 -dataset $dataset \
    -axisX {Drain OuterVoltage} -axisY {Drain TotalCurrent}
if {$use_log} {
    set_axis_prop -plot Plot_1 -axis y -type log
}

#exp nodes
set vd_list [get_variable_data "Drain OuterVoltage" -dataset $dataset]
set id_list [get_variable_data "Drain TotalCurrent"  -dataset $dataset]
puts "INFO: [llength $vd_list] data points"

#find val
if {$target_axis == "Y"} {
    set search_list $id_list
    set return_list $vd_list
} else {
    set search_list $vd_list
    set return_list $id_list
}

set n [llength $search_list]
set result "NOT_FOUND"

for {set i 1} {$i < $n} {incr i} {
    set s1 [expr {abs([lindex $search_list [expr {$i-1}]])}]
    set s2 [expr {abs([lindex $search_list $i])}]
    set r1 [lindex $return_list [expr {$i-1}]]
    set r2 [lindex $return_list $i]
    if {($s1 <= $target_value && $s2 >= $target_value) || \
        ($s1 >= $target_value && $s2 <= $target_value)} {
        if {$s2 == $s1} {
            set result $r2
        } else {
            set result [expr {$r1 + ($target_value - $s1)*($r2 - $r1)/($s2 - $s1)}]
        }
        break
    }
}

if {$result == "NOT_FOUND"} {
    set result [lindex $return_list end]
    puts "WARNING: target $target_value not reached, using last point"
}

#write to file
set summary_file "Results_n${sde_node}_${diff_model}_${diff_boron}.txt"
set is_new [expr {![file exists $summary_file]}]

set fid [open $summary_file "a"]
if {!$is_new} {
    puts $fid ""
}
puts $fid "n${prev_node}_${diff_model}_${diff_boron}_${test_label} [format %.4g $result] $unit"
close $fid

puts "RESULT: $test_label = [format %.4g $result] $unit"
puts "RESULT: appended to $summary_file"


ext::ExtractExtremum -out $test_label -name $test_label \
    -f [list $result] -type max

exit