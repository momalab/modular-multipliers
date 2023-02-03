#!/bin/sh

#if [ -f inter.vpd ]
#then
#rm -rf inter.vpd simv session.inter.vpd.tcl vlogan.log vcs.log csrc ucli.key DVEfiles simv.daidir
#fi

#vlogan  -sverilog  $VERIF_LIBRARY aes128_table_ecb_tb.v  ../synth/$SYNTH_RUN/netlist/${DESIGN}_flat.v  +delay_mode_zero  | tee vcs_${TECH}_${NUMTRACE}_${NUMKEY}/vlogan.log
vlogan  -sverilog  $VERIF_LIBRARY ${DESIGN}_tb.v  ../synth/$SYNTH_RUN/netlist/${DESIGN}_flat.v  +delay_mode_zero +define+${INPUTMODE}=TRUE  | tee vcs_${TECH}_${NUMTRACE}_${NUMKEY}/vlogan.log

echo "---------------------vlogan Done--------------------"
echo "---------------------Running VCS--------------------"
#vcs -y vcs_${TECH}_${NUMTRACE}_${NUMKEY}  -debug_access+all aes128_table_ecb_tb -sverilog -o vcs_${TECH}_${NUMTRACE}_${NUMKEY}/simv_${TECH}_${NUMTRACE}_${NUMKEY} | tee vcs_${TECH}_${NUMTRACE}_${NUMKEY}/vcs.log
vcs -y vcs_${TECH}_${NUMTRACE}_${NUMKEY}  -debug_access+all ${DESIGN}_tb -sverilog -o vcs_${TECH}_${NUMTRACE}_${NUMKEY}/simv_${TECH}_${NUMTRACE}_${NUMKEY} | tee vcs_${TECH}_${NUMTRACE}_${NUMKEY}/vcs.log

echo "---------------------VCS Done--------------------"
cd vcs_${TECH}_${NUMTRACE}_${NUMKEY}
./simv_${TECH}_${NUMTRACE}_${NUMKEY} | tee simv_nogui_$VCD_NAME.log
