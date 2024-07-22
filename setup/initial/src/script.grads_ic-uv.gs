'set display color white'
'c'

color='color 1 30 2 -kind lightblue->blue->orange->red'
color='color 14 26 1'
color='color 27 46 2 -kind lightblue->blue->orange->red'
vvar='salt'
nvars=1

'sdfopen workdir/INPUT/ic_file.nc'
say result

k=1
while(k<=nvars)
var=subwrd(vvar,k)

sellat='set lat -40 -20'
sellon='set lon -60 -20'


'set z 50'
sellat
sellon
color
'd 'var''
'cbar'
'set gxout vector'
'd u;skip(v,4)'
'draw title IC input 'var'+correntes IC z=50 '
'printim ICinput_'var'correntes_sup.png'
'c'

'set z 1'
sellat
sellon
color
'd 'var''
'cbar'
'set gxout vector'
'd u;skip(v,4)'
'draw title IC input 'var'+correntes  z=1'
'printim ICinput_'var'correntes _bottom.png'
'c'
k=k+1
endwhile

'reinit'
'set display white'
'c'
'!ls workdir/GOLD_IC_fix.nc || cdo -timmean workdir/GOLD_IC.nc workdir/GOLD_IC_fix.nc'
*'!ls workdir/GOLD_IC_fix-uv.nc || cdo -timmean -settaxis,2002-01-01,,1day -selvar,u,v  workdir/GOLD_IC.nc workdir/GOLD_IC_fix-uv.nc'
'sdfopen workdir/GOLD_IC_fix.nc'
'sdfopen workdir/GOLD_IC_fix-uv.nc'
say result
'q file 2'

k=1
while(k<=nvars)
var=subwrd(vvar,k)

sellat='set lat -40 -20'
sellon='set lon -60 -20'


'set z 50'
sellat
sellon
color
'd 'var''
'cbar'
'draw title IC output 'var'+correntes  IC z=50'
'printim ICoutput_'var'correntes _sup.png'
'c'

'set z 1'
sellat
sellon
color
'd 'var''
'd u.2;v.2'
'cbar'
'draw title IC output 'var'+correntes  z=1'
'printim ICoutput_'var'correntes _bottom.png'

'c'
k=k+1
endwhile
'quit'
