#!/bin/csh -f
#PBS -o ./testes.run.log
#PBS -j oe
#PBS -N submit_001
#PBS -q memshort
#PBS -l nodes=1:ppn=128

#Script para submeter jobs

set echo

echo "---------- Begin of script ----------"
date
/home/lovelace/proj/proj891/nicole/programas/mom/create_obc_mix/BESM_2script_cdo.sh
date
echo "---------- End of script ----------"
