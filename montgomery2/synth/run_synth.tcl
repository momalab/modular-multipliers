date
set_host_options -max_cores 4
set compile_seqmap_propagate_constants     false
set compile_seqmap_propagate_high_effort   false
set compile_enable_register_merging        false
set write_sdc_output_net_resistance        false
set timing_separate_clock_gating_group     true
set verilogout_no_tri tru
set html_log_enable true

set design       [getenv "DESIGN"]
set numbits      [getenv "NBITS"]
set pbits        [getenv "PBITS"]
set clkname      [getenv "CLKNAME"]
set clkperiod    [getenv "CLK_PERIOD"]
set target_lib   [getenv "SYNTH_LIBRARY"]
set tech         [getenv "TECH"]
set work_dir     ${design}_${numbits}_${pbits}_synth_${tech}_${clkperiod}ns

#if {[file exist $work_dir]} {
#sh rm -rf $work_dir
#}

sh mkdir -p $work_dir/reports
sh mkdir -p $work_dir/netlist

set search_path [concat * $search_path]

sh rm -rf ./$work_dir/work
define_design_lib WORK -path ./$work_dir/work

  set_svf $design.svf

  set synthetic_library dw_foundation.sldb
  set target_library $target_lib

  set link_library $target_lib

  lappend link_library "./spram_hs_32x128_nldm_ss_1p08v_1p08v_125c.db"
  #source -echo -verbose ../../../../../memlib/link_mem.tcl

if {[file exist ./set_design.tcl]} {
  source ./set_design.tcl
} else {
  source -echo -verbose ./analyze.tcl
}
elaborate $design -param "NBITS => $numbits, PBITS => $pbits"
date
 

link
set_dont_use   [get_lib_cells */*X0P*]
set_dont_use   [get_lib_cells */*D0*]
set_dont_use   [get_lib_cells */G*]
#Level shifters and isolation cell
#set_dont_use   [get_lib_cells */LVL*]
#set_dont_use   [get_lib_cells */ISO*]
#Clock Cells
set_dont_use   [get_lib_cells */CK*]
#set_dont_use   [get_lib_cells */CLMUX*]
#Delay cells
set_dont_use   [get_lib_cells */DEL*]
#Footer cells and always on cells
#set_dont_use   [get_lib_cells */HDR*] 
#set_dont_use   [get_lib_cells */FTR*] 
#set_dont_use   [get_lib_cells */PT*] 
#set_dont_touch [get_cells -hier *DONT_TOUCH*]

  #set_wire_load_model -name Medium
  set_max_area 0
  set_clock_gating_style -sequential_cell latch -positive_edge_logic {nand} -negative_edge_logic {nor} -minimum_bitwidth 5 -max_fanout 64


  source -echo -verbose ./constraints.tcl


  group_path -name output_group -to   [all_outputs]
  group_path -name input_group  -from [all_inputs]

date
mem -all -verbose
  #compile_ultra -no_autoungroup -no_seq_output_inversion -no_boundary_optimization -gate_clock -area_high_effort_script
  compile_ultra -no_autoungroup -no_seq_output_inversion -no_boundary_optimization  -area_high_effort_script
report_area
date
mem -all -verbose
#  optimize_netlist -area
#report_area
#date
#mem -all -verbose
#  compile_ultra -no_autoungroup -no_seq_output_inversion -no_boundary_optimization -incremental
#date
#mem -all -verbose

   change_names -hier -rule verilog

   write_file -hierarchy -format verilog -output "$work_dir/netlist/$design.v"
   write_sdc "$work_dir/netlist/$design.sdc"

   report_timing -delay max  -nosplit -input -nets -cap -max_path 10 -nworst 10    > ./$work_dir/reports/report_timing_max.rpt
   report_timing -delay min  -nosplit -input -nets -cap -max_path 10 -nworst 10    > ./$work_dir/reports/report_timing_min.rpt
   report_constraint -all_violators -verbose  -nosplit                             > ./$work_dir/reports/report_constraint.rpt
   check_design -nosplit                                                           > ./$work_dir/reports/check_design.rpt
   report_design                                                                   > ./$work_dir/reports/report_design.rpt
   report_area                                                                     > ./$work_dir/reports/report_area.rpt
   report_timing -loop                                                             > ./$work_dir/reports/timing_loop.rpt
   report_power -hierarchy -analysis_effort high                                   > ./$work_dir/reports/report_power.rpt
   report_qor                                                                      > ./$work_dir/reports/report_qor.rpt
   report_area -hierarchy -nosplit                                                 > ./$work_dir/reports/report_area_hier.rpt
   report_resources -hierarchy                                                     > ./$work_dir/reports/report_resource.rpt

   ungroup -all -flatten
   write_file -hierarchy -format verilog -output "$work_dir/netlist/${design}_flat.v"


date
exit
