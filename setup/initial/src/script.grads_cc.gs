'set display color white'
'c'

color='color 1 30 2 -kind lightblue->blue->orange->red'
vobc='north south east'
var='temp'

'!mkdir -p tmp'

'sdfopen workdir/20020107.ocean_daily_ts.nc'
say result

k=1
while(k<4)
obc=subwrd(vobc,k)

if (obc = 'north')
sellat='set lat -20.125'
sellon='set lon -60 -20'
montage='!montage -mode concatenate -tile x1 tmp/obcout_exp_AScoast002_temp_north_*  ./obcout_exp_AScoast002_north.png'
endif

if (obc = 'south')
sellat='set lat -40'
sellon='set lon -60 -20'
montage='!montage -mode concatenate -tile x1 tmp/obcout_exp_AScoast002_temp_south_* ./obcout_exp_AScoast002_south.png'
endif

if (obc = 'east')
sellat='set lat -40 -20'
sellon='set x 80'
montage='!montage -mode concatenate -tile x1 tmp/obcout_exp_AScoast002_temp_east_* ./obcout_exp_AScoast002_east.png'
endif

t=1
while(t<31)
'set t 't
say result
time=subwrd(result,4)

sellat
sellon
'set z 1 50'
color
'd temp'
'draw title exp_AScoast002 'var' 'obc' dia 'time
'cbar'       
'printim tmp/obcout_exp_AScoast002_'var'_'obc'_'t'.png'
'c'

t=t+5     
endwhile

montage
k=k+1
endwhile

quit
