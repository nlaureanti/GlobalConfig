'set display color white'
'c'

colorb='color 1 30 2 -kind lightblue->blue->orange->red'
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
'draw title IC input 'var' IC z=50 '
'printim ICinput_'var'_sup.png'
'c'

'set z 1'
sellat
sellon
color
'd 'var''
'cbar'
'draw title IC input 'var' z=1'
'printim ICinput_'var'_bottom.png'
'c'
k=k+1
endwhile

'reinit'
'set display white'
'c'
'!ls workdir/GOLD_IC_fix.nc || cdo timmean workdir/GOLD_IC.nc workdir/GOLD_IC_fix.nc'
'sdfopen workdir/GOLD_IC_fix.nc'
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
'draw title IC output 'var' IC z=50'
'printim ICoutput_'var'_sup.png'
'c'

'set z 1'
sellat
sellon
color
'd 'var''
'cbar'
'draw title IC output 'var' z=1'
'printim ICoutput_'var'_bottom.png'

'c'
k=k+1
endwhile
'quit'
