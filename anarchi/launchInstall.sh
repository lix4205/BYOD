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

   
DIR_SCRIPTS="$( dirname $0 )" 
# && [[ "$DIR_SCRIPTS" == "." ]] && DIR_SCRIPTS=$( pwd )
WORK_DIR="/tmp/install"
NAME_ARCHIVE="arch-install"
FILE2SOURCE="/tmp/anarchi-"
NAME_SCRIPT="launchInstall.sh"
NAME_SCRIPT2CALL="pacinstall.sh"
DEFAULT_CACHE_PKG="/var/cache/pacman/pkg"
PREFIX_PACMAN="$WORK_DIR/root.x86_64"
ROOT_DIR_BOOTSTRAP="/install.arch"
LOG_EXE="/tmp/anarchi.log"
FILE_COMMANDS="/tmp/anarchi_command"
# mkdir install directory

# force script to running on $WORK_DIR
# force files copy to install directory
if [[ "$DIR_SCRIPTS" != "$WORK_DIR" ]]; then
	mkdir -p $WORK_DIR 
	cp -RfL "$DIR_SCRIPTS"/{$NAME_SCRIPT2CALL,$NAME_SCRIPT,files} $WORK_DIR || echo "==> ERROR: Copy failed !"
	cp -R "$DIR_SCRIPTS/tool" $WORK_DIR/files/
	cp -R "$DIR_SCRIPTS/../extras" $WORK_DIR/files/
	# TODO Regler dependances...
	rm "$WORK_DIR/files/extras/tools"
# 	cp -a "$DIR_SCRIPTS/../confs" $WORK_DIR/files/
# 	cp -Rf "$DIR_SCRIPTS/../imgs" $WORK_DIR/files/
# 	( cd "$WORK_DIR/files"; rm imgs bgs; ln -sf extras/imgs . && ln -sf imgs bgs )
# 	cp -RfL $DIR_SCRIPTS/../services files/services
# 	printf "Copie dans $WORK_DIR\n"
	$WORK_DIR/$NAME_SCRIPT "${@}"
	# Using "retry" with termine
	[[ $? -eq 100 ]] && printf "\t$DIR_SCRIPTS/$NAME_SCRIPT ${*}\n" && $DIR_SCRIPTS/$NAME_SCRIPT "${@}"
	exit $?
fi
cd $WORK_DIR

# BEGIN FUNCTIONS
usage() {
  cat <<EOF
usage: ${0##*/} [options] root [packages]

  Options:
    -C config      Use an alternate config file for pacman
    -d             Allow installation to a non-mountpoint directory
    -G             Avoid copying the host's pacman keyring to the target
    -i             Avoid auto-confirmation of package selections
    -M             Avoid copying the host's mirrorlist to the target
    -a architecture                       Architecture du processeur (x64/i386) DEBIAN UNIQUEMENT
    -g graphic driver to install          Pilote carte graphique (intel,nvidia{-304,340},radeon,all)
    -e desktop environnement              Environnement de bureau (plasma,xfce,lxde,gnome,mate,cinnamon,fluxbox,enlightenment)
    -h hostname                           Nom de la machine
    -u username                           Login utilisateur
    -S                                      Utiliser sudo pour l'utilisateur principal
    -n [ nm, dhcpcd@<< network_interface >> ]       Utilisation de NetworkManager ou dhcpcd (avec l'interface NETWORK_INTERFACE)
    -p                                 	Gestion imprimante ( cups )
    -H		                        Gestion imprimante HP ( cups + hplip )
    -b		                        Gestion du bluetooth ( bluez bluez-utils )
    -l /dev/sdX                           Installation de grub sur le péripherique /dev/sdX.
    -L  		 	                  Installation de libreoffice
    -T		                        Installation de thunderbird
    -c CACHE_PAQUET           		Utilisation des paquets contenu dans le dossier CACHE_PAQUET
    -t             Test mode
    -q             Quiet mode

    -h             Print this help message

pacinstall installs packages named in files/de/*.conf to the specified new root directory.
Then generate fstab, add the user,create passwords, install grub if specified,
enable systemd services like the display manager
And files/custom_user is executed as a personal script 

EOF
}

on_exit() {
    [[ ! -f "$FILE_BOOTSTRAP" ]] && remove_boostrap
    [[ ! -z $LAUNCH_COMMAND_ARGS ]] && echo "$DIR_SCRIPTS/$NAME_SCRIPT" "${LAUNCH_COMMAND_ARGS[@]}" "${SHOW_COMMANDE[@]}" "$RACINE" "$OTHER_PACKAGES" > /tmp/aaic-$( date "+%Y%m%d-%H-%M" ) && msg_ntin "32" "32" "$_util_command" "/tmp/aaic-$( date "+%Y%m%d-%H-%M" )"
cat <<EOF

$DIR_SCRIPTS/$NAME_SCRIPT ${LAUNCH_COMMAND_ARGS[@]} ${SHOW_COMMANDE[@]} $RACINE $OTHER_PACKAGES

EOF

}

# BEGIN not in arch
remove_boostrap () {
	[[ ! -z "$PID_WGET" ]] && kill $PID_WGET 2> /dev/null && rm $FILE_BOOTSTRAP
	[[ -e "$FILE_BOOTSTRAP" ]] && [[ ! -z "$FIN" ]] && [[ $FIN -eq 0 ]] && rm $FILE_BOOTSTRAP
# 	[[]] &&rm $FILE_BOOTSTRAP
	echo -e "\n"
}

download_img () {
# 	UNAMEM=$ARCH
	UNAMEM="x86_64"
	[[ "$ARCH" == "x64" ]] && UNAMEM="x86_64"
	FILE_BOOTSTRAP="$WORK_DIR/$NAME_ARCHIVE-$UNAMEM.tar.gz"
	ROOT_BOOTSTRAP="$WORK_DIR/root.$UNAMEM"
	
# 	LATEST="2015.12.01"
	LATEST="$( date +%Y ).$( date +%m ).01"	
	URL_BOOTSTRAP="http://mirrors.kernel.org/archlinux/iso/latest/archlinux-bootstrap-$LATEST-$UNAMEM.tar.gz"
	if [[ ! -e "$ROOT_BOOTSTRAP" ]]; then
		msg_n "$_launch_dl"
		if [[ ! -f "$FILE_BOOTSTRAP" ]]; then
			WGET="curl $URL_BOOTSTRAP -o $FILE_BOOTSTRAP"
# 			check_command "curl" || {
				check_command "wget" && {
						WGET="wget $URL_BOOTSTRAP -O $FILE_BOOTSTRAP"
				} || {
						die "$_wget_missing"
				}
# 			}
			! [[ -e "$WORK_DIR" ]] && mkdir $WORK_DIR
			cd "$WORK_DIR"
			msg_nn2 "$_test_net"
			ping -q -c 2 "www.archlinux.org" >/dev/null 2>&1
			[[ $? -eq 0 ]] && msg_nn_end " $_ok" || msg_nn_end "$_fail"

			echo "$WGET"
# 			exit
			# Downloading in background until user has information...
			$WGET > /tmp/$NAME_ARCHIVE-$UNAMEM.tar.gz.log 2>&1 &
			PID_WGET=$!		
# 			trap "remove_boostrap" EXIT	
		fi
	fi
	
}

notinarch_function() {
# 	MIRROR="https://archlinux.surlyjake.com/archlinux"
	MIRROR="http://mirrors.evowise.com/archlinux/"
	MIRROR="${MIRROR//\//\\\/}"
	
	WORK_DIR_BOOTSTRAP="$ROOT_BOOTSTRAP$WORK_DIR"
	[[ ! -e "$WORK_DIR_BOOTSTRAP" ]] && mkdir $WORK_DIR_BOOTSTRAP
	[[ ! -e "$ROOT_BOOTSTRAP$ROOT_DIR_BOOTSTRAP" ]] && mkdir $ROOT_BOOTSTRAP$ROOT_DIR_BOOTSTRAP
	
	msg_nn "$_prepare_chroot..."
	cp -RfL $DIR_SCRIPTS/{$NAME_SCRIPT2CALL,files} $WORK_DIR_BOOTSTRAP/ || die "$_install_copie"
# 	ln -fs  "$DIR_SCRIPTS" $WORK_DIR_BOOTSTRAP/files/anarchi
	# Décommenter un seul serveur
	sed -i "s/#Server = $MIRROR/Server = $MIRROR/g" root.$UNAMEM/etc/pacman.d/mirrorlist
	# Décommenter tout les serveurs
# 	sed -i "s/^#Server/Server/g" root.$UNAMEM/etc/pacman.d/mirrorlist

	COMMAND4ARCH="$WORK_DIR/$NAME_SCRIPT2CALL -x $( echo $LA_LOCALE | sed "s/\..*//" ) $QUIET$TESTING$PACSTRAP_OPTIONS $( [[ ! -z "$CACHE_PAQUET" ]] && echo "-c $DEFAULT_CACHE_PKG" || echo "-c $ROOT_DIR_BOOTSTRAP$DEFAULT_CACHE_PKG" ) $( [[ ! -z "$GRUB_INSTALL" ]] && echo "-l $GRUB_INSTALL" ) -a $ARCH -n $CONF_NET -g $DRV_VID $( [[ "$DRV_VID" != "0" ]] && echo " -e $DE" ) -D ${envir[syst_$DE]} -h $NAME_MACHINE -u $USER_NAME -z \"$TIMEZONE\" -k $CONSOLEKEYMAP -K $X11_KEYMAP $USER_SUDO -C $ROOT_DIR_BOOTSTRAP$WORK_DIR/files/pacman.conf.$ARCH  $ROOT_DIR_BOOTSTRAP $OTHER_PACKAGES"

	
	COMMAND2LAUNCH="source $WORK_DIR_BOOTSTRAP/files/linux-part.sh $PREFIX_PACMAN $RACINE $NAME_MACHINE $LA_LOCALE $DE" 
	msg_nn_end "$_ok"
}

# Attend la fin du téléchargement de l'image minimal d'Archlinux puis décompresse
# Recupere la sortie de curl ou wget et la renvoie vers l'utilisateur
wait_arch_define() {
	if [[ ! -e "root.$UNAMEM" ]]; then
		cd "$WORK_DIR"
		if [[ ! -z "$PID_WGET" ]]; then
			msg_nn "$_downloading..."
			loading &
			PID_LOAD=$! && disown
			while kill -0 $PID_WGET 2> /dev/null; do
				sleep 3
				clear_line
				if [[ -e /proc/$PID_WGET/fd/2 ]]; then
					if tail -n 2 /tmp/$NAME_ARCHIVE-$UNAMEM.tar.gz.log | grep -q "%"; then
						PERCENT="$( tail /tmp/$NAME_ARCHIVE-$UNAMEM.tar.gz.log | grep "%" | tail -n 1 | sed "s/.* \(.*\%\)/\1/" )"
						SPEED=""
					else
						echo "" > /tmp/$NAME_ARCHIVE-$UNAMEM.tar.gz.log
						PERCENT="$( tail -n 1 /proc/$PID_WGET/fd/2 | awk '{print $4}' )%"
						SPEED=" - $( tail -n 1 /proc/$PID_WGET/fd/2 | awk '{print $13}') "
					fi
					msg_nn2 "\r"  "$_downloading...%s%s" "$PERCENT" "$SPEED "
				else
					msg_n "32" "32" "$_downloading...ok"
				fi
			done
			kill $PID_LOAD && printf "\b"
		fi
		if [[ -e "$FILE_BOOTSTRAP" && ! -e "root.$UNAMEM"  ]]; then
			loading beg="$_archive_extract" end="$_archive_extract$ok" tar xf $FILE_BOOTSTRAP
	#		tar xvf arch-install-$UNAMEM.tar.gz # verbose mode
			PID_WGET=$!
		fi
	fi
}
# END not in arch

checkrequirements () {
#	Arch base config
#	On vérifie si on est sur Arch ou une distribution basée sur arch
	msg_n "32" "32" "$_check_init"
	
	msg_nn2 "$_test_net"
	ping -q -c 2 "www.archlinux.org" >/dev/null 2>&1
	[[ $? -eq 0 ]] && msg_nn_end " $_ok" ||  { msg_nn_end "$_fail"; die "$_no_internet"; }
	
	check_command "command" || {
		caution "$_command_not_found"
		return 1 ;
	}
	if [[ -z "$DEBIAN_INSTALL" ]]; then
        check_command "pacman" && {
            exist_install ${_needed_commands} || die "$_install_ais_failed" 				
        } || {
            caution "$_requirement_missing"	
            REQUIRE_PACMAN=1
            rid_continue "$_bootstrap" && download_img || die "Pacman needed !"
        }
    else
        check_command "debootstrap" && {
            exist_install ${_needed_commands} || die "$_install_ais_failed" 				
        } || {
            caution "$_requirement_missing"			
#             rid_continue "$_debootstrap" && { run_or_su "apt install debootstrap"; } || 
            die "debootstrap needed!"
        }
    fi
}

define_arch () {
	ARCH=$1
	if [[ ! -z "$DEBIAN_INSTALL" ]]; then 
	# For i686 processor... ask user to switch directly to i686 
        [[ "$(uname -m)" == "i386" && "$ARCH" != "i386" ]] && rid_continue "$_processor_i686" && ARCH="i386" 
        while [[ "$ARCH" == "" ]] || [[ "$ARCH" != "x64" && "$ARCH" != "i386" ]]; do
            msg_nn "$_arch"
            echo -e "$( print_menu "${valid_arch[@]}" )"
            OPT=$(rid "$_choix_de" )	
            if [[ "$OPT" != "" ]]; then
                [[ ! -z ${valid_arch[$OPT]} ]] && ARCH=${valid_arch[$OPT]} || error "$_valid_choice" "$OPT"
            fi
        done
    else
        [[ "$(uname -m)" != "x86_64" ]] && die "$_impossible"
        ARCH="x64"
	fi
	msg_n "32" "32" "$_arch_selected" "$ARCH"

	LAUNCH_COMMAND_ARGS+=("-a $ARCH");
}

conf_net () {
	local j=0
	CONF_NET="$1"
	list_if
# 	echo "$(msg_info "He") --> ${j} ${valid_iface[$j]}" >> /tmp/tmp.log
	valid_iface[0]="none"
	valid_iface[none]="0"
	valid_iface[$((j+1))]="nm"
	valid_iface[nm]=$((j+1))
	valid_iface[$((j+2))]="connman"
	valid_iface[connman]=$((j+2))
	valid_iface[$((j+3))]="nfsroot"
	valid_iface[nfsroot]=$((j+3))
	valid_iface[$((j+4))]="dhcpcd"
	valid_iface[dhcpcd]=$((j+4))
	
	TFACES=( "${TFACES[@]}" "$_net_nm" "Connman" "$_net_nfsroot" "$_net_dhcp" )
	
	if [[ -z "$CONF_NET" ]] || ( [[ -z ${valid_iface[${CONF_NET//dhcpcd@/}]} ]] &&  [[ -z ${valid_iface[${CONF_NET//wifi@/}]} ]] ); then
		msg_nn "$_net"
		printf "$(print_menu "${TFACES[@]}")\n"
        while [[ -z "$CONF_NET" || ( -z ${valid_iface[${CONF_NET//dhcpcd@/}]} && -z ${valid_iface[${CONF_NET//wifi@/}]} ) ]]; do 
            [[  ! -z "$NUM_CONF_NET" ]] && [[ -z ${valid_iface[$NUM_CONF_NET]} ]] && choix2error "$_valid_choice" "$NUM_CONF_NET" && clear_line
            NUM_CONF_NET=$(rid "33" "31" "$_choix_de" )
# 				msg_n "%s--%s" "$CONF_NET" "${valid_iface[$NUM_CONF_NET]}"
            [[ ! -z $NUM_CONF_NET ]] && [[ ! -z ${valid_iface[$NUM_CONF_NET]} ]] && CONF_NET="${valid_iface[$NUM_CONF_NET]}"
            [[ "$NUM_CONF_NET" == "q" ]] && exit
            [[ -z "$NUM_CONF_NET" ]] && CONF_NET="${valid_iface[$((j+4))]}" && break;
#             NUM_CONF_NET=$((j+4)) && break
            [[ "$NUM_CONF_NET" == "$((j+3))" || "$NUM_CONF_NET" == "$((j+2))" || "$NUM_CONF_NET" == "$((j+1))" ]] && break
        done
	fi

	if echo "$CONF_NET" | grep -v nfsroot | grep -v dhcpcd | grep -v nm | grep -q wifi || echo "$CONF_NET" | grep -v nfsroot | grep -v dhcpcd | grep -v nm | grep -q wlp; then
		WIFI_NETWORK=$( bash $DIR_SCRIPTS/files/extras/wifi-utils.sh ${CONF_NET//wifi@/} "get" ) || exit
		[[ -z "$WIFI_NETWORK" ]] && rid_continue "Voulez vous configurer le reseau ?" && conf_net "" 
		[[ ! -z "$WIFI_NETWORK" ]] && msg_n "32" "32" "$_net_selected" "${valid_iface[${valid_iface[${CONF_NET//wifi@/}]}]}"
		CONF_NET="${valid_iface[${valid_iface[${CONF_NET//wifi@/}]}]}"
	else
		case "${valid_iface[${valid_iface[${CONF_NET//dhcpcd@/}]}]}" in
			nm) msg_n "32" "32" "$_net_selected" "Network Manager" ;;
			connman) msg_n "32" "32" "$_net_selected" "Connman" ;;
			nfsroot) msg_n "32" "32" "$_net_selected" "$_net_nfsroot" ;;
			dhcpcd) msg_n "32" "32" "$_net_selected" "Dhcpcd";;
			none) rid_continue "Voulez vous configurer le reseau ?" && conf_net ""; msg_n "32" "32" "$_net_selected" "None";;
			*) 
				msg_n "32" "32" "$_net_selected" "${valid_iface[${valid_iface[${CONF_NET//dhcpcd@/}]}]}"
				# On redefinit CONF_NET dans le cas ou l'utilisateur a saisi le nom de la carte ( type enp0s3 )...
				CONF_NET="${valid_iface[${valid_iface[${CONF_NET//dhcpcd@/}]}]}"
			;;
		esac
	fi
	LAUNCH_COMMAND_ARGS+=("-n $CONF_NET");
}

net_wifi () {
	NET_CON=${1//*@/}
	TYPE_CON=${1//@*/}
	source /tmp/$NET_CON
	[[ "$TYPE_CON" == "wpa_supplicant" ]] && SYSTD_TOENABLE+=" wpa_supplicant@$I_W dhcpcd@$I_W"
}


write_package() {
	echo -en " $1" >> "$2"
}

graphic_setting () {
	local rep=;
	DRV_VID=$1
# 	msg_n "${graphic_drv[$1]}---$1---${graphic_drv[$DRV_VID]}" 
	if [[ "$DRV_VID" == "nv" ]];then
		msg_nn "$_graphic ( %s )" "Nvidia"
		# TODO C'est quoi ce test !
		while [[ -z "$rep" ]] && ( [[ $rep != "1" ]] || [[ $rep != "2" ]] || [[ $rep != "3" ]] || [[ $rep != "4" ]] ); do
			echo -e "$( print_menu "${_graphic_nv[@]}" )"
# 			echo -e "$_graphic_nv"
			rep=$(rid "$_choix_de")
			case "$rep" in
			1) DRV_VID="nouveau" ;;
			2) DRV_VID="nvidia" ;;
			3) DRV_VID="nvidia-340xx" ;;
			4) DRV_VID="nvidia-304xx" ;;
			"") lspci | grep VGA --color ;rep=;;
			*) rep=
			esac
		done
	fi
	if [[ ! -z "$DRV_VID" ]] && (( ${graphic_drv[$DRV_VID]} )); then
		:
	else
		while [[ -z "$rep" ]]; do
			[[ -z "$DRV_VID" ]] && msg_nn "$_graphic"
			echo -e "$( print_menu "${_graphic_list[@]}")"
			rep=$(rid "$_choix_de" "$_0_select")
			case "$rep" in
				0) DRV_VID=0;;
				1) DRV_VID="intel" ;;
				2) graphic_setting "nv" "1";;
				3) DRV_VID="radeon" ;;
				4) DRV_VID="virtualbox" ;;
				"") 
                    ! command -v lspci >> /dev/null && lspci | grep VGA --color || error "%s n'est pas installé !" "lspci"
                    rep=
                ;;
				*) rep=
			esac
		done
	fi
# 	msg_n "${graphic_drv[$1]}---$1---${graphic_drv[$DRV_VID]}!!!!${graphic_drv[name_$DRV_VID]}" 
	[[ ! -z ${graphic_drv[name_$DRV_VID]} ]] && DRV_VID="${graphic_drv[name_$DRV_VID]}"
# 	msg_n "${graphic_drv[${graphic_drv[name_$DRV_VID]}]}--->${graphic_drv[_${graphic_drv[name_$DRV_VID]}]}"
	[[ "$DRV_VID" == "0" ]] && DE=0 && clear_line && caution "$_graphic_none"
	[[ "$DRV_VID" != "0" ]] && [[ -z "$2" ]] && msg_n "32" "32" "$_graphic_set" "${DRV_VID^}" && LAUNCH_COMMAND_ARGS+=("-g $DRV_VID");

}

choose_dm() {
	local choix_dm
	i=0
	for dm_dispo in ${DISPLAYMANAGER[@]}; do 
		i=$((i+1));
		envir[dm_$i]="$dm_dispo"
        [[ "$dm_dispo" == "$DM" ]] && envir[syst_$DE]="$DM" && envir[dm_$DE]="$DM" && return 0;
		
# 		envir[$env_dispo]="$env_dispo"
# 		msg_edit+="\n\t$i) $RACINE$f2e"
	done
	if ! rid_continue "$_defaultdm" "${envir[syst_$DE]}"; then
        msg_nn "$_select_dm"
        while [[ -z "$choix_dm" ]] || [[ -z ${envir[dm_$choix_dm]} ]]; do
            echo -e "$( print_menu "${DISPLAYMANAGER[@]}")"
            choix_dm=$(rid "$_choix_de")
        done
        envir[syst_$DE]="${envir[dm_$choix_dm]}"
        msg_n "32" "32" "$_selected" "${envir[dm_$choix_dm]}"
        envir[dm_$DE]="${envir[dm_$choix_dm]}"
    fi
# 	die "ok %s ok %s" "$choix_dm" "${envir[dm_$choix_dm]}"
}

choose_debvers() {
	local choix_dm
	i=0
	for dv_dispo in ${DEBIANVERSION[@]}; do 
		i=$((i+1));
		envir[dv_$i]="$dv_dispo"
#         [[ "$dm_dispo" == "$DM" ]] && envir[syst_$DE]="$DM" && envir[dm_$DE]="$DM" && return 0;
    done
	if ! rid_continue "$_defaultdv" "$DEBIAN_DEFAULT"; then
        msg_nn "$_select_dv"
        while [[ -z "$choix_dv" ]] || [[ -z ${envir[dv_$choix_dv]} ]]; do
            echo -e "$( print_menu "${DEBIANVERSION[@]}")"
            choix_dv=$(rid "$_choix_de")
        done
#         envir[syst_$DE]="${envir[dm_$choix_dm]}"
        msg_n "32" "32" "$_selected" "${envir[dv_$choix_dv]}"
        DEBIAN_VERS="${envir[dv_$choix_dv]}"
    else
        DEBIAN_VERS="${envir[dv_default]}"
    fi
# 	die "ok %s ok %s" "$choix_dm" "${envir[dm_$choix_dm]}"
}

desktop_environnement () {
	DE="$1"
	i=0
	for env_dispo in ${ENVIRONNEMENT[@]}; do 
		i=$((i+1));
		envir[$i]="$env_dispo"
		envir[$env_dispo]="$env_dispo"
        [[ "$env_dispo" == "$DE" ]] && break;
# 		msg_edit+="\n\t$i) $RACINE$f2e"
	done 
	if [[ -z "$DE" ]] || [[ -z ${envir[$DE]} ]]; then 
# 		msg_nn "$_env"
		msg_nn "$(rid_menu -q "$_env" "${ENVIRONNEMENT[@]}")"
		while [[ -z "$DE" ]] || [[ -z ${envir[$DE]} ]]; do
			[[ ! -z "$OPT" ]] && [[ -z ${envir[$OPT]} ]] && choix2error "$_valid_choice" "$OPT" && clear_line
			OPT=$( rid "\r  ->" "$_choix_de" )
			[[ ! -z $OPT ]] && [[ ! -z ${envir[$OPT]} ]] && DE="${envir[$OPT]}"
			[[ "$OPT" == "q" ]] && exit
			[[ "$OPT" == "0" ]] && DE=0 && break 
		done
	fi

	[[ "$DE" != "0" ]] && msg_n "32" "32" "$_env_set" "$DE"
	LAUNCH_COMMAND_ARGS+=("-e $DE");
	# Choix du display manager...
	[[ "$DE" != "0" ]] && choose_dm "$DE"
	LAUNCH_COMMAND_ARGS+=("-D ${envir[syst_$DE]}");
    [[ ! -z "${envir[pack_${envir[syst_$DE]}]}" ]] && envir[dm_$DE]="${envir[pack_${envir[syst_$DE]}]}"
# die "${LAUNCH_COMMAND_ARGS[@]}"
}
name_host () {
	#NOM MACHINE
	NAME_MACHINE=$1; 
	[[ ! -z "$NAME_MACHINE" ]] && msg_n "32" "32" "$_hostname_set" "$NAME_MACHINE"
	while [[ -z $NAME_MACHINE ]]; do
		NAME_MACHINE=$(rid "$_hostname" )
	done
	LAUNCH_COMMAND_ARGS+=("-h $NAME_MACHINE");
}

name_user () {
	#NOM UTILISATEUR
	USER_NAME=$1; 
	[[ ! -z "$USER_NAME" && $USER_NAME != "root" ]] && msg_n "32" "32" "$_username_set" "$USER_NAME"
	while [[ -z "$USER_NAME" || $USER_NAME == "root"  ]]; do
		[[ $USER_NAME == "root" ]] && msg_n "31" "31" "User login can't be %s !" "$USER_NAME"
		USER_NAME=$(rid "$_username " )
	done
	LAUNCH_COMMAND_ARGS+=("-u $USER_NAME");
}

# INSTALLATION DE GRUB SUR LE DISQUE DUR $1
check_disk() { [[ -b "$1" ]] && return 0 || die "$_grub_unable $1"; }
cache_packages () { 
    if [[ -d "$1" ]]; then
        CACHE_PAQUET=$1 
        LAUNCH_COMMAND_ARGS+=("-c $CACHE_PAQUET")
    else
        die "$_not_a_dir" $1; 
    fi
}

# Set Zone and Sub-Zone
set_timezone() {
	declare -A zones
	declare -A subzones
	TIMEZONE=$1
	if [[ -z "$TIMEZONE" || !  -e /usr/share/zoneinfo/$TIMEZONE ]]; then
        [[ -z "$TIMEZONE" ]] && ( msg_n "$_set_timezone" && msg_nn2 "$_list_loading" ) || msg_nn2 "33" "$_timezone_checking" "$TIMEZONE"
        j=0
        for i in $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud); do
            ZONE_AFF="$( echo "${ZONE_AFF} $((j+1))) ${i}" ) $( [[ "$(expr $((j+1))  % 4 )"  == "0" ]] && echo "\n"  ) "
# 				while read -r; do
#                     
# 				done < <(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | grep $i | sort -ud )
            j=$((j+1))
# 				zones[$j]="1"
            zones[_$j]="$i"
        done

        if [[ -z "$TIMEZONE" || -z "${zones["$TIMEZONE"]}" ]]; then
			msg_nn_end "$( [[ -z "$TIMEZONE" ]] && echo "$_ok" || echo "$_fail" )"
			echo -e "${ZONE_AFF}" | column -t
			NUM_TIMEZONE=$( rid "$_choix_de" )
			while [[ -z "${zones[_$NUM_TIMEZONE]}" ]]; do
				NUM_TIMEZONE=$( rid "$_choix_de" )
				[[ $NUM_TIMEZONE == "q" ]] && exit 2
			done
			j=0
# 			loading &
# 			PID_LOAD=$! && disown
			for i in $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sort -ud); do
				zones["_${i}"]="${i}"
				subzones["${i//\/*}"]="${subzones["${i//\/*}"]} $( echo ${i} | sed "s/${i//\/*}\///g"  )"
				j=$((j+1))
			done
# 			kill $PID_LOAD && printf "\b"
			j=0
			for i in ${subzones[${zones[_$NUM_TIMEZONE]}]}; do
				SUBZONE_AFF="$( echo "${SUBZONE_AFF} $((j+1))) ${i}" ) $( [[ "$(expr $((j+1))  % 4 )"  == "0" ]] && echo "\n"  ) "
				j=$((j+1))
				subzones[_$j]="$i"
			done
			echo -e "${SUBZONE_AFF}" | column -t
			while [[ -z "$TIMEZONE" || -z "${zones[_$TIMEZONE]}" ]]; do
				NUM_SUBTIMEZONE=$( rid "$_choix_de" )
				SUBTIMEZONE="${subzones[_$NUM_SUBTIMEZONE]}"		
				TIMEZONE="${zones[_$NUM_TIMEZONE]}/$SUBTIMEZONE"
				[[ "$NUM_SUBTIMEZONE" == "q" ]] && exit 2
			done
		else
			msg_nn_end "$_ok"		
		fi
	fi

# 	msg_n "32" "32" "$_timezone_set\n\n${zones[@]}" "${zones[@]}";
	msg_n "32" "32" "$_timezone_set" "$TIMEZONE";
	LAUNCH_COMMAND_ARGS+=("-z $TIMEZONE");
# 	sleep 1
}

# From AIF ARchitect... 
# Set keymap for X11 
 set_xkbmap() {
	declare -A langue
	XKBMAP_LIST=""
	keymaps_xkb=("af_Afghani al_Albanian am_Armenian ara_Arabic at_German-Austria az_Azerbaijani ba_Bosnian bd_Bangla be_Belgian bg_Bulgarian br_Portuguese-Brazil bt_Dzongkha bw_Tswana by_Belarusian ca_French-Canada cd_French-DR-Congo ch_German-Switzerland cm_English-Cameroon cn_Chinese cz_Czech de_German dk_Danishee_Estonian epo_Esperanto es_Spanish et_Amharic fo_Faroese fi_Finnish fr_French gb_English-UK ge_Georgian gh_English-Ghana gn_French-Guinea gr_Greek hr_Croatian hu_Hungarian ie_Irish il_Hebrew iq_Iraqi ir_Persian is_Icelandic it_Italian jp_Japanese ke_Swahili-Kenya kg_Kyrgyz kh_Khmer-Cambodia kr_Korean kz_Kazakh la_Lao latam_Spanish-Lat-American lk_Sinhala-phonetic lt_Lithuanian lv_Latvian ma_Arabic-Morocco mao_Maori md_Moldavian me_Montenegrin mk_Macedonian ml_Bambara mm_Burmese mn_Mongolian mt_Maltese mv_Dhivehi ng_English-Nigeria nl_Dutch no_Norwegian np_Nepali ph_Filipino pk_Urdu-Pakistan pl_Polish pt_Portuguese ro_Romanian rs_Serbian ru_Russian se_Swedish si_Slovenian sk_Slovak sn_Wolof sy_Arabic-Syria th_Thai tj_Tajik tm_Turkmen tr_Turkish tw_Taiwanese tz_Swahili-Tanzania ua_Ukrainian us_English-US uz_Uzbek vn_Vietnamese za_English-S-Africa")
	j=0

	[[ -z "$1" ]] && ( msg_n "$_set_keymapX11" && msg_nn2 "$_list_loading"  "X11 keymaps" ) || msg_nn2 "33" "$_x11k_checking" "$1"
	loading &
	PID_LOAD=$! && disown
	for i in ${keymaps_xkb}; do
		XKBMAP_LIST="$( echo "${XKBMAP_LIST} $((j+1))) ${i}" ) $( [[ "$(expr $((j+1))  % 4 )"  == "0" ]] && echo "\n"  ) "
		j=$((j+1))
		langue[_$j]="${i}"
		langue[_${i//_*/}]="${i//_*/}"
		localisation_tab[${i//_*/}]="$i"
		[[ "${i//_*/}" == "$1" ]] && break;
	done
	kill $PID_LOAD && printf "\b"
	[[ -z "$1" ]] && msg_nn_end "$_ok"
	if [[ -z "$1" || -z "${localisation_tab[$1]}" ]]; then
		[[ ! -z "$1" ]] && msg_nn_end "$_fail"
		echo -e ${XKBMAP_LIST} | column -t
		while [[ -z "${langue[_$XKBMAP]}" ]]; do
			XKBMAP=$( rid "$_choix_de $_pageup" )
            [[ "$XKBMAP" == "q" ]] && exit 2
		done
		X11_KEYMAP=$(echo ${langue[_${XKBMAP}]} | sed 's/_.*//')
	else
		msg_nn_end "$_ok"	
	fi
	msg_n "32" "32" "$_x11k_selected..." "$X11_KEYMAP"
	LAUNCH_COMMAND_ARGS+=("-K $X11_KEYMAP");
}

 set_console_kmap() {
	declare -A valid_kmap	
	KEYMAPS=""
	KBD_DIR="/usr/share/kbd/keymaps"
	KBD_EXT="map.gz"
	j=0
	CONSOLEKEYMAP="$1"
	if [[ -z $DEBIAN_INSTALL ]] && [[ ! -e "$2$KBD_DIR" ]]; then
        msg_n "$_missing_file" "$KBD_DIR"
		wait_arch_define
    else        
        [[ ! -e "$2$KBD_DIR" ]] && KBD_DIR="/usr/share/keymaps" && KBD_EXT="kmap.gz"
        [[ ! -e "$2$KBD_DIR" ]] && die "$_missing_file\n  -> Vous devriez installer \"console-data\"." "/usr/share/keymaps"        
	fi
	
# 	die "$2"
	[[ ! -z "$CONSOLEKEYMAP" ]] &&  msg_nn2 "33" "$_console_k_checking" "$CONSOLEKEYMAP" || ( msg_n "$_set_consolek" && msg_nn2 "$_list_loading" )
	loading &
	PID_LOAD=$! && disown
	for i in $(ls -R "$2$KBD_DIR" | grep "$KBD_EXT" | sed "s/\.$KBD_EXT//g" | sort); do
		j=$((j+1))
# 		valid_kmap["$j"]="$i"
		valid_kmap["_$j"]="$i"
		valid_kmap["_$i"]="1"
		[[ "$i" == "$CONSOLEKEYMAP" ]] && break;
		KEYMAPS="${KEYMAPS} $j) ${i} $( [[ "$(expr $((j+1))  % 4 )"  == "0" ]] && echo "\n"  ) "
	done
	kill $PID_LOAD && printf "\b"
	[[ ! -z "$CONSOLEKEYMAP" && -z "${valid_kmap["_$CONSOLEKEYMAP"]}" ]] && msg_nn_end "$_fail" || msg_nn_end "$_ok" 
	if [[ -z "${valid_kmap["_$CONSOLEKEYMAP"]}" ]]; then
		echo -e $KEYMAPS | column -t
		CONSOLEKEYMAP=
		while [[ -z "${valid_kmap["_$CONSOLEKEYMAP"]}" ]]; do
			NUM_KEYMAP=$( rid "$_choix_de $_pageup" )
			CONSOLEKEYMAP="${valid_kmap[_$NUM_KEYMAP]}"
            [[ "$NUM_KEYMAP" == "q" ]] && exit 2
		done
	fi
	unset valid_kmap;
	msg_n "32" "32" "$_console_k_set" "$CONSOLEKEYMAP";
	LAUNCH_COMMAND_ARGS+=("-k $CONSOLEKEYMAP");
}

set_locale() {
	declare -A locales
	LOCALES=""
	j=0
	LA_LOCALE="$1" 
# 	echo "$2 $PREFIX_PACMAN"
# 	exit
	if [[ ! -e "$2/etc/locale.gen" ]]; then
		msg_n "$_missing_file" "/etc/locale.gen"
		wait_arch_define
	fi
	[[ ! -z "$LA_LOCALE" ]] && msg_nn2 "33" "$_locale_checking" "$LA_LOCALE" || ( msg_n "$_set_locale" && msg_nn2 "$_list_loading" )
	loading &
	PID_LOAD=$! && disown
	for i in $( cat "$2/etc/locale.gen" | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8 ); do
		LOCALES="${LOCALES} $((j+1))) ${i} $( [[ "$(expr $((j+1))  % 4 )"  == "0" ]] && echo "\n"  ) "
		j=$((j+1))
		locales[_${i//.*/}]=1
		locales[_$j]="$i"
        [[ "$LA_LOCALE" == "${i//.*/}" ]] && break;
	done


	kill $PID_LOAD && printf "\b"
	[[ ! -z "$LA_LOCALE" && -z "${locales["_${LA_LOCALE//.*/}"]}" ]] && msg_nn_end "$_fail" || msg_nn_end "$_ok" 

	if [[ -z "${locales["_${LA_LOCALE//.*/}"]}" ]]; then
		echo -e $LOCALES | column -t
		while [[ -z "${locales["_${LA_LOCALE//.*/}"]}" ]]; do
			local_tmp="$( rid "$_choix_de $_pageup" )"
			LA_LOCALE=${locales[_$local_tmp]}
            [[ "$local_tmp" == "q" ]] && exit 2
		done
	fi
	unset locales;
	msg_n "32" "32" "$_locales_set" "$LA_LOCALE"
	LAUNCH_COMMAND_ARGS=("$LA_LOCALE" "${LAUNCH_COMMAND_ARGS[@]}")
}

perso () {
	FLAG="$1"
	case "$FLAG" in
		b)
			write_package "$PACK_BLUEZ" files/de$DEBIAN_INSTALL/common.conf
			SYSTD_TOENABLE="$SYSTD_TOENABLE $SYSTD_BLUEZ"
			return 1
		;;
		p) 
			write_package "$PACK_CUPS" files/de$DEBIAN_INSTALL/common.conf
			SYSTD_TOENABLE="$SYSTD_TOENABLE $SYSTD_CUPS"
			return 1
		;;
		H) 
			write_package "$PACK_HPLIP" files/de$DEBIAN_INSTALL/common.conf
			SYSTD_TOENABLE="$SYSTD_TOENABLE $SYSTD_CUPS"
			return 1
		;; 
		# LANGUAGE FOR Libreoffice and Thunderbird
		L) 
			write_package "$PACK_OFFICE_SUITE $( [[ ! -z $PACK_OFFICE_SUITE_LANG ]] && trans_packages $(set_trans_package "$PACK_OFFICE_SUITE_LANG" "$LA_LOCALE") )" files/de$DEBIAN_INSTALL/common.conf
			return 1
		;;
		T) 
			write_package "$PACK_MAIL $([[ ! -z $PACK_OFFICE_SUITE_LANG ]] && trans_packages $(set_trans_package "$PACK_MAIL_LANG" "$LA_LOCALE") )" files/de$DEBIAN_INSTALL/common.conf
			return 1
		;;
        S)
            USER_SUDO+=("-$FLAG")
#             SHOW_COMMANDE+=(" -$flag")
        ;;
# 		s) 
# 			write_package "$PACK_TOUCHPAD" files/de/common.conf
# 			return 1
# 
# 		;;
		q) 
			QUIET="-q "
			return 1
		;;
		t) 
			NO_EXEC=1
			TESTING="-t "
			return 1
		;;
# 		m) 
# #                     sed -i "s/#\[multilib\]\n#/[multilib]/" files/pacman.conf
#                    [[ "$ARCH" == "x64" ]] && echo -e "\n#Multilib configuration\n[multilib]\nInclude = /etc/pacman.d/mirrorlist"
# #                    >> files/pacman.conf.$ARCH
# 
# #                     sed -i "s/#[multilib]/[multilib]/" files/pacman.conf
# # 			write_package "xf86-input-synaptics" files/de/common.conf
# # 			COMMAND2LAUNCH="$( echo $COMMAND2LAUNCH | sed "s/-$FLAG/ /")"
# # 			SHOW_COMMANDE="$( echo $SHOW_COMMANDE | sed "s/-$FLAG/ /")"
# 
# 		;;
	esac
	return 0
# 	write_package "$PACKAGE_TO_INSTALL" files/de/common.conf
}

load_language() {
	local file_2_load
	
	LA_LOCALE="$1";
	[[ "${LA_LOCALE:${#LA_LOCALE}-5}" != "UTF-8" ]] && LA_LOCALE+=".UTF-8" 
	
	file_2_load="files/lang/${LA_LOCALE:0:${#LA_LOCALE}-6}.trans"
	if [[ -e $DIR_SCRIPTS/$file_2_load ]]; then 
# 	die "$file_2_load"
		source "$DIR_SCRIPTS/$file_2_load" 
		return 0
	else
		file_2_load="files/lang/${LANG:0:${#LANG}-6}.trans"
		if [[ -e "$DIR_SCRIPTS/$file_2_load" ]]; then 
			source "$DIR_SCRIPTS/$file_2_load"
			locale_2_load=${LANG:0:${#LANG}-6}
		else
			source "$DIR_SCRIPTS/files/lang/en_GB.trans" 
			locale_2_load="en_GB"
			
		fi
		echo "${LA_LOCALE:0:5}" | grep -q "_" && msg_n2 "31" "31" "$_no_translation" "${LA_LOCALE:0:${#LA_LOCALE}-6}" "$locale_2_load" && return 0 
		LA_LOCALE="" && return 1 
	fi
}

termine() {
	msg_nn2 "32" "32" "$show_a2d" "$RACINE" 
	choix_fin=$(rid "\t->" "32")
	case $choix_fin in
		1) is_root "reboot" && rid_continue "Reboot ?" && reboot ;;
		2) is_root "poweroff" && rid_continue "Poweroff ?" && poweroff ;;
		3) 
			msg_n "32" "32" "%s" "Recommence avec la commande :"
# 			"${LAUNCH_COMMAND[*]}"
# 			${LAUNCH_COMMAND[@]}
            trap - EXIT
			exit 100
			;;
		4) 
			sed -i "s/PACSTRAP_OPTIONS=\"/PACSTRAP_OPTIONS=\"-i/" $FILE2SOURCE$NAME_MACHINE-$LA_LOCALE.conf 
			${LAUNCH_COMMAND[@]}
			exit $?
		;;
		5) 
			rm /tmp/done/anarchi_* 
		;;
		6)
# 			msg_n "cp -RfLv $DIR_SCRIPTS/{$NAME_SCRIPT2CALL,$NAME_SCRIPT,files} files/"
# 			mkdir -p files/anarchic
# 			cp -RfL $DIR_SCRIPTS/{$NAME_SCRIPT2CALL,$NAME_SCRIPT,files} files/anarchic/ >> /dev/null 2>&1

# 			cp -RfL $DIR_SCRIPTS/{$NAME_SCRIPT2CALL,$NAME_SCRIPT,files} files/anarchic || error "$_install_copie"
# 			cp -RfL $DIR_SCRIPTS/../services files/services || error "$_install_copie"
			
			bash files/extras/arch-utils.sh --no-reboot "$RACINE"
		;;
		7)
			bash files/extras/arch-utils.sh --no-reboot "$RACINE" edit
		;;
		8)
			nano $FILE_COMMANDS
		;;
		9)
			nano $LOG_EXE
		;;
		q) exit $FIN
		;;
	esac
	termine
}
# END FUNCTIONS

# BEGIN Declaration des tableaux
declare -A localisation_tab
declare -A valid_arch=( [1]="x64" [2]="i386" )
# Arch based distributions
declare arch_base=( "Manjaro" "Antergos" )
declare -A netw

declare -A yaourt_envir=(
	[0]=""
	[plasma]=""
	[kde4]=""
	[gnome]=""
	[mate]=""
	[lxde]=""
	[xfce]=""
	[lxqt]=""
)

# END Declaration

_needed_commands="arch-chroot arch-install-scripts" ;
files2source=( "$DIR_SCRIPTS/files/src/bash-utils.sh" "$DIR_SCRIPTS/files/src/futil" "$DIR_SCRIPTS/files/src/doexec" "$DIR_SCRIPTS/files/src/net-utils" )
# Fichier source des paquets de base, drivers et suite bureautique, client mail, navigateur.
# Change selon la distribution...
files2source_drv="$DIR_SCRIPTS/files/de/drv_vid"

# BEGIN debootstrap configuration
if [[ "$1" == "debian" ]]; then
    DEBIAN_INSTALL=".debian" 
    _needed_commands="debootstrap"
    
    DEFAULT_CACHE_PKG="/var/cache/apt/archives"
    shift;
    files2source_drv="$DIR_SCRIPTS/files/de$DEBIAN_INSTALL/drv_vid"
fi
# END 

# BEGIN debootstrap configuration
# if [[ "$1" == "gentoo" ]]; then
#     DEBIAN_INSTALL=".gentoo" 
#     _needed_commands="emerge"
#     
#     DEFAULT_CACHE_PKG="/var/cache/apt/archives"
#     shift;
#     files2source_drv="$DIR_SCRIPTS/files/de$DEBIAN_INSTALL/drv_vid"
# fi
# END 



files2source+=("$files2source_drv")

# Usefull functions 
# source $DIR_SCRIPTS/files/futil
# source $DIR_SCRIPTS/files/drv_vid 
# source $DIR_SCRIPTS/files/net-utils

source $DIR_SCRIPTS/files/src/sources_files.sh "${files2source[@]}"
# || { printf "\"%s\" est introuvable !" "$DIR_SCRIPTS/files/bash-utils.sh" && exit 1; }
# declare -A valid_iface
# echo "Le fichier est sourcé !"
# # source_files "${files2source[@]}"
# msg_n "${envir[*]}"
# msg_n "${valid_iface[*]}"


hostcache=0
copykeyring=1
copymirrorlist=1
ARCH=
GRUB_INSTALL=
SYSTD=
SOFT_UTILS=
SYNAPTICS_DRIVER=
ON_ARCH_BASE=0
# Not in arch based 
REQUIRE_PACMAN=0


# Set localisation
load_language "$( echo $1 | sed "s/\..*//" )" && shift 
msg_n "32" "32" "%s" "$_welcome" 


# edit_file
# exit

checkrequirements
if [[ ! -z $DEBIAN_INSTALL ]]; then
    choose_debvers
    source "$DIR_SCRIPTS/files/de$DEBIAN_INSTALL/drv_vid.$DEBIAN_VERS"
    source "$DIR_SCRIPTS/files/de$DEBIAN_INSTALL/drv_vid$DEBIAN_INSTALL"
    ln -sf $DIR_SCRIPTS/files/de$DEBIAN_INSTALL/$DEBIAN_VERS/* $DIR_SCRIPTS/files/de$DEBIAN_INSTALL/
fi

# die "$DEBIAN_VERS"

if ls $FILE2SOURCE*.conf >> /dev/null 2>&1; then
	rf="$(rid_1 "32" "32" "$_file_load (%s)  [ ${_yes^}/$_no/e ]" "$( ls $FILE2SOURCE*.conf )" )"
	while [[ "${rf,,}" != "$_no" ]]; do
		[[ "${rf,,}" == "e" ]] && nano $FILE2SOURCE*.conf
		if [[ "${rf,,}" == "$_yes" ]] || [[ -z "$rf" ]]; then
			FROM_FILE=1
			source $FILE2SOURCE*.conf
# 			Not in Arch based distributions...
			(( $REQUIRE_PACMAN )) && define_arch "$ARCH" && wait_arch_define
			(( ! $REQUIRE_PACMAN )) && PREFIX_PACMAN=""

			envir[syst_$DE]="$DM"
			envir[dm_$DE]="$DM"
			[[ ! -z "${envir[pack_$DM]}" ]] && envir[dm_$DE]="${envir[pack_$DM]}"
			while getopts ':C:c:tdGiMpqTLSbHu:l:a:e:n:g:h:z:k:K:' flag; do
				case $flag in
					q|t) perso "$flag"
					;;
				esac	
			done

            LAUNCH_COMMAND_ARGS+="$LA_LOCALE -a $ARCH $( [[ ! -z "$GRUB_INSTALL" ]] && echo "-l $GRUB_INSTALL" ) ${PACSTRAP_OPTIONS[@]} $( [[ ! -z "$CACHE_PAQUET" ]] && echo "-c $CACHE_PAQUET" ) $QUIET$TESTING -n $CONF_NET $( [[ "$DRV_VID" != "0" ]] && echo "-g $DRV_VID  -e $DE -D $DM" ) -h $NAME_MACHINE -u $USER_NAME -z $TIMEZONE -k $CONSOLEKEYMAP -K $X11_KEYMAP"
			break;
		fi
		rf="$(rid_1 "32" "32" "$_file_load (%s)  [ ${_yes^}/$_no/e ]" "$( ls $FILE2SOURCE* )" )"
	done
	msg_nn_end
	[[ "$rf" == "$_no" ]] && rm $FILE2SOURCE*.conf

fi

trap "on_exit" EXIT	
if [[ ! $FROM_FILE ]]; then
	if [[ -z $1 || $1 = @(-h|--help) ]]; then
		msg "$_nodir"
		usage
		exit $(( $# ? 0 : 1 ))
	fi
	while getopts ':C:c:tGiMpqTLSbHu:l:a:e:n:g:h:z:k:K:D:' flag; do
		case $flag in
			C) SHOW_COMMANDE+=" -C $OPTARG"
				LAUNCH_COMMAND_ARGS+=("-$flag $OPTARG") ;;
			c) cache_packages "$OPTARG" ;; 
# 			d)
# 				directory=1
# 				SHOW_COMMANDE+=" -d"
# 				LAUNCH_COMMAND_ARGS+=("-$flag")
# 			;;
			a) define_arch "$OPTARG" ;;
			n) CONF_NET="$OPTARG" ;;
			g) DRV_VID="$OPTARG" ;;
			e) DE="$OPTARG" ;;
			D) DM="$OPTARG" ;;
			K) X11_KEYMAP="$OPTARG" ;;
			k) CONSOLEKEYMAP="$OPTARG" ;;
			z) TIMEZONE="$OPTARG" ;;
			h) NAME_MACHINE="$OPTARG" ;;
			u) USER_NAME="$OPTARG" ;;
			p|T|L|b|H)
				SHOW_COMMANDE+=" -$flag"			
			;;
			i|G|M|d)
				LAUNCH_COMMAND_ARGS+=("-$flag")
				PACSTRAP_OPTIONS+=(" -$flag")
			;;
			S)
# 				LAUNCH_COMMAND_ARGS+=("-$flag")
				SHOW_COMMANDE+=(" -$flag")
				USER_SUDO=" -$flag"
			;;
# 			p|T|L|b|H|i|G|M|s|d)
# 				SHOW_COMMANDE+=" -$flag"
# 			;;
			
			q|t) 
# 				perso "$flag";
				LAUNCH_COMMAND_ARGS+=("-$flag")
			;;
			l) check_disk "$OPTARG" && GRUB_INSTALL="$OPTARG" && LAUNCH_COMMAND_ARGS+=("-l $GRUB_INSTALL") ;;
			:) die "$_argument_option" "${0##*/}" "$OPTARG" ;;
			?) die "$_invalid_option" "${0##*/}" "$OPTARG" ;;
		esac
	done
	(( ! $REQUIRE_PACMAN )) && PREFIX_PACMAN=""

	shift $(( OPTIND - 1 ))

	(( $# )) || die "$_nodir"

	RACINE=$1; shift
	OTHER_PACKAGES="$@"
	
	[[ -z "$ARCH" ]] && define_arch "$ARCH"

	# check/set configuration
	conf_net "$CONF_NET" 
	graphic_setting "$DRV_VID" 
	[[ "$DRV_VID" != "0" ]] && desktop_environnement "$DE"
	name_host "$NAME_MACHINE"
	name_user "$USER_NAME"
	set_locale "$LA_LOCALE" "$PREFIX_PACMAN"
	set_timezone "$TIMEZONE"
	set_console_kmap "$CONSOLEKEYMAP" "$PREFIX_PACMAN"
	set_xkbmap "$X11_KEYMAP"
	
fi
[[ -d $RACINE ]] || die "$_not_a_dir" "$RACINE"
# if ! mountpoint -q "$RACINE" && (( ! directory )); then
# 	error "$_mountpoint" "$RACINE"
# fi

# Check if we are on arch based distribution 
# and ask to continue
if [[ -z "$DEBIAN_INSTALL" ]];then
    for ab in "${arch_base[@]}"; do
        if cat /etc/issue | grep -q "$ab"; then
        #  Installe la distribution basée sur archlinux...
            if ! rid_continue "Installer $ab ?"; then
#                 ON_ARCH_BASE=1
    # 			SHOW_COMMANDE="$SHOW_COMMANDE -M"
                LAUNCH_COMMAND_ARGS+=("-M")
    # 			die ${LAUNCH_COMMAND_ARGS[*]}
                
	# TODO Faire autrement
	# Ca doit plus marcher...
                mkdir -p $RACINE/etc/pacman.d
                cp files/mirrorlist $RACINE/etc/pacman.d/
                sed -i "s/Include = \/etc/Include = ${RACINE//\//\\\/}\/etc/" files/pacman.conf.$ARCH
                break
            fi
        fi		
    done
fi

# If we are on non arch based distribution
# if (( $REQUIRE_PACMAN ));then
	[[ -e /tmp/install/trans_packages ]] && rm /tmp/install/trans_packages 
# fi

# BEGIN GRAPHIC DRIVERSOFTS LANG and SYSTEMD SERVICE TO ENABLE 	
[[ "$DE" != "0" ]] && SYSTD_TOENABLE+=" ${envir[syst_$DE]}"
[[ "$CONF_NET" == "nm" || "$CONF_NET" == "network-manager" || "$CONF_NET" =~ "networkmanager" || "$WIFI_NETWORK" =~ "networkmanager" ]] && write_package "$PACK_NETWORKMANAGER ${envir[netm_$DE]}" "files/de$DEBIAN_INSTALL/common.conf" && SYSTD_TOENABLE+=" NetworkManager"
[[ "$CONF_NET" == "connman" ]] && write_package "$PACK_CONNMAN" "files/de$DEBIAN_INSTALL/common.conf" 

[[ "$CONF_NET" != "none" && "$CONF_NET" != "nm" && "$CONF_NET" != "network-manager" && ! "$CONF_NET" =~ "networkmanager" && -z "$WIFI_NETWORK" && "$CONF_NET" != "nfsroot" ]] && SYSTD_TOENABLE+=" $CONF_NET"
[[ ! -z "$WIFI_NETWORK" ]] && net_wifi "$WIFI_NETWORK" && cp /tmp/$NET_CON files/
# [[ "$DE" == "mate" ]] && rid_continue "Utiliser Mate GTK3 ?" && ( cd files/de/ && cat mate-gtk3.conf > mate.conf )

# Display Manager
write_package "${envir[dm_$DE]}" "files/de$DEBIAN_INSTALL/common.conf" 

# GRAPHIC DRIVER
write_package "${graphic_drv[_$DRV_VID]}" "files/de$DEBIAN_INSTALL/common.conf" 
source files/softs-trans
# $DEBIAN_INSTALL
# Kde lang
# if [[ -z $DEBIAN_INSTALL ]]; then
    [[ "$DE" == "plasma" || "$DE" == "kde4" ]] && write_package "$( trans_packages $(set_trans_package "$PACK_KDE_LANG" "$LA_LOCALE") )" files/de$DEBIAN_INSTALL/plasma.conf
    # Firefox lang
    write_package "$PACK_NAV $( [[ ! -z "$PACK_NAV_LANG" ]] && trans_packages $(set_trans_package "$PACK_NAV_LANG" "$LA_LOCALE") )" files/de$DEBIAN_INSTALL/common.conf
# fi

# Additionnal packages noto-fonts-cjk for korean, japanese, chinese
case $( echo "${LA_LOCALE,,}" | sed "s/_.*//" ) in 
    ja|ko|zh) 
        write_package "$LANGAGE_PACK" files/de$DEBIAN_INSTALL/common.conf
#             caution ""
    ;;
esac

# PACSTRAP_OPTIONS=""
for i in $SHOW_COMMANDE; do
	perso "$( echo "${i}" | sed "s/-//")" 
done
[[ -z $USER_SUDO ]] && rid_continue "Utiliser \"sudo\" ?" && USER_SUDO=" -S"
# LAUNCH_COMMAND_ARGS+=("-S") && SHOW_COMMANDE+=(" -$flag")

#     for i in $( grep -h -v ^# files/de$DEBIAN_INSTALL/trans-packages.conf ); do
#         write_package "$i" files/de$DEBIAN_INSTALL/common.conf
#     done

if [[ ! -z "${yaourt_envir[$DE]}" ]]; then
	write_package "${yaourt_envir[$DE]}" files/de$DEBIAN_INSTALL/yaourt.conf
fi

# DEBIAN
if [[ ! -z $DEBIAN_INSTALL ]]; then
#     choose_debvers
    LAUNCH_COMMAND_ARGS=("debian" "$DEBIAN_VERS" ${LAUNCH_COMMAND_ARGS[@]})
fi

if (( $REQUIRE_PACMAN )); then
	notinarch_function 
else
	COMMAND2LAUNCH=("$WORK_DIR/$NAME_SCRIPT2CALL" "${LAUNCH_COMMAND_ARGS[@]}" "$USER_SUDO" "$RACINE" "$OTHER_PACKAGES")
	search_pkg $OTHER_PACKAGES
    
    rid_exit "$_continue"
    msg_n "32" "$_go_on"
fi

LAUNCH_COMMAND=("$DIR_SCRIPTS/$NAME_SCRIPT" "${LAUNCH_COMMAND_ARGS[@]}" "$USER_SUDO" "${SHOW_COMMANDE[@]}" "$RACINE" "$OTHER_PACKAGES")

echo "#!/bin/bash

#CONFIG
ARCH=$ARCH
RACINE=$RACINE
GRUB_INSTALL=$GRUB_INSTALL
DRV_VID=$DRV_VID
DE=$DE
DM=${envir[syst_$DE]}
CONF_NET=$CONF_NET
WIFI_NETWORK=$WIFI_NETWORK
NAME_MACHINE=$NAME_MACHINE
USER_NAME=$USER_NAME
CACHE_PAQUET=$CACHE_PAQUET

# X11_KEYMAP
LA_LOCALE=$LA_LOCALE
CONSOLEKEYMAP=$CONSOLEKEYMAP
TIMEZONE=$TIMEZONE
X11_KEYMAP=$X11_KEYMAP

PACSTRAP_OPTIONS=\"$PACSTRAP_OPTIONS\"
SHOW_COMMANDE=\"$SHOW_COMMANDE $USER_SUDO\"
OTHER_PACKAGES=\"$OTHER_PACKAGES\"
" > $FILE2SOURCE$NAME_MACHINE-$LA_LOCALE.conf

echo -en "$SYSTD_TOENABLE" >> files/systemd.conf

# END GRAPHIC DRIVERSOFTS LANG and SYSTEMD SERVICE TO ENABLE
	
echo ${LAUNCH_COMMAND[*]} >> /tmp/history

# caution "${LA}"
# die "${COMMAND2LAUNCH[*]}"
# exit
run_or_su "${COMMAND2LAUNCH[*]}"
FIN=$?
# msg_n "$FIN"
# "
# Fin is set in linux-part.sh
[[ ! -z $PID_COM ]] && FIN=$PID_COM

case $FIN in
	0) 
		if (( ! $NO_EXEC )); then
			msg_n "32" "32" "$_install_ok" "${LAUNCH_COMMAND[*]}"
			mkdir -p /tmp/$NAME_MACHINE/files/{de,bgs,lang}
	# 		cp $RACINE/post_install-$NAME_MACHINE.sh /tmp/$NAME_MACHINE/
			cp $NAME_SCRIPT2CALL /tmp/$NAME_MACHINE/
			cp $DIR_SCRIPTS/$NAME_SCRIPT /tmp/$NAME_MACHINE/
			cp $FILE2SOURCE$NAME_MACHINE-$LA_LOCALE.conf /tmp/$NAME_MACHINE/
			cp files/de$DEBIAN_INSTALL/{common.conf,$DE.conf} /tmp/$NAME_MACHINE/files/de$DEBIAN_INSTALL/
			cp -R files/{src/futil,extras/genGrub.sh,custom*,systemd.conf,extras/ipxe*,pacman.conf.$ARCH} /tmp/$NAME_MACHINE/files/
			
			IMG_BG=$(find "$RACINE/boot/" -maxdepth 1 -type f -name bg.* | shuf | head -n 1 )
			EXT_BG_NAME=$( echo "$IMG_BG" | sed "s/.*\.//")
			[[ -e "$IMG_BG" ]] && cp $RACINE/boot/bg.$EXT_BG_NAME /tmp/$NAME_MACHINE/files/bgs/grub.$EXT_BG_NAME
			
			if [[ -e $RACINE/usr/share/pixmaps/ ]]; then
				IMG_BG=$(find "$RACINE/usr/share/pixmaps/" -maxdepth 1 -type f -name bg.* | shuf | head -n 1 )
				EXT_BG_NAME=$( echo "$IMG_BG" | sed "s/.*\.//")
				[[ -e "$IMG_BG" ]] && cp "$RACINE/usr/share/pixmaps/bg.$EXT_BG_NAME" /tmp/$NAME_MACHINE/files/bgs/lightdm.$EXT_BG_NAME
			fi
			rid_yes_no "$_delete_tmp" && rm -R $WORK_DIR
		else
			msg_n "32" "32" "Vous pourrez trouver les commandes à éxecuter dans le fichier \"%s\".\n%sVoici la commande globale :\n%s"  "$FILE_COMMANDS" "==> " "${LAUNCH_COMMAND[*]}"
		fi
	;;
		
	1) error "$_install_error$_relaunch" "${LAUNCH_COMMAND[*]}" ;;
	2) msg_n "$_relaunch" "${LAUNCH_COMMAND[*]}";;
esac

[[ ! -z $QUIET ]] && _choix_finish+=("$_show_logs")
show_a2d="$( rid_menu -q "Que voulez vous faire ?" "${_choix_finish[@]}")"
termine
exit 0
