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
dir_saida='output_exp_SA001/'

# Regional model definitions
fgrid='/home/nicole/Documentos/INPE/mom/exps_mom6/cenapad/exp_SA001/workdir/INPUT/ocean_hgrid.nc'
lati='-60'
latf='-5'
loni='290'
lonf='340'


# PAra uso de remapeamento
dirdata='/home/nicole/programas/downloads_automatizadores/SODA/'
fnames=('soda3.15.2_5dy_ocean_reg_2002.nc' 
	'soda3.15.2_5dy_ocean_reg_2002.nc' 
	'soda3.15.2_5dy_ocean_reg_2002.nc'  
	'soda3.15.2_5dy_ocean_reg_2002_u.nc' 
	'soda3.15.2_5dy_ocean_reg_2002_v.nc')

vvars=('temp' 'salt' 'ssh' 'u' 'v')


################################################################################
################################################################################
if [[ ${#1} == 0 ]] ;then 
read -p "remap_cdo? 1-yes 0-no    " remap_cdo
fi
if [[ ${#2} == 0 ]] ;then 
read -p "remap_python? 1-yes 0-no    " remap_python
fi

source /home/nicole/programas/lib.sh
src='/home/nicole/programas/cenapad/create_obc_cdo/src/'
mkdir -p $dir_saida
cd $dir_saida
rm -f *.log

for n in $(seq 0 $(( ${#vvars[@]} -1 )) ); do
    v=${vvars[n]}
    fname=${fnames[n]}

    #Definições
    fronteiractl=("north.ctl" "south.ctl" "east.ctl")
    fronteirasuffix=("_segment_001" "_segment_002" "_segment_003")
    fronteiracaract=("set lat $(( $latf -1 )) $latf';'set lon $loni $lonf" "set lat  $lati $(($lati +1))';'set lon $loni $lonf" "set lon $(($lonf -1)) $lonf';'set lat $lati $latf")
    fronteiraname=("north" "south" "east")
    if [[ $v == 'temp' || $v == 'salt' || $v == 'SSH' ||  $v == 'ssh' || $v == 'h' ]] ; then
        fronteiranc=("north_ts.nc" "south_ts.nc" "east_ts.nc")
    else
        fronteiranc=("north_${v}.nc" "south_${v}.nc" "east_${v}.nc")
    fi
    if [[ $v == 'SSH'  ]] ; then 
        dim2d='2d'
    else
        dim2d=''
    fi

    #Cria arquivos de grade regional vazios em netcdf
    echo -ne "> ${mr}Regional: ${fim} ${fronteiranc[@]} \n "


    if [[ ! -f $(basename ${fgrid}) || ! -f ${fronteiranc[0]} || ! -f ${fronteiranc[1]} || ! -f ${fronteiranc[2]} ]] ;then
        echo -ne ${mr}" criando arqs grid vazios em nc ${fim}${pr}"
        ${src}/gridregional_to_binctl.sh ${fgrid} ${dirdata}$fname $dim2d
        echo -ne $fim
        cdo -L -s -f nc import_binary $(basename ${fgrid}| sed "s#.nc#.ctl#g") $(basename ${fgrid}) || exit
        for n in 0 1 2 ; do
            cdo -L -s -f nc import_binary ${fronteiractl[n]} ${fronteiranc[n]} || exit
        done

    fi
    if [[ $remap_cdo = 1 ]]; then
    
            echo -ne "${bg_mr}${ps} Recortando arquivo com grads  \n $v ${fim} $fname \n "
            cdo -L -s showname ${dirdata}$fname

            for n in 0 1 2 ; do
        #Cria arquivo global em netcdf para extração das BC
                echo -ne "> ${mr}Global: ${fim} global_${v}-${fronteiraname[n]}.nc ${v} \n"
                echo "'sdfopen ${dirdata}${fname}'
        '${fronteiracaract[n]}'
        'set z 1 50'
        'set t 2 last'
        'set undef 1e20;*define ${v}=const(${v},0,-u)'
        'ncwrite ${v} global_${v}-${fronteiraname[n]}';quit" > scrip.grads.gs

                if [[ ! -f global_${v}-${fronteiraname[n]}.nc ]] ; then
                echo -ne " criando arqs dado global em nc ${pr}"
                grads -lbc "run scrip.grads.gs" 
                echo -ne $fim

                fi
            done
    
    
    for n in 0 1 2 ; do
        #Remapeamento para cada fronteira

            echo -ne "${bg_mr} Remapeando ${fim} obc2_${v}_${fronteiranc[$n]} \n"        
            if [[ $v == 'SSH' ||  $v == 'ssh' ]] ; then 
            cdo -L -s -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo -L -s -merge -chname,ssh,${v}${fronteirasuffix[$n]} -setcalendar,365_day   tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]}
            elif [[ $v == 'h' ]] ; then
            cdo -L -s -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo -L -s -merge -chname,h,dz_${v}${fronteirasuffix[$n]} -setcalendar,365_day   tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]}
            else
            cdo -L -s -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo -L -s -chname,${v},${v}${fronteirasuffix[$n]} -setcalendar,365_day   tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]}
            
            fi
            
            if [[ ! -f tmp_obc_h_${fronteiranc[$n]} ]]; then
		 ${src}/create_dx_from_soda.sh tmp_obc_${v}_${fronteiranc[$n]} tmp_obc_h_${fronteiranc[$n]}  || exit
       
            fi  

            #adição de dx_segment_
            if [[ $v != 'h'  ]] ; then            
		cdo -L -s -invertlev -fillmiss -merge -chname,h,dz_${v}${fronteirasuffix[$n]}  tmp_obc_h_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]} obc_${v}_${fronteiranc[$n]}
       
            fi
            
        if [[ $v != 'ssh' &&  $v != 'SSH' ]] ; then       
        #filling trough the vertical 
        ${src}/fill_OBC_vert.py obc_${v}_${fronteiranc[$n]} obc3_${v}_${fronteiranc[$n]} || exit
        else
        #filling trough the horizontal 
        ${src}/fill_OBC_horz.py obc_${v}_${fronteiranc[$n]} obc2_${v}_${fronteiranc[$n]} &>>/dev/null || exit
        ${src}/fill_OBC_vert.py obc2_${v}_${fronteiranc[$n]} obc3_${v}_${fronteiranc[$n]} || exit
        fi
    done

	echo -ne "${bg_mr} Remapeando ${fim} ic_${v}.nc \n"
	cdo -L -s -timmean  -remapdis,$(basename ${fgrid}) -seltimestep,1 ${dirdata}${fname} tmp_ic_h.nc
	cdo -L -s -selvar,$v tmp_ic_h.nc tmp_ic_${v}.nc
	${src}/fill_OBC_horz.py tmp_ic_${v}.nc tmp2_ic_${v}.nc || exit
	if [[ $v != 'ssh' && ! -f ic_h.nc ]] ; then 
	        ${src}/create_dx_from_soda.sh tmp_ic_h.nc tmp2_ic_h.nc || exit
	        #cdo -mermean -zonmean tmp2_ic_h.nc tmp3_ic_h.nc
	        ncwa -a time tmp2_ic_h.nc tmp3_ic_h.nc
	        ncks -c -O -x -v time  tmp3_ic_h.nc ic_h.nc
        fi
        ncwa -a time tmp2_ic_${v}.nc tmp3_ic_${v}.nc 
        ncks -c -O -x -v time  tmp3_ic_${v}.nc ic_${v}.nc
#        ncrename -d lon,nx ic_${v}.nc
#        ncrename -d lat,ny ic_${v}.nc
#        ncrename -d st_ocean,lev ic_${v}.nc 

	    
    fi
    
    if [[ $remap_python = 1 ]]; then
        echo -ne "${bg_mr}${ps} Recortando arquivo com grads  \n $v ${fim} $fname \n "
            cdo -L -s showname ${dirdata}$fname

            for n in 0 1 2 ; do
        #Cria arquivo global em netcdf para extração das BC
                echo -ne "> ${mr}Global: ${fim} global_${v}-${fronteiraname[n]}.nc ${v} \n"
                echo "'sdfopen ${dirdata}${fname}'
        '${fronteiracaract[n]}'
        'set z 1 50'
        'set t 2 last'
        'set undef 1e20;*define ${v}=const(${v},0,-u)'
        'ncwrite ${v} global_${v}-${fronteiraname[n]}';quit" > scrip.grads.gs

                if [[ ! -f global_${v}-${fronteiraname[n]}.nc ]] ; then
                echo -ne " criando arqs dado global em nc"
                grads -lbc "run scrip.grads.gs" >> grads.log || exit
                fi
            
                echo -ne "${bg_mr} Remapeando ${fim} obc ${fronteiraname[n]}\n"    
                ${src}/remap_obc_from_soda.sh ${fgrid} global_${v}-${fronteiraname[n]}.nc ${v} ${fronteiraname[n]} &>> python.log || exit
        done
    fi
    


done

if [[ $remap_cdo = 1 ]]; then
        cdo -s -merge ic_salt.nc ic_ssh.nc ic_temp.nc ic_u.nc ic_v.nc ic_file.nc
fi        

rm -f tmp* *.{bin,ctl} obc_* obc2_* # ${fronteiranc[@]} global_*
cd - &>>/dev/null
    echo "FIM!"

