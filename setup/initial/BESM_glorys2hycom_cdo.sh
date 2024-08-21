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
export dir_saida=$(pwd)"/output_exp_global_hycom/"

# Global model definitions
export fgrid="/home/nicole.laureanti/scratch/nicole.laureanti/GlobalConfig/grid/"

# Arquivo para uso de remapeamento
export dirdata="$(pwd)/"
export fnames="cmems_mod_glo_phy_my_0.083deg_P1D-m_multi-vars_180.00W-179.92E_80.00S-90.00N_0.49-5274.78m_1993-11-01.nc"


export layerfile="/home/nicole.laureanti/scratch/nicole.laureanti/GlobalConfig/grid/hycom1_75_800m.nc"
################################################################################
################################################################################

source $(pwd)/src/lib.sh
src="$(pwd)/src/"
mkdir -p $dir_saida
cd $dir_saida
rm -f *.log obc*.nc tmp* regrid*.nc	


( ls ${dirdata}${fnames} 2> originalfile.tmp ) || ( cat originalfile.tmp && exit 0 )
fgrid_tmp=$dir_saida/ocean_hgrid.nc
#fremap_cdo=$dir_saida/tmp.ocean_topog.nc
#cp ${fgrid}/topog.nc ${fremap_cdo}
#cp $fgrid/ocean_hgrid.nc $fgrid_tmp

vvars=("temp" "salt" "ssh" 'siconc' 'sithick' 'u' 'v')
vfvars=('thetao' 'so' 'zos' 'siconc' 'sithick' 'uo' 'vo')

#for n in 0 5 6  ; do #$(seq 0 $(( ${#vvars[@]} -1 )) ); do
for n in $(seq 0 $(( ${#vvars[@]} -1 )) ); do
    v=${vvars[n]}
    vf=${vfvars[n]}
    ls ${dirdata}${fnames} || exit	
    echo -ne ${mr}" criando arqs grid vazios em nc ${fim}${pr}"
    ${src}/gridregional_to_binctl_var.sh ${fgrid}/ocean_hgrid.nc ${layerfile} ${v} || exit
 
    echo -ne $fim
    cdo -L -s -f nc import_binary $(basename ${fgrid_tmp}| sed "s#.nc#.ctl#g") $(basename ${fgrid_tmp}) || exit
    #ignore all above
    #cp $(basename ${fgrid_tmp}| sed "s#.nc#.ctl#g") grid${v}.ctl
    #fgrid_tmp="../grid_${v}.nc"
    echo -ne "${bg_mr} Remap ${fim} ($v) \n"
    cdo  -L -s -chname,${vf},${v} -remapdis,${fgrid_tmp} -selvar,${vf} ${dirdata}${fnames} tmp.${fnames}
	(cdo showname tmp.${fnames} | grep $v ) || exit

    #Definições
    if [[ $v == 'ssh' || $v == 'zos' || $v == 'SSH' || $v == 'siconc' || $v == 'sithick' ]] ; then 
	file2remap=tmp.${fnames} #file remapped h with cdo, saves time
    else
	echo -ne "${bg_mr} Vertical Interp ${fim} ($v) \n"
	#$src/transform_z.py ${layerfile} tmp.${fnames} 'zt' || exit
	${src}/transform_vgrid2z.py ${layerfile} tmp.${fnames} 'dz' 6500 || exit
	file2remap="$( echo tmp.${fnames} |sed 's#.nc##g' )_zl.nc" #file remapped h with cdo and v with python, saves time
    fi
	echo -ne "${bg_mr} Remapeando ${fim} ic_${v}.nc \n"
	ls ${file2remap} || exit
	#ls ${fgrid} || exit
        #$src/remap_ic_from_glorys.sh ${fgrid_tmp} ${file2remap} ${v} initial #2> python.log || exit
	cdo  -setmissval,1e20 -fillmiss2 ${file2remap} ic_${v}.nc || exit

done
	rm -f ic_file.nc
        cdo -s -merge ic_salt.nc ic_ssh.nc ic_temp.nc ic_u.nc ic_v.nc ic_siconc.nc ic_sithick.nc ic_file.nc
#rm -f tmp* *.{bin,ctl} obc_* obc2_* obc1_*  # ${fronteiranc[@]} global_*
cd - &>>/dev/null
    echo "FIM!"

