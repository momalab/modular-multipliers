#!/bin/sh


function usage()
{
    echo "Script to run synthesis"
    echo "./run_verif.sh -design    <design_name in ../rtl>
               -nbits     <modulus size>
               -pbits     <log2(radix)>
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
        -debug | --debug)
            export DEBUG=$VALUE
            ;;
        -testcase | --testcase)
            export TESTCASE=$VALUE
            ;;
        -pbits | --pbits)
            export PBITS=$VALUE
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
Modulus Size        : $NBITS
LOG2(RADIX)         : $PBITS
Number of iteration : $NUMTRACE
"
echo "---------------------------------------------------------"



echo "---------------------Running vlogan-----------------"
   vlogan -kdb -sverilog +define+${TESTCASE} +define+DUTNAME=${DESIGN} +define+NUMBITS=${NBITS} +define+PBITS=$PBITS  +define+NUMTRACE=$NUMTRACE  -f verilog_files.txt  | tee vlogan.log

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
