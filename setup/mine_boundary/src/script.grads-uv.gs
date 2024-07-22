'set display color white'

'sdfopen workdir/20020107.ocean_daily_z_ts.nc'
'sdfopen workdir/20020107.ocean_daily_z_u.nc'
'sdfopen workdir/20020107.ocean_daily_z_v.nc'
color='color 27 40 1 -kind lightblue->blue->orange->red'
vobc='north south east'
var='salt'


say result
t=1
while(t<31)
'set t 't
say result
time=subwrd(result,4)
color
'set z 50'
'd 'var
'draw title exp_AScoast002 (note) \ 'var'+correntes sup dia 'time
'cbar'
'set gxout vector'
'd skip(u.2,3);lterp(v.3,u.2)'
'printim exp_AScoast002_'var'_sup_'t'.png'
'c'
        
if (bottom = 0);
color
'set z 1'
'd 'var''
'draw title exp_AScoast002 (note) \ 'var'+correntes bottom dia 'time
'cbar'
'set gxout vector'
'd skip(u.2,3);lterp(v.3,u.2)'
'printim exp_AScoast002_'var'_bottom_'t'.png'  
'c'
endif
t=t+1      
endwhile


color
'd ave('var'(z=50),t=1,t=31)'
'cbar'
'set gxout vector'
'define uave=ave(u.2(z=50),t=1,t=31)'
'define vave=ave(v.3(z=50),t=1,t=31)'
'd skip(uave,3);lterp(vave,u.2)'
'draw title exp_AScoast002 (note) \ 'var'+correntes ave 2002-01' 
'printim exp_AScoast002_'var'_ave.png'  
'c'

'!montage -tile x1 -mode concatenate exp_AScoast002_salt_sup_1.png exp_AScoast002_salt_sup_11.png exp_AScoast002_salt_sup_26.png exp_AScoast002_salt_ave.png note_uv.png'



k=1
while(k<4)
obc=subwrd(vobc,k)
if (obc = 'north')
sellat='set lat -20.125'
sellon='set lon -60 -20'

endif

if (obc = 'south')
sellat='set lat -40'
sellon='set lon -60 -20'

endif

if (obc = 'east')
sellat='set lat -40 -20'
sellon='set x 80'

endif


'set z 50'
sellat
sellon
'set t 1 15'
color
'd 'var''
'cbar'
'draw title MOMRegional evolucao 'var' 'obc' sup'
'printim MOMRegionalevolucao_'var'_'obc'_sup.png'


'c'
k=k+1
endwhile
'quit'
quit


