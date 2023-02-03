#!/bin/sh

function usage()
{
    echo "Script to run synthesis"
    echo "./run_synth.sh -design    <design_name in ../rtl>
               -nbits     <modulus size>
               -zbits     <Number of Zeros>
               -pbits     <log2(radix)>
               -mstage1   <Number of stages for first multiplier>
               -mstage2   <Number of stages for second multiplier>
               -mstage3   <Number of stages for third multiplier>
               -clkname   <clock_port name>
               -clkperiod <clock period for synthesis>
               -lib       <complete path for target library for synthesis>
               -tech      <55nm/65nm>
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
        -mstage3 | --mstage3)
            export MUL_STAGE3=$VALUE
            ;;
        -tb | --tb | -t | --t)
            export TBENCH=$VALUE
            ;;
        -clkname | --clkname | -clk | --clk)
            export CLKNAME=$VALUE
            ;;
        -clkperiod | --clkperiod | -period | --period)
            export CLK_PERIOD=$VALUE
            ;;
        -lib | --lib | -synth_lib | --synth_lib | -l | --l)
            export SYNTH_LIBRARY=$VALUE
            ;;
        -tech | --tech | -t | --t)
            export TECH=$VALUE
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
export VCD_NAME=${DESIGN}_${NBITS}_${PBITS}_${CLK_PERIOD}.vcd


echo "Running synthesis for design : $DESIGN with clock port : $CLKNAME and technology $TECH with parameters
Multiplier1 stage   : $MUL_STAGE1
Multiplier2 stage   : $MUL_STAGE2
Multiplier3 stage   : $MUL_STAGE3
Modulus Size : $NBITS
LOG2(RADIX)  : $PBITS
Clock Period : $CLK_PERIOD
"

#dc_shell-t -no_gui -64bit -output_log_file ./synth_${DESIGN}_${NBITS}_${PBITS}_${TECH}.log -x "source -echo -verbose ./run_synth.tcl"
/data/tools/Synopsys/primetime/prime/T-2022.03-SP2/bin/pt_shell -output_log_file ./pt_$DESIGN_${NBITS}_${PBITS}_${TECH}_${CLK_PERIOD}.log -x   "source -echo -verbose ./run_pt.tcl"
