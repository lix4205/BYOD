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

search_term() {
	local term_dispo
	for term_dispo in ${binterm[@]}; do 
		[[ -e /usr/bin/$term_dispo ]] && break
	done
	[[ ! -e /usr/bin/$term_dispo ]] && echo "Aucun terminal graphique trouvé !" && exit 1
	[[ "$term_dispo" == "qterminal" || "$term_dispo" == "xterm" ]] && command -v xcompmgr >> /dev/null && LAUNCH_XCOMPMGR=1
	[[ "$term_dispo" == "qterminal" ]] && term_dispo="$term_dispo --drop"
	TERM2LAUNCH="$term_dispo"
}

search_wm() {
	local wm_dispo
	for wm_dispo in ${binwm[@]}; do 
		[[ -e /usr/bin/$wm_dispo ]] && break
	done
	WM2LAUNCH="$wm_dispo"
}

LAUNCH_XCOMPMGR=0
# LAUNCH_COMPMARCO=0
# Search 4 a terminal
binterm=( "tilda" "qterminal" "yakuake" "lxterminal" "xterm" "terminology" "konsole" "mate-terminal" "gnome-terminal" )
search_term
# Search 4 a windows manager
binwm=("openbox" "xfwm4" "marco" "kwin_x11" )
search_wm

# [[ -z "$WM2LAUNCH" ]] && 
# Launch windows manager
exec $WM2LAUNCH &

# Launch compositor fo qterminal and xterm
(( $LAUNCH_XCOMPMGR )) && xcompmgr -c  >> ~/.node.log & 
# Launch compositor for marco
[[ "$WM2LAUNCH" == "marco" ]] && gsettings set org.mate.Marco.general compositing-manager true  >> ~/.node.log

# On lance les extensions de virtualbox si besoin
lsmod | grep -q vboxvideo && VBoxClient --clipboard --draganddrop --display --check3d
# lsmod | grep -q vboxvideo && VBoxClient-all

# Launch terminal
exec /usr/bin/$TERM2LAUNCH
