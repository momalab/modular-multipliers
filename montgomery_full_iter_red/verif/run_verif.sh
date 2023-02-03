#!/bin/sh


function usage()
{
    echo "Script to run synthesis"
    echo "./run_verif.sh -design    <design_name in ../rtl>
               -nbits     <modulus size>
               -pbits     <log2(radix)>
               -mstage1   <Number of stages for first multiplier>
               -mstage2   <Number of stages for second multiplier>
               -mstage3   <Number of stages for third multiplier>
               -w         <Value of W>
               -tb        <Testbench name in ./>
               -ntrace    <Number of random inputs to apply to run>
               -debug     <Open waveform in debug mode>
               -testcase  <Selection of test enviroment for verification of DUT>
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
        -w | --w)
            export W=$VALUE
            ;;
        -debug | --debug)
            export DEBUG=$VALUE
            ;;
        -testcase | --testcase)
            export TESTCASE=$VALUE
            ;;
        -tb | --tb | -t | --t)
            export TBENCH=$VALUE
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


echo "---------------------------------------------------------"
echo "Running verification for design : $DESIGN with parameters
Multiplier1 stage   : $MUL_STAGE1
Multiplier2 stage   : $MUL_STAGE2
Multiplier3 stage   : $MUL_STAGE3
W                   : $W
Modulus Size        : $NBITS
LOG2(RADIX)         : $PBITS
Number of iteration : $NUMTRACE
"
echo "---------------------------------------------------------"



echo "---------------------Running vlogan-----------------"
   vlogan -kdb -sverilog +define+${TESTCASE} +define+DUTNAME=${DESIGN} +define+MUL_STAGE1=${MUL_STAGE1} +define+MUL_STAGE2=${MUL_STAGE2} +define+MUL_STAGE3=${MUL_STAGE3} +define+W=${W} +define+NUMBITS=${NBITS} +define+PBITS=$PBITS  +define+NUMTRACE=$NUMTRACE  -f verilog_files.txt  | tee vlogan.log

echo "---------------------vlogan Done--------------------"
echo "---------------------Running VCS--------------------"
vcs -lca +lint=all -V -kdb -sverilog -debug_access $TBENCH -o vcs_out/simv  | tee vcs.log

echo "---------------------VCS    Done--------------------"
if [ "$DEBUG" == "1" ]; then
  echo "Debug mode on"
  ./vcs_out/simv -gui=sx &
else
  echo "Debug mode off"
  ./vcs_out/simv
fi

echo "Simulation ends"
