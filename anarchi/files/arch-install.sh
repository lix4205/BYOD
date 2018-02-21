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

set_sudo() {
	show_msg msg_n "32" "32" "$_init_sudo" "sudo"
	exe ">" $RACINE/etc/sudoers.d/$1 echo "$1 $sudo_entry" 
# 	arch_chroot "gpasswd -a $1 sudo" 
	arch_chroot "passwd -l root" 
}

# BEGIN CONFIGURATION FONCTIONS
conf_net () {
	NETERFACE=$1
	[[ "$NETERFACE" == "nfsroot" ]] && CONF_NET="mkinitcpio-nfs-utils" || CONF_NET=""
	[[ $WIFI_NETWORK =~ "wpa" || $WIFI_NETWORK =~ "netctl" ]] && CONF_NET="wpa_supplicant" 
}

desktop_environnement () {
	DE=$1
	[[ -z "$GRUB_INSTALL" ]] && GRUB_PACKAGES=""
# 	[[ "$DRV_VID" != "0" ]] && ADD_PACKAGES=""
	SOFTLIST="$BASE_PACKAGES $GRUB_PACKAGES"
	SYSTD="$( recup_files files/systemd.conf )"
# NOTE Voir aussi desktop_environnement() dans linux-part.sh
	LIST_SOFT="$SYNAPTICS_DRIVER $CONF_NET $( (( ! EXEC_DIRECT )) && [[ -e files/de/$DE.conf ]] && recup_files files/de/$DE.conf && printf " "; recup_files files/de/common.conf )"
# 	(( ! FROM_FILE )) && LIST_SOFT="$LIST_SOFT"
	LIST_YAOURT="$( recup_files files/de/yaourt.conf )"
}

anarchi_create_root() {
	show_msg msg_n "33" "32" "$_creating_root" "$RACINE"
	exe mkdir -m 0755 -p "$RACINE"/var/{cache/pacman/pkg,lib/pacman,log} "$RACINE"/{dev,run,etc}
	exe mkdir -m 1777 -p "$RACINE"/tmp 
	exe mkdir -m 0555 -p "$RACINE"/{sys,proc} 
}
# Install base system
anarchi_base() {
	show_msg msg_n "33" "32" "$_pacman_install" "$RACINE"
	if ! exe $QUIET pacman -r "$RACINE" --config=$( [[ ! -z "$pacman_config" ]] && echo $pacman_config || echo $PATH_SOFTS/pacman.conf.$ARCH ) -Sy ; then
		die "$_pacman_fail" "$RACINE"
	fi

	if ! exe $QUIET pacman -r "$RACINE" -S --needed ${pacman_args[@]}; then
		die "$_pacman_fail" "$RACINE"
	fi
	if (( copykeyring )); then
	# if there's a keyring on the host, copy it into the new root, unless it exists already
		if [[ -d /etc/pacman.d/gnupg && ! -d $RACINE/etc/pacman.d/gnupg ]]; then
			exe cp -a /etc/pacman.d/gnupg "$RACINE/etc/pacman.d/"
		fi
	fi

	if (( copymirrorlist )); then
	# install the host's mirrorlist onto the new root
		exe cp -a /etc/pacman.d/mirrorlist "$RACINE/etc/pacman.d/"
	fi
	show_msg msg_n "32" "$_mi_install"
}
set_lang_chroot () {
	arch_chroot "$1" "sed -i s/\#$LA_LOCALE/$LA_LOCALE/g /etc/locale.gen"
	$exe ">" $1/etc/vconsole.conf echo "KEYMAP=\"$CONSOLEKEYMAP\"" 
	$exe ">" $1/etc/locale.conf echo "LANG=\"$LA_LOCALE\"" 
	arch_chroot "$1" "locale-gen"
# 	On force le TIMEZONE
	arch_chroot "$1" "ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime"
}


anarchi_conf() {
# echo $NAME_MACHINE > $RACINE/etc/hostname
	exe ">" $RACINE/etc/hostname echo $NAME_MACHINE 
	hosts_entry="${hosts_entry//%s/$NAME_MACHINE}"
# 	exe echo -e "$hosts_entry" > $RACINE/etc/hosts
	exe ">" $RACINE/etc/hosts echo -e "$hosts_entry" 
# echo -e "$hosts_entry" > $RACINE/etc/hosts
	
	[[ "${RACINE:${#RACINE}-1}" == "/" ]] && RACINE="${RACINE:0:${#RACINE}-1}"
	if [[ "$NETERFACE" != "nfsroot" ]]; then
# genfstab -U $RACINE >> $RACINE/etc/fstab
		exe ">>" $RACINE/etc/fstab genfstab -U $RACINE 
	fi
	set_lang_chroot "$RACINE"
	return 0
}

anarchi_passwd() {
	show_msg msg_n2 "33" "32" "$_pass_msg" "$USER_NAME" 
	if arch_chroot "useradd -m -g users -G wheel -s /bin/bash $USER_NAME"; then
        [[ "$pass_root" == "sudo" ]] && set_sudo "$USER_NAME" || set_pass_chroot "root" "$pass_root" 
        set_pass_chroot "$USER_NAME" "$pass_user" 
    else
        show_msg caution "$_pass_unchanged" "$USER_NAME"
    fi
}

anarchi_pacman_conf() {
	# Write AUR config in pacman.conf
	[[ "$ARCH" == "x64" ]] && exe ">>" $RACINE/etc/pacman.conf echo -e "$pacman_multilib" 
# 	[[ "$ARCH" == "x64" ]] && exe echo -e "$pacman_multilib" >> $RACINE/etc/pacman.conf
	exe ">>" $RACINE/etc/pacman.conf echo -e "$pacman_yaourt" 
# 	exe echo -e "$pacman_yaourt" >> $RACINE/etc/pacman.conf
    return 0
}

anarchi_packages() {
	show_msg msg "$_yaourt_install" "$yaourt_args"
	show_msg decompte 9 "$_mi_install2" "$_go_on %s"

# 	Install others packages 
	if (( ! EXEC_DIRECT )); then
		sed -i "s/^[[:space:]]*SigLevel[[:space:]]*=.*$/SigLevel = Never/" "$PATH_SOFTS/pacman.conf.$ARCH"
		# Si pacman a flingué notre liste de mirroirs alors on la rafrachie !
		[[ -e $RACINE/etc/pacman.d/mirrorlist.pacorig ]] && sed -i "s/^#Server/Server/g" $RACINE/etc/pacman.d/mirrorlist
	fi
	
#	Install packages 
	! exe $QUIET pacman -r "$RACINE" -Sy --needed ${yaourt_args[@]} && die "$_pacman_fail" "$RACINE"

# 	[[ -e /tmp/00-keyboard.conf ]] && exe mkdir -p $RACINE/etc/X11/xorg.conf.d/ && exe cp /tmp/00-keyboard.conf $RACINE/etc/X11/xorg.conf.d/00-keyboard.conf 
	[[ -e /tmp/00-keyboard.conf ]] && exe cp /tmp/00-keyboard.conf $RACINE/etc/X11/xorg.conf.d/00-keyboard.conf 

}

anarchi_nfsroot() {
    show_msg msg_n2 "$_recompile_nfs" 
    arch_chroot "bash /tmp/files/nfs_root.sh"
}
# END CONFIGURATION FONCTIONS

# Used by run_once
hostcache=0
copykeyring=1
copymirrorlist=1

# CONSOLEKEYMAP="fr"
# LA_LOCALE="fr_FR.UTF-8"

DEFAULT_CACHE_PKG="/var/cache/pacman/pkg"
# NAME_SCRIPT="pacinstall.sh"
# FILES2SOURCE="files/src/doexec files/src/chroot_common.sh files/src/futil files/src/bash-utils.sh files/drv_vid"

pacman_multilib="\n#Multilib configuration\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" 
pacman_yaourt="\n#AUR configuration\n[archlinuxfr]\nServer = http://repo.archlinux.fr/\$arch\nSigLevel = Never" 

sudo_entry="      ALL=(ALL) ALL"
# from ARCHitect + header
interactive_modes=("Installer les paquets de base" "Installer les paquets complémentaires" "Effectuer les opérations post installations (1) ( LANG, fstab, hostname, users/pass )" "Activer les services" "Installer grub sur le disque %s" "Executer les scripts de personnalisation" "Garder la main sur pacman" )

# -x option initialise EXEC_DIRECT to 1 if we install ArchLinux from another distribution
# Arch Linux bootstrap image doesn't have sed or grep installed so we use them at the end of linux_parts.sh....
# EXEC_DIRECT=0
[[ "$1" == "-x" ]] && cd $PATH_WORK && EXEC_DIRECT=1 && shift

if (( ! EXEC_DIRECT )); then
	PATH_SOFTS="$PATH_WORK/files"
fi

