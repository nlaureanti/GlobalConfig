'set display color white'



vobc='north east south'
vvar='temp salt ssh u v'
vsuffix='ts ts ts u v'

l=1
while(l<=3)
var=subwrd(vvar,l)
var2=var'_segment_00'
suffix=subwrd(vsuffix,l)

k=1
while(k<4)
obc=subwrd(vobc,k)


if (obc = 'north')
sellat='set lat -20.125'
sellon='set lon -60 -20'
if (var = 'ssh')
var2='ssh_segment_001'
endif
endif

if (obc = 'south')
sellat='set lat -40'
sellon='set lon -60 -20'
if (var = 'ssh')
var2='ssh_segment_002'
endif
endif

if (obc = 'east')
sellat='set lat -40 -20'
sellon='set lon -20'
if (var = 'ssh')
var2='ssh_segment_003'
endif
endif
if (var = 'temp')
color='color 1 31 1 -kind lightblue->blue->orange->red->darkred->magenta'
else
color='color -var 'var2' -kind lightblue->blue->orange->red->darkred->magenta'
endif
'xdfopen ./obc3_'var'_'obc'_'suffix'.ddf'
'set z 1 50'
color
'd 'var2
'cbar'
'draw title OBC remap 'var' 'obc' vertical'
'printim OBC_remap_'var'_'obc'_vert.png'
'c'

if(var='ssh')
'd dz_'var'_segment_'
else
'd dz_'var'_segment'
endif
'cbar'
'draw title OBC remap dz 'obc' vertical'
'printim OBC_remap_dz_'obc'_vert.png'
'c'


'set z 45'
sellat
sellon
'set t 1 last'
color
'd 'var2''
'cbar'
'draw title OBC remap evolucao 'var' 'obc' sup'
'printim OBC_remap_evolucao_'var'_'obc'_sup.png'


'c'
'reinit'
'set display color white'
k=k+1
endwhile

l=l+1
endwhile

'reinit'
'set display color white'
nvars=3

'sdfopen ./ic_file.nc'
say result

k=1
while(k<=nvars)
var=subwrd(vvar,k)

sellat='set lat -40 -20'
sellon='set lon -60 -20'

if (var = 'temp')
color='color 1 31 1 -kind lightblue->blue->orange->red->darkred->magenta'
else
color='color -var 'var' -kind lightblue->blue->orange->red->darkred->magenta'
endif

'set z 45'
sellat
sellon
color
'd 'var''
'cbar'
'draw title IC input 'var' IC z=45 '
'printim ICinput_'var'_sup.png'
'c'

'set z 1'
sellat
sellon
'd 'var''
'cbar'
'draw title IC input 'var' z=1'
'printim ICinput_'var'_bottom.png'
'c'
k=k+1
endwhile

'quit'


