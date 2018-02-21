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

# BEGIN FUNCTIONS
# BEGIN Automatic login 

# Auto login with lightdm and 10 second timeout by default
auto_lightdm() {
	local _user="$1" _timeout="$2"; 
	[[ -z "$_timeout" ]] && _timeout="10"
	if [[ ! -e /etc/lightdm/lightdm.conf.d/70-linuxmint.conf ]]; then
        sed -i "s/.*autologin-user=.*/autologin-user=$_user/" "/etc/lightdm/lightdm.conf"
        sed -i "s/.*autologin-user-timeout=.*/autologin-user-timeout=$_timeout/" "/etc/lightdm/lightdm.conf"
        
        sed -i "s/.*position=.*/position=75% 75%/" "/etc/lightdm/lightdm-gtk-greeter.conf"
    else
	# On déplace le login en bas a droite...
        echo "autologin-user=$_user" >> /etc/lightdm/lightdm.conf.d/70-linuxmint.conf
        echo "autologin-user-timeout=$_timeout" >> /etc/lightdm/lightdm.conf.d/70-linuxmint.conf
        
        echo "position=75% 75%" >> /etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf
        sed -i "s/.*autologin-user=.*/autologin-user=$_user/" "/etc/lightdm/lightdm.conf.d/70-linuxmint.conf"
        sed -i "s/.*autologin-user-timeout=.*/autologin-user-timeout=$_timeout/" "/etc/lightdm/lightdm.conf.d/70-linuxmint.conf"
        sed -i "s/.*position=.*/position=75% 75%/" "/etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf"
    fi
# 	[[ ! -e /etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf ]] && sed -i "s/.*position=.*/position=75% 75%/" "/etc/lightdm/lightdm-gtk-greeter.conf" && sed -i "s/.*position=.*/position=75% 75%/" "/etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf" 
}

auto_sddm() {
	local _user="$1" _desktop="$2"; 
	[[ "$_desktop" == "lxde" ]] && _desktop="${_desktop^^}"
	sed -i.backup -e "s/^Session=/Session=$_desktop.desktop #/" /etc/sddm.conf
	sed -i.backup -e "s/^User=/User=$_user #/" /etc/sddm.conf
}

auto_lxdm() {
	local _user="$1" _desktop="$2"; 
	sed -i "s/#[[:space:]]*autologin=.*$/autologin=$_user/" "/etc/lxdm/lxdm.conf"
	sed -i "s/#[[:space:]]*timeout=.*$/timeout=10/" "/etc/lxdm/lxdm.conf"
# 	sed -i "s/#[[:space:]]*session=.*$/session=\/usr\/share\/xsessions\/$_desktop.desktop/" "/etc/lxdm/lxdm.conf"
	sed -i "s/#[[:space:]]*session=.*$/session=\/usr\/bin\/${binde[$_desktop]}/" "/etc/lxdm/lxdm.conf"
}

auto_slim() {
	local _user="$1"; 
	sed -i "s/^#auto_login.*/auto_login yes/" "/etc/slim.conf" &&
	sed -i "s/^#default_user.*/default_user $_user/" "/etc/slim.conf" && return 0
	return 1
}

auto_nodm() {
	local _user="$1" _desktop="$2"; 
	sed -i "s/^NODM_USER=.*/NODM_USER=$_user/" /etc/nodm.conf
	sed -i "s/^NODM_XSESSION=.*/NODM_XSESSION=\/home\/$_user\/.xinitrc/" /etc/nodm.conf

	su - $_user -c "echo \"exec ${binde[$_desktop]}\" > /home/$_user/.xinitrc && chmod +x /home/$_user/.xinitrc" 

	[[ ! -e /etc/pam.d/nodm ]] && echo "#%PAM-1.0

auth      include   system-login
account   include   system-login
password  include   system-login
session   include   system-login" > "/etc/pam.d/nodm"
}
# auto_gdm() { }

# auto_mdm() { }
# END

# END

# Used for lxdm/nodm
declare -A binde=(
	[plasma]="startkde"
	[gnome]="gnome-session"
	[cinnamon]="cinnamon-session"
	[mate]="mate-session"
	[lxde]="startlxde"
	[xfce]="startxfce4"
	[lxqt]="startlxqt"
	[fluxbox]="startfluxbox"
	[enlightenment]="enlightenment_start"
# 	NoDE
	[node]="node"
)
#
#	$1: User login name as $NAME_USER
#	$2: Display Manager in use as $DPM
#	$3: Desktop Environnement as $DE
# [[ "$1"  == "1" ]] && shift && INIT_AUTOLOGIN=1
NAME_USER="$1"
[[ -z $NAME_USER ]] && echo "Aucun utilisateur défini !" && exit 1
! id -u "$NAME_USER" > /dev/null && echo "L'utilisateur n'existe pas !" && exit 1
DPM="$2"
[[ -z $DPM ]] && echo "Aucun gestionnaire de connexion défini !" && exit 1
DE=$3
[[ -z $DE ]] && echo "Aucun environnement de bureau défini !" && exit 1
DIR_SCRIPTS="$(dirname $0)/.."

case $DPM in 
	sddm)
		[[ ! -e /etc/sddm.conf ]] && sddm --example-config > /etc/sddm.conf
		[[ ! -e /etc/sddm.conf.ok ]] && cp /etc/sddm.conf /etc/sddm.conf.ok
		auto_sddm "$NAME_USER" "$DE"
	;;
	lightdm)
        if [[ ! -e /etc/lightdm/lightdm.conf.d/70-linuxmint.conf ]]; then
            [[ ! -f /etc/lightdm/lightdm.conf.ok ]] && cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.ok
            [[ ! -f /etc/lightdm/lightdm-gtk-greeter.conf.ok ]] && cp /etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf.ok
        else
            [[ ! -f /etc/lightdm/lightdm.conf.d/70-linuxmint.conf.ok ]] && cp /etc/lightdm/lightdm.conf.d/70-linuxmint.conf /etc/lightdm/lightdm.conf.d/70-linuxmint.conf.ok
            [[ ! -f /etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf.ok ]] && cp /etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf /etc/lightdm/lightdm-gtk-greeter.conf.d/99_linuxmint.conf.ok
#                 sed -i "s/.*autologin-user=.*/autologin-user=$_user/" "/etc/lightdm/lightdm.conf.d/70-linuxmint.conf"
        fi
        [[ -f /etc/lightdm/slick-greeter.conf ]] && [[ ! -f /etc/lightdm/slick-greeter.conf.ok ]] && cp /etc/lightdm/slick-greeter.conf /etc/lightdm/slick-greeter.conf.ok

		# Ajout du groupe autologin
		getent group autologin >> /dev/null || { groupadd -g 630 autologin ; }
		# Ajout de l'uilisateur au groupe autologin
		! groups $NAME_USER | grep -q autologin && gpasswd -a $NAME_USER autologin
		
		auto_lightdm "$NAME_USER" "10"
	;;
	slim)
		[[ ! -f /etc/slim.conf.ok ]] && cp /etc/slim.conf /etc/slim.conf.ok
		auto_slim "$NAME_USER"
	;;
	lxdm)
		[[ ! -f /etc/lxdm/lxdm.conf.ok ]] && cp /etc/lxdm/lxdm.conf /etc/lxdm/lxdm.conf.ok
		auto_lxdm "$NAME_USER" "$DE"
	;;
	nodm) 
		[[ ! -f /etc/nodm.conf.ok ]] && cp /etc/nodm.conf /etc/nodm.conf.ok
		auto_nodm "$NAME_USER" "$DE"
	;;

esac
exit 0

