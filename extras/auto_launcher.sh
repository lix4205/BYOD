#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published byb
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
# 2018-02-03
#
# BEGIN FUNCTIONS

# On efface les fichiers temporaires et on replace les fichiers la ou ils étaient
delete_tmp () {
[[ -e $IMG_BG.png ]] && exec4user "rm -v $IMG_BG.png"
[[ -e $IMG_BG ]] && exec4user "rm -v $IMG_BG"
[[ -e $IMG_BG.tmp ]] && exec4user "rm -v $IMG_BG.tmp"
# On remet en place les bons fichiers...
[[ -e /etc/sddm.conf ]] && [[ -e /etc/sddm.conf.ok ]] && cp -v /etc/sddm.conf.ok /etc/sddm.conf
[[ -e "/etc/lightdm/lightdm-gtk-greeter.conf.ok" ]] && cp -v /etc/lightdm/lightdm-gtk-greeter.conf.ok /etc/lightdm/lightdm-gtk-greeter.conf
[[ -e "/etc/lightdm/lightdm.conf.ok" ]] && cp -v /etc/lightdm/lightdm.conf.ok /etc/lightdm/lightdm.conf
[[ -e "/etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf.ok" ]] && cp -v /etc/lightdm/lightdm-gtk-greeter.conf.d/99-linuxmint.conf.ok /etc/lightdm/lightdm-gtk-greeter.conf.d/99-linuxmint.conf
[[ -e "/etc/lightdm/lightdm.conf.d/70-linuxmint.conf.ok" ]] && cp -v /etc/lightdm/lightdm.conf.d/70-linuxmint.conf.ok /etc/lightdm/lightdm.conf.d/70-linuxmint.conf
[[ -e "/etc/lightdm/slick-greeter.conf.ok" ]] && cp -v /etc/lightdm/slick-greeter.conf.ok /etc/lightdm/slick-greeter.conf
[[ -e /etc/lxdm/lxdm.conf.ok ]] && cp -v /etc/lxdm/lxdm.conf.ok /etc/lxdm/lxdm.conf
[[ -e /etc/slim.conf.ok ]] && cp -v /etc/slim.conf.ok /etc/slim.conf
[[ -e /etc/nodm.conf.ok ]] && cp -v /etc/nodm.conf.ok /etc/nodm.conf
#  fi
}

# Image aléatoire pour lightdm
img_aleatoire () {
    echo "Recherche d'une nouvelle image pour lightdm dans $DIR_IMGS."
	IMG_AP_HOME=
	IMG_AP_HOME=$( exec4user "source $DIR_SCRIPTS/rdm_img.sh;imgs $PATTERN_DIR $DIR_IMGS" )
	[[ ! -z $IMG_AP_HOME ]] && echo "Nouvelle image: $IMG_AP_HOME" &&
	exec4user "cp -L \"$IMG_AP_HOME\" \"$IMG_BG\"; chmod 755 \"$IMG_BG\"" || echo "Une erreur s'est produite !"
	exec4user "source $DIR_SCRIPTS/rdm_img.sh;imgs Images $PATTERN_DIR"
}

# Image aléatoire pour GRUB
boot_img () {
	BG_NAME="bg.jpg"
	if [[ -e /boot/$BG_NAME ]]; then 
		echo "Changement de l'image de boot"
# 		img_aleatoire
		mv /boot/$BG_NAME /boot/old_$BG_NAME
		IMG_BOOT="$( exec4user "source $DIR_SCRIPTS/rdm_img.sh;imgs jpg $PATTERN_DIR $DIR_IMGS" )"
		exec4user "cp -L \"$IMG_BOOT\" \"/tmp/.$BG_NAME\""
		cp "/tmp/.$BG_NAME" /boot/$BG_NAME 
# 		&& echo  ($IMG_BOOT)
	fi
}

# END

NAME_USER="$1"
[[ -z $NAME_USER ]] && echo "==> ERROR: Aucun utilisateur défini !" && exit 1
DPM="$2"
[[ -z $DPM ]] && echo "==> ERROR: Aucun display manager défini !" && exit 1
DE=$3
[[ -z $DE ]] && echo "==> ERROR: Aucun environnement de bureau défini !" && exit 1
isDM=0
DIR_SCRIPTS="$(dirname $0)"
IMG_BG="/tmp/.$NAME_USER.jpg"
PATTERN_DIR="land"
# NAME_SERVICE="auto-launcher\\@$NAME_USER"
NAME_SERVICE="$NAME_SERVICE"
# Chemin du répertoire principal des images
DIR_IMGS=.	




echo "################"
echo "# $NAME_USER launcher #"
echo "################"
echo "# USER=$NAME_USER"
echo "# DM=$2"
echo "# DE=$3"


source $DIR_SCRIPTS/src/sources_files.sh doexec bash-utils.sh futil 

# # 
if [[ -f "$DIR_SCRIPTS/auto-launcher.d/$NAME_USER" ]]; then 
# On lance un script qui va créer notre utilisateur au besoin et copier une conf au passage...
    source "$DIR_SCRIPTS/auto-launcher.d/$NAME_USER"
fi
# Si l'utilisateur n'existe pas 
if ! id -u $NAME_USER 2>&1 >> /dev/null; then
    die "L'utilisateur \"$NAME_USER\" n'existe pas !"
fi
# # END

[[ $(trap -p EXIT) ]] && die "Un probleme est survenu !"
trap 'delete_tmp' EXIT

[[ ! -e /etc/X11/xorg.conf.d/00-keyboard.conf ]] && localectl set-x11-keymap fr pc105 latin9 terminate:ctrl_alt_bksp

[[ ! -e /etc/systemd/system/$NAME_SERVICE.service ]] && isDM=1 && boot_img &
# Utile??
exec4user "[[ -e /home/$NAME_USER/.dmrc ]] && sed -i 's/Session=.*/Session=default/' /home/$NAME_USER/.dmrc"

case $DE in 
# 	plasma) : ;;
# 	mate) : ;;
	fluxbox) exec4user "fluxbox-generate_menu" ;;
# 	xfce) : ;;
	lxde) exec4user "[[ -e /home/$NAME_USER/.dmrc ]] && sed -i -e 's/Session=.*$/Session=LXDE/' /home/$NAME_USER/.dmrc" ;;
# 	lxqt) : ;;
esac
echo "# Modifications des fichiers de $DPM pour l'utilisateur $NAME_USER avec la session $DE"

# echo "# Modifications des fichiers de $DPM pour l'utilisateur $NAME_USER avec la session $DIR_SCRIPTS"
bash $DIR_SCRIPTS/init_x.sh $NAME_USER $DPM $DE

# On arrete le Display Manager en train de tourner...
systemctl --quiet is-active $DPM && systemctl stop $DPM
case $DPM in 
	sddm)
		echo "Demarrage de $DE avec \"/usr/bin/sddm &\""
		/usr/bin/sddm &
		PID=$!
	;;
	lightdm)
		img_aleatoire
		echo -n "# Demarrage de $DE avec \"/usr/sbin/lightdm >> /dev/null 2>&1 &\""
		# On change l'image de fond de lightdm
		[[ ! -e /etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf ]] && 
		sed -i "s/.*background=.*/background=${IMG_BG//\//\\\/}/" "/etc/lightdm/lightdm-gtk-greeter.conf" || 
		sed -i "s/.*background=.*/background=${IMG_BG//\//\\\/}/" "/etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf"
		
		[[ -e /etc/lightdm/slick-greeter.conf ]] && ! cat /etc/lightdm/slick-greeter.conf | grep "$IMG_BG" && echo "background=$IMG_BG" >> /etc/lightdm/slick-greeter.conf
		/usr/sbin/lightdm >> /dev/null 2>&1 &
		PID=$!
		img_aleatoire
# 		echo ">>>>>> $PID"
	;;
	slim)
		img_aleatoire
		/usr/sbin/slim  >> /dev/null 2>&1 &
		PID=$!
	;;
	lxdm)
		echo "Recherche d'une image pour $DPM"
		img_aleatoire
		sed -i "s/.*bg=.*$/bg=${IMG_BG//\//\\\/}/" "/etc/lxdm/lxdm.conf"
		/usr/sbin/lxdm &
		PID=$!
	;;
	nodm) 
		trap "systemctl start nodm" EXIT
# 		trap "systemctl start nodm;sleep 15 && ! ps uax | grep -v grep | grep -q anim_bg.sh && exec4user \"bash $DIR_SCRIPTS/anim_bg.sh 1 land\"" EXIT
	;;
esac

[[ "$DE" == "lxqt" ]] && exec4user "sleep 10 && export DISPLAY=:0 && xcompmgr -c &"
[[ "$DE" == "fluxbox" ]] && exec4user "sleep 10 && export DISPLAY=:0.0 && xcompmgr -c &"

[[ "$DE" != "lxqt" ]] && [[ "$DE" != "plasma" ]] && [[ "$( ps uax | grep anim_bg.sh | grep -v grep | awk ' { print $2 }' )" ==  "" ]] && exec4user "sleep 10; bash $DIR_SCRIPTS/anim_bg.sh init $DIR_IMGS $PATTERN_DIR &"


# echo "
# Attente $PID!"	
[[ ! -z $PID ]] && wait $PID
# [[ ! -z $PID ]] && echo -n "[ $PID ] "
echo "Terminé !"

exit 0
