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

#
# ANother ARCH Installer
#
#
# Assumptions:
#  1) User has partitioned, formated, and mounted partitions on /mnt
#  2) Network is functional
#  3) Arguments passed to the script are valid pacman targets
#  4) A valid mirror appears in /etc/pacman.d/mirrorlist
#

usage() {
  cat <<EOF
usage: ${0##*/} [options] root [packages...]

  Options:
    -C config      Use an alternate config file for pacman
    -d             Allow installation to a non-mountpoint directory
    -G             Avoid copying the host's pacman keyring to the target
    -i             Avoid auto-confirmation of package selections
    -M             Avoid copying the host's mirrorlist to the target
    -a architecture                       Architecture du processeur (x64/i686)
    -g graphic driver to install          Pilote carte graphique (intel,nvidia{-304,340},radeon)
    -e desktop environnement              Environnement de bureau (plasma,xfce,lxde,gnome,mate,fluxbox,cinnamon)
    -h hostname                           Nom de la machine
    -u username                           Login utilisateur
    -n [ nm, dhcpcd@<< network_interface >> ]       Utilisation de NetworkManager ou dhcpcd (avec l'interface NETWORK_INTERFACE)
    -l /dev/sdX                           Installation de grub sur le péripherique /dev/sdX.
    -c CACHE_PAQUET           		Utilisation des paquets contenu dans le dossier CACHE_PAQUET

    -h             Print this help message

pacinstall installs packages named in files/de/*.conf to the specified new root directory.
Then generate fstab, add the user,create passwords, install grub if specified,
enable systemd services like the display manager
And files/custom.d/<username> is executed as a personal script 

EOF
}
    
# See chroot_common.sh
chroot_setup() {
	init_chroot "$RACINE"
	[[ -e $NAME_SCRIPT ]] && [[ ! -e "$1$PATH_WORK" ]] && mkdir -p $1$PATH_WORK 
	[[ -e $NAME_SCRIPT ]] && cp -R files $1$PATH_WORK/

# 	[[ "$CACHE_PAQUET" != "" ]] && chroot_add_mount "$CACHE_PAQUET" "$1$DEFAULT_CACHE_PKG" -t none -o bind || return 0
}

set_pass_chroot () {
	if [[ ! -z "$2" ]]; then
		(( ! $NO_EXEC )) && lix_chroot $RACINE "echo "$1:$2" | chpasswd"

		# In log...
		echo "chroot "$RACINE" passwd $1" >> $FILE_COMMANDS
	else
		show_msg msg_n2 "31" "$_empty_pass" "$1"
	fi
}

# BEGIN CONFIGURATION FONCTIONS
conf_net () {
	NETERFACE=$1
# 	[[ "$NETERFACE" == "nfsroot" ]] && CONF_NET="mkinitcpio-nfs-utils" || CONF_NET=""
# 	[[ $WIFI_NETWORK =~ "wpa" || $WIFI_NETWORK =~ "netctl" ]] && CONF_NET="wpa_supplicant" 
}

graphic_setting () {
	if (( ! FROM_FILE )); then
		DRV_VID=$1
		if [[ ! -z "$DRV_VID" ]] && [[ ${graphic_drv[$DRV_VID]} ]]; then
			DRV_VID=${graphic_drv[_$DRV_VID]}
		else
			ERROR="\n\t\"-g GRAPHIC_DRIVER\" Invalid option : Graphics settings incorrect !"
		fi
	else
		DRV_VID=
	fi
}

recup_files () {
 	local TMP=""
	if (( ! EXEC_DIRECT )); then
		for i in $( cat $1 | grep -v "#" ); do TMP+="$i "; done
		echo $TMP
	else
		echo -ne $( tail -n 1 $1 )
	fi

}

get_pass () {
	USR=$1
	local color="$2"
	count=2
	pass_user_tmp=$( rid_pass "33" "$color" "$_pass_user1" "$USR"  )
	while [[ "$( rid_pass  "33" "$color" "$_pass_user2"  )" != "$pass_user_tmp" ]]; do
		if [[ $count == 2 ]]; then
			error "$_error_pass" >&2
			count=1
		fi
		pass_user_tmp=$( rid_pass  "33" "$color" "$_pass_user1" "$USR" )
		count=$((count+1))
	done
	echo "$pass_user_tmp"
}

load_language() {
	local file_2_load

	LA_LOCALE="$1"
	[[ "${LA_LOCALE:${#LA_LOCALE}-5}" != "UTF-8" ]] && LA_LOCALE+=".UTF-8" 
	
	file_2_load="files/lang/${LA_LOCALE:0:${#LA_LOCALE}-6}.trans"
	if [[ -e $file_2_load ]]; then 
		source "$file_2_load" 
		return 0
	else
		file_2_load="files/lang/${LANG:0:${#LANG}-6}.trans"
		if  [[ -e $file_2_load ]]; then 
			source $file_2_load 
			locale_2_load=${LANG:0:${#LANG}-6}
		else
			source "files/lang/en_GB.trans" 
			locale_2_load="en_GB"
		fi
		(( EXEC_DIRECT )) && [[ "${1:${#1}-5}" != "UTF-8" ]] && msg_n2 "31" "31" "$_no_translation" "${LA_LOCALE:0:${#LA_LOCALE}-6}" "$locale_2_load" && return 0
		(( $( echo "$LA_LOCALE" | grep "_" | wc -l ) )) && msg_n2 "31" "31" "$_no_translation" "${LA_LOCALE:0:${#LA_LOCALE}-6}" "$locale_2_load" && return 0 
		LA_LOCALE="" && return 1 
	fi
}

anarchi_custom() {
	if (( ! interactive )); then
        arch_chroot "bash /tmp/files/custom" 
    else
        msg "$_chroot_newroot_msg" "$NAME_MACHINE"
        arch_chroot "$RACINE" "/bin/bash"
    fi
}


# anarchi_nfsroot() {
#     show_msg msg_n2 "$_recompile_nfs" 
#     arch_chroot "bash /tmp/files/nfs_root.sh"
# }
anarchi_wifi() {
#	 Creation des connexions WiFi avec wifi-netctl
	TYPE_CON=${WIFI_NETWORK//@*/}
	NET_CON=${WIFI_NETWORK//*@/}
	NAME_CON=${WIFI_NETWORK//$TYPE_CON@/} 
	NAME_CON=${NAME_CON//@$NET_CON/}

	source /tmp/$NET_CON
	show_msg msg_n "Creation de la connexion au point d'acces \"%s\" avec \"%s\"." "$NET_CON" "$TYPE_CON"	
	cp -a $PATH_SOFTS $RACINE/tmp/
	cp /tmp/$NET_CON $RACINE/tmp/
	arch_chroot "bash /tmp/files/extras/wifi-utils.sh $NET_CON $TYPE_CON $NAME_CON /"
	[[ "$TYPE_CON" == "netctl" ]] && arch_chroot "netctl enable $NAME_CON"
	return 1

}

anarchi_systd() {
#	Activation des services systemd
    local _systd res; 
    res=0
	show_msg msg_n2 "32" "32" "systemctl enable %s" "$SYSTD"; 
	for _systd in ${SYSTD[@]}; do
        if ! arch_chroot "systemctl enable $_systd"; then
            error "$_systd_error" "$_systd"; 
            [[ $? -gt 0 ]] && res=1
        fi
    done
    return $res;
}

anarchi_custom_user() {
	show_msg msg_n2 "32" "$_exec_custom"
	arch_chroot "bash /tmp/files/custom user"
}
anarchi_grub() {
	if (( ! $NO_EXEC )) && [[ ! -e $RACINE$GRUB_FILES ]]; then
		show_msg caution "$_grub_notinstalled"
		return 1
	fi
	exe ">>" "$RACINE/etc/grub.d/40_custom" echo -e "$grub_entries" 
	install_grub "$GRUB_INSTALL"
	
}

install_grub() {
	show_msg msg_n "Installation de grub sur le disque \"%s\"" "$1"
# 	echo -e "$grub_entries" >> "$RACINE/etc/grub.d/40_custom"
	arch_chroot "grub-install --recheck $1"
	arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}
# END CONFIGURATION FONCTIONS


# Used by run_once
work_dir=/tmp

ERROR=

ARCH=
GRUB_INSTALL=
SYSTD=
SYNAPTICS_DRIVER=
TIMEZONE="Europe/Paris"
CONSOLEKEYMAP="fr"
LA_LOCALE="fr_FR.UTF-8"
SOFTLIST=
PATH_WORK="$work_dir/install"
PATH_INSTALL="/install.arch$PATH_WORK"
PATH_SOFTS="$PATH_INSTALL/files"
CONF2SOURCE="$work_dir/anarchi-"
# DEFAULT_CACHE_PKG="/var/cache/pacman/pkg"
NAME_SCRIPT="pacinstall.sh"
FILES2SOURCE="files/src/doexec files/src/chroot_common.sh files/src/futil files/src/bash-utils.sh "
FILE_COMMANDS=/tmp/anarchi_command
LOG_EXE="/tmp/anarchi.log"
PACMAN_NOCONFIRM="--noconfirm"
GRUB_FILES="/usr/bin/grub-mkconfig"
# Entries shutdown/restart GRUB
grub_entries="\n\nmenuentry \"System shutdown\" {\n\techo \"System shutting down...\"\n\thalt\n}"
grub_entries+="\n\nmenuentry \"System restart\" {\n\techo \"System rebooting...\"\n\treboot\n}"
sudo_entry="      ALL=(ALL) ALL"
# from ARCHitect + header
hosts_entry="#\n#\n# /etc/hosts: static lookup table for host names\n#\n#<ip-address>\t<hostname.domain.org>\t<hostname>\n127.0.0.1\tlocalhost.localdomain\tlocalhost\t%s\n::1\tlocalhost.localdomain\tlocalhost\t%s"
keyboard_conf="Section \"InputClass\"\n\tIdentifier \"system-keyboard\"\n\tMatchIsKeyboard \"on\"\n\tOption \"XkbLayout\" \"%s\"\nEndSection"
interactive_modes=("Installer les paquets de base" "Installer les paquets complémentaires" "Effectuer les opérations post installations (1) ( LANG, fstab, hostname, users/pass )" "Activer les services" "Installer grub sur le disque %s" "Executer les scripts de personnalisation" "Garder la main sur pacman" )

# BEGIN debootstrap configuration
if [[ "$1" == "debian" ]]; then
    DEBIAN_INSTALL=".debian" 
    DEBIAN_VERS=$2
    shift 2;
    FILES2SOURCE+="files/de$DEBIAN_INSTALL/drv_vid files/de$DEBIAN_INSTALL/drv_vid.$DEBIAN_VERS files/debian-install.sh"
#     source files/debian-install.sh
else
    FILES2SOURCE+="files/de/drv_vid files/arch-install.sh"
#     source files/arch-install.sh
fi
cat <<EOF
# $0 ${*}
#
# LANCEMENT DE L'INSTALLATION $DEBIAN_INSTALL
#
#

${FILES2SOURCE[*]}
EOF
# exit;
# END 
# exit

# Install Packages 
PACK_P=1
# Install Base packages only
BASE_P=1
# Install "Graphic" packages only
GRAP_P=1
# Generate fstab, hostname , hosts, user pass, 
LANG_P=1
# Systemd service, grub and customization
POST_P=1
# Grub
GRUB_P=1
# Services
SERV_P=1
# customization
CUST_P=1
FREE_PACMAN=1

# -x option initialise EXEC_DIRECT to 1 if we install ArchLinux from another distribution
# Arch Linux bootstrap image doesn't have sed or grep installed so we use them at the end of linux_parts.sh....
# EXEC_DIRECT=0
[[ "$1" == "-x" ]] && cd $PATH_WORK && EXEC_DIRECT=1 && shift

# Usefull functions
# pwd
source files/src/sources_files.sh $FILES2SOURCE 

# exit
echo -e "#\n#\n# Anarchi ($(date "+%Y/%m/%d-%H:%M:%S"))\n#\n#\n" >> $FILE_COMMANDS

# Set localisation
load_language "$1" && LA_LOCALE="$1" && shift && [[ "${LA_LOCALE:${#LA_LOCALE}-5}" != "UTF-8" ]] && LA_LOCALE+=".UTF-8" 
if (( ! EXEC_DIRECT )); then
	PATH_SOFTS="$PATH_WORK/files"
fi

if [[ -z $1 || $1 = @(-h|--help) ]]; then
    usage
    exit $(( $# ? 0 : 1 ))
fi

while getopts ':C:c:tdxGiMSqu:l:a:e:n:g:h:z:k:K:D:' flag; do
    case $flag in
        C) pacman_config=$OPTARG ;;
        d) directory=1 ;;
        i) interactive=1 ;;
        G) copykeyring=0 ;;
        M) copymirrorlist=0 ;;
        n) CONF_NET="$OPTARG" ;;
        a) ARCH="$OPTARG" ;;
        g) DRV_VID="$OPTARG" ;;
        e) DE="$OPTARG";;
        D) DM="$OPTARG";;
        K) X11_KEYMAP="$OPTARG" ;;
        k) CONSOLEKEYMAP="$OPTARG" ;;
        z) TIMEZONE="$OPTARG" ;;
        h) NAME_MACHINE="$OPTARG" ;;
        q) QUIET="-q" ;;
        # USELESS
        S) pass_root="sudo" ;;
#         SYNAPTICS_DRIVER="xf86-input-libinput" 
# 			s) SYNAPTICS_DRIVER="xf86-input-synaptics" ;;
        u) USER_NAME="$OPTARG" ;;
# 			t) TEST=1; COLORED_PROMPT=0 ;;
        t) NO_EXEC=1 ;;
# 			x) EXEC_DIRECT=1 ;;
        c) 
            hostcache=1
            [[ -d "$OPTARG" ]] && CACHE_PAQUET=$OPTARG || die "$_not_a_dir" $OPTARG
        ;;
        l)
            GRUB_INSTALL="$OPTARG"
            ! [[ -b "$GRUB_INSTALL" ]] && ERROR+="\n\t\"-l DISK\" : invalid parameter $_grub_unable $GRUB_INSTALL"
        ;;
        :) die "$_argument_option" "${0##*/}" "$OPTARG" ;;
        ?) die "$_invalid_option" "${0##*/}" "$OPTARG" ;;
    esac
done
shift $(( OPTIND - 1 ))
(( $# )) || die "$_nodir"

RACINE=$1; shift
OTHER_PACKAGES="$@"
    
# 	[[ -z "$ARCH" ]] && ERROR+="\n\t\"-a ARCHITECTURE\" Missing option" 
# 	[[ ! -z "$ARCH" && ( "$ARCH" != "x64" && "$ARCH" != "i686" ) ]] && ERROR+="\n\t\"-a ARCHITECTURE\" Invalid parameter : $ARCH" 
[[ -z "$NAME_MACHINE" ]] && ERROR+="\n\t\"-h HOSTNAME\" Missing option" 
[[ -z "$USER_NAME" ]] && ERROR+="\n\t\"-u USERNAME\" Missing option"

if [[ -z "$DRV_VID" ]]; then
	ERROR+="\n\t\"-g VIDEO_DRIVER\" Missing option"
else
	if [[ "$DRV_VID" != "0" ]]; then
		if [[ -e /etc/X11/xorg.conf.d/00-keyboard.conf ]]; then
			cp /etc/X11/xorg.conf.d/00-keyboard.conf /tmp/
		else
# 			echo -e "${keyboard_conf//%s/${X11_KEYMAP}}" > /tmp/00-keyboard.conf
			exe ">" /tmp/00-keyboard.conf echo -e "${keyboard_conf//%s/${X11_KEYMAP}}"
		fi
		graphic_setting "$DRV_VID"
	fi
fi
[[ "$CONF_NET" != "0" ]] && conf_net "$CONF_NET"
desktop_environnement "$DE"
	
[[ ! -z "$ERROR" ]] && die "$_invalid_param :$ERROR"

if (( interactive )); then
# Install Packages 
    PACK_P=1
    # Install Base packages only
    BASE_P=0
    # Install "Graphic" packages only
    GRAP_P=0
    # Generate fstab, hostname , hosts, user pass, 
    LANG_P=0
    # Systemd service, grub and customization
    POST_P=1
    # Grub
    GRUB_P=0
    # Services
    SERV_P=0
    # customization
    CUST_P=0
    FREE_PACMAN=1
    show_imodes="$(rid_menu -q "Indiquez les opérations à effectuer (%s)." "${interactive_modes[@]}")"; 
    msg_nn "$show_imodes"
    while [[ -z "$validmodes" ]]; do
        validmodes=$(rid "\t->");
        [[ "$validmodes" == "q" ]] && exit 2;
        for modes in ${validmodes}; do
            if is_number $modes; then
                case $modes in 
                    1) BASE_P=1 ;; # BASE_PACKAGES
                    2) GRAP_P=1 ;; # Graphic packages
                    3) LANG_P=1 ;; # Post install
                    4) SERV_P=1 ;; # services a activer
                    5) GRUB_P=1 ;; # install grub
                    6) CUST_P=1 ;; # Script perso
                    7) FREE_PACMAN=0 ;; # Garder la main sur pacman...
                    *) validmodes= ;;
            # 		7) 
            # 		8) 	
                esac
            else
                validmodes=
            fi
        done
    done
fi

# BEGIN package manager configuration
pacman_args+=("$SOFTLIST")
yaourt_args+="$PACK_YAOURT $LIST_SOFT $OTHER_PACKAGES"

if [[ -z $DEBIAN_INSTALL ]]; then
    if (( hostcache )); then
    pacman_opt+=(--cachedir="$CACHE_PAQUET")
    fi

    (( $FREE_PACMAN )) && pacman_opt+=($PACMAN_NOCONFIRM)

    if [[ ! -z "$pacman_config" ]]; then
        pacman_opt+=(--config="$pacman_config")
    else
        pacman_opt+=(--config="$PATH_SOFTS/pacman.conf.$ARCH")
    fi
    # END
    pacman_args+=(${pacman_opt[*]})
    yaourt_args+=(${pacman_opt[*]})
else
    (( $FREE_PACMAN )) && PACMAN_NOCONFIRM=""
    REAL_ARCH=${real_arch[$ARCH]}
fi

if (( $LANG_P )) && ! ls /tmp/done/*_passwd >> /dev/null 2>&1; then
	msg_n "$_set_pass_msg"
	[[ -z $pass_root ]] && pass_root="$( get_pass "root" "31" )"
# 	rid_continue "Utiliser \"sudo\" ?" && pass_root="sudo" || pass_root="$( get_pass "root" "31" )"
	pass_user="$( get_pass "$USER_NAME" "32" )"
fi
# BEGIN PAVE D'INFO 

msg_n "32" "$_info_gen"  
cat <<EOF
	$( [[ ! -z "$GRUB_INSTALL" ]] && echo "	$_info_grub \"$GRUB_INSTALL\" " ) 
	"$RACINE" $_info_root" 
	$_info_arch                			$ARCH
	$_info_drv_vid         			$DRV_VID
	$_info_net      			$CONF_NET$NETERFACE
	$_info_de   			$DE
	$_info_hostname         			$NAME_MACHINE
	$_info_user           			$USER_NAME
	
EOF
msg_n "32" "$_info_base"
echo "$SOFTLIST"
msg_n "32" "$_info_complement"
echo "$LIST_SOFT $OTHER_PACKAGES"
msg_n "32" "$_info_systd"
echo "$SYSTD"
[[ ! -z "$LIST_YAOURT" ]] && ( msg_n "32" "$_info_yaourt" ; echo "$LIST_YAOURT" ; )

[[ ! -z "$CACHE_PAQUET" ]] && ( msg_n "32" "$_info_cache" "$CACHE_PAQUET" )
[[ -z "$pass_root" ]] && caution "$_empty_pass" "root"
[[ -z "$pass_user" ]] && caution "31" "32" "$_empty_pass" "$USER_NAME"
rid_exit "$_continue"
msg_n "32" "$_go_on"
# END PAVE

# BEGIN CHROOT SETUP, PACMAN INSTALL & CONFIGURATION
if [[ -z $DEBIAN_INSTALL ]]; then
    run_once anarchi_create_root
    chroot_setup "$RACINE" || die "$_failed_prepare_chroot" "$RACINE" 
    (( ! EXEC_DIRECT )) && exe ">>" $RACINE/etc/resolv.conf echo "nameserver $( routel | grep default.*[0..9] | awk '{print $2}' )" 
fi
# (( ! EXEC_DIRECT )) && exe echo "nameserver $( routel | grep default.*[0..9] | awk '{print $2}' )" >> $RACINE/etc/resolv.conf
# (( ! EXEC_DIRECT )) && chroot_add_resolv_conf "$RACINE"

if (( $PACK_P )); then
	if (( $BASE_P )); then
		# Install base system
		run_once anarchi_base
	fi
fi

if [[ ! -z $DEBIAN_INSTALL ]]; then
    chroot_setup "$RACINE" || die "$_failed_prepare_chroot" "$RACINE" 
#     (( ! EXEC_DIRECT )) && exe ">>" $RACINE/etc/resolv.conf echo "nameserver $( routel | grep default.*[0..9] | awk '{print $2}' )" 
#     chroot "$RACINE"
fi
# On exporte les variables nécessaires à l'execution de custom pour les utiliser en chroot
export NAME_USER=$USER_NAME LIST_SOFT SYSTD_SOFT="$SYSTD" GRUB_DISK=$GRUB_INSTALL NFSROOT=$NETERFACE DE DM X11_KEYMAP ARCH LIST_YAOURT DEBIAN_INSTALL
# Et on copie les fichiers dans /tmp de la nouvelle install pour les executer en chroot		
exe cp -a "$PATH_SOFTS" $RACINE/tmp/

if (( $LANG_P )); then
	run_once anarchi_conf
	(( $CUST_P )) && run_once anarchi_custom
	run_once anarchi_passwd
fi
if (( $PACK_P )); then
	if (( $GRAP_P )); then	
		run_once anarchi_pacman_conf
		run_once anarchi_packages
	fi

fi
# END CHROOT SETUP, PACMAN INSTALL & CONFIGURATION

if (( $POST_P )); then
	show_msg msg_n "32" "32" "%s" "$_finalisation"
	if (( $SERV_P )); then
		if [[ ! -z "$WIFI_NETWORK" ]]; then
			run_once anarchi_wifi
		fi
		[[ ! -z "$SYSTD" ]] && run_once anarchi_systd
	fi
# 	mount the host's resolv.conf in the fresh install 
	chroot_add_resolv_conf "$RACINE"	
	
	if (( $CUST_P )); then
		run_once anarchi_custom_user
	fi
	if [[ "$NETERFACE" == "nfsroot" ]]; then
#         Run NFS post installation configuration
        run_once anarchi_nfsroot
#         Generate a syslinux entry and display it at the end of installation
		final_message="$( bash files/extras/genloader.sh "$NAME_MACHINE" "$ARCH" "$DE" "$RACINE" )"
    else
# 	GRUB
        if (( $GRUB_P )) && [[ ! -z "$GRUB_INSTALL" ]]; then
            run_once anarchi_grub &&
            (( ! NO_EXEC )) && final_message="$_grub_installed $GRUB_INSTALL"
        fi
	fi
	# 	Generate a grub entry and display it at the end of installation
	if (( ! EXEC_DIRECT )) && [[ "$NETERFACE" != "nfsroot" ]] && [[ -z "$GRUB_INSTALL" ]]; then
        bash files/extras/genGrub.sh "$RACINE" "$NAME_MACHINE" > /tmp/grub_$NAME_MACHINE && 
        show_msg msg_n "32" "32" "$_grub_created" "\"/tmp/grub_$NAME_MACHINE\""
    fi
	cat <<EOF
$final_message

EOF
fi
echo -e "#\n#\n# Anarchi Ending ($(date "+%Y/%m/%d-%H:%M:%S"))\n#\n#\n" >> $FILE_COMMANDS
