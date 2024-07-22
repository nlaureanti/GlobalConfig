#!/bin/bash 

set echo

echo "---------- Begin of script ----------"
date
#
#
#    Scrip para remapear saídas do MOM6 global para o regional
#    Inputs: arquivo netcdf saídas do global + grade regional
#    Desenvolvido por Nicole C. Laureanti
#    nlaureanti@gmail.com
#
#

# Para uso de geração de g
# Global model definitions
export dir_saida="/home/lovelace/proj/proj891/nicole/programas/mom/create_obc_mix/output_exp_global/"

# Global model definitions
export fgrid="/home/lovelace/proj/proj891/nicole/Modelos/work19931101.1metros/INPUT/ocean_hgrid.nc"

# Arquivo para uso de remapeamento
export dirdata="/home/lovelace/proj/proj891/nicole/BESM3.0_InterpVert/"
export fnames="cmems_mod_glo_phy_my_0.083deg_P1D-m_multi-vars_180.00W-179.92E_80.00S-90.00N_0.49-5274.78m_1993-11-01.nc"


export layerfile="/home/lovelace/proj/proj891/nicole/BESM3.0_InterpVert/layer_6000_75.nc"
################################################################################
################################################################################

source /home/lovelace/proj/proj891/nicole/programas/lib.sh
src="/home/lovelace/proj/proj891/nicole/programas/mom/create_obc_mix/src/"
mkdir -p $dir_saida
cd $dir_saida
rm -f *.log obc*.nc tmp*


echo -ne ${mr}" criando arqs grid vazios em nc ${fim}${pr}"
ls ${dirdata}${fnames} || exit
fgrid_tmp=$dir_saida/ocean_hgrid.nc
cp ${fgrid} ${fgrid_tmp}
${src}/gridregional_to_binctl.sh ${fgrid_tmp} ${layerfile} ""
echo -ne $fim
cdo -L -s -f nc import_binary $(basename ${fgrid_tmp}| sed "s#.nc#.ctl#g") $(basename ${fgrid_tmp}) || exit
cdo remapdis,${fgrid_tmp} ${dirdata}${fnames} ${fnames}

echo -ne "${bg_mr} Vertical Interp ${fim} (allvar) \n"
ls ${fnames} || exit
ls ${layerfile} || exit
$src/transform_z.py ${layerfile} ${fnames}  Layer || exit

vvars=("temp" "salt" "ssh" "u" "v")
for n in $(seq 0 $(( ${#vvars[@]} -1 )) ); do
    v=${vvars[n]}

    #Definições
    if [[ $v == 'SSH'  ]] ; then 
	file2remap='${fnames}'
    else
	file2remap='$(echo ${fnames} |sed -i 's#.nc##g' )_zl.nc'
    fi
	echo -ne "${bg_mr} Remapeando ${fim} ic_${v}.nc \n"
	ls ${file2remap} || exit
	ls ${fgrid} || exit
        $src/remap_ic_from_glorys.sh ${fgrid} ${file2remap} ${v} initial 2> python.log || exit

done
        cdo -s -merge ic_salt.nc ic_ssh.nc ic_temp.nc ic_u.nc ic_v.nc ic_file.nc
rm -f tmp* *.{bin,ctl} obc_* obc2_* obc1_*  # ${fronteiranc[@]} global_*
cd - &>>/dev/null
    echo "FIM!"

