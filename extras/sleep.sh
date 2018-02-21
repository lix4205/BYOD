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

search_dm() {
	for f2e in "${dm2edit[@]}"; do 
		if [[ -e "$ROOT2SHOW$f2e" ]]; then
			echo "$f2e"
			break
		fi
	done
}

choix2do() {
	local choix_fin=;
	while [[ ! -z "$1" ]]; do
        [[ "$1" =~ ^.?.?:.?.?:.?.?:.?.?:.?.?:.?.?$ ]] && MAC_ADDR="$1" 
        is_number "$1" && TIME2SLEEP="$1m"  
        [[ "$1" =~ ^.?.?m$ ]] && TIME2SLEEP=$1
        [[ "$1" =~ ^.*m$ ]] && TIME2SLEEP=$1
        [[ "$1" == "sleep" || "$1" == "bluetooth" || "$1" == "vlc" ]] && choix_fin="$1"
        ls "${@}"&& LAST_USED_FILES="${@}" && break
        shift
	done
# 	is_number $choix_fin && choix_fin="decompte" && TIME2SLEEP="$1m" 
# 	[[ "$choix_fin" =~ .*:.*:.*:.*:.*:.* ]] && MAC_ADDR="$1" && choix_fin="bluetooth"
# # 	&& shift && [[ ! -z $1 ]] && TIME_MIN="$1m"
# echo "$choix_fin" | grep -q "m$" && choix_fin="decompte" && TIME2SLEEP=$1 
	
# 	&& die "$choix_fin"
# 	clear
	msg_nn "$show_a2d" "$LAST_USED_FILES" "$TIME2SLEEP" "$SYNSRV"
	[[ -z "$choix_fin" ]] && choix_fin=$(rid "\t->") || RUN_ONCE=1
# 	Si l'utilisateur a passe une durée comme argument alors on decompte, et on eteind/met en veille
	while [[ "$choix_fin" != "q" ]]; do
		case $choix_fin in
			1|bluetooth) 
				bash $DIR_SCRIPTS/bluez-auto.sh "$MAC_ADDR"
				choix_fin=""
			;;
			2|vlc) 
				nohup vlc "${LAST_USED_FILES}" &
				choix_fin=""
			;;
			3|sleep) 
				decompte $TIME2SLEEP "Extinction dans %s " && decompte 5 "Extinction - %s " && systemctl poweroff -i
				choix_fin=""
			;;
			4|synclient) 
				nohup synergyc -f $SYNSRV & 
				choix_fin=""
			;;
			5|synserver) 
				nohup synergys -f & 
				choix_fin=""
			;;
			80463) 
# 				aneble_dux() {  }
#                 ! systemctl is-enabled dux &&
                ! systemctl --quiet is-enabled dux &&
				su - -c "systemctl disable $DISPLAYMANAGER && systemctl enable dux" || su - -c "systemctl disable dux; systemctl enable $DISPLAYMANAGER"
				choix_fin="" 
			;;
			$NUM_REBOOT) [[ -z $NO_REBOOT ]] && { rid_continue "Suspend ?" && systemctl suspend -i; break; } || choix2error "\"%s\" n'est pas une action valide !\r" "$choix_fin"
				choix2do;;
			$(($NUM_REBOOT+1))) [[ -z $NO_REBOOT ]] && { rid_continue "Reboot ?" && systemctl reboot; break; } || choix2error "\"%s\" n'est pas une action valide !\r" "$choix_fin"
				choix2do;;
			$(($NUM_REBOOT+2))) [[ -z $NO_REBOOT ]] && { rid_continue "Poweroff ?" && systemctl poweroff -i; break; } || choix2error "\"%s\" n'est pas une action valide !\r" "$choix_fin"
				choix2do;;
# 			9) tail -n 50 $LOG_FILE ;;
# 			4) # echo "$LAUNCH_COMMAND -i"
# 				sed -i "s/PACSTRAP_OPTIONS=\"/PACSTRAP_OPTIONS=\"-i/" /tmp/arch-$NAME_MACHINE-$LA_LOCALE.conf 
# 				sed -i "s/SHOW_COMMANDE=\"/SHOW_COMMANDE=\"-i/" /tmp/arch-$NAME_MACHINE-$LA_LOCALE.conf
# 				$LAUNCH_COMMAND
# 			;;
# 			5) 
# 				rm /tmp/done.anarchi_* 
# 				$LAUNCH_COMMAND;;
# 			6)
# 	# 			source files/chroot_common.sh
# 				msg_n "32" "32" "Entre dans l'environnement chroot sur %s" "$ROOT"
# 				init_chroot "$ROOT"
# 				chroot_add_resolv_conf "$ROOT"
# 				arch_chroot "/bin/bash" "$ROOT"
# 				chroot_teardown "reset" 
# 	# 			choix_fin=""
# 				termine
# 			;;
			q) break ;;
			"") 
# 			choix2error "\"%s\" n'fre !\r" "$choix_fin"
# 				OLD_DISPLAY=$DISPLAY
# 				DISPLAY=
				bash
# 				DISPLAY=$OLD_DISPLAY
# 				choix2error "$DISPLAY"
				choix2do
			;;
			*) 
				[[ "$choix_fin" != "" ]] && choix2error "\"%s\" n'est pas une action valide !\r" "$choix_fin"
				choix_fin="" 
				choix2do
			;;
		esac
	done
	[[ "$choix_fin" == "q" ]] && exit
}

# [[ ! -z $1 ]] && TIME2SLEEP="$1m" && shift && [[ "$1" =~ .*:.*:.*:.*:.*:.* ]] && MAC_ADDR="$1" && shift
TIME2SLEEP="45m"
SYNSRV="dux-machine"
DIR_SCRIPTS="$(dirname $0)/.."
_ask_2do=( "Bluetooth connexion" "Lancer VLC %s" "Lancer le compte a rebours (%s)" "Synergy Client (%s)" "Synergy server" )
# Display Manager configuration files
dm2edit=( "/etc/lightdm/lightdm.conf" "/etc/lxdm/lxdm.conf" "/etc/sddm.conf" "/etc/slim.conf" "/etc/nodm.conf" )
# files2source="futil"
source $DIR_SCRIPTS/src/sources_files.sh $DIR_SCRIPTS/src/futil

#COLORED_PROMPT=0
# rid_menu -q "Que voulez vous faire ?" "${_ask_2do[@]}"
# echo $DIR_SCRIPTS/src/sources_files.sh 
[[ ! -z $1 ]] && [[ "$1" == "--no-reboot" ]] && NO_REBOOT=1 && shift
DISPLAYMANAGER=$( search_dm | sed "s/.*\/\(.*\).conf/\1/g" ) 
[[ -z $DISPLAYMANAGER ]] && DISPLAYMANAGER="?" && msg_info "Display manager not found ! (sddm/lightdm/lxdm/slim/nodom)"

# [[ ! -z $1 ]] && [[ -e "$1" ]] && [[ ! -b "$1" ]] && ROOT="$1" && shift
# On calcule le nombre d"éléments pour ne pas a décaler reboot et poweroff dans la liste quand on ajoute une entrée dans ${_ask_2do...
NUM_REBOOT="$((${#_ask_2do[*]}+1))"
[[ -z $NO_REBOOT ]] && _ask_2do=( "${_ask_2do[@]}" "Suspend" "Redémarrer" "Éteindre"  )
show_a2d="$( rid_menu -q "Que voulez vous faire ?" "${_ask_2do[@]}")"
echo "${@}"
choix2do "${@}"

