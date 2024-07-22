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
fgrid='/home/nicole/mom/exps_mom6/supers/tupa/exp_SA001/workdir/INPUT/ocean_hgrid.nc'
lati='-60'
latf='-5'
loni='290'
lonf='340'
#'set lat -60 -5'
#'set lon -70 -20'

# PAra uso de remapeamento
dirdata='/home/nicole/Documentos/INPE/dados_tese/SODA/'
fnames=('soda3.15.2_5dy_ocean_reg_2001-2002_ts.nc' 
	'soda3.15.2_5dy_ocean_reg_2001-2002_ts.nc' 
	'soda3.15.2_5dy_ocean_reg_2001-2002_ts.nc'  
	'soda3.15.2_5dy_ocean_reg_2001-2002_u.nc' 
	'soda3.15.2_5dy_ocean_reg_2001-2002_v.nc')

vvars=('temp' 'salt' 'ssh' 'u' 'v')

method='' #depth, h, soda
dzfile='/home/nicole/mom/create_layer/exp_SA001/create_dz_to_obcs_layer.nc' #use depth
dzfile_h='/home/nicole/mom/create_obc/create_obc_mix/dz_prog.nc' #use h
################################################################################
################################################################################
if [[ ${#1} == 0 ]] ;then 
read -p "remap_cdo? 1-yes 0-no    " remap_cdo
else
remap_cdo=$1
fi

if [[ ${#2} == 0 ]] ;then 
read -p "remap_python? 1-yes 0-no    " remap_python
else
remap_python=$2
fi

source /home/nicole/programas/lib.sh
src='/media/nicole/Arquivos/Backup/Documentos/INPE/mom/create_obc/create_obc_mix/src/'
mkdir -p $dir_saida
cd $dir_saida
rm -f *.log obc*.nc tmp*

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
        fronteiraddf=("north_ts.ddf" "south_ts.ddf" "east_ts.ddf")
    else
        fronteiranc=("north_${v}.nc" "south_${v}.nc" "east_${v}.nc")
        fronteiraddf=("north_${v}.ddf" "south_${v}.ddf" "east_${v}.ddf")
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
            cdo -L -s -chname,ssh,${v}${fronteirasuffix[$n]}  tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]} || exit
            elif [[ $v == 'h' ]] ; then
            cdo -L -s -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo -L -s -chname,h,dz_${v}${fronteirasuffix[$n]}  tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]} || exit
            else
            cdo -L -s -remapdis,${fronteiranc[$n]} global_${v}-${fronteiraname[n]}.nc tmp_${v}_${fronteiranc[$n]} || exit
            cdo -L -s -chname,${v},${v}${fronteirasuffix[$n]}  tmp_${v}_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]} || exit
            
            fi
            
            if [[ ! -f tmp_obc_h_${fronteiranc[$n]} ]]; then
                echo "Create dx from $method"
                if [[ $method == 'depth' ]]; then
		dztmp='tmp_layer.dz.nc'
		cdo -s -L -remapdis,${fronteiranc[$n]} $dzfile $dztmp || exit
		${src}/create_dx_from_depth.sh "tmp_layer.dz.nc" tmp_obc_${v}_${fronteiranc[$n]} tmp_obc_h_${fronteiranc[$n]}  || exit
		elif [[ $method == 'h' ]] ; then
		dztmp='tmp_layer.dz.nc'
		cdo -s -L -remapdis,${fronteiranc[$n]} $dzfile_h $dztmp || exit
		${src}/create_dx_from_h.sh "tmp_layer.dz.nc" tmp_obc_${v}_${fronteiranc[$n]} tmp_obc_h_${fronteiranc[$n]}  || exit
		else 
		${src}/create_dx_from_soda.sh tmp_obc_${v}_${fronteiranc[$n]} tmp_obc_h_${fronteiranc[$n]}  || exit
		#
		#
		fi
       
            fi  

            #adição de dx_segment_
            if [[ $v != 'h'  ]] ; then 
                       
		#cdo -L -s -merge tmp_obc_h_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]} obc_${v}_${fronteiranc[$n]}
		#cdo -L -s -setcalendar,365_day -chname,h,dz_${v}${fronteirasuffix[$n]} obc_${v}_${fronteiranc[$n]} obc1_${v}_${fronteiranc[$n]}
		
		cdo -L -s -merge tmp_obc_h_${fronteiranc[$n]} tmp_obc_${v}_${fronteiranc[$n]} obc_${v}_${fronteiranc[$n]} || exit
		cdo -L -s -setcalendar,365_day -chname,dz,dz_${v}${fronteirasuffix[$n]} obc_${v}_${fronteiranc[$n]} obc0_${v}_${fronteiranc[$n]} || exit
		cdo -L -invertlev obc0_${v}_${fronteiranc[$n]} obc1_${v}_${fronteiranc[$n]} || exit
       
            fi
            
        if [[ $v == 'ssh' &&  $v == 'SSH' ]] ; then       
        #filling trough the vertical 
        ${src}/fill_OBC_vert.py obc1_${v}_${fronteiranc[$n]} obc3_${v}_${fronteiranc[$n]} || exit
        else
        #filling trough the horizontal 
        ${src}/fill_OBC_horz.py obc1_${v}_${fronteiranc[$n]} obc2_${v}_${fronteiranc[$n]} || exit
        ${src}/fill_OBC_vert.py obc2_${v}_${fronteiranc[$n]} obc3_${v}_${fronteiranc[$n]} || exit
        fi
    #exit    
    done
        
	echo -ne "${bg_mr} Remapeando ${fim} ic_${v}.nc \n"
	cdo -L -s -timmean  -remapdis,$(basename ${fgrid}) -seltimestep,1 ${dirdata}${fname} tmp_ic_h.nc
	cdo -L -s -selvar,$v tmp_ic_h.nc tmp_ic_${v}.nc
	${src}/fill_OBC_horz.py tmp_ic_${v}.nc tmp2_ic_${v}.nc || exit
	if [[ $v != 'ssh' && ! -f ic_h.nc ]] ; then 
	        cdo -s -L -remapdis,$(basename ${fgrid})  $dzfile tmp2_ic_h.nc || exit
	        #${src}/create_dx_from_soda.sh tmp_ic_h.nc tmp2_ic_h.nc || exit
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
                python ${src}/remap_obc_from_soda.sh ${fgrid} global_${v}-${fronteiraname[n]}.nc ${v} ${fronteiraname[n]} 2> python.log || exit
        done
    fi
    
    for n in 0 1 2 ; do
    echo "dset ^obc3_${v}_${fronteiranc[$n]}
options  365_day_calendar
tdef time 145 linear 01jan2001 1dy" > obc3_${v}_${fronteiraddf[$n]}
   done
   

done

if [[ $remap_cdo = 1 ]]; then
        cdo -s -merge ic_salt.nc ic_ssh.nc ic_temp.nc ic_u.nc ic_v.nc ic_file.nc
fi        


        grads -lbc "run ../src/script.grads.gs" 


rm -f tmp* *.{bin,ctl} obc_* obc2_* obc1_*  # ${fronteiranc[@]} global_*
cd - &>>/dev/null
    echo "FIM!"

