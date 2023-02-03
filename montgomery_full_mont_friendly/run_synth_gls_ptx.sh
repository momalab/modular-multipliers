#!/bin/bash
DESIGN=montgomery_mul
#DESIGN=mod_mul_opt_4_fly
#NBITS_ALL="16 20 24 28 "
NBITS_ALL+="32 "
NBITS_ALL+="64 "
NBITS_ALL+="128 "
NBITS_ALL+="256 "
#NBITS_ALL+="32 "
ZBITS_ALL="1 "
#ZBITS_ALL="2 3 19 "
PBITS=1
ZBITS=0
CLKNAME=clk
MSTAGE1[0]=4
MSTAGE1[1]=2
MSTAGE1[2]=2
MSTAGE1[3]=3
MSTAGE2[0]=2
MSTAGE2[1]=1
MSTAGE2[2]=2
MSTAGE2[3]=3
W[0]=16
W[1]=32
W[2]=64
W[3]=128
CLKPERIOD[0]=".250"
CLKPERIOD[1]="1.5"
CLKPERIOD[2]="1.5"
CLKPERIOD[3]="1.5"
CLKPERIOD[4]=".900"
CLKPERIOD[5]="1"
RPERIOD[0]="250"
RPERIOD[1]="1500"
RPERIOD[2]="1500"
RPERIOD[3]="1500"
RPERIOD[4]="900"
RPERIOD[5]="1000"
TECHNODE=22nm
TESTBENCH=montgomery_mul_tb
NTRACES=1000

##Control Signals
CLK_IDX=0
SYNTH_ONLY=0
POWER_ONLY=0
VERIF_ONLY=0

if [[ $TECHNODE == 22nm ]]; then 
TECHLIB="/home/projects/vlsi/libraries/TSMC_22nm_ULL/TSMC_STD_IO_LIBRARIES/tcbn22ullbwp40p140hvt_110b/TSMCHOME/digital/Front_End/LVF/CCS/tcbn22ullbwp40p140hvt_110b/tcbn22ullbwp40p140hvtssg0p81v125c_hm_lvf_p_ccs.db"
TECHLIB_PTPX="/home/projects/vlsi/libraries/TSMC_22nm_ULL/TSMC_STD_IO_LIBRARIES/tcbn22ullbwp40p140hvt_110b/TSMCHOME/digital/Front_End/LVF/CCS/tcbn22ullbwp40p140hvt_110b/tcbn22ullbwp40p140hvttt0p9v25c_hm_lvf_p_ccs.db"
echo "22nm"
elif [[ $TECHNODE == 55nm ]]; then 
TECHLIB="/home/projects/vlsi/libraries/55lpe/ref_lib/arm/std_cells/hvt/timing_lib/nldm/db/sc9_55lpe_base_hvt_ss_nominal_max_1p08v_125c.db"
else
echo "Incorrect TECHNODE."; exit 1
fi

for NBITS in $NBITS_ALL; do
for ZBITS in $ZBITS_ALL; do
#for ZBITS in $(seq 1 $(($NBITS-1))); do     
#for ZBITS in $(seq $((($NBITS/16))) $((NBITS/16)) $(($NBITS-1))); do     
     if [[ $SYNTH_ONLY == 1 ]]; then
         (echo "Running Synthsis." && cd synth && ./run_synth.sh -design $DESIGN -nbits  $NBITS -zbits  $(($ZBITS-1))    -pbits $PBITS -clkname $CLKNAME  -clkperiod  ${CLKPERIOD[$CLK_IDX]}  -tech $TECHNODE -lib $TECHLIB -mstage1 ${MSTAGE1[$CLK_IDX]} -mstage2 ${MSTAGE2[$CLK_IDX]} -w ${W[$CLK_IDX]} && echo "Synthesis Completed." && cd ../ ) &
     elif [[ $POWER_ONLY == 1 ]]; then
         (echo "Running GLS." && cd gls && export SYNOPSYS_SIM_SETUP=/data/nyu_projects/dss545/barrett_red_DAC/gls/synopsys_sim.setup &&./run_verif.sh -design $DESIGN -tb $TESTBENCH -ntrace $NTRACES -nbits $NBITS -zbits $(($ZBITS-1))  -pbits $PBITS -tech $TECHNODE -clkperiod ${CLKPERIOD[$CLK_IDX]} -rperiod ${RPERIOD[$CLK_IDX]} -mstage1 ${MSTAGE1[$CLK_IDX]} -mstage2 ${MSTAGE2[$CLK_IDX]} -w ${W[$CLK_IDX]} && cd ../ && echo "GLS Completed." && echo "Running PTPX." && cd ptpx &&./run_ptpx.sh -design $DESIGN -tb $TESTBENCH -nbits $NBITS -zbits $(($ZBITS-1))   -pbits $PBITS -clkname $CLKNAME -clkperiod ${CLKPERIOD[$CLK_IDX]} -lib $TECHLIB_PTPX -tech $TECHNODE -mstage1 ${MSTAGE1[$CLK_IDX]} -mstage2 ${MSTAGE2[$CLK_IDX]} -w ${W[$CLK_IDX]} && cd ../ && echo "PTPX Completed." && echo "Verification Started" && cd verif && ./run_verif.sh -design $DESIGN -tb $TESTBENCH -ntrace $NTRACES -nbits $NBITS -zbits $(($ZBITS-1))  -pbits $PBITS -tech $TECHNODE -clkperiod ${CLKPERIOD[$CLK_IDX]} && cd ../ && echo "Verification Completed.") &
     elif [[ $VERIF_ONLY == 1 ]]; then
         (echo "Verification Started" && cd verif && ./run_verif.sh -design $DESIGN -tb $TESTBENCH -ntrace $NTRACES -nbits $NBITS -zbits $(($ZBITS-1))  -pbits $PBITS -tech $TECHNODE -clkperiod ${CLKPERIOD[$CLK_IDX]} -mstage1 ${MSTAGE1[$CLK_IDX]} -mstage2 ${MSTAGE2[$CLK_IDX]} -w ${W[$CLK_IDX]} && cd ../ && echo "Verification Completed.") &
     else
         (cd synth && ./run_synth.sh -design $DESIGN -nbits  $NBITS -zbits  $(($ZBITS-1))    -pbits $PBITS -clkname $CLKNAME  -clkperiod  ${CLKPERIOD[$CLK_IDX]}  -tech $TECHNODE -lib $TECHLIB -mstage1 ${MSTAGE1[$CLK_IDX]} -mstage2 ${MSTAGE2[$CLK_IDX]} -w ${W[$CLK_IDX]} && echo "Synthesis Completed." && cd ../ && echo "Running GLS." && cd gls && export SYNOPSYS_SIM_SETUP=/data/nyu_projects/dss545/barrett_red_DAC/gls/synopsys_sim.setup &&./run_verif.sh -design $DESIGN -tb $TESTBENCH -ntrace $NTRACES -nbits $NBITS -zbits $(($ZBITS-1))  -pbits $PBITS -tech $TECHNODE -clkperiod ${CLKPERIOD[$CLK_IDX]} -rperiod ${RPERIOD[$CLK_IDX]} -mstage1 ${MSTAGE1[$CLK_IDX]} -mstage2 ${MSTAGE2[$CLK_IDX]} -w ${W[$CLK_IDX]} && cd ../ && echo "GLS Completed." && echo "Running PTPX." && cd ptpx &&./run_ptpx.sh -design $DESIGN -tb $TESTBENCH -nbits $NBITS -zbits $(($ZBITS-1))   -pbits $PBITS -clkname $CLKNAME -clkperiod ${CLKPERIOD[$CLK_IDX]}   -lib $TECHLIB_PTPX -tech $TECHNODE -mstage1 ${MSTAGE1[$CLK_IDX]} -mstage2 ${MSTAGE2[$CLK_IDX]} -w ${W[$CLK_IDX]} && cd ../ && echo "PTPX Completed." && echo "Verification Started" && cd verif && ./run_verif.sh -design $DESIGN -tb $TESTBENCH -ntrace $NTRACES -nbits $NBITS -zbits $(($ZBITS-1))  -pbits $PBITS -tech $TECHNODE -clkperiod ${CLKPERIOD[$CLK_IDX]} -mstage1 ${MSTAGE1[$CLK_IDX]} -mstage2 ${MSTAGE2[$CLK_IDX]} -w ${W[$CLK_IDX]} && cd ../ && echo "Verification Completed.") &
     fi
done
#wait
#CLK_IDX=$(($CLK_IDX+1))
done
