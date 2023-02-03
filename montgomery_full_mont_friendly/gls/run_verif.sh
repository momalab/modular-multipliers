#!/bin/sh


function usage()
{
    echo "Script to run synthesis"
    echo "./run_verif.sh -design    <design_name in ../rtl>
               -nbits     <modulus size>
               -zbits     <Number of 0s>
               -pbits     <log2(radix)>
               -mstage1   <Number of stages for first multiplier>
               -mstage2   <Number of stages for second multiplier>
               -mstage3   <Number of stages for third multiplier>
               -tb        <Testbench name in ./>
               -testcase  <Selection of test enviroment for verification of DUT>
               -ntrace    <Number of random inputs to apply to run>
               -h         print this message"
    echo ""
}

    #GUI=  `echo $3 | awk -F= '{print $1}'`
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $2 | awk -F= '{print $1}'`

    case $PARAM in
        -h | --help | -help)
            usage
            exit
            ;;
        -design | --design | -d | --d)
            export DESIGN=$VALUE
            ;;
        -nbits | --nbits)
            export NBITS=$VALUE
            ;;
        -zbits | --zbits)
            export ZBITS=$VALUE
            ;;
        -pbits | --pbits)
            export PBITS=$VALUE
            ;;
        -mstage1 | --mstage1)
            export MUL_STAGE1=$VALUE
            ;;
        -mstage2 | --mstage2)
            export MUL_STAGE2=$VALUE
            ;;
        -w | --w)
            export W=$VALUE
            ;;
        -tb | --tb | -t | --t)
            export TBENCH=$VALUE
            ;;
        -tech | --tech | -t | --t)
            export TECH=$VALUE
            ;;
        -clkperiod | --clkperiod | -period | --period)
            export CLKPERIOD=$VALUE
            ;;
        -realperiod | --realperiod | -rperiod | --rperiod)
            export REALPERIOD=$VALUE
            ;;
        -testcase | --testcase)
            export TESTCASE=$VALUE
            ;;
        -ntrace | --ntrace)
            export NUMTRACE=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
    shift
done


export SNPSLMD_QUEUE=true

mkdir vcs_${DESIGN}_${NBITS}_${PBITS}_${MUL_STAGE1}_${MUL_STAGE2}_${W}_${CLKPERIOD}
#cd    vcs_${DESIGN}_${NBITS}_${PBITS}

echo "---------------------------------------------------------"
echo "Running verification for design : $DESIGN with parameters
Multiplier1 stage   : $MUL_STAGE1
Multiplier2 stage   : $MUL_STAGE2
W                   : $W
Modulus Size        : $NBITS
LOG2(RADIX)         : $PBITS
Number of iteration : $NUMTRACE
Clock period        : $CLKPERIOD
Real  period        : $REALPERIOD
"
echo "---------------------------------------------------------"

L=$((NBITS/W))
LW=$((L*W))
if [ $LW -ne $NBITS ]
then
L=$((L+1))
fi
echo "L = $L"
export VERIF_LIBRARY="/home/projects/vlsi/libraries/TSMC_22nm_ULL/TSMC_STD_IO_LIBRARIES/tcbn22ullbwp40p140hvt_110b/TSMCHOME/digital/Front_End/verilog/tcbn22ullbwp40p140hvt_110a/tcbn22ullbwp40p140hvt.v"
#export VERIF_LIBRARY="/home/projects/vlsi/libraries/55lpe/55lpe/sc9/arm/gf/55lpe/sc9_base_hvt/r1p0/verilog/sc9_55lpe_base_hvt.v /home/projects/vlsi/libraries/55lpe/55lpe/sc9/arm/gf/55lpe/sc9_base_hvt/r1p0/verilog/sc9_55lpe_base_hvt_udp.v"

echo "---------------------Running vlogan-----------------"
vlogan -kdb  -sverilog +define+VCD_NAME=\"vcs_${DESIGN}_${NBITS}_${PBITS}_${MUL_STAGE1}_${MUL_STAGE2}_${W}_${CLKPERIOD}/${DESIGN}_${NBITS}_${PBITS}_${MUL_STAGE1}_${MUL_STAGE2}_${W}.vcd\"  +define+DUTNAME=${DESIGN}_MUL_STAGE1${MUL_STAGE1}_MUL_STAGE2${MUL_STAGE2}_NBITS${NBITS}_W${W}_L${L}_PBITS${PBITS}  +define+CLKPERIOD=${CLKPERIOD} +define+MUL_STAGE1=${MUL_STAGE1} +define+MUL_STAGE2=${MUL_STAGE2} +define+W=${W} +define+${TESTCASE}=TRUE +define+NUMBITS=${NBITS} +define+PBITS=$PBITS  +define+NUMTRACE=$NUMTRACE $VERIF_LIBRARY ${TBENCH}.v ../synth/${DESIGN}_${NBITS}_${PBITS}_${MUL_STAGE1}_${MUL_STAGE2}_${W}_synth_${TECH}_${CLKPERIOD}ns/netlist/${DESIGN}_flat.v   +delay_mode_zero +define+${INPUTMODE}=TRUE  | tee vcs_${DESIGN}_${NBITS}_${PBITS}_${MUL_STAGE1}_${MUL_STAGE2}_${W}_${CLKPERIOD}/vlogan.log
#vlogan -kdb  -sverilog +define+VCD_NAME="${DESIGN}_${NBITS}_${PBITS}.vcd"  +define+DUTNAME=${DESIGN}_NBITS${NBITS}_PBITS${PBITS} +define+NUMBITS=${NBITS} +define+PBITS=$PBITS  +define+NUMTRACE=$NUMTRACE $VERIF_LIBRARY ${TBENCH}.v ../synth/${DESIGN}_${NBITS}_${PBITS}_synth_${TECH}_${CLKPERIOD}ns/netlist/${DESIGN}_flat.v   +delay_mode_zero +define+${INPUTMODE}=TRUE  | tee vcs/${DESIGN}_${NBITS}_${PBITS}_vlogan.log

echo "---------------------vlogan Done--------------------"
echo "---------------------Running VCS--------------------"
vcs +lint=TFIPC-L -lca -V -kdb -y vcs -sverilog -debug_access+all $TBENCH -o vcs_${DESIGN}_${NBITS}_${PBITS}_${MUL_STAGE1}_${MUL_STAGE2}_${W}_${CLKPERIOD}/simv  | tee vcs_${DESIGN}_${NBITS}_${PBITS}_${MUL_STAGE1}_${MUL_STAGE2}_${W}_${CLKPERIOD}/vcs.log

echo "---------------------VCS    Done--------------------"
./vcs_${DESIGN}_${NBITS}_${PBITS}_${MUL_STAGE1}_${MUL_STAGE2}_${W}_${CLKPERIOD}/simv +realperiod=$REALPERIOD   | tee vcs_${DESIGN}_${NBITS}_${PBITS}_${MUL_STAGE1}_${MUL_STAGE2}_${W}_${CLKPERIOD}/simv.log
#./vcs/${DESIGN}_${NBITS}_${PBITS}_simv  -gui=sx &
#mv abcd.vcd  ./vcs/${DESIGN}_${NBITS}_${PBITS}_${CLKPERIOD}.vcd
#./vcs_out/simv -gui=sx &
