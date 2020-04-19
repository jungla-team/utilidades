#!/bin/sh

#funciones script
ENLACE_URL="https://raw.githubusercontent.com/jungla-team/utilidades/master/sources.tar.gz"
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m'

function check_variable() {
	VARIABLE="$1"
	if [[ ! $VARIABLE =~ ^(|-host|-token)$ ]]; then
		Mensaje "Variable aceptada" $VERDE
	else
		Mensaje "Error! Te has dejado variables sin poner" $ROJO
		exit 1
	fi
}

function Mensaje() {
	echo -e "$2$1${NC}"
}

function Error() {
	echo -e "\n\a  ${ROJO} $1${NC}" 1>&2
	exit 1
}

function install_curl() {

	if [ ! -f /usr/bin/curl ];
	then
		echo "Instalando curl..."
		paquete="curl"
		opkg update
		opkg install $paquete
	fi
}

function create_dir() {
	if [ -f /home/root/$HOST/dehydrated/certs/$HOST/fullchain.pem ]; then
	     Mensaje "!!!Se han localizado certificados validos para ese dominio en directorio /home/root/$HOST/dehydrated/certs/$HOST" $RED
	     Mensaje "Se cierra la creacion de certificados para evitar sobrepasar el limite para dominio $HOST" $ROJO
	     exit
    fi
	          
	if [ ! -d /home/root/$HOST/dehydrated ]; then
		mkdir -p /home/root/$HOST/dehydrated
	fi
	Mensaje "carpeta /home/root/$HOST/dehydrated creada" $VERDE
	
}

function instalacion() {
	wget -q $ENLACE_URL -P /tmp/
	tar zxf /tmp/sources.tar.gz -C /home/root/$HOST/dehydrated/
	rm -f /tmp/source.gz
	chmod +x /home/root/$HOST/dehydrated/dehydrated
	chmod +x /home/root/$HOST/dehydrated/hook.sh
	
}

function parche() {
	sed -i s/DUCKDNS/$HOST/g /home/root/$HOST/dehydrated/domains.txt
	sed -i s/DUCKDNS/$HOST/g /home/root/$HOST/dehydrated/hook.sh
	sed -i s/MITOKEN/$TOKEN/g /home/root/$HOST/dehydrated/hook.sh
	
}

function function_certificados() {
	cd /home/root/$HOST/dehydrated
	./dehydrated --register  --accept-terms
	./dehydrated -c
	[ -f /etc/enigma2/cert.pem ] && rm -r /etc/enigma2/cert.pem
	[ -f /etc/enigma2/key.pem ] && rm -r /etc/enigma2/key.pem
	ln -s /home/root/$HOST/dehydrated/certs/$HOST/fullchain.pem /etc/enigma2/cert.pem
	ln -s /home/root/$HOST/dehydrated/certs/$HOST/privkey.pem /etc/enigma2/key.pem
	
}

function copia() {
    tar czpvf $HOST.tar.gz /home/root/$HOST
    mv /home/root/$HOST/dehydrated/$HOST.tar.gz /home/root
	
}


cronjob_editor () {
# usage: cronjob_editor '<interval>' '<command>' <add|remove>

if [[ -z "$1" ]] ;then printf " no interval specified\n" ;fi
if [[ -z "$2" ]] ;then printf " no command specified\n" ;fi
if [[ -z "$3" ]] ;then printf " no action specified\n" ;fi

if [[ "$3" == add ]] ;then
    # add cronjob, no duplication:
    ( crontab -l | grep -v -F -w "$2" ; echo "$1 $2" ) | crontab -
elif [[ "$3" == remove ]] ;then
    # remove cronjob:
    ( crontab -l | grep -v -F -w "$2" ) | crontab -
fi
}

function add_to_crontab() {

	cronjob_editor "0 1 1 * *" "/home/root/$HOST/dehydrated/dehydrated -c" "add"
	Mensaje "Añadido un cron para actualizar certificados" $VERDE
}

function mostrar_mensajes() {

Mensaje "/home/root/$HOST/dehydrated/certs/$HOST     -- directorio certificados creados" $VERDE
echo " "
Mensaje "/etc/enigma2/key.pem   					 -- archivo para enigma2" $VERDE
echo " "
Mensaje "/etc/enigma2/cert.pem       				 -- archivo para enigma2" $VERDE

}

function logofin(){
	clear
	echo -e "\e[32m${AZUL} ******************************************************************************\e[0m"
	echo -e "\e[32m${AZUL} *              CREACION CERTIFICADOS PARA DUCKDNS                            *\e[0m"
	echo -e "\e[32m${AZUL} *           Soporte: https://t.me/joinchat/Bv0_2hZ8jH6dsUJFoYG-Rg            *\e[0m" 
	echo -e "\e[32m${AZUL} *                 con mucho ⅽ[_] ͌ + (♥) jungle-team 2019		      			*\e[0m"
	echo -e "\e[32m${AZUL} *                         by Jungle-team     	                			*\e[0m" 
	echo -e "\e[32m${AZUL} ******************************************************************************\e[0m"

}



while test $# -gt 0
do
    case "$1" in
	  -h|--help)
	   echo "debe usar parametro -host tuhosduck -token tokendetuhost"
	   exit 0
	   ;;

	  -host)
	   HOST=$2
	   echo $HOST
	   check_variable $HOST
				 ;;
	  -token)
	   TOKEN=$2
	   echo $TOKEN
	   check_variable $TOKEN
				 ;;
	  -*) echo "bad option $1"
				;;
	  #*) echo "argument $1"
			#    ;;
    esac
    shift
done

install_curl
create_dir
instalacion
parche
function_certificados
copia
add_to_crontab
logofin
mostrar_mensajes
