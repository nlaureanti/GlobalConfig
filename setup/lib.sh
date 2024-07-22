#!/bin/bash

{

#Início da declaração de variáveis de formatação de texto e fundo.
   #Micelânea.
   nh='\e[00m' #Nenhum.

   #Estilos aplicados às fontes.
   ng='\e[01m' #Negrito.
   sb='\e[04m' #Sublinhado.
   ps='\e[05m' #Piscante.
   rv='\e[07m' #Reverso.
   oc='\e[08m' #Oculto.

   #Cores da fonte.
   pt='\e[30m' #Preto.
   vm='\e[31m' #Vermelho.
   vd='\e[32m' #Verde.
   mr='\e[33m' #Marrom.
   az='\e[34m' #Azul.
   rx='\e[35m' #Roxo.
   ci='\e[36m' #Ciano.
   pr='\e[37m' #Prata.
   cz='\e[1;30m' #Cinza.
   am='\e[1;33m' #Amarelo.
   br='\e[1;37m' #Branco.

   #Cores de fundo.
   bg_pt='\e[40m' #Preto.
   bg_vm='\e[41m' #Vermelho.
   bg_vd='\e[42m' #Verde.
   bg_mr='\e[43m' #Marrom.
   bg_az='\e[44m' #Azul.
   bg_rx='\e[45m' #Roxo.
   bg_ci='\e[46m' #Ciano.
   bg_pr='\e[47m' #Prata.

	fim="\033[00m"
#Fim da declaração de variáveis de formatação de texto e fundo.

}

function help_lib(){
echo -e "--------------------------------------------\n"
echo -e "ctl_info \n ctl_info_str \n dir_ctl \n gerar_ctl \n verificar_dimensoes \n listar_binarios \n definir_tper \n verificar_ctl \n gera_unidade \n name_var_translate \n  GERA_FAS"

}

function ctl_info(){

   if [ $# -lt 2 ]; then
      echo "null"
      exit
   fi

   ctl=$1
   arg=$2

   if [ ! -e $ctl ]; then
      echo "Erro na função bash \"ctl_info\". Arquivo inexistente!"
      exit
   fi

   #echo "Arquivo: $ctl";

   case $arg in
      -filename)
         nome=$(grep -i "^dset" $ctl | tr -s " " | cut -d " " -f2)
         ini=$(echo "$nome"|cut -c1)
         if [ "$ini" == "^" ];then
            bin=$(echo ${nome}|cut -c2-)
            dir_ctl=$(dir_ctl $ctl $bin)
            echo ${dir_ctl}${bin}
         else
            echo ${nome}
         fi
         ;;
      -dset) echo $(grep -i "^dset" $ctl | tr -s "^" " " | cut -d " " -f2);;
      -undef) echo $(grep -i "^undef" $ctl | tr -s " " | cut -d " " -f2);;
      -title) echo $(grep -i "^title" $ctl | tr -s " " | cut -d " " -f2-);;

      -nx) echo $(grep -i "^xdef" $ctl | tr -s " " | cut -d " " -f2);;
      -lon) echo $(grep -i "^xdef" $ctl | tr -s " " | cut -d " " -f4);;
      -dx) echo $(grep -i "^xdef" $ctl | tr -s " " | cut -d " " -f5);;

      -ny) echo $(grep -i "^ydef" $ctl | tr -s " " | cut -d " " -f2);;
      -lat) echo $(grep -i "^ydef" $ctl | tr -s " " | cut -d " " -f4);;
      -dy) echo $(grep -i "^ydef" $ctl | tr -s " " | cut -d " " -f5);;

      -nt) echo $(grep -i "^tdef" $ctl | tr -s " " | cut -d " " -f2);;
      -data) echo $(grep -i "^tdef" $ctl | tr -s " " | cut -d " " -f4);;
      -anoi) data=$(grep -i "^tdef" $ctl | tr -s " " | cut -d " " -f4); echo $(echo $(echo ${data} | tr -s "A-Z" "a-z") | cut -d"n" -f2) ;;
      -dt) echo $(grep -i "^tdef" $ctl | tr -s " " | cut -d " " -f5);;

      -nz) echo $(grep -i "^zdef" $ctl | tr -s " " | cut -d " " -f2);;
      -levels) echo $(grep -i "levels" $ctl | cut -d 's' -f2-);;
      -dz) echo $(grep -i "^zdef" $ctl | tr -s " " | cut -d " " -f5);;

#      -vars) echo $(awk 'c-->0;/vars/{c=1}' $ctl| cut -d " " -f1);;
      -vars) echo $(grep -A1 -i "^vars" $ctl|grep -v "^vars" | tr -s " " | cut -d " " -f1);;
      *) echo "Erro na funcao bash \"ctl_info\". Opcao invalida: ${arq}!"
   esac

}



function ctl_info_str(){

   if [ $# -lt 1 ]; then
      echo "null"
      exit
   fi

   ctl=$1

   if [ ! -e $ctl ]; then
      echo "Erro na função bash \"ctl_info_str\". Arquivo inexistente!"
      exit
   fi

   dir_ctl=$(dir_ctl $ctl)
   nx=$(ctl_info $ctl -nx)
   ny=$(ctl_info $ctl -ny)
   nt=$(ctl_info $ctl -nt)
   undef=$(ctl_info $ctl -undef)
   bin=$(ctl_info $ctl -filename)

   echo "${dir_ctl}${bin} $nx $ny $nt $undef"

}



function dir_ctl(){

   ctl=$1

   dir_ctl=${ctl%/*}

   if [ $# == "1" ];then
      bin=$(ctl_info $ctl -filename)
   else
      bin=$2
   fi

   if [ "$dir_ctl" == "$ctl" ]; then
      dir_ctl=""
   elif [ ! -f $dir_ctl/$bin ]; then
      dir_ctl=""
   else
      dir_ctl="$dir_ctl/"
   fi

   echo $dir_ctl
}



function gerar_ctl(){

   for arg in $*; do
      case $arg in
         -ctl_in=*) ctl_in=${arg//-ctl_in=/};;
         -ctl_out=*) ctl_out=${arg//-ctl_out=/};;
         -nx=*) nx_nv=${arg//-nx=/};;
         -ny=*) ny_nv=${arg//-ny=/};;
         -nt=*) nt_nv=${arg//-nt=/};;
         -dx=*) dx_nv=${arg//-dx=/};;
         -dy=*) dy_nv=${arg//-dy=/};;
         -data=*) data_nv=${arg//-data=/};;
         -lat=*) lat_nv=${arg//-lat=/};;
         -lon=*) lon_nv=${arg//-lon=/};;
         -undef=*) undef_nv=${arg//-undef=/};;
         -filename=*) nome_nv=${arg//-filename=/};;
         -title=*) titulo_nv=${arg//-title=/};;
         -dt=*) dt_nv=${arg//-dt=/};;
         *) echo "Erro na funca bash \"gerar_ctl\". Opcao invalida: ${arg}!"
      esac
   done

if [[ ${#ctl_in} -eq 0 ]] ; then
	ctl_in=.tmp.ctl
	local $ctl_in
	echo -ne "dset ^arq.bin \n title ^title_arq \nundef 9999.9 \nxdef 144 linear 0 2.5\nydef 73 linear -90 2.5 \nzdef 1 levels 0 1 \ntdef 828 linear jan1948 1mo\n vars 1 \n uwnd  0 9999.9  t,z,y,x  Monthly mean u wind\nendvars" > $ctl_in

fi
   cp $ctl_in $ctl_out

   nx=$(ctl_info $ctl_in -nx)
   ny=$(ctl_info $ctl_in -ny)
   nt=$(ctl_info $ctl_in -nt)
   undef=$(ctl_info $ctl_in -undef)
   bin=$(ctl_info $ctl_in -filename)
   data=$(ctl_info $ctl_in -data)
   lat=$(ctl_info $ctl_in -lat)
   lon=$(ctl_info $ctl_in -lon)
   dx=$(ctl_info $ctl_in -dx)
   dy=$(ctl_info $ctl_in -dy)
   dt=$(ctl_info $ctl_in -dt)
#   nome=$(ctl_info $ctl_in -filename)
   nome=$(ctl_info $ctl_in -dset)
   titulo=$(ctl_info $ctl_in -title)



   #http://www.vivaolinux.com.br/dica/Bash-Nao-use-if
   [ -n "${nome_nv}" ] && sed -i "/dset/ s#${nome}#${nome_nv}#" ${ctl_out}
   [ -n "${titulo_nv}" ] && sed -i "/title/ s#${titulo}#${titulo_nv}#" ${ctl_out}
   [ -n "${undef_nv}" ] && sed -i "/undef/ s#${undef}#${undef_nv}#" ${ctl_out}
   [ -n "${nx_nv}" ] && sed -i "/xdef/ s#${nx}#${nx_nv}#" ${ctl_out}
   [ -n "${lon_nv}" ] && sed -i "/xdef/ s#${lon}#${lon_nv}#" ${ctl_out}
   [ -n "${dx_nv}" ] && sed -i "/xdef/ s#${dx}#${dx_nv}#" ${ctl_out}
   [ -n "${ny_nv}" ] && sed -i "/ydef/ s#${ny}#${ny_nv}#" ${ctl_out}
   [ -n "${lat_nv}" ] && sed -i "/ydef/ s#${lat}#${lat_nv}#" ${ctl_out}
   [ -n "${dy_nv}" ] &&  sed -i "/ydef/ s#${dy}#${dy_nv}#" ${ctl_out}
   [ -n "${nt_nv}" ] && sed -i "/tdef/ s#${nt}#${nt_nv}#" ${ctl_out}
   [ -n "${data_nv}" ] && sed -i "/tdef/ s#${data}#${data_nv}#" ${ctl_out}
   [ -n "${dt_nv}" ] && sed -i "/tdef/ s#${dt}#${dt_nv}#" ${ctl_out}

   #echo "Gerando CTL:"
   #echo "CTL_IN : $ctl_in; NX: $nx; NY: $ny; NT: $nt; DX: $dx; DY: $dy; TIME: $time; LAT: $lat; LON: $lon; UNDEF: $undef"
   #echo "CTL_OUT: $ctl_out; NX: $nx_nv; NY: $ny_nv; NT: $nt_nv; DX: $dx_nv; DY: $dy_nv; TIME: $time_nv; LAT: $lat_nv; LON: $lon_nv; UNDEF: $undef_nv"

   #echo "Gerando CTL:"
   #echo "CTL_IN : $ctl_in; BIN: $nome"
   #echo "CTL_OUT: $ctl_out; BIN: $nome_nv"
}




function verificar_dimensoes(){

   lista_ctl=$*

   pri_arq=$1
   #echo "Primeiro arquivo: $PRI_ARQ."

   nx_ant=$(ctl_info $pri_arq -nx)
   ny_ant=$(ctl_info $pri_arq -ny)
   nt_ant=$(ctl_info $pri_arq -nt)

   for ctl in $lista_ctl; do

      #echo "Verificando arquivo: $ARQ."

      nx=$(ctl_info $ctl -nx)
      ny=$(ctl_info $ctl -ny)
      nt=$(ctl_info $ctl -nt)

#      if (( "${nx}"!="${nx_ant}" )) || (( "${ny}"!="${ny_ant}" )) || (( "${nt}"!="${nt_ant}" )) ; then
#         echo
#         printf "${ng}${vm}Erro: o arquivo $ctl tem NX, NY ou NT diferente dos anteriores.${nh}\n"
#         echo -e "nx_ant=${ng}${vm}$nx_ant${nh}; NX=${ng}${vm}$nx${nh}"
#         echo -e "ny_ant=${ng}${vm}$ny_ant${nh}; NY=${ng}${vm}$ny${nh}"
#         echo -e "nt_ant=${ng}${vm}$nt_ant${nh}; NT=${ng}${vm}$nt${nh}"
#         echo
#         exit
#      fi

      if (( "${nx}"!="${nx_ant}" )) ; then
         echo
         echo -e "${ng}${vm}Erro: o arquivo $ctl possui o ${vd}NX${vm} diferente dos anteriores.${nh}"
         echo -e "NX_ANT=${ng}${vm}$nx_ant${nh}; NX=${ng}${vm}$nx${nh}"
         echo -e "NY_ANT=$ny_ant; NY=$ny"
         echo -e "NT_ANT=$nt_ant; NT=$nt"
         echo
         exit
      fi

      if (( "${ny}"!="${ny_ant}" )) ; then
         echo
         echo -e "${ng}${vm}Erro: o arquivo $ctl possui o ${vd}NY${vm} diferente dos anteriores.${nh}"
         echo -e "NX_ANT=$nx_ant; NX=$nx"
         echo -e "NY_ANT=${ng}${vm}$ny_ant${nh}; NY=${ng}${vm}$ny${nh}"
         echo -e "NT_ANT=$nt_ant; NT=$nt"
         echo
         exit
      fi

      if (( "${nt}"!="${nt_ant}" )) ; then
         echo
         echo -e "${ng}${vm}Erro: o arquivo $ctl possui o ${vd}NT${vm} diferente dos anteriores.${nh}"
         echo -e "NX_ANT=$nx_ant; NX=$nx"
         echo -e "NY_ANT=$ny_ant; NY=$ny"
         echo -e "NT_ANT=${ng}${vm}$nt_ant${nh}; NT=${ng}${vm}$nt${nh}"
         echo
         exit
      fi

      nx_ant=$nx
      ny_ant=$ny
      nt_ant=$nt

   done
}



function listar_binarios(){

   lista_ctl=$*

   for ctl in $lista_ctl; do
      #echo "Nome do binário do arquivo: $ARQ."

      bin=$(ctl_info $ctl -filename)
      dir_ctl=$(dir_ctl $ctl)
      bin=$dir_ctl/$bin
      lista_bin="${lista_bin} ${bin}"
   done

   echo ${lista_bin[*]}
}



function definir_tper(){

   tipo=$1

   if [ "$tipo" = "diario" ] || [ "$tipo" = "365" ] || [ "$tipo" = "1dy" ]; then
      tper="365"
   elif [ "$tipo" = "mensal" ] || [ "$tipo" = "12" ] || [ "$tipo" = "1mo" ] || [ "$tipo" = "708hr" ]; then
      tper="12"
   elif [ "$tipo" = "1yr" ] ; then
	tper="1"
   else
      echo "Erro na funcao bash \"definir_tper\". Opcao invalida: $tipo!"
	tper="Erro na funcao bash \"definir_tper\". Opcao invalida: $tipo!"
      exit
   fi

   echo $tper
}



function verificar_ctl(){

   ctl=$1

   filename=$(ctl_info $ctl -filename)
   nx=$(ctl_info $ctl -nx)
   ny=$(ctl_info $ctl -ny)
   nt=$(ctl_info $ctl -nt)

   dx=$(ctl_info $ctl -dx)
   dy=$(ctl_info $ctl -dy)
   dt=$(ctl_info $ctl -dt)

   lon=$(ctl_info $ctl -lon)
   lat=$(ctl_info $ctl -lat)
   data=$(ctl_info $ctl -data)

   loni=$lon
   lonf=$(echo "$lon+($nx*$dx)"|bc )

   lati=$lat
   latf=$(echo "$lat+($ny*$dy)"|bc )

   pos_char=$(( $(echo $data|wc -c)-4 ))
   per=$(definir_tper $dt)

   anoi=$(echo $data|cut -c$pos_char-)
   datai=$(echo $data|cut -c-$(( $pos_char-1 )))
   anof=$(( $anoi+($nt/$per)-1 )) #$(echo "$anoi+($nt/$per)"|bc )
   mesf=$( date +%b -d"$(( (($nt+$per)%$per)+1 ))/01/01"|tr '[:upper:]' '[:lower:]' )
   dataf=$mesf$anof

   echo -e "--------------------------------------------\n"
   echo -e "Informações do CTL: \"$ctl\".\n"
   echo -e "Nome do binário: $filename. "$([ ! -f $filename ] && echo "[${ng}${vm}Arquivo não encontrado!${nh}]")
   echo -e ""
   echo -e "Definições do eixo 'x':"
   echo -e "   NX: $nx;"
   echo -e "   DX: $dx;"
   echo -e "   Longitude inicial: $loni;"
   echo -e "   Longitude final: $lonf.\n"

   echo -e "Definições do eixo 'y':"
   echo -e "   NY: $ny;"
   echo -e "   DY: $dy;"
   echo -e "   Latitude inicial: $lati;"
   echo -e "   Latitude final: $latf.\n"

   echo -e "Definições do eixo 't':"
   echo -e "   NT: $nt;"
   echo -e "   DT: $dt;"
   echo -e "   Data inicial: $data;"
   echo -e "   Data final: $dataf.\n"

   tam_ctl=$(( $nx*$ny*$nt*4 ))

   #Caso o arquivo exista, atribui o tamanho à variável "tam_bin".
   if [ -f $filename ]; then
      tam_bin=$(ls -l $filename|cut -d" " -f5)
   else
      tam_bin="null"
   fi
   echo -e "Tamanho esperado em bytes: "$tam_ctl"."
   echo -e "Tamanho do binário em bytes: "$tam_bin". "$([ ! -f $filename ] && echo "[${ng}${vm}Arquivo não encontrado!${nh}]")

   if [[ $tam_ctl -ne $tam_bin ]]; then
      echo -e "[${ng}${vm}Erro! Tamanho do binário não coincide com o CTL.${nh}]"
      echo -e "[A diferença entre os arquivos é de "$(( $tam_ctl - $tam_bin ))" bytes.]"
      [ $(( $tam_ctl - $tam_bin )) -le 0 ] && echo "[Arquivo binário maior do que o esperado.]" || echo "[Arquivo binário menor do que o esperado.]"
#   else
#      echo -e "[${ng}${az}Tamanho do binário coincide com o CTL.${nh}]"
   fi
   echo -e "\n--------------------------------------------"
}


function gera_unidade(){

	var=$1
	fat=$2
if [[ $2 == "en" ]] ; then
      case $var in
         PT | ppt) echo "mm/month" ;;
         PM) echo "mm/dy" ;;
         ND)  echo "dy";;
         ext) echo "dy";;
         tsm) echo "ºC";;
         pnm | slp) echo "${fat}hPa";;
         psiza |psi) echo "${fat}m²/s";;
         *) echo "Erro na funca bash \"gera_unidade\". Opcao invalida: ${var}!"
      esac
else
      case $var in
         PT | ppt) echo "mm/mes" ;;
         PM) echo "mm/dia" ;;
         ND)  echo "dias";;
         ext) echo "dias";;
         tsm) echo "ºC";;
         pnm | slp) echo "${fat}hPa";;
         psiza |psi) echo "${fat}m²/s";;
         *) echo "Erro na funca bash \"gera_unidade\". Opcao invalida: ${var}!"
      esac

fi
return

}


function name_var_translate(){

	var=$1
if [[ en -eq 1 ]] ; then
      case $var in
         PT | ppt) nomevar=TP ;;
         PM) nomevar=DMP ;;
         ND) nomevar=NWD ;;
         ext) nomevar=NEXT ;;
         tsm) nomevar=SST ;;
         pnm | slp) nomevar=SLP ;;
         psiza |psi) nomevar=PSIZA ;;
	pptpsiza ) nomevar=GPCC_PSIZA ;;
         *) echo "Erro na funca bash \"gera_unidade\". Opcao invalida: ${var}!"
      esac
else

      echo $var
fi
	echo $nomevar


return

}

function GERA_FAS
{
	local ARQ_FAS=${1}
	local ANOI=${2}
	local ANOF=${3}
	local PER=${4}

	if [[ $PER == "ver" || $PER == "dec" ]] ; then
	local NT_FAKE=$((ANOF-ANOI))
	else
	local NT_FAKE=$((ANOF-ANOI+1))
	fi
	#gera factor score a partir do txt
		local TEMP_INV="inv.txt"
		local AUX="aux.txt"
		local AUX2="aux2.txt"

		rm -f $TEMP_INV $AUX $AUX2
		cp "${ARQ_FAS:0:-4}.txt" $AUX
		for I in $(seq 1 $NT_FAKE) ; do
			echo "-99999" >> $TEMP_INV
		done

		for I in $(seq 2 30) ; do
			paste $AUX $TEMP_INV > $AUX2
			cp $AUX2 $AUX
		done
		if [[ ${PER} == "ver" || ${PER} == "dec"  ]] ; then
		echo -ne "$ANOI $(($ANOF-1)) \n" > $AUX
		else
		echo -ne "$ANOI $ANOF \n" > $AUX
		fi
		echo -ne "\n FACTOR SCORES MODOS NORMAIS - ACP 4.0 \n\n" >> $AUX
		cat $AUX2 >> $AUX
		echo -e "\n\n\n\n\n$ANOI $ANOF \n\n FACTOR SCORES MODOS ROTACIONADOS - ACP 4.0 \n" >> $AUX

		cat $AUX2 >> $AUX
echo -ne "\n\n\n\n\n\n\n" >> $AUX
		cp $AUX $ARQ_FAS
		rm -f $TEMP_INV $AUX $AUX2
		#fim do gera factor score
		return

}
