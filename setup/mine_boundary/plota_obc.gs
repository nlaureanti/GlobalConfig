'set display color white'
'c'
*==================================================================================

vobc='north south east'
var='temp'
fglobal='/home/nicole/Documentos/INPE/mom/exps_mom6/supers/tupa/exp_global_group0911/20010116.prog_ts.nc'

selz='set z 1 63'
color='color 1 30 2 -kind lightblue->blue->orange->red'

*==================================================================================
'!mkdir -p tmp_check_111'
k=1
while(k<4)
obc=subwrd(vobc,k)
'reinit'
'set display white'
'c'
if (obc = 'north')
sellat='set lat -20.125'
sellon='set lon -60 -20'
montage='!montage -mode concatenate -tile 7x2 tmp_check_111/MOMGlobal_temp_north_* tmp_check_111/BC_temp_north_* ./MOMGlobal_to_BC_temp_north.png'
endif

if (obc = 'south')
sellat='set lat -40'
sellon='set lon -60 -20'
montage='!montage -mode concatenate -tile 7x2 tmp_check_111/MOMGlobal_temp_south_* tmp_check_111/BC_temp_south_* ./MOMGlobal_to_BC_temp_south.png'
endif

if (obc = 'east')
sellat='set lat -40 -20'
sellon='set lon -20'
montage='!montage -mode concatenate -tile 7x2 tmp_check_111/MOMGlobal_temp_east_* tmp_check_111/BC_temp_east_* ./MOMGlobal_to_BC_temp_east.png'
endif



*Início do script
'sdfopen 'fglobal
say result
t=2
while(t<31)
'set t 't
say result
data=subwrd(result,4)
color
sellat
sellon
selz
'd 'var''
'draw title MOMGlobal - 'var' 'obc' dia 'data 
'cbar'
'printim tmp_check_111/MOMGlobal_'var'_'obc'_'t-1'.png'
'c'

t=t+5     
endwhile


color
sellat
selz
'd ave('var',t=1,t=30)'
'cbar'
'draw title MOMGlobal - 'var' 'obc' ave 1st mo' 
'printim tmp_check_111/MOMGlobal_'var'_'obc'_ave.png'  
'c'


'set z 63'
sellat
sellon
'set t 1 15'
color
'd 'var''
'cbar'
'draw title MOMGlobal evolucao 'var' 'obc' sup'
'printim MOMGlobalevolucao_'var'_'obc'_sup.png'

'reinit'
'set display color white'
'c'

fobc='./output_exp_AScoast001/obc3_'var'_'obc'_ts.nc'
'sdfopen 'fobc
say result

t=1
while(t<31)
'set t 't
say result
data=subwrd(result,4)
selz
color
'd 'var'_segment_00'
'draw title BC 'obc' - 'var' day 'data
'cbar'       
'printim tmp_check_111/BC_'var'_'obc'_'t'.png'
'c'
t=t+5
endwhile

selz
color
'd ave('var'_segment_00,t=1,t=30)'
'draw title BC 'obc' - 'var' ave 1st mo'
'cbar'
'printim tmp_check_111/BC_'var'_'obc'_ave.png'
'c'

'set z 63'
'set t 1 15'
color
'd 'var'_segment_00'
'cbar'
'draw title OBC evolucao 'var' 'obc' sup'
'printim OBCevolucao_'var'_'obc'_sup.png'


montage
k=k+1
endwhile
'!rm -r tmp_check_111'

quit
\How to create ddf file 
dset ^obc2_temp_east_ts.nc
options  365_day_calendar
tdef time 365 linear 01jan1900 1dy

echo "dset ^obc3_temp_east_ts.nc
options  365_day_calendar
tdef time 365 linear 01jan1900 1dy" > output_exp_AScoast_cdo/obc2_temp_east_ts.ddf ; echo "dset ^obc3_temp_north_ts.nc
options  365_day_calendar
tdef time 365 linear 01jan1900 1dy" > output_exp_AScoast_cdo/obc2_temp_north_ts.ddf ; echo "dset ^obc3_temp_south_ts.nc
options  365_day_calendar
tdef time 365 linear 01jan1900 1dy" > output_exp_AScoast_cdo/obc2_temp_south_ts.ddf
