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
exe_usr() {
	local _user="$1"
	shift; 
	echo "su - $_user -c \"${@}\"" 2>&1
	su - $_user -c "${@}"
	return $?
}

redim_function() {
	(( EUID == 0 )) && exe_usr "convert \"$IMG_BG\" -resize \"1920x1080^\" -gravity center -extent \"1920x1080\" \"$IMG_BG$1\"" || convert "$IMG_BG" -resize "1920x1080^" -gravity center -extent "1920x1080" "$IMG_BG$1"
}

find_d() { 
	local dir="";	

	dir="$(find "$1" -follow -type d -iname $2* | shuf | head -n 1)"
	[[ "$dir" == "" ]] && dir="$(find "$2" -follow -type d | shuf | head -n 1)"
	[[ "$dir" != "" ]] && ! ls "$dir" | grep -qi .jpg$ && ! ls "$dir" | grep -qi .png$ && echo "$dir -- ls \"$dir\" | grep -qi *.jpg -- dir=\"\$(find_d "$@" )\"" >> /tmp/img.log && dir="$(find_d "$@" )"
	echo $dir;
}
find_f() { 
	local file="";
	SPEC="-iname *.jpg -or -iname *.png" 
	[[ "$1" == "jpg" || "$1" == "png" ]] && SPEC="-iname *.$1" && shift
	file="$( find "$1" -follow -type f $SPEC | shuf | head -n 1 )"
# 
# 	Probleme avec la commande find < 4.6
# 	On doit mettre les guillemets 
	[[ "$file" == "" ]] && file="$( find "$1" -follow -type f -iname "*.jpg" -or -iname "*.png" | shuf | head -n 1 )"
	[[ "$file" == "" ]] &&  echo "find \"$1\" -follow -type f $SPEC | shuf | head -n 1" >> /tmp/img.log && return 1;
	echo "$file"
}

imgs() { 
	local file="";
	[[ "$1" == "jpg" || "$1" == "png" ]] && SPEC="$1" && shift
	[[ ! -z "$1" ]] && PATTERN_DIR="$1" && [[ -e $PATTERN_DIR ]] && DIR_IMGS="$1" && PATTERN_DIR=""
	[[ ! -z "$2" ]] && DIR_IMGS="$2" 
	msg2show="$( date "+%Y-%m-%d %H:%M:%S" ) ==> DIR_IMGS=\"$DIR_IMGS\" PATTERN=$PATTERN_DIR SPEC=$SPEC USER=$NAME_USER\n"
	! ls -l $DIR_IMGS >> /dev/null 2>&1 && echo -e "$msg2show --> Aucun fichier (PATTERN=$PATTERN_DIR) !\n" >> /tmp/img.log && return 1
	if [[ "$PATTERN_DIR" != "" ]]; then
		dir=$(find_d "$DIR_IMGS" "$PATTERN_DIR")
		[[ "$dir" == "" ]] && return 1;
	else
		dir="$DIR_IMGS"
	fi
	file="$(find_f $SPEC "$dir")"
	[[ -z $file ]] && echo -e "$msg2show --> \"Aucun fichier trouvé dans \"$dir\" $file!\"" >> /tmp/img.log && return 1
	echo -e "$msg2show --> \"$file\"" >> /tmp/img.log
	echo $file;
	return 0
}

#END

HISTORY=500
LOG_FILE="$HOME/img.log"
LOG_CMD="/tmp/comm_imgs.log"

touch /tmp/img.log

[[ -e $LOG_FILE ]] && [[ $(cat $LOG_FILE | wc -l) -gt $HISTORY ]] && tail -n 20 $LOG_FILE > $LOG_FILE

# if [[ ! -z $NAME_USER ]]; then
#     [[ -e /home/$NAME_USER/.config/user-dirs.dirs ]] && DIR_IMGS="$HOME/$(cat /home/$NAME_USER/.config/user-dirs.dirs | sed "s/XDG_PICTURES_DIR=\"\$HOME\/\(.*\)\"/\1/")"
# else
	if ! (( EUID == 0 )) ; then 
		[[ -e /home/$USER/.config/user-dirs.dirs ]] && DIR_IMGS="$HOME/$(cat /home/$USER/.config/user-dirs.dirs | grep XDG_PICTURES_DIR= | sed "s/XDG_PICTURES_DIR=\"\$HOME\/\(.*\)\"/\1/")"
	fi
# fi
