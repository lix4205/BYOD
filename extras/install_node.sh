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

DIR_SCR="$(dirname "$0")"
DISPLAYMANAGER="$1"
THEUSER="$2"
[[ -z $THEUSER ]] && printf "==> ERROR: Please give me a valid username...\n" 
[[ -z $DISPLAYMANAGER ]] && printf "==> ERROR: Please give me a valid display manager...\n"
# && exit 1; 

[[ ! -e "$DIR_SCR/desktops/node.desktop" ]] && printf "==> ERROR: Unable to find node.desktop !\n" && exit 1; 
[[ ! -e "$DIR_SCR/node.sh" ]] && printf "==> ERROR: Unable to find node.sh !\n" && exit 1; 

(( ! EUID == 0 )) && printf "==> ERROR: You have to be root !\n" && exit 1; 
if [[ ! -z "$DISPLAYMANAGER" ]] && [[ ! -z $THEUSER ]]; then
	if [[ "$DISPLAYMANAGER" == "slim" || "$DISPLAYMANAGER" == "nodm" ]] && [[ ! -z $THEUSER ]]; then 
		su $THEUSER -c "echo exec /usr/bin/node > ~/.xinitrc" 
		printf "Creating /.xinitrc with \"exec /usr/bin/node\"\n"
# 	else
	fi
# else
# 	printf "Aucun Display Manager supporté !\n" 
# 	exit 1
fi
install $DIR_SCR/node.sh /usr/bin/node
printf "Installation de NoDE dans /usr/bin/node\n"
cp $DIR_SCR/desktops/node.desktop /usr/share/xsessions/
printf "Installation de node.desktop dans /usr/share/xsessions/\n"

exit 0;
