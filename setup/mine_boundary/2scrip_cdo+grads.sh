#!/bin/bash
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
dir_saida='output_exp_AScoast_cdo-isopc/'

# Regional model definitions
fgrid='/home/nicole/Documentos/INPE/mom/exps_mom6//exp_AScoast_cdo/workdir/INPUT/ocean_hgrid.nc'  #NÃO USAR SUPERGRID
lati='-40'
latf='-20'
loni='-60'
lonf='-20'


# PAra uso de remapeamento
#dirdata='/home/nicole/Documentos/INPE/mom/exps_mom6/cenapad/exp_g001/'
dirdata='/home/nicole/Documentos/INPE/mom/exps_mom6/supers/tupa/exp_global_group0911/'
fname_ts='20010116.prog_ts.nc'

vvars='h temp salt SSH u v'

################################################################################
################################################################################
if [[ ${#1} == 0 ]] ;then 
read -p "remap? 1-yes 0-no    " remap
fi
source ~/programas/lib.sh
src='/home/nicole/programas/cenapad/create_obc_cdo/src/'
mkdir -p $dir_saida
cd $dir_saida

for v in $vvars; do
    #Definições
    fronteiractl=("north.ctl" "south.ctl" "east.ctl")
    fronteirasuffix=("_segment_001" "_segment_002" "_segment_003")
    fronteiracaract=("set lat $(( $latf -1 )) $latf';'set lon $loni $lonf" "set lat  $lati $(($lati +1))';'set lon $loni $lonf" "set lon $(($lonf -1)) $lonf';'set lat $lati $latf")
    fronteiraname=("north" "south" "east")
    if [[ $v == 'temp' || $v == 'salt' || $v == 'SSH' || $v == 'h' ]] ; then 
        fname=$fname_ts
        fronteiranc=("north_ts.nc" "south_ts.nc" "east_ts.nc")
    else
        fname="20010116.prog_${v}.nc"
        fronteiranc=("north_${v}.nc" "south_${v}.nc" "east_${v}.nc")
    fi
    if [[ $v == 'SSH' ]] ; then 
        dim2d='2d'
    else
        dim2d=''
    fi

    #Cria arquivos de grade regional vazios em netcdf
    echo -ne "> ${mr}Regional: ${fim} ${fronteiranc[@]} \n "


    if [[ ! -f $(basename ${fgrid}) || ! -f ${fronteiranc[0]} || ! -f ${fronteiranc[1]} || ! -f ${fronteiranc[2]} ]] ;then
        echo -ne ${mr}" criando arqs grid vazios em nc ${fim}${pr}"
        ${src}/gridregional_to_binctl.sh ${fgrid} ${dirdata}$(echo $fname | sed 's#.ddf#.nc#g') $dim2d
        echo -ne $fim
        cdo  -s -f nc import_binary $(basename ${fgrid}| cut -f1 -d'.')'.ctl' $(basename ${fgrid}) || exit
        for n in 0 1 2 ; do
            cdo  -s -f nc import_binary ${fronteiractl[n]} ${fronteiranc[n]} || exit
        done

    fi
    if [[ $1 = 1 || $remap = 1 ]]; then
            echo -ne "${bg_mr}${ps} Recortando arquivo com grads  \n $v ${fim} $fname \n "
            cdo  -s showname ${dirdata}$(echo $fname | sed 's#.ddf#.nc#g')

            for n in 0 1 2 ; do
        #Cria arquivo global em netcdf para extração das BC
                echo -ne "> ${mr}Global: ${fim} global_${v}-${fronteiraname[n]}.nc ${v} \n"
                echo "'sdfopen ${dirdata}${fname}'
        '${fronteiracaract[n]}'
        'set z 1 63'
        'set t 2 90'
        'set undef 1e20'
        'ncwrite ${v} global_${v}-${fronteiraname[n]}';quit" > scrip.grads.gs

                if [[ ! -f global_${v}-${fronteiraname[n]}.nc ]] ; then
                echo -ne " criando arqs dado global em nc ${pr}"
                grads -lbc "run scrip.grads.gs" 
                echo -ne $fim

                fi
            done
    fi
    
    for n in 0 1 2 ; do
        #Remapeamento para cada fronteira
        if [[ $1 = 1 || $remap = 1 ]]; then
	    echo -ne "${bg_mr} Remapeando ${fim} ic_${v}.nc \n"
 	    cdo  -s -remapdis,$(basename ${fgrid}) -seltimestep,1 global_${v}-${fronteiraname[n]}.nc ic_${v}.nc
 

            echo -ne "${bg_mr} Remapeando ${fim} obc2_${v}_${fronteiranc[$n]} \n"        
            if [[ $v == 'SSH' ]] ; then 
            cdo  -s -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo  -s -setcalendar,gregorian -chname,ssh,${v}${fronteirasuffix[$n]}  tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]}
            elif [[ $v == 'h' ]] ; then
            cdo  -s  -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo -s -setcalendar,gregorian tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]}
            else
            cdo -s -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo  -s -setcalendar,gregorian -chname,${v},${v}${fronteirasuffix[$n]}  tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]}
            
            fi
            
            if [[ ! -f tmp_obc_h_${fronteiranc[$n]} ]]; then
                cdo  -s  -remapdis,${fronteiranc[$n]} global_h-${fronteiraname[n]}.nc tmp_h_${fronteiranc[$n]} || exit
                cdo  -s -setcalendar,gregorian tmp_h_${fronteiranc[$n]} tmp_obc_h_${fronteiranc[$n]}
#                ${src}/create_dx_from_soda.sh tmp_obc_${v}_${fronteiranc[$n]} tmp_obc_h_${fronteiranc[$n]}  || exit     #apenas quando a coord vert é z
            fi  

            #adição de dx_segment_
            if [[ $v != 'h' ]] ; then 
                 
            cdo  -s -merge -chname,h,dz_${v}${fronteirasuffix[$n]}  tmp_obc_h_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]} obc2_${v}_${fronteiranc[$n]}
            
                if [[ $v != 'ssh' &&  $v != 'SSH' ]] ; then       
                #filling trough the vertical 
                ${src}/fill_OBC_vert.py obc2_${v}_${fronteiranc[$n]} obc3_${v}_${fronteiranc[$n]}  || exit
                else
                #filling trough the horizontal 
                ${src}/fill_OBC_horz.py obc2_${v}_${fronteiranc[$n]} obc3_${v}_${fronteiranc[$n]}  || exit
                ${src}/fill_OBC_vert.py obc2_${v}_${fronteiranc[$n]} obc3_${v}_${fronteiranc[$n]} || exit
                fi
        fi
            
        fi
    done


done
if [[ $1 = 1 || $remap = 1 ]]; then
        cdo  -s -merge ic_temp.nc ic_salt.nc ic_SSH.nc ic_u.nc ic_v.nc ic_file.nc
fi

rm -f tmp_* *.{bin,ctl} # ${fronteiranc[@]} global_*
cd - &>>/dev/null
    echo "FIM!"

