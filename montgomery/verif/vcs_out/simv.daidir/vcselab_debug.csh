#!/bin/csh -f

cd /home/dss545/fhe/dse_mult/montgomery/verif

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/opt/programs/synopsys/vcs-sx/vcs/R-2020.12-SP1/linux64/bin/vcselab $* \
    -o \
    vcs_out/simv \
    -nobanner \

cd -

