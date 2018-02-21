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
DIR_SRC="$(dirname $0)"
source $DIR_SRC/src/sources_files.sh $DIR_SRC/src/bash-utils.sh $DIR_SRC/src/futil $DIR_SRC/src/net-utils $DIR_SRC/src/doexec

function dhclient_systemd() {
cat <<EOF
[Unit]
Description=dhclient on %I
Documentation=man:dhclient(8)
Wants=network.target
Before=network.target
BindsTo=sys-subsystem-net-devices-%i.device
After=sys-subsystem-net-devices-%i.device

[Service]
Type=forking
PIDFile=/run/dhclient-%I.pid
ExecStart=$(command -v dhclient) -pf /run/dhclient-%I.pid %I
ExecStop=$(command -v dhclient) -r %I

[Install]
WantedBy=multi-user.target                 
EOF
}

function wpa_systemd() {
cat <<EOF
[Unit]
Description=WPA supplicant daemon (interface-specific version)
Requires=sys-subsystem-net-devices-%i.device
After=sys-subsystem-net-devices-%i.device
Before=network.target
Wants=network.target

# NetworkManager users will probably want the dbus version instead.

[Service]
Type=simple
ExecStart=$(command -v wpa_supplicant) -c/etc/wpa_supplicant/wpa_supplicant-%I.conf -i%I

[Install]
Alias=multi-user.target.wants/wpa_supplicant@%i.service                    
EOF
}

function wpa_pass_ssl() {
    echo "$1" | openssl enc -base64 -d
}

# Lance l'authentification auprès de la box 
# $1 : interface
# $2 : SSID
# $3 : password (ssl)
function wpa_launch() {
    exe wpa_supplicant -B -D nl80211,wext -i $1 -c <(echo "$2");
    return $?;    
}


con_wpa_supplicant() {
    if rid_continue "Lancer la connexion ?"; then
        netman_stop "NetworkManager"
        netman_stop "wicd"
        netman_stop "connman"

        WPA_PASS="$( wpa_passphrase $ESSID $(wpa_pass_ssl "$PASS_NET_CH") )"
        [[ ! $? -eq 0 ]] && die "Erreur lors de saisie du mot de passe !\n%s" "  -> $WPA_PASS"
        
        msg_nn "Lancement de wpa_supplicant..."
        wpa_launch "$I_W" "$WPA_PASS"
        _has_connected=$?
        if [[ $_has_connected -eq 0 ]]; then
            msg_nn_end "ok"
            msg_n "Attribution d'une adresse ip..."
            check_command -q "dhclient" && exe dhclient $I_W || ( check_command -q "dhcpcd" && exe dhcpcd -b $I_W )
        else
            msg_nn_end "fail !"
            error "La connexion au point d'accès a échouée !"
            return $_has_connected;
        fi
    fi
	if [[ ! -e $1/etc/wpa_supplicant/wpa_supplicant-$I_W.conf ]] || ! cat $1/etc/wpa_supplicant/wpa_supplicant-$I_W.conf | grep -q "$ESSID"; then
        if rid_continue "Ajouter le point d'accès \"%s\" dans \"%s\" ?" "$ESSID" "/etc/wpa_supplicant/wpa_supplicant-$I_W.conf"; then
            [[ ! -e $1/etc/wpa_supplicant/wpa_supplicant-$I_W.conf ]] && echo -e "ctrl_interface=/run/wpa_supplicant\nupdate_config=1" > $1/etc/wpa_supplicant/wpa_supplicant-$I_W.conf
            if [[ -z "$WPA_PASS" ]]; then
                WPA_PASS="$( wpa_passphrase $ESSID $(wpa_pass_ssl "$PASS_NET_CH") )"
                [[ ! $? -eq 0 ]] && die "Erreur lors de saisie du mot de passe !\n%s" "  -> $WPA_PASS"
            fi
            echo "$WPA_PASS" >> $1/etc/wpa_supplicant/wpa_supplicant-$I_W.conf 
        fi
    fi
	if [[ -z $1 ]]; then
        if [[ ! -e /etc/systemd/system/multi-user.target.wants/wpa_supplicant@$I_W.service ]] && rid_continue "Lancer \"%s\" au démarrage ?" "wpa_supplicant@$I_W"; then
            if [[ ! -e /usr/lib/systemd/system/wpa_supplicant@.service ]] && [[ ! -e /lib/systemd/system/wpa_supplicant@.service ]]; then
#                 if [[ -e /lib/systemd/system/wpa_supplicant.service ]]; then
#                         cp /lib/systemd/system/wpa_supplicant.service /lib/systemd/system/wpa_supplicant\@.service
                    wpa_systemd >> /lib/systemd/system/wpa_supplicant\@.service && msg_n2 "Création du fichier /lib/systemd/system/wpa_supplicant\@.service"
#                 else
#                     error "Impossible de trouver le service wpa_supplicant"
#                     return 1
#                 fi
            fi
            if ! systemctl is-enabled wpa_supplicant@$I_W  --quiet; then
                netman_check "NetworkManager"
                netman_check "wicd"
                netman_check "connman"
                if exe systemctl enable wpa_supplicant@$I_W; then
                    if check_command -q "dhclient"; then
                        dhclient_systemd >> /etc/systemd/system/dhclient\@.service
                        exe systemctl enable dhclient@$I_W
                    elif check_command -q "dhcpcd"; then
                        exe systemctl enable dhcpcd@$I_W
                    fi
                fi
            fi
        fi
	fi
	return 0;
}

rid_wifi() {
	[[ -e "/tmp/$1" ]] && source /tmp/$1 || die "Unable to find \"/tmp/$1\" !"
	[[ ! -z $2 ]] && TYPE_CON=$2 || die "Connection not set !"
	[[ ! -z $3 ]] && NAME_CON=$3 || die "Name connection not set !"
	[[ ! -z $4 ]] && PATH_CON=$4
	
	exist_install "wpa_supplicant" || {
        error "wpa_supplicant n'est pas installé !"
        msg_n "32" "32" "Veuillez installer \"%s\" avec \"%s\"" "wpa_supplicant" "pacman -S wpa_supplicant"
        exit 1
    }
    con_wpa_supplicant "$PATH_CON"
	return $?;
}


set_wifi() {
#	Recuperation du SSID
	ESSID="$1"
	if [[ -z "$ESSID" ]]; then
		ESSID="$( get_text "$_choix_ssid" )" || return 1; 
	fi
#	Recuperation du password dans un fichier, sinon l'utilisateur est invite a le taper
	if [[ -e /tmp/$ESSID ]] && rid_continue "$_pass_file" "/tmp/$ESSID"; then
		source /tmp/$ESSID && msg_n2 "$_read_pass" "/tmp/$ESSID"; 
	else
		while [[ -z "$PASS_NET_CH" ]]; do
			PASS_NET_CH=$( clear_line && str2ssl "$(rid "$_pass_net"  "$ESSID" " " )" );
			[[ "$PASS_NET_CH" == "$(str2ssl "q")" ]] && return 1
			[[ -z "$PASS_NET_CH" ]] && choix2error "$_error_pass" "sécurisé"
		done
		clear_line
# 		On genere le fichier /tmp/$ESSID contenant les infos nécessaires a la connexion.
		echo -e "I_W=$I_W\nESSID=$ESSID\nSEC_NET=$SEC_NET\nPASS_NET_CH=\"$PASS_NET_CH\"" > /tmp/$ESSID && msg_n2 "Creation du fichier dans %s" "/tmp/$ESSID"
	fi
	return 0;
}

wifi_scan_iw() {
	i=-1
	echo -e "#\n# Scan des réseaux disponible avec l'interface $I_W :\niw dev $I_W scan" >> $FILE_COMMANDS
	while read -r; do
		[[ $REPLY =~ ^BSS ]] && i=$((i+1)) && netw[valid_$i]=1
# 		[[ $REPLY =~ SSID.* ]] && netw[ssid_$i]="$( echo $REPLY | sed "s/.*ESSID/ESSID/g")" 
		[[ $REPLY =~ SSID.* ]] && netw[ssid_$i]="${REPLY//*SSID: /}"
# 		[[ $REPLY =~ Quality.* ]] && netw[qual_$i]="${REPLY//*Quality=/}" && netw[qual_$i]=${netw[qual_$i]//\/*/} 
		[[ $REPLY =~ WEP* ]] && netw[sec_$i]="WEP" && netw[sec_net_$i]="wep"
		[[ $REPLY =~ "WPA" ]] && [[ $REPLY =~ "Version: 1" ]] && netw[sec_$i]="WPA" && netw[sec_net_$i]="wpa"
		[[ $REPLY =~ "WPA2 Version" ]] && netw[sec_$i]="WPA2" && netw[sec_net_$i]="wpa"
		[[ $REPLY =~ PSK* ]] && netw[auth_$i]="/PSK" 	
	done < <(iw dev $I_W scan)
}
wifi_scan_iwlist() {
	i=-1
	echo -e "#\n# Scan des réseaux disponible avec l'interface $I_W :\niwlist $I_W scan" >> $FILE_COMMANDS
	while read -r; do
		[[ $REPLY =~ Cell.* ]] && i=$((i+1)) && netw[valid_$i]=1
		[[ $REPLY =~ ESSID.* ]] && netw[ssid_$i]="$( echo $REPLY | sed "s/.*ESSID/ESSID/g")" 
		[[ $REPLY =~ Quality.* ]] && netw[qual_$i]="${REPLY//*Quality=/}" && netw[qual_$i]=${netw[qual_$i]//\/*/} 
		[[ $REPLY =~ WEP* ]] && netw[sec_$i]="WEP" && netw[sec_net_$i]="wep"
		[[ $REPLY =~ "WPA Version 1" ]] && netw[sec_$i]="WPA" && netw[sec_net_$i]="wpa"
		[[ $REPLY =~ "WPA2 Version" ]] && netw[sec_$i]="WPA2" && netw[sec_net_$i]="wpa"
		[[ $REPLY =~ PSK* ]] && netw[auth_$i]="/PSK" 	
	done < <(iwlist $I_W scan)
}

# Liste les réseau WiFi à proximité, puis demande à l'utilisateur d'en choisir un
list_wifi() {
	I_W=$1
	if ! iw dev $I_W scan >> /tmp/err.log; then
        error "\"iw dev $I_W scan\" a échouée !"
        if check_command -q "iwlist" && iwlist $I_W scan >> /tmp/err.log; then
            IWLIST=1
        else
            die "\"iwlist $I_W scan\" a échouée !"
        fi
    fi
	msg_nn "\r" "$_mess_wait" 
	loading & 
	PID_LOAD=$! 
	
	[[ -z "$IWLIST" ]] && wifi_scan_iw || wifi_scan_iwlist
# 	echo -e "#\n# Scan des réseaux disponible avec l'interface $I_W :\niw dev $I_W scan" >> $FILE_COMMANDS
# 	while read -r; do
# 		[[ $REPLY =~ ^BSS ]] && i=$((i+1)) && netw[valid_$i]=1
# # 		[[ $REPLY =~ SSID.* ]] && netw[ssid_$i]="$( echo $REPLY | sed "s/.*ESSID/ESSID/g")" 
# 		[[ $REPLY =~ SSID.* ]] && netw[ssid_$i]="${REPLY//*SSID: /}"
# # 		[[ $REPLY =~ Quality.* ]] && netw[qual_$i]="${REPLY//*Quality=/}" && netw[qual_$i]=${netw[qual_$i]//\/*/} 
# 		[[ $REPLY =~ WEP* ]] && netw[sec_$i]="WEP" && netw[sec_net_$i]="wep"
# 		[[ $REPLY =~ "WPA" ]] && [[ $REPLY =~ "Version: 1" ]] && netw[sec_$i]="WPA" && netw[sec_net_$i]="wpa"
# 		[[ $REPLY =~ "WPA2 Version" ]] && netw[sec_$i]="WPA2" && netw[sec_net_$i]="wpa"
# 		[[ $REPLY =~ PSK* ]] && netw[auth_$i]="/PSK" 	
# 	done < <(iw dev $I_W scan)
	disown 
	[[ ! -z $PID_LOAD ]] && kill $PID_LOAD 
	[[ -z ${netw[valid_0]} ]] && sleep 2 && list_wifi $I_W && exit
# 	[[ $i -eq -1 ]] && sleep 2 && list_wifi $I_W && exit
	clear_line
	msg_nn "\r" "$_nb_net" "$((i+1))"
	out_n "  0)"  "32" "32" "Ajouter un réseau caché\n"
	j=0
	while [[ $j -lt $((i+1)) ]]; do
		PSK="    "  && [[ ! -z ${netw[auth_$j]} ]] && PSK=${netw[auth_$j]}
		SEC="   --   " && [[ ! -z ${netw[sec_$j]} ]] && SEC="${netw[sec_$j]}$PSK$([[ "${netw[sec_$j]}" == "WPA" ]] && printf " ")"
		[[ ! -z "${netw[qual_$j]}" ]] && out_n " $( [[ $j -lt 9 ]] && echo " ")$((j+1)))"  "32" "32" "$((${netw[qual_$j]}*10/7))/100" ||
		out_n " $( [[ $j -lt 9 ]] && echo " ")$((j+1)))" "32" "32"
		printf " | $SEC | ">&2
		msg_nn_end "${netw[ssid_$j]}"
		j=$((j+1))
	done
	NET_CH=0
	while  [[ $NET_CH -eq 0 ]] || [[ ${netw[valid_$((NET_CH-1))]} != 1 ]]; do
		NET_CH=$( rid "$_choix_net" "q" "r")
		[[ "$NET_CH" == "0" ]] && set_wifi
# 		choix2error "Pas encore disponible !"
		[[ "$NET_CH" == "q" ]] && msg_n "End" && exit
		[[ "$NET_CH" == "r" ]] && msg_nn "Reload" && list_wifi $I_W
	done
	ESSID=$(echo ${netw[ssid_$((NET_CH-1))]} | sed "s/.*ESSID:\"\(.*\)\"/\1/g" )
	SEC_NET=${netw[sec_net_$((NET_CH-1))]}
}
conf_net_wifi () {
	I_W=$1
	OP=1
    list_wifi $I_W && set_wifi "$ESSID"
	NAME_NETCTL=$( echo "$ESSID" ) && [[ -z $NAME_NETCTL ]] && NAME_NETCTL="$SEC_NET-${ESSID,,}"
	[[ -z $2 ]] && rid_wifi "$ESSID" "$OP" "$NAME_NETCTL" || printf "${methods[_$OP]}@$NAME_NETCTL@$ESSID"
}

init_wifi() {
	I_W="$1"

	exist_install "iw" "iw" || {
		error "%s n'est pas installé !" "iw"
		msg_n "32" "32" "Veuillez installer \"%s\" avec \"%s\"" "iw" "pacman -S iw"
		exit 1
	}

	( [[ -z $I_W ]] || ( ! ip addr | grep -q "$I_W" && error "L'interface %s n'existe pas !" "$I_W")  ) && { I_W="$(list_if "wifi" && ask_if )"; [[ $? -gt 0 ]] && die "Aucun périphérique disponible ! $I_W"; }
	
	if ! ip addr | grep -q $I_W | grep -q UP; then
		caution "L'interface %s n'est pas activée !" "$I_W" 
# 		&& 
		
		if is_root "ip link set up dev $I_W" && msg_nn2 "32" "32" "ip link set up dev %s..." "$I_W"; then
			msg_nn_end "ok"
# 			msg_n "Attention :$I_W"
# 			ip addr | grep $I_W | grep UP
# 			msg_n "Attention :"
# 			
			if ! ip addr | grep -q $I_W | grep -q UP; then 
				is_root 1 "/bin/bash $0 ${@}"
			fi
# 			msg_n "Attention : $( ip addr | grep $I_W  | grep UP )"
		else	
			msg_nn_end "error !"
			error "Impossible d'activer l'interface \"%s\" !" "$I_W"
			die "Vérifier les drivers pour \"%s\" !" "$I_W"
		fi
	fi
# 	msg_n "Attention 2: $( ip addr | grep $I_W  | grep UP )"
	conf_net_wifi $I_W $2
}

declare -A netw
declare -A valid_iface
declare -A methods=(
	[1]="WPA Supplicant"
	[2]="Netctl"
	[3]="NetworkManager"
	[_1]="wpa_supplicant"
	[_2]="netctl"
	[_3]="networkmanager"
)

valid_methods=(
	"WPA Supplicant (default)"
	"Netctl"
	"NetworkManager"
	"Extras"
)

_mess_wait="Veuillez patienter, scan en cours..."
_choix_net="Quel reseau ? (Type '%s' to quit, '%s' to reload networks list)"
_nb_net="%s reseau(x) trouve(s)\n"
_choix_ssid="Entrez le SSID"
_pass_file="Utiliser le mot de passe du fichier %s ?"
_pass_net="Veuillez entrer le mot de passe pour %s %s"
_read_pass="Lecture du mot de passe dans %s"
_error_pass="La connexion \"%s\" nécessite un mot de passe !"

I_W="wlan0"
FILE_COMMANDS=/tmp/wifi_util_command
# FILES_SYSTEMD=
# FILES_DHCP=
# FILES_WPA=
echo -e "#\n#\n# Wifi utils ($(date "+%Y/%m/%d-%H:%M"))\n#\n#\n" >> $FILE_COMMANDS

# $1 Interface wifi
# Si $1 est un fichier, alors on va récupérer les infos directement...
[[ ! -z $1 ]] && { [[ -f /tmp/$1 ]] && rid_wifi $@; } || init_wifi $@
# [[ ! -z $1 ]] && { I_W=$1 && [[ -f /tmp/$I_W ]] && rid_wifi $@; } || init_wifi $@
# echo "Ca va se finir !"
# [[ -f /tmp/$I_W ]] && rid_wifi $@ || init_wifi $@

