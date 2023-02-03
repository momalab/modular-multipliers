set power_enable_analysis true
set power_analysis_mode time_based

set_host_options -max_cores 4

set vcd_name   [getenv "VCD_NAME"]

set design       [getenv "DESIGN"]
set tbench       [getenv "TBENCH"]
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

sh mkdir -p $work_dir/

set search_path [concat * $search_path]

set link_library $target_lib
read_verilog  ../synth/${design}_${numbits}_${pbits}_synth_${tech}_${clkperiod}ns/netlist/${design}_flat.v
source -echo -verbose ./constraints.tcl
update_timing
report_disable_timing

#read_vcd ../gls/vcs/$vcd_name -zero_delay -strip_path ${design}_tb/$design_NBITS
#read_vcd ../gls/vcs/$vcd_name -zero_delay -strip_path ${design}_tb mod_mul_il_gen_NBITS${numbits}_PBITS${pbits}
read_vcd ../gls/vcs_${design}_${numbits}_${pbits}_${clkperiod}/$vcd_name -zero_delay -strip_path $tbench/${design}_NBITS${numbits}_PBITS${pbits}

set_power_analysis_options -cycle_accurate_clock CLK -waveform_output $work_dir/${design}_${numbits}_${pbits} -waveform_format out
update_power
report_power > $work_dir/power.rpt
report_power -verbose -hier -nosplit -sort_by name > $work_dir/power.hier.rpt
save_session -include libraries pt_session_${design}_${numbits}_${pbits}
exit
