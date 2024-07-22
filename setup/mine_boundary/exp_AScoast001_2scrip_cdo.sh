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
dir_saida='output_exp_AScoast001/'

# Regional model definitions
fgrid='/home/nicole/Documentos/INPE/mom/exps_mom6//exp_AScoast_cdo/workdir/INPUT/ocean_hgrid.nc'  #NÃO USAR SUPERGRID
lati='-40'
latf='-20'
loni='-60'
lonf='-20'


# PAra uso de remapeamento
dirdata='/home/nicole/Documentos/INPE/mom/exps_mom6/supers/tupa/exp_global_group0911/'
fname_ts='20010116.prog_ts.nc'

vvars='temp salt SSH u v'

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
    fronteiracaract=("set lat $(( $latf -1 )) $latf';'set lon $loni $lonf" "set lat $(($lati -1)) $lati';'set lon $loni $lonf" "set lon $(($lonf -1)) $lonf';'set lat $lati $latf")
    fronteiraname=("north" "south" "east")
    if [[ $v == 'temp' || $v == 'salt' || $v == 'h' ]] ; then 
        fname=$fname_ts
        fronteiranc=("north_ts.nc" "south_ts.nc" "east_ts.nc")
        fronteiraddf=("north_ts.ddf" "south_ts.ddf" "east_ts.ddf")        
    elif [[  $v == 'SSH' || $v == 'ssh' ]] ; then 
        fname="20010116.prog_ssh.nc"
        fronteiranc=("north_${v}.nc" "south_${v}.nc" "east_${v}.nc")
        fronteiraddf=("north_${v}.ddf" "south_${v}.ddf" "east_${v}.ddf")        
        dim2d='2d'
    else
        fname="20010116.prog_${v}.nc"
        fronteiranc=("north_${v}.nc" "south_${v}.nc" "east_${v}.nc")
    fi

    #Cria arquivos de grade regional vazios em netcdf
    echo -ne "> ${mr}Regional: ${fim} ${fronteiranc[@]} \n "


    if [[ ! -f $(basename ${fgrid}) || ! -f ${fronteiranc[0]} || ! -f ${fronteiranc[1]} || ! -f ${fronteiranc[2]} ]] ;then
        echo -ne ${mr}" criando arqs grid vazios em nc ${fim}${pr}"
        ${src}/gridregional_to_binctl.sh ${fgrid} ${dirdata}$fname $dim2d
        echo -ne $fim
        cdo  -s -f nc import_binary $(basename ${fgrid}| cut -f1 -d'.')'.ctl' $(basename ${fgrid}) || exit
        for n in 0 1 2 ; do
            cdo  -s -f nc import_binary ${fronteiractl[n]} ${fronteiranc[n]} || exit
        done

    fi
    if [[ $1 = 1 || $remap = 1 ]]; then
            echo -ne "${bg_mr}${ps} Recortando arquivo com grads  \n $v ${fim} $fname \n "
            cdo  -s showname ${dirdata}$fname

            for n in 0 1 2 ; do
        #Cria arquivo global em netcdf para extração das BC
                echo -ne "> ${mr}Global: ${fim} global_${v}-${fronteiraname[n]}.nc ${v} \n"
                echo "'sdfopen ${dirdata}${fname}'
        '${fronteiracaract[n]}'
        'set z 1 50'
        'set t 2 last'
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
            echo -ne "${bg_mr} Remapeando ${fim} obc2_${v}_${fronteiranc[$n]} \n"        
            if [[ $v == 'SSH' || $v == 'ssh' ]] ; then 
            cdo  -s -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo  -s  -chname,ssh,${v}${fronteirasuffix[$n]}  tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]}
            elif [[ $v == 'h' ]] ; then
            cdo  -s  -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cp tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]}
            else #####################
            cdo -s  -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo  -s   -chname,${v},${v}${fronteirasuffix[$n]}   tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]}
            
            fi
            
            if [[ ! -f tmp_obc_h_${fronteiranc[$n]} ]]; then       
                ${src}/create_dx_from_soda.sh tmp_obc_${v}_${fronteiranc[$n]} tmp_obc_h_${fronteiranc[$n]}  || exit   
            fi           

            #adição de dx_segment_
            if [[ $v != 'h' ]] ; then 
            cdo  -s -setcalendar,gregorian -chname,h,dz_${v}${fronteirasuffix[$n]} -merge tmp_obc_h_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]} obc_${v}_${fronteiranc[$n]}
            fi
        fi

        if [[ $v == 'ssh' &&  $v == 'SSH' ]] ; then       
        #filling trough the vertical 
        ${src}/fill_OBC_vert.py obc_${v}_${fronteiranc[$n]} obc3_${v}_${fronteiranc[$n]}  || exit
        else
        #filling trough the horizontal 
        ${src}/fill_OBC_horz.py obc_${v}_${fronteiranc[$n]} obc2_${v}_${fronteiranc[$n]}  || exit
        ${src}/fill_OBC_vert.py obc2_${v}_${fronteiranc[$n]} obc3_${v}_${fronteiranc[$n]} || exit
        fi
    done
        if [[ $1 = 1 || $remap = 1 ]]; then
	        echo -ne "${bg_mr} Remapeando ${fim} ic_${v}.nc \n"
	        cdo -s -remapdis,$(basename ${fgrid}) -seltimestep,1 -selvar,$v ${dirdata}${fname}  tmp_ic_${v}.nc
	        
	        ${src}/fill_OBC_horz.py tmp_ic_${v}.nc tmp2_ic_${v}.nc  &>>/dev/null || exit
	       
	        
	        if [[ $v == 'h' && ! -f ic_h.nc ]] ; then 
        	        cdo -s -remapdis,$(basename ${fgrid}) -seltimestep,1 -selvar,h ${dirdata}${fname}  tmp_ic_h.nc                
	                #cdo -mermean -zonmean tmp2_ic_h.nc tmp3_ic_h.nc
	                ncwa -a Time tmp_ic_h.nc tmp3_ic_h.nc
	                ncks -c -O -x -v Time  tmp3_ic_h.nc ic_h.nc
                fi
                ncwa -a Time tmp2_ic_${v}.nc tmp3_ic_${v}.nc 
                ncks -c -O -x -v Time  tmp3_ic_${v}.nc ic_${v}.nc
                #ncrename -d lon,nx ic_${v}.nc
                #ncrename -d lat,ny ic_${v}.nc
        #        ncrename -d st_ocean,lev ic_${v}.nc 
        
        fi
    for n in 0 1 2 ; do
    echo "dset ^obc3_${v}_${fronteiranc[$n]}
options  365_day_calendar
tdef time 365 linear 01jan1900 1dy" > obc3_${v}_${fronteiraddf[$n]}
   done              

done

if [[ $1 = 1 || $remap = 1 ]]; then
        cdo  -b f32 -s -merge ic_temp.nc ic_salt.nc ic_SSH.nc ic_u.nc ic_v.nc ic_file.nc
fi
 grads -lbc "run ../src/script.grads.gs"
rm -f tmp* *.{bin,ctl} obc_*  # ${fronteiranc[@]} global_*
cd - &>>/dev/null
    echo "FIM!"

