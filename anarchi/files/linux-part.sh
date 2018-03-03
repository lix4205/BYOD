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

# BEGIN For locale_gen_chroot from ArchLinux /bin/locale-gen
is_entry_ok() {
	if [ -n "$locale" -a -n "$charset" ] ; then
		true
	else
		echo "error: Bad entry '$locale $charset'"
		false
	fi
}

locale_gen_chroot() {
	rm -rf $1/usr/lib/locale/* || true
	input=`echo $LA_LOCALE | sed 's/\([^.]*\)[^@]*\(.*\)/\1\2/'`;
	charset=${LA_LOCALE//*./};
#     input=${LA_LOCALE//}
    arch_chroot "$1" "localedef -i $input -c -f $charset -A /usr/share/locale/locale.alias $LA_LOCALE;" 
    return $?
# 	[[ -z "$1" ]] && die "Aucun répertoire défini !" 
# 	set -e
# 
# 	LOCALEGEN="$1/etc/locale.gen"
# 	LOCALES="$1/usr/share/i18n/locales"
# 	if [ -n "$POSIXLY_CORRECT" ]; then
# 		unset POSIXLY_CORRECT
# 	fi
# 
# 	[ -f $LOCALEGEN -a -s $LOCALEGEN ] || exit 0;
# 
# 	# Remove all old locale dir and locale-archive before generating new
# 	# locale data.
# 	rm -rf $1/usr/lib/locale/* || true
# 
# 	umask 022
# 
# 
# 	echo "Generating locales..."
# 	while read locale charset; do \
# 		case $locale in \#*) continue;; "") continue;; 
# 		esac; \
# 		is_entry_ok || continue
# 		echo -n "  `echo $locale | sed 's/\([^.\@]*\).*/\1/'`"; \
# 		echo -n ".$charset"; \
# 		echo -n `echo $locale | sed 's/\([^\@]*\)\(\@.*\)*/\2/'`; \
# 		echo -n '...'; \
# 		if [ -f $LOCALES/$locale ]; then input=$locale; else \
# 		input=`echo $locale | sed 's/\([^.]*\)[^@]*\(.*\)/\1\2/'`; fi; \
# 		arch_chroot "$1" "localedef -i $input -c -f $charset -A /usr/share/locale/locale.alias $locale;" 
# 		echo ' done'; \
# 	done < $LOCALEGEN
# 	echo "Generation complete."

}
# END

# See chroot_common.sh
chroot_setup() {
	CHROOT_ACTIVE_MOUNTS=()
#	TMP_ROOT=Arch Boostrap
	TMP_ROOT=$1
#	NEW_ROOT=$RACINE
	NEW_ROOT=$2
	
	[[ "${NEW_ROOT:${#NEW_ROOT}-1}" == "/"  ]] && NEW_ROOT="${NEW_ROOT:0:${#NEW_ROOT}-1}"
	mount_setup "$@"

	[[ "$CACHE_PAQUET" != ""  ]] && chroot_add_mount "$CACHE_PAQUET" "$1$DEFAULT_CACHE_PKG" -t none -o bind
	chroot_maybe_add_mount "! mountpoint -q '$TMP_ROOT$ROOT_DIR_BOOTSTRAP'" "$NEW_ROOT" "$TMP_ROOT$ROOT_DIR_BOOTSTRAP" -t none -o bind &&
	chroot_setup_others
    [[ -d /tmp/done ]] && ls /tmp/done | grep -q anarchi_* && cp -R /tmp/done $TMPROOT/tmp/
	# On copie les fichiers 
	[[ -e $NAME_SCRIPT2CALL ]] && [[ ! -e "$1$WORK_DIR" ]] && mkdir -p $1$WORK_DIR 
	[[ -e $NAME_SCRIPT2CALL ]] && cp -R {$NAME_SCRIPT2CALL,files} $1$WORK_DIR/ 
}
# BEGIN On recupere le contenu des fichiers de paquets files/de/*
recup_files () {
	local TMP=""
	for i in $( cat $1 | grep -v "#" ); do TMP+="$i "; done
	echo $TMP
}

desktop_environnement () {
	DE=$1
	SYSTD="$( recup_files files/systemd.conf )"

	LIST_SOFT="$( [[ -e files/de/$DE.conf  ]] && recup_files files/de/$DE.conf && printf " " && recup_files files/de/common.conf )"
	LIST_YAOURT="$( recup_files files/de/yaourt.conf )"

	echo $SYSTD > $TMPROOT$WORK_DIR/files/systemd.conf
	echo $LIST_SOFT > $TMPROOT$WORK_DIR/files/de/common.conf
	echo $LIST_YAOURT > $TMPROOT$WORK_DIR/files/de/yaourt.conf
}
# END

# BEGIN fstab
# bind mounts do not have a UUID! ( genfstab... )
anarchi_uuid_fstab() {
	str="/"
	replace="\/"
	findmnt -Recvruno SOURCE,TARGET "$1" |
	while read -r src target fstype; do
		blkid | grep $src |
		while read -r disk ; do
			UUID="$( echo "$disk" | sed "s/.* UUID=\"/UUID=/" | sed "s/\".*//" )"
			exe sed -i "s/${src//$str/$replace}.*\//$UUID\t\//" $1/etc/fstab
		done
		# handle swaps devices
		{
		# ignore header
			read

			while read -r device type _ _ prio; do				
				UUID="$( blkid | grep "$device" | sed "s/.* UUID=\"/UUID=/" | sed "s/\".*//" )"
				exe sed -i "s/${device//$str/$replace}.*none/$UUID\tnone/" $1/etc/fstab
			done
		} </proc/swaps
	done
}
# END

# BEGIN load translations
load_language() {
	local file_2_load

	LA_LOCALE="$1"
	[[ "${LA_LOCALE:${#LA_LOCALE}-5}" != "UTF-8"  ]] && LA_LOCALE+=".UTF-8" 
	
	file_2_load="files/lang/${LA_LOCALE:0:${#LA_LOCALE}-6}.trans"
	if [[ -e $file_2_load  ]]; then 
		source "$file_2_load" 
		return 0
	else
		file_2_load="files/lang/${LANG:0:${#LANG}-6}.trans"
		if  [[ -e $file_2_load  ]]; then 
			source $file_2_load 
			locale_2_load=${LANG:0:${#LANG}-6}
		else
			source "files/lang/en_GB.trans" 
			locale_2_load="en_GB"
		fi
		(( $( echo "$LA_LOCALE" | grep "_" | wc -l ) )) && msg_n2 "31" "31" "$_no_translation" "${LA_LOCALE:0:${#LA_LOCALE}-6}" "$locale_2_load" && return 0 
		LA_LOCALE="" && return 1 
	fi
}
# END

# BEGIN Override show_pacman_for_lang dans softs-trans
# We need chroot, grep et sed...
# sed et grep ne sont pas installé dans arch Bootstrap...

# We have to load package list before search with pacman
anarchi_pac_sy() {
    loading chroot "$TMPROOT" pacman -Sy
}
# show_pacman_for_lang_chroot() {
# 	# Forme generique "nom_paquet-locale-pays" Ex : firefox-es-mx
#     PACK=$(chroot "$TMPROOT" pacman -Ss "$1-$3-$2" | grep "$1-$3-$2" | sed "s/.*\($1-$3-$2\).*/\1/");
# #     echo "1: $PACK : pacman -Ss $1-$3-$2 | grep $1-$3-$2"
# 	# Pour la forme  "nom_paquet-locale-locale" Ex : firefox-es-es
#     [[ -z $PACK ]] && PACK=$(chroot "$TMPROOT" pacman -Ss "$1-$3-$3" | grep "$1-$3-$3" | sed "s/.*\($1-$3-$3.*\) .*/\1/");
# #     echo "2: $PACK"
# 	# Pour la forme  "nom_paquet-locale" Ex : firefox-es
#     [[ -z $PACK ]] && PACK=$(chroot "$TMPROOT" pacman -Ss "$1-$3" | grep "$1-$3" | sed "s/.*\($1-$3.*\) .*/\1/" | head -n 1);
# 	[[ -z $PACK ]] && return 1;
# #     echo "3: $PACK"
# 	echo "$PACK";
# 	return 0;
# }
# # END

# BEGIN create new PGP keys to avoid install errors
anarchi_gpg_init() {
	msg_n "32" "Initialisation des cles GPG avec \"pacman-key --init\""
	caution "Cette opération peut prendre un certain temps !"
	loading chroot "$TMPROOT" pacman-key --init &
	PID_CHT=$!
	ls -R / >/dev/null 2>&1 &
	PID_LS=$!
    disown
	wait $PID_CHT
	kill $PID_LS >/dev/null 2>&1
	loading chroot "$TMPROOT" pacman-key --populate
	pkill gpg-agent

}

anarchi_pac_Ss() {
    ERR_PKG=
    for i in $OTHER_PACKAGES; do 
        chroot "$TMPROOT" pacman -Ss $i >> /dev/null || ERR_PKG="$ERR_PKG $i "; 
    done;
    [[ ! -z "$ERR_PKG" ]] && die "$_pkg_err\n\t%s" "$ERR_PKG ";
    return 0;
}
# END

# BEGIN main

source "$FILE2SOURCE$3-$4.conf"
source files/src/chroot_common.sh
# Used by run_once
work_dir=/tmp
# Bootstrap path
TMPROOT="$1"
# Real path
OLDROOT="$2"
# On repasse NO_EXEC a zero pour ecrire les commandes...
# NOTE ici pourquoi je fais ca déjà !!!!
# NO_EXEC à 1 va executer les commandes et les inscrires dans $FILE_COMMANDS
# NO_EXEC à 0 inscrires les commandes dans $FILE_COMMANDS
TMP_NO_EXEC=$NO_EXEC
NO_EXEC=0

# Entete du fichiers de commandes /tmp/anarchi_command
echo -e "#\n#\n# Anarchi (From non based Arch ) ($(date "+%Y/%m/%d-%H:%M:%S"))\n#\n#\n" >> $FILE_COMMANDS

declare -A to_mount

is_root "$@" 
# On reset le trap affichant la commande complete...
trap - EXIT
# Prepare le chroot 
chroot_setup "$TMPROOT" "$OLDROOT"  || die "$_failed_prepare_chroot" "$TMPROOT"
# Initialise le langage
$exe sed -i "s/\#$LA_LOCALE/$LA_LOCALE/g" "$TMPROOT/etc/locale.gen"
$exe ">" $TMPROOT/etc/vconsole.conf echo "KEYMAP=\"$CONSOLEKEYMAP\"" 
# msg_n "Chargement de la langue dans l'environnement chroote"
$exe ">" $TMPROOT/etc/locale.conf echo "LANG=\"$LA_LOCALE\"" 
	
run_once locale_gen_chroot "$TMPROOT" >> /dev/null &
# set_lang_chroot "$TMPROOT" 1 >> /dev/null &
# Force la connexion Internet sur la "route" principale
echo "nameserver $( routel | grep default.*[0..9] | awk '{print $2}' )" >> $TMPROOT/etc/resolv.conf
sleep .2
# Initialise les clés PGP
run_once anarchi_gpg_init
# Copie la conf de pacman
cp files/pacman.conf.$ARCH $OLDROOT/pacman.conf.$ARCH
# 
mkdir -m 0755 -p $OLDROOT$DEFAULT_CACHE_PKG
[[ -e $FILE2SOURCE*.conf ]] && cp $FILE2SOURCE*.conf $TMPROOT/tmp/

# Initialise pacman database
run_once anarchi_pac_sy >> /dev/null || exit 1
# Check if packages exist in pacman database
#     df -a | grep $TMPROOT
[[ ! -z "$OTHER_PACKAGES" ]] && run_once anarchi_pac_Ss

# BEGIN Recuperation des paquets de langue 
# inscris dans le fichier /tmp/install/trans_packages
# (pour kde, libreoffice, thunderbird et firefox)
# NOTE La fonction set_trans_package se trouve dans files/soft_trans
if [[ -e /tmp/install/trans_packages ]]; then
    CMD_SEARCH="chroot $TMPROOT $CMD_SEARCH" 
#     CMD_SEARCH_ARGS="search"
    while read -r; do
#         write_package "$(show_pacman_for_lang_chroot $(set_trans_package "$REPLY" "$LA_LOCALE"))" "files/de/common.conf"
        write_package "$(show_pacman_for_lang $(set_trans_package "$REPLY" "$LA_LOCALE"))" "files/de/common.conf"
    done< <( cat "/tmp/install/trans_packages" )
fi
# END

# Création de la liste des paquets à installer
desktop_environnement "$5"

# NOTE WiFi install...
[[ "$WIFI_NETWORK" != "" ]] && conf_net_wifi "$WIFI_NETWORK" && cp /tmp/$NET_CON files/


rid_exit "$_continue"
msg_n "32" "$_go_on"

# Lancement de la commande 'pacinstall' dans l'environnement chrooté
arch_chroot "$TMPROOT" "$COMMAND4ARCH"
PID_COM=$?

# Recuperation des fichiers indiquant qu'une opération à déjà été faite
[[ -d $TMPROOT/tmp/done ]] && ls $TMPROOT/tmp/done | grep -q anarchi_* && cp -R $TMPROOT/tmp/done /tmp/
# Ecrit les commandes executés en chroot dans le fichier /tmp/anarchi_command sur l'hote
[[ -e $TMPROOT/tmp/anarchi_command ]] && cat $TMPROOT/tmp/anarchi_command >> /tmp/anarchi_command
# Si la commande à bien été executée, alors
if [[ $PID_COM -eq 0 ]]; then
# On reinitialise la variable NO_EXEC
	NO_EXEC=$TMP_NO_EXEC
# On réecrit /etc/fstab pour monter les disques avec UUID
	run_once anarchi_uuid_fstab "$RACINE"
	
# 	final_message="$( set_lang_chroot "$RACINE" )\n"
# Genere un fichier de configuration pour grub (hors nfsroot)
	[[ "$NETERFACE" != "nfsroot"  ]] && [[ -z "$GRUB_INSTALL" ]] && bash files/extras/genGrub.sh "$RACINE" "$NAME_MACHINE" > /tmp/grub_$NAME_MACHINE && msg_n "32" "32" "$_grub_created" "\"/tmp/grub_$NAME_MACHINE\""
fi
NO_EXEC=0
# CAUTION gpg-agent can be running while we're unmounting the installation...
pkill gpg-agent >> /dev/null 2>&1

clear_line
# On démonte tout...
chroot_teardown "reset"
# Initialise $FIN avec le resultat de la commande $COMMAND4ARCH
FIN=$PID_COM
# On reaffecte NO_EXEC
NO_EXEC=$TMP_NO_EXEC
# Fin du fichiers de commandes /tmp/anarchi_command
echo -e "#\n#\n# Anarchi Ending (From non based Arch ) ($(date "+%Y/%m/%d-%H:%M:%S"))\n#\n#\n" >> $FILE_COMMANDS

# END
