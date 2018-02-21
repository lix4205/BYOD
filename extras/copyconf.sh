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

copy_conf() {
	local dir="$1" && shift;
# 	[[ ! -e $DIR_TARGET/$dir ]] && su - $NAME_USER -c "mkdir -p $DIR_TARGET/$dir"
	[[ ! -e $DIR_TARGET/$dir ]] && mkdir -p "$DIR_TARGET/$dir"  
# 	&& msg_n "Dossier %s créé !" "$dir"
	for fconf in ${@}; do
# 		su - $NAME_USER -c "cp -R \"$DIR_SOURCE/$dir/$fconf\" \"$DIR_TARGET/$dir\""
        cp -R "$DIR_SOURCE/$dir/$fconf" "$DIR_TARGET/$dir"

# 		[[ -e $DIR_SOURCE/$dir/$fconf ]] && su - $NAME_USER -c "cp -R \"$DIR_SOURCE/$dir/$fconf\" \"$DIR_TARGET/$dir\"" || caution "'%s' n'existe pas !" "$DIR_SOURCE/$dir/$fconf"

	done
}

DIR_SCRIPTS=$( dirname $0 ) && [[ "$DIR_SCRIPTS" == "." ]] && DIR_SCRIPTS=$( pwd )
source $DIR_SCRIPTS/src/futil




# declare -A

#
#	PLASMA Config/local
# TODO "session" is necessary ?
conf_plasma=("autostart-scripts" "baloofilerc" "dconf" "gtkrc" "gtkrc-2.0" "kconf_updaterc" "kdebugrc" "kded_device_automounterrc" "kdeglobals" "kglobalshortcutsrc" "khotkeysrc" "konsolerc" "kscreenlockerrc" "ksplashrc" "ktimezonedrc" "kwinrc" "plasma-localerc" "plasma-org.kde.plasma.desktop-appletsrc" "plasmashellrc" "plasmarc" "powerdevilrc" "powermanagementprofilesrc" "startupconfig" "startupconfigfiles" "startupconfigkeys" "dolphinrc" "katerc" "kateschemarc" "katesyntaxhighlightingrc" "user-dirs.dirs")
local_plasma=("konsole" "kxmlgui5" "user-places.xbel")
autostart_plasma=("org.kde.yakuake.desktop")
#
#	Gnome
#
conf_gnome=("dconf" "tilda")
#
#	Gnome
#
conf_cinnamon=("dconf" "tilda")
#
#	XFCE
#
conf_xfce=("xfce4" "tilda")
#
#	MATE
#
conf_mate=("dconf" "caja" "tilda" )
autostart_mate=("tilda.desktop")
#
#	LXDE
#
conf_lxde=("libfm" "lxpanel" "lxsession" "lxterminal" "openbox" "pcmanfm" )
#
#	LXQT
#
conf_lxqt=("gconf" "lxqt" "qterminal.org" "pcmanfm-qt" )
autostart_lxqt=("BgSlideShow.desktop" "Qterminal.desktop")
#
#	FluxBox
#
gen_fluxbox=(".fluxbox")
#
#	Enlightenment
#
gen_e=(".e")
# config : .config
# local : .local/share
# autostart : .config/autostart

declare -A conf_all=(
	[config_plasma]="${conf_plasma[@]}"
	[local_plasma]="${local_plasma[@]}"
	[autostart_plasma]="${autostart_plasma[@]}"
	
	[config_gnome]="${conf_gnome[@]}"
	[autostart_gnome]="${autostart_mate[@]}"
	
	[config_cinnamon]="${conf_cinnamon[@]}"
	[autostart_cinnamon]="${autostart_mate[@]}"
	
	[config_xfce]="${conf_xfce[@]}"
	[autostart_xfce]="${autostart_mate[@]}"
	
	[config_mate]="${conf_mate[@]}"
	[autostart_mate]="${autostart_mate[@]}"
	
	[config_lxde]="${conf_lxde[@]}"
	
	[config_lxqt]="${conf_lxqt[@]}"
	[autostart_lxqt]="${autostart_lxqt[@]}"
	
	[gen_fluxbox]="${gen_fluxbox[@]}"
	[gen_enlightenment]="${gen_e[@]}"
)

[[ -e "$1" ]] && DIR_SOURCE="$1" && shift
[[ -e "$1" ]] && DIR_TARGET="$1" && shift
(( $# )) || die "Aucun parametre passé !"
NAME_USER="$1"
DE="$2"
[[ -z $DIR_TARGET ]] && DIR_TARGET="/home/$NAME_USER"
[[ -z $DIR_SOURCE ]] && DIR_SOURCE=$DIR_SCRIPTS/../users/$NAME_USER

# echo $NAME_USER
# echo $DE
# echo $DIR_SOURCE
# echo $DIR_TARGET
# exit
# msg_n "${conf_all[config_$DE]}"
[[ ! -z ${conf_all[config_$DE]} ]] && copy_conf ".config" "${conf_all[config_$DE]}"
[[ ! -z ${conf_all[local_$DE]} ]] && copy_conf ".local/share" "${conf_all[local_$DE]}"
[[ ! -z ${conf_all[autostart_$DE]} ]] && copy_conf ".config/autostart" "${conf_all[autostart_$DE]}"
[[ ! -z ${conf_all[gen_$DE]} ]] && copy_conf "" "${conf_all[gen_$DE]}" 
# command -v copy_$DE >> /dev/null && copy_$DE || die "%s inconnu !" "$DE"

exit 0

case $DE in
	plasma)
		su $NAME_USER -c "mkdir -p /home/$NAME_USER/.local/share
		cp -R $DIR_USR_CONF/.$NAME_USER/.config/{autostart-scripts,baloofilerc,dconf,gtkrc,gtkrc-2.0,kconf_updaterc,kdebugrc,kded_device_automounterrc,kdeglobals,kglobalshortcutsrc,khotkeysrc,konsolerc,kscreenlockerrc,ksplashrc,ktimezonedrc,kwinrc,plasma-localerc,plasma-org.kde.plasma.desktop-appletsrc,plasmashellrc,plasmarc,powerdevilrc,powermanagementprofilesrc,session,startupconfig,startupconfigfiles,startupconfigkeys,dolphinrc,katerc,kateschemarc,katesyntaxhighlightingrc,user-dirs.dirs} /home/$NAME_USER/.config/
		cp -R $DIR_USR_CONF/.$NAME_USER/.local/share/{konsole,kxmlgui5,user-places.xbel} /home/$NAME_USER/.local/share/
		"
# 			$pacman -S --noconfirm kdeconnect
	;;
	xfce)
		su $NAME_USER -c "cp -R $DIR_USR_CONF/.$NAME_USER/.config/xfce4/ /home/$NAME_USER/.config/"
	;;
	mate)
		su $NAME_USER -c "cp -R $DIR_USR_CONF/.$NAME_USER/.config/{dconf,caja} /home/$NAME_USER/.config/"
# 			su $NAME_USER -c "yaourt --arch $ARCH_PACKAGES -Sy mate-menu"
	;;
	lxde)
		su $NAME_USER -c "cp -R $DIR_USR_CONF/.$NAME_USER/.config/{libfm,lxpanel,lxsession,lxterminal,openbox,pcmanfm} /home/$NAME_USER/.config/"
	;;
	lxqt)
		su $NAME_USER -c "cp -R $DIR_USR_CONF/.$NAME_USER/.config/{gconf,lxqt,qterminal.org,pcmanfm-qt,autostart} /home/$NAME_USER/.config/"
		
	;;
	fluxbox)
		su $NAME_USER -c "cp -R $DIR_USR_CONF/.$NAME_USER/.fluxbox /home/$NAME_USER/
		fluxbox-generate_menu"
		
		
	;;
esac
