create_clock $clkname  -name CLK  -period $clkperiod

set input_ports  [remove_from_collection [all_inputs] $clkname]
set output_ports [all_outputs]

set_input_delay  -max [expr $clkperiod/4.0]   [get_ports $input_ports ]  -clock CLK
set_input_delay  -min 0   [get_ports $input_ports ]  -clock CLK

set_output_delay -max [expr $clkperiod/4.0]   [get_ports $output_ports ] -clock CLK
set_output_delay -min 0.5            [get_ports $output_ports ] -clock CLK

##  set_input_transition -max 0.5 [get_ports $input_ports]
##  set_input_transition -min 0   [get_ports $input_ports]


##  set_load -max .001   [get_ports $output_ports]
##  set_load -min .0005  [get_ports $output_ports]
