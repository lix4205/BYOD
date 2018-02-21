#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script need futil
DIR_SCRIPTS="$(dirname $0)/.."
source $DIR_SCRIPTS/src/sources_files.sh futil net-utils bash-utils.sh doexec

# [[ ! -e  $(dirname $0)/futil ]] && printf "==> ERROR: File \"%s\" not found\n" "futil" && exit 1
# source $(dirname $0)/futil
# source $(dirname $0)/net-utils
# source $(dirname $0)/bash-utils.sh

set_br_iptable() {
	I_W=${valid_iface[$1]} && shift
	if [[ ! $( ip addr | grep $I_W | grep UP | wc -l ) -gt 0 ]]; then
		caution "L'interface %s n'est pas activée !" "$I_W" && ! is_root "$@" && msg_nn2 "32" "32" "ip link set up dev %s..." "$I_W" 
		if ip link set up dev $I_W >> /dev/null 2>&1; then
			msg_nn_end "ok"
		else	
			msg_nn_end "error !" 
			caution "Impossible d'activer l'interface \"%s !\"" "$I_W"
			msg_n "31" "31" "Vérifier les drivers pour \"%s !\"" "$I_W"
			exit
	# 		die "Impossible d'activer l'interface %s" "$I_W"
		fi
	fi

	echo ${valid_iface[$2]}
	echo ${valid_iface[$3]}
	list_wifi $I_W && set_wifi $ESSID
	rid_wifi "$ESSID" 2 "$NAME_NETCTL"
	
	echo "Description=\"bridge-${valid_iface[$2]} ${valid_iface[$3]}\"
Interface=$1
Connection=bridge
BindsToInterfaces=(${valid_iface[$2]})
IP=static
Address='192.168.0.5/24'


" > /etc/netctl/sub-bridge-$1
# netctl stop neuf_1f74
# netctl stop br0
# loading ip link set ${valid_iface[$3]} down


	netctl start $NAME_NETCTL
	netctl start sub-bridge-$1

# 	# TEST avec iproute2
# 	loading ip link add name $NAME_NETCTL type bridge
# 	loading ip link set $NAME_NETCTL up
# 	loading ip link set ${valid_iface[$2]} up
# 	loading ip link set ${valid_iface[$2]} master $NAME_NETCTL
# 
# 	loading ip link set ${valid_iface[$3]} up
# 	loading ip link set ${valid_iface[$3]} master $NAME_NETCTL
# 	loading bridge link
# 
# 	ip ad
# 	sleep 5
# 	loading ip link delete $NAME_NETCTL type bridge
# 	loading ip link set ${valid_iface[$2]} down
# 	loading ip link set ${valid_iface[$3]} down
# 
	shift

}

# Set an access point with hostapd and iptable
set_ap() {
	SSID=$( rid "Nom de SSID" )
	PASS_NET_CH=$( rid "Mot de passe pour le point d'accès \"%s\"" "SSID" )
	echo "ssid=$SSID
wpa_passphrase=$PASS_NET_CH
#interface=wlp0s26u1u5
#interface=wf0
interface=${valid_iface[$1]}
bridge=$2
auth_algs=3
channel=7
driver=nl80211
hw_mode=g
logger_stdout=-1
logger_stdout_level=2
max_num_sta=5
rsn_pairwise=CCMP
wpa=2
wpa_key_mgmt=WPA-PSK                                                                                                                                                                                                              
wpa_pairwise=TKIP CCMP                                                                                                                                                                                         
" 
# > /etc/hostapd/hostapd.conf
echo "


"
echo "Description=\"bridge-wifi\"
Interface=br0
Connection=bridge
BindsToInterfaces=(${valid_iface[$3]})
IP=static
Address='192.168.0.5/24'
" 
# > /etc/netctl/bridge-$2

# systemctl start hostapd
# netctl start bridge-$2
}

# $1=command2test $2=package2install


# is_root "ls sa" 

# exist_install "arch-chroot" "arch-install-scripts"

# echo $?
# exit
    # Test de validité IPv4 de l'adresse entrée (expression régulière)
    
out_dnsmasq() {
echo "domain-needed
bogus-priv
filterwin2k

localise-queries
local=/$NET_DOMAINE/
domain=$NET_DOMAINE
expand-hosts
no-negcache
#resolv-file=/tmp/resolv.conf.auto

dhcp-authoritative
dhcp-leasefile=/tmp/dhcp.leases

# use /etc/ethers for static hosts; same format as --dhcp-host
# read-ethers

# Plage DHCP
dhcp-range=${_net_plage[1]},${_net_plage[2]},12h
# Netmask
dhcp-option=1,$NET_MASK
# Route
#dhcp-option=3,$NET_PASS
# DNS
#dhcp-option=6,192.168.0.5,8.8.8.8,8.8.4.4

#dhcp-option=option:router,192.168.1.1
dhcp-authoritative


# OPTIONS PXE
interface=$I_W
dhcp-boot=pxelinux.0
# GPXE
# dhcp-boot=gpxelinux.0
# LPXE
# dhcp-boot=lpxelinux.0

enable-tftp
tftp-root=$ROOT_TFTP
tftp-secure" 
}


out_subnet () {
# Description='Bridge with $1'
# Interface=$2
# Connection=bridge
# BindsToInterfaces=($1 )
# IP=dhcp
echo "
Description='Ethernet connexion with $1'
Interface=$1
Connection=ethernet
IP=static
Address=('$NET_IP0/$(mask2bits "$NET_MASK")' )
#Routes=('192.168.0.0/24 via 192.168.1.2')
# Gateway='$NET_PASS'
# DNS=('$NET_PASS')

## For IPv6 autoconfiguration
#IP6=stateless

## For IPv6 static address configuration
#IP6=static
#Address6=('1234:5678:9abc:def::1/64' '1234:3456::123/96')
#Routes6=('abcd::1234')
#Gateway6='1234:0:123::abcd'" 
# Description='bridge-wifi $1'
# Interface=br0
# Connection=bridge
# BindsToInterfaces=($1)
# #BindsToInterfaces=(enp2s0)
# #DHCP Options
# #DHCPClient='dhcpcd'
# #IP=dhcp
# 
# ##Static ip options
# IP=static
# Address=('$NET_IP0/$(mask2bits "$NET_MASK")' )
# #Gateway='192.168.1.1'
# #Gateway='192.168.0.5'
# ### Ignore (R)STP and immediately activate the bridge
# ##SkipForwardingDelay=yes






}
syslinux_config() {
	WGET="curl $URL_SYSLINUX -o $FILE_SYSLINUX"
	[[ ! -e $FILE_SYSLINUX ]] &&
# 	check_command "syslinux" || {
		check_command "curl" || {
			check_command "wget" && {
				WGET="wget $URL_SYSLINUX -O $FILE_SYSLINUX"
				} || {
				die "Impossible de télécharger syslinux"
			}				
		}
		loading "Telechargement de syslinux..." $WGET && cd /tmp/syslinux &&
		loading beg="Extraction de l'archive syslinux" end="Extraction terminé" tar xf $FILE_SYSLINUX
		cp syslinux-*/bios/core/pxelinux.0 $ROOT_TFTP/
		cp syslinux-*/bios/com32/elflink/ldlinux/ldlinux.c32 $ROOT_TFTP/
		cp syslinux-*/bios/com32/modules/poweroff.c32 $ROOT_TFTP/
		cp syslinux-*/bios/com32/modules/reboot.c32 $ROOT_TFTP/
		cp syslinux-*/bios/com32/menu/vesamenu.c32 $ROOT_TFTP/
		cp syslinux-*/bios/com32/menu/menu.c32 $ROOT_TFTP/
		cp syslinux-*/bios/com32/lib/libcom32.c32 $ROOT_TFTP/
		cp syslinux-*/bios/com32/libutil/libutil.c32 $ROOT_TFTP/
		cp syslinux-*/bios/com32/chain/chain.c32 $ROOT_TFTP/
# 	}
	
echo "DEFAULT menu.c32
UI vesamenu.c32
PROMPT 0
# MENU BACKGROUND bg.jpg
MENU TITLE PXE Boot System on $NET_DOMAINE network
NOESCAPE 1

MENU INCLUDE pxelinux.cfg/head.conf 
###
# Insert your systems in pxelinux.cfg/systems.conf !
MENU INCLUDE pxelinux.cfg/systems.conf
###
MENU INCLUDE pxelinux.cfg/tail.conf
" > $ROOT_TFTP/pxelinux.cfg/default

echo "MENU VSHIFT 1
MENU WIDTH 78
MENU MARGIN 4
MENU ROWS 13
MENU HELPMSGROW 20
MENU TIMEOUTROW 30

MENU COLOR border       30;44   #40ffffff #a0000000 std
MENU COLOR title        1;36;44 #9033ccff #a0000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #a0000000 std
MENU COLOR help         37;40   #c0ffffff #a0000000 std
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std
MENU COLOR msg07        37;40   #90ffffff #a0000000 std
MENU COLOR tabmsg       31;40   #30ffffff #00000000 std
" > $ROOT_TFTP/pxelinux.cfg/head.conf

echo "label ------ Autre  ------
	label btl
	menu label Boot to Nearby Next Loader
	localboot -1
	text help
Boot to Nearby Next Loader
	endtext

label Boot on local hard disk
	com32 chain.c32
	append hd0 0
	text help
Boot an existing operating system.
Press TAB to edit the disk and partition number to boot.
	endtext

label reboot
	menu label Reboot
	COM32 reboot.c32
	text help
Redemarrer
	endtext

label poweroff
	menu label Power Off
	COM32 poweroff.c32
	text help
Eteindre
	endtext
" > $ROOT_TFTP/pxelinux.cfg/tail.conf
		
		
}
    
# get_text() {
# 	local txt2return="";
# 	while [[ "$txt2return" == "" ]]; do
# 		txt2return="$( rid "$@" )"
# 		[[ "$txt2return" == "q" ]] && return 1
# # 		isIPv4 "$txt2return" && break || txt2return=""
# 	done	
# 	echo "$txt2return"
# }
get_plage() {
	local txt2return="" i=0 valid=1 default="$DEFAULT_PLAGE";
	txt2return="$(rid "$@ $Q_QUIT" "q")" || return 1
	[[ "$txt2return" == "" ]] && txt2return="$default" 
	for i in $txt2return; do 
		! [[ $i -lt 255 && $i -gt 0 ]] && valid=0 && break; 
	done
	(( $valid )) && ! is_sup $txt2return 
	(( ! $valid )) && msg_nn "\r" "31" "31" "Plage d'adresses \"%s\" non valide" "$txt2return" && sleep 1 && valid=0
	(( ! $valid )) && { txt2return="$(get_plage "$@")" || return 1; }
	echo $txt2return
}

get_net_addr() {
	local txt2return="" default="$DEFAULT_IP";
	txt2return=$(rid "$@ $Q_QUIT" "q") || return 1
	[[ "$txt2return" == "q" ]] && return 1
	[[ "$txt2return" == "" ]] && txt2return="$default" 
	isIPv4 "0" "$txt2return" && echo $txt2return || { msg_nn "\r" "31" "31" "Adresse \"%s\" invalide !" "$txt2return" && sleep 1 && txt2return=$(get_net_addr "$@"); }
}

get_net_masq() {
	local txt2return="" default="$DEFAULT_NETMASK";
	txt2return=$(rid "$@ $Q_QUIT" "q") || return 1
	[[ "$txt2return" == "q" ]] && return 1
	[[ "$txt2return" == "" ]] && txt2return="$default" 
# && echo $txt2return && return 0
	isIPv4 "0" "$txt2return" && echo $txt2return || { msg_nn "\r" "31" "31" "Adresse \"%s\" invalide !" "$txt2return" && sleep 1 && txt2return=$(get_net_addr "$@"); }
}

set_dnsmasq() {
	mkdir -p $ROOT_TFTP/pxelinux.cfg /tmp/syslinux
	mv /etc/dnsmasq.conf /etc/dnsmasq.conf.original
	out_dnsmasq > /etc/dnsmasq.conf
}

# https://wiki.archlinux.org/index.php/Internet_sharing#Enable_NAT
set_iptables() {
# 	&& return 1
	iptables -t nat -A POSTROUTING -o $INTERNET_IF  -j MASQUERADE
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i $I_W -o $INTERNET_IF -j ACCEPT
	# Puis on sauvegarde...
	iptables-save > /etc/iptables/iptables.rules
	! check_command "service" >> /dev/null && systemctl enable iptables
# 	no_service_iptables
	# Et ne pas oublier d'activer le service iptables !!!
# 	systemctl enable iptables

}

no_service_iptables() {
# 	check_command "iptables-persistent"
# 	iptables-save -c 
# 	service iptables-persistent
	iptables-save > /etc/iptables/rules.v4
	return 0
}

# https://wiki.archlinux.org/index.php/Internet_sharing#Enable_packet_forwarding
set_sysctl() {
	echo " 
net.ipv4.ip_forward=1
net.ipv6.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
" > /etc/sysctl.d/30-ipforward.conf
}

no_netctl() {
# 	On reinitialise la connexion...
	ip addr del $NET_IP0/$(mask2bits "$NET_MASK") dev $1
	ip link set down dev $1
	
	ip link set up dev $1
	ip addr add $NET_IP0/$(mask2bits "$NET_MASK") dev $1 # arbitrary address	
}

launch() {
	netman_stop
	if (( $1 )); then
	# 	For Archlinux and probably his childs...
		netctl start static-$I_W && (( $NET_SHARE )) && systemctl start iptables
	else
	# 	For the others
		no_netctl "$I_W" && (( $NET_SHARE )) && no_service_iptables && sysctl net.ipv4.ip_forward=1
	fi
	systemctl start dnsmasq
	(( $NET_SHARE )) && sysctl net.ipv4.ip_forward=1
	msg_n "Lance !"
}

check_command "systemctl" || die "This script run with systemd !"
exist_install "dnsmasq"
exist_install "iptables"
exist_install "bc"

declare -A valid_iface

DEFAULT_DOMAINE="home.lan"
DEFAULT_ROOT_TFTP="/srv/tftp"
DEFAULT_NETMASK="255.255.255.0"
DEFAULT_IP="192.168.2.1"
DEFAULT_PLAGE="100 150"
Q_QUIT=" Type '%s' to quit"
URL_SYSLINUX="https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz"
FILE_SYSLINUX="/tmp/syslinux/syslinux.tar.xz"
NET_SHARE=0
INTERNET_IF=
NETCTL=1

# echo "$IFACES"
I_W=$( list_if "eth" && ask_if ) || exit 1
# rid_continue "Partager une connexion Internet ?" && set_iptables
NET_IP0=$(get_net_addr "Indiquez l'adresse ip du reseau dhcp. ( Default:$DEFAULT_IP )" ) || exit 1
NET_MASK=$(get_net_masq "Indiquez le masque du reseau . ( Default:$DEFAULT_NETMASK )" ) || exit 1
 
# out_subnet "$I_W" > /etc/netctl/bridge-$I_W
#  
# exit 
NET_PLAGE=$(get_plage "Indiquez la plage d'adresses ip du reseau dhcp. ( Default:$DEFAULT_PLAGE )") || exit 1
# NET_PASS is useless at this point
# NET_PASS=$(get_net_addr "Indiquez l'adresse ip de la passerelle. ( Ex:192.168.0.1 )" ) || exit 1
# [[ "$NET_MASK" == "" ]] && NET_MASK="$DEFAULT_NETMASK"

NET_IP=$( echo $NET_IP0 | sed "s/\(.*\)\..*/\1/")
# ${NET_IP0//.0$/} #(get_net_addr "Indiquez l'adresse ip du reseau dhcp. ( Ex:192.168.0.0 )" ) || exit 1
NET_DOMAINE=$(rid "Indiquez le nom de domaine (default:\"$DEFAULT_DOMAINE\").")
[[ "$NET_DOMAINE" == "" ]] && NET_DOMAINE="$DEFAULT_DOMAINE"
# DOMAINE=$(get_text "Indiquez le nom de domaine.")

ROOT_TFTP=$(rid "Indiquez le chemin de la racine des fichier PXE (default:\"$DEFAULT_ROOT_TFTP\").")
[[ "$ROOT_TFTP" == "" ]] && ROOT_TFTP="$DEFAULT_ROOT_TFTP"

i=0;
_net_plage=()
for range in ${NET_PLAGE}; do
	i=$((i+1))
	_net_plage+=( [$i]="$NET_IP.$range" )
done

rid_continue "Partager une connexion Internet ?" && NET_SHARE=1 && { INTERNET_IF=$( list_if && ask_if ) || exit; }

echo "Interface  	   	 : $I_W"
echo "Adresse IP serveur : $NET_IP0"
echo "Masque 	       : $NET_MASK"
echo "Plage d'adresses   : ${_net_plage[1]} - ${_net_plage[2]}"
echo "Domaine  	   	 : $NET_DOMAINE"
echo "Racine du serveur  : $ROOT_TFTP"
(( $NET_SHARE )) && 
echo "Partage  		 : $INTERNET_IF"

# echo "$NET_IP $NET_DOMAINE $NET_PLAGE $I_W"

# exit
if check_command "netctl" >> /dev/null; then
	out_subnet "$I_W" > /etc/netctl/static-$I_W 
	netctl enable static-$I_W	
else
	
	NETCTL=0
fi
set_dnsmasq
syslinux_config

systemctl enable dnsmasq
netman_check
chown -R dnsmasq /$ROOT_TFTP
(( $NET_SHARE )) && set_iptables && set_sysctl 
# rid_continue "Partager une connexion Internet ?" && set_iptables && set_sysctl && NET_SHARE=1
rid_continue "Lancer ?" && launch $NETCTL
# netctl start static-$I_W && systemctl start dnsmasq && (( $NET_SHARE )) && systemctl start iptables && sysctl net.ipv4.ip_forward=1
rid_continue "Installer ArchLinux diskless ?" && bash $(dirname $0)/arch-diskless.sh $ROOT_TFTP
exit
