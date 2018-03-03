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

# See chroot_common.sh
chroot_setup() {
	init_chroot "$RACINE"
	[[ -e $NAME_SCRIPT ]] && [[ ! -e "$1$PATH_WORK" ]] && mkdir -p $1$PATH_WORK 
	[[ -e $NAME_SCRIPT ]] && cp -R files $1$PATH_WORK/
	[[ -L /bin ]] && echo "PATH=\$PATH:/bin:/sbin:/usr/sbin" >> $FILE_COMMANDS && (( ! $NO_EXEC )) && PATH=$PATH:/bin:/sbin:/usr/sbin
#     FUCK YOU DEBIAN !!!
# We can't use nfs server to put cached package 
#     CHROOT_ACTIVE_MOUNTS+=($1$DEFAULT_CACHE_PKG)
# 	if [[ "$CACHE_PAQUET" != "" ]]; then
#         mountpoint -q $1$DEFAULT_CACHE_PKG && CHROOT_ACTIVE_MOUNTS+=($1$DEFAULT_CACHE_PKG) ||chroot_add_mount "$CACHE_PAQUET" "$1$DEFAULT_CACHE_PKG" -t none -o bind || return 0
#     fi
    return 0;
}
set_sudo() {
	show_msg msg_n "32" "32" "$_init_sudo" "sudo"
	exe ">" $RACINE/etc/sudoers.d/$1 echo "$1 $sudo_entry" 
# 	arch_chroot "gpasswd -a $1 sudo" 
	arch_chroot "passwd -l root" 
}

# BEGIN CONFIGURATION FONCTIONS
conf_net () {
	NETERFACE=$1
	[[ "$NETERFACE" == "nfsroot" ]] && CONF_NET="" || CONF_NET=""
	[[ $WIFI_NETWORK =~ "wpa" || $WIFI_NETWORK =~ "netctl" ]] && CONF_NET="wpa_supplicant" 
}

desktop_environnement () {
	DE=$1
# 	[[ -z "$GRUB_INSTALL" ]] && GRUB_PACKAGES=""
# 	[[ "$DRV_VID" != "0" ]] && ADD_PACKAGES=""
	SOFTLIST="$GRUB_PACKAGES"
	SYSTD="$( recup_files files/systemd$DEBIAN_INSTALL.conf )"
# NOTE Voir aussi desktop_environnement() dans linux-part.sh
	LIST_SOFT="$SYNAPTICS_DRIVER $CONF_NET $( (( ! EXEC_DIRECT )) && [[ -e files/de$DEBIAN_INSTALL/$DE.conf ]] && recup_files files/de$DEBIAN_INSTALL/$DE.conf && printf " "; recup_files files/de$DEBIAN_INSTALL/common.conf )"
# 	(( ! FROM_FILE )) && LIST_SOFT="$LIST_SOFT"
	LIST_YAOURT="$( recup_files files/de$DEBIAN_INSTALL/yaourt.conf )"
}

anarchi_create_root() {
	show_msg msg_n "33" "32" "$_creating_root" "$RACINE"
	exe mkdir -m 0755 -p "$RACINE"/var/{cache/pacman/pkg,lib/pacman,log} "$RACINE"/{dev,run,etc}
	exe mkdir -m 1777 -p "$RACINE"/tmp 
	exe mkdir -m 0555 -p "$RACINE"/{sys,proc} 
}
# Install base system
anarchi_base() {

# deboostrap installera ces paquets en plus
    [[ ! -z "$GRUB_INSTALL" ]] && PACKAGES_PLUS+=",$GRUB_PACKAGES" 
    [[ "$pass_root" == "sudo" ]] && PACKAGES_PLUS+=",sudo"
# W: chown to _apt:root of directory /var/cache/apt/archives/partial failed - SetupAPTPartialDirectory (1: Opération non permise)
# W: chmod 0700 of directory /var/cache/apt/archives/partial failed - SetupAPTPartialDirectory (1: Opération non permise)

	if [[ ! -z "$CACHE_PAQUET" ]]; then
        show_msg msg_n "33" "32" "Copying packages from \"%s\" to \"%s\"" "$CACHE_PAQUET" "$RACINE$DEFAULT_CACHE_PKG/"
        exe mkdir -p "$RACINE$DEFAULT_CACHE_PKG" 
        exe cp -n $CACHE_PAQUET/*.deb $RACINE$DEFAULT_CACHE_PKG/
    fi
	show_msg msg_n "33" "32" "$_pacman_install" "$RACINE"
# NOTE We can't use nfs server to put downloaded package
# So we copy packages from specified directory to the default cache
# 	[[ "$CACHE_PAQUET" != "" ]] && exe mkdir -p "$RACINE$DEFAULT_CACHE_PKG" && ! mountpoint -q $RACINE$DEFAULT_CACHE_PKG && exe mount -o bind "$CACHE_PAQUET" $RACINE$DEFAULT_CACHE_PKG && exe mkdir -p "$RACINE$DEFAULT_CACHE_PKG/partial" && caution "Le cache des paquets a ete modifié !" 
# die "%s" "$ARCH $REAL_ARCH"
# die "debootstrap --include=$PACKAGES_PLUS --arch $REAL_ARCH $DEBIAN_VERS $RACINE $DEBIAN_MIRROR"
	if !  exe $QUIET debootstrap --include=$PACKAGES_PLUS --arch ${real_arch[db_$ARCH]} $DEBIAN_VERS $RACINE $DEBIAN_MIRROR; then
# 		[[ "$CACHE_PAQUET" != "" ]] && mountpoint -q $RACINE$DEFAULT_CACHE_PKG && loading "Veuillez patienter...\r" sleep 3 && exe umount $RACINE$DEFAULT_CACHE_PKG
		die "$_pacman_fail" "$RACINE"
	fi
# 	df
# 	[[ "$CACHE_PAQUET" != "" ]] && mountpoint -q $RACINE$DEFAULT_CACHE_PKG && loading "Veuillez patienter...\r" sleep 3 && exe umount $RACINE$DEFAULT_CACHE_PKG
# 	lsof | grep $RACINE$DEFAULT_CACHE_PKG
	show_msg msg_n "32" "$_mi_install"
}
# set_lang_chroot () {
# 	arch_chroot "$1" "sed -i s/\#$LA_LOCALE/$LA_LOCALE/g /etc/locale.gen"
# 	$exe ">" $1/etc/vconsole.conf echo "KEYMAP=\"$CONSOLEKEYMAP\"" 
# 	$exe ">" $1/etc/locale.conf echo "LANG=\"$LA_LOCALE\"" 
# 	arch_chroot "$1" "locale-gen"
# # 	On force le TIMEZONE
# 	arch_chroot "$1" "ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime"
# }
# 

# Create a fstab file
anarchi_set_fstab() {
# 	str="/"
# 	replace="\/"
	echo -e "# /etc/fstab: static file system information.\n#\n# file system    mount point   type    options                  dump pass"
	findmnt -Recvruno SOURCE,TARGET,FSTYPE "$1" |
	while read -r src target fstype; do
		blkid | grep $src |
		while read -r disk ; do
# 			msg_n ""
			UUID="$( echo "$disk" | sed "s/.* UUID=\"/UUID=/" | sed "s/\".*//" )"
# 			sed -i "s/${src//$str/$replace}.*\//$UUID\t\//" $1/etc/fstab
			echo -e "\n# $src in ${target//$RACINE/}/\n$UUID	${target//$RACINE/}/ $fstype	defaults 0 0\n"
		done
		# handle swaps devices
		{
		# ignore header
			read

			while read -r device type _ _ prio; do				
				UUID="$( blkid | grep "$device" | sed "s/.* UUID=\"/UUID=/" | sed "s/\".*//" )"
# 				sed -i "s/${device//$str/$replace}.*none/$UUID\tnone/" $1/etc/fstab
				echo -e "\n# $device swap \n$UUID	none    swap	sw 0 0"
			done
		} </proc/swaps
	done
}

anarchi_conf() {
	exe ">" $RACINE/etc/hostname echo $NAME_MACHINE 

	hosts_entry="${hosts_entry//%s/$NAME_MACHINE}"
# 	msg_n "$hosts_entry"
	exe ">" $RACINE/etc/hosts echo -e "$hosts_entry" 
# 	> $RACINE/etc/hosts
	
	[[ "${RACINE:${#RACINE}-1}" == "/" ]] && RACINE="${RACINE:0:${#RACINE}-1}"
	if [[ "$NETERFACE" != "nfsroot" ]]; then
# 		[[ "$CACHE_PAQUET" != "" ]] && exe umount $RACINE$DEFAULT_CACHE_PKG
# genfstab -U $RACINE >> $RACINE/etc/fstab
# 		exe ">>" $RACINE/etc/fstab genfstab -U $RACINE 
		
	# On update le fstab
	exe  ">" "$RACINE/etc/fstab" echo -e "$(run_once anarchi_set_fstab "$RACINE")"
	fi
	exe sed -i "s/\#.*$LA_LOCALE/$LA_LOCALE/g" $RACINE/etc/locale.gen
# 	arch_chroot "locale-gen" 
	exe rm $RACINE/etc/localtime
	arch_chroot "ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime"

# 	dpkg-reconfigure keyboard-configuration

	arch_chroot "dpkg-reconfigure locales keyboard-configuration"
# 	(( ! EXEC_DIRECT )) && set_lang_chroot "$RACINE"
	return 0
# 	if (( ! EXEC_DIRECT )); then
# # 		exe sed -i "s/\#$LA_LOCALE/$LA_LOCALE/g" $RACINE/etc/locale.gen
# 		set_lang_chroot "$RACINE"
# 	fi
}

anarchi_passwd() {
	show_msg msg_n2 "33" "32" "$_pass_msg" "$USER_NAME" 
	if arch_chroot "useradd -m -g users -s /bin/bash $USER_NAME"; then
        [[ "$pass_root" == "sudo" ]] && set_sudo "$USER_NAME" || set_pass_chroot "root" "$pass_root" 
        set_pass_chroot "$USER_NAME" "$pass_user" 
    else
        show_msg caution "$_pass_unchanged" "$USER_NAME"
    fi
}

anarchi_search_pkg_deb() {
    # BEGIN Recuperation des paquets de langue 
    CMD_SEARCH="chroot $RACINE apt" 
    CMD_SEARCH_ARGS="search"
    
    source files/softs-trans
       
# lit dans le fichier /tmp/install/trans_packages (voir linux-parts)
# (pour kde, libreoffice, thunderbird et firefox)
# NOTE La fonction set_trans_package se trouve dans files/soft_trans
if [[ -e /tmp/install/trans_packages ]]; then
    while read -r; do
        yaourt_args+=( "$(show_pacman_for_lang $(set_trans_package "$REPLY" "$LA_LOCALE"))" )
    done< <( cat "/tmp/install/trans_packages" )
fi
# END

    
# 	die "$yaourt_args"
	for i in ${yaourt_args[*]}; do chroot "$RACINE" apt search $i | grep -q $i  || ERR_PKG="$ERR_PKG $i "; done;
	[[ $ERR_PKG != "" ]] && return 1;
	return 0
}
anarchi_apt_update() {
    arch_chroot "apt update"
    return $?
}
anarchi_pacman_conf() {
	# On remplit /etc/apt/sources.list histoire de pouvoir installer quelques softs
	! cat $RACINE/etc/apt/sources.list | grep -q "deb http://ftp.us.debian.org/debian $DEBIAN_VERS main contrib" && 
	exe ">" "$RACINE/etc/apt/sources.list" echo -e "deb http://ftp.us.debian.org/debian $DEBIAN_VERS main contrib\ndeb-src http://ftp.us.debian.org/debian $DEBIAN_VERS main\ndeb http://security.debian.org/ $DEBIAN_VERS/updates main\ndeb-src http://security.debian.org/ $DEBIAN_VERS/updates main" 
	
	run_once anarchi_apt_update || die "Erreur lors de la récupération des mises à jour !"
	
	(( ! $NO_EXEC )) && ! anarchi_search_pkg_deb  >> /dev/null 2>&1 && die "$_pkg_err\n\t%s" "$ERR_PKG "
	
	return 0
}
anarchi_dl_packages() {
    arch_chroot "apt -d -y --no-install-recommends install ${yaourt_args[@]} $KERNEL" || die "$_pacman_fail" "$RACINE"; 
	[[ ! -z "$CACHE_PAQUET" ]] && exe cp -n $RACINE$DEFAULT_CACHE_PKG/*.deb $CACHE_PAQUET/ &
	return 0;
}

anarchi_packages() {
# 	run_once anarchi_update
	show_msg msg "$_yaourt_install" "$yaourt_args"
	show_msg decompte 9 "$_mi_install2" "$_go_on %s"

# 	(( ! $NO_EXEC )) && KERNEL="$( chroot "$RACINE" apt search linux-image-[0-9].*-[0-9]-$REAL_ARCH | grep ^linux-image-[0-9].*-[0-9]-$REAL_ARCH/ | sed "s/\(^.*-$REAL_ARCH\)\/.*/\1/g" | head -n 1 )" || KERNEL=linux-image
	(( ! $NO_EXEC )) && KERNEL="$( chroot "$RACINE" apt search linux-image-[0-9].*-[0-9]-$REAL_ARCH | grep ^linux-image-[0-9].*-[0-9]-$REAL_ARCH | sed "s/\(.*\)\/.*/\1/g" | head -n 1 )" || KERNEL=linux-image
# 	bash
	[[ -z $KERNEL ]] && echo "apt search linux-image-[0-9].*-[0-9]-$REAL_ARCH | grep ^linux-image-[0-9].*-[0-9]-$REAL_ARCH | sed \"s/\(.*\)\/.*/\1/g\" | head -n 1" >> $FILE_COMMANDS &&
	die "Aucun noyaux disponible !"
# 	echo -e "apt install ${yaourt_args[@]} $KERNEL" >> $FILE_COMMANDS
	run_once anarchi_dl_packages

# 	(( ! $NO_EXEC )) && { 
	arch_chroot "apt $PACMAN_NOCONFIRM --no-install-recommends install ${yaourt_args[@]} $KERNEL" || die "$_pacman_fail" "$RACINE"; 
# 	}
	[[ -e /tmp/00-keyboard.conf ]] && exe mkdir -p $RACINE/etc/X11/xorg.conf.d/ && exe cp /tmp/00-keyboard.conf $RACINE/etc/X11/xorg.conf.d/00-keyboard.conf 
}

anarchi_nfsroot() { :
#     show_msg msg_n2 "$_recompile_nfs" 
#     arch_chroot "bash /tmp/files/nfs_root.sh"
    sed -i "s/^MODULES=.*/MODULES=netboot/" "$RACINE/etc/initramfs-tools/initramfs.conf"
    for _module in ${LIST_MODULES[@]}; do 
        echo "$_module" >> "$RACINE/etc/initramfs-tools/modules"
    done
    KERNEL_NFS="${KERNEL//linux-image-/}"
#     KERNEL_NFS=${KERNEL_NFS//-$REAL_ARCH/}
    arch_chroot "$RACINE" "mkinitramfs -o /boot/initrd.img-$KERNEL_NFS $KERNEL_NFS"
}

install_grub() {
	show_msg msg_n "Installation de grub sur le disque \"%s\"" "$1"
# 	echo -e "$grub_entries" >> "$RACINE/etc/grub.d/40_custom"
	arch_chroot "grub-install --recheck $1"
	arch_chroot "update-grub"
}
# END CONFIGURATION FONCTIONS

# CONSOLEKEYMAP="fr"
# LA_LOCALE="fr_FR.UTF-8"

declare -A real_arch=( 
	[x64]="amd64" 
	[i386]="686" 
	# uname -m on ArchLinux
	[db_x64]="amd64" 
	[db_i386]="i386" 
)
	

DEFAULT_CACHE_PKG="/var/cache/apt/archives"
# NAME_SCRIPT="pacinstall.sh"
# FILES2SOURCE="files/src/doexec files/src/chroot_common.sh files/src/futil files/src/bash-utils.sh files/drv_vid"

# from ARCHitect + header
interactive_modes=("Installer les paquets de base" "Installer les paquets complémentaires" "Effectuer les opérations post installations (1) ( LANG, fstab, hostname, users/pass )" "Activer les services" "Installer grub sur le disque %s" "Executer les scripts de personnalisation" "Garder la main sur apt" )

# NETWORK CARDS MODULES for NFS root
LIST_MODULES="nfsv4 atl1c forcedeth 8139too 8139cp r8169 e1000 e1000e broadcom tg3 sky2"

PACMAN_NOCONFIRM="-y"
[[ -z $DEBIAN_VERS ]] && DEBIAN_VERS="testing"
DEBIAN_MIRROR="http://ftp.fr.debian.org/debian"
GRUB_FILES="/usr/sbin/update-grub"
PACKAGES_PLUS="$BASE_PACKAGES"
# ,console-data,kbd"
