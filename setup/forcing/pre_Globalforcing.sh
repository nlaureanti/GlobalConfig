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
export dir_saida="/home/nicole.laureanti/scratch/nicole.laureanti/data/era5_global/"
year='1993'

# Global model definitions
fgrid="/home/nicole.laureanti/scratch/nicole.laureanti/MOM6Global/grid/ocean_hgrid.nc"

# Arquivo para uso de remapeamento
dirdata="/home/nicole.laureanti/scratch/nicole.laureanti/data/era5_raw/"
fnames=(    'Era5_10m_u_component_of_wind'
            'Era5_10m_v_component_of_wind'
            'Era5_2m_temperature'
            'Era5_surface_solar_radiation_downwards'
            'Era5_surface_thermal_radiation_downwards'
            'Era5_total_rain_rate'
            'Era5_mean_sea_level_pressure'
            'Era5_2m_specific_humidity'
	    'Era5_sea_ice_cover')
layerfile='/home/nicole.laureanti/scratch/nicole.laureanti/MOM6Global/grid/layer_6000_75.nc'
################################################################################
################################################################################

source /home/nicole.laureanti/scratch/nicole.laureanti/MOM6Global/setup/lib.sh
src="/home/nicole.laureanti/scratch/nicole.laureanti/MOM6Global/setup/create_obc_mix/src/"
mkdir -p $dir_saida ${dir_saida}2/
cd $dir_saida
rm -f *.log obc*.nc tmp*

echo -ne ${mr}" criando arqs grid vazios em nc ${fim}${pr}"
fgrid_tmp=$dir_saida/ocean_hgrid.nc
cp ${fgrid} ${fgrid_tmp}
${src}/gridregional_to_binctl.sh ${fgrid_tmp} ${layerfile} ""
echo -ne $fim
cdo -L -s -f nc import_binary $(basename ${fgrid_tmp}| sed "s#.nc#.ctl#g") $(basename ${fgrid_tmp}) || exit

for f in $(seq 0 $(( ${#fnames[@]} -1 )) ); do
        fname=${fnames[f]}
        ls ${dirdata}${fname}_${year}.nc || exit
        cdo remapdis,${fgrid_tmp} ${dirdata}${fname}_${year}.nc ${fnames}
done

bash /home/nicole.laureanti/scratch/nicole.laureanti/MOM6Global/setup/forcing/GlobalSubset_calc_era5.py

cd - &>>/dev/null
    echo "FIM!"

