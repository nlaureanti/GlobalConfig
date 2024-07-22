#!/bin/bash

if [[ ${#1} == 0 ]] ;then 
read -p "file:    " fname
else 
fname=$1
fi

if [[ ${#2} == 0 ]] ;then 
read -p "plotar_bottom?    " bottom
else 
bottom=$2
fi

if [[ ${#3} == 0 ]] ;then
read -p "var?    " var
else
var=$3
fi



echo "'set display color white'
'c'
'xdfopen ${fname}'
say result
t=1
while(t<31)
'set t 't
'set z 1 50'
'color 0 27 3'
'd ${var}'
'draw title exp_SA001 \  ${var} dia 't 
'cbar'       
'printim exp_SA001_${var}_sup_'t'.png'
'c'
        
if (bottom = $bottom);
'color 0 27 3'
'set z 50'
'd ${var}'
'draw title exp_SA001 \  ${var} dia 't
'cbar'       
'printim exp_SA001_${var}_z50_'t'.png'  
'c'
endif
t=t+1      
endwhile
quit" > scrip.grads.gs



grads -pbc "run scrip.grads.gs" 
#convert exp_SA001__sup_{1..30}.png exp_SA001__sup.gif

