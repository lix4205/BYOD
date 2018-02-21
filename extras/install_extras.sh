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

install_conf() {
# 	local dir="$1" && shift;
# # 	[[ ! -e $DIR_TARGET/$dir ]] && su - $NAME_USER -c "mkdir -p $DIR_TARGET/$dir"
	[[ ! -e $DIR_TARGET ]] && mkdir -p "$DIR_TARGET"  
# 	&& msg_n "Dossier %s créé !" "$dir"
	for fconf in ${@}; do
# 		su - $NAME_USER -c "cp -R \"$DIR_SOURCE/$dir/$fconf\" \"$DIR_TARGET/$dir\""
        cp -R "$DIR_SOURCE/$fconf" "$DIR_TARGET/"

# 		[[ -e $DIR_SOURCE/$dir/$fconf ]] && su - $NAME_USER -c "cp -R \"$DIR_SOURCE/$dir/$fconf\" \"$DIR_TARGET/$dir\"" || caution "'%s' n'existe pas !" "$DIR_SOURCE/$dir/$fconf"

	done
}

[[ "$1" != "-x" && "$1" != "archives" ]] && (( ! EUID == 0 )) && printf "==> ERROR: You have to be root !\n" && exit 1; 

dir2install=("../anarchi" "../src" "../extras" "../tools" "../imgs" "../confs.tar.gz" )
# dir2install=("anarchi" "anarchic" "andix" "calux" "desktops" "extras" "src" "files" "services"  )
# files2install=("install_extras.sh" "arch-utils.sh" "copyconf.sh" "wifi-netctl.sh" "node.sh" )
# files2install=("install_extras.sh" "arch-utils.sh" "node.sh" )

NAME_SOFT="dists-extra"
# NAME_APP="${NAME_SOFT^}"
ARCHIVE_NAME="$NAME_SOFT-$( date -I | sed  "s/-//g" ).tar.gz"
NO_INSTALL=0

DIR_SCRIPTS=$( dirname "$0" ) && [[ "$DIR_SCRIPTS" == "." ]] && DIR_SCRIPTS=$( pwd )
[[ ! -e "$DIR_SCRIPTS" ]] && printf "==> ERROR: Can't find \"%s\" directory  !\n" "$DIR_SCRIPTS" && exit
# source $DIR_SCRIPTS/src/futil

DIR_SOURCE="$DIR_SCRIPTS" 

# rm $DIR_SCRIPTS/../confs.tar.gz
# tar czf $DIR_SCRIPTS/../confs.tar.gz $DIR_SCRIPTS/../confs/
if [[ "$1" == "-x" || "$1" == "archives" ]]; then
	shift
	DIR_TARGET="/tmp/dists-extra"
	install_conf "${dir2install[@]}"
# 	install_conf "${files2install[@]}"
	
# 	echo "$(dirname "$1")"
	DIR_ARCHIVE="/tmp/"
	[[ -e "$1" ]] && DIR_ARCHIVE="$1" && [[ "$1" == "." ]] && DIR_ARCHIVE="$(pwd)/" 
	ln -sf $ARCHIVE_NAME "$DIR_ARCHIVE$NAME_SOFT-latest.tar.gz"
	cd /tmp
	tar zcf $DIR_ARCHIVE$ARCHIVE_NAME dists-extra/ 
	rm -R /tmp/dists-extra
	printf "==> L'archive %s est disponible.\n" "$DIR_ARCHIVE$ARCHIVE_NAME"
	
else
	DIR_TARGET="/usr/share/dists-extra"
	[[ -e "$1" ]] && DIR_TARGET="$1" && NO_INSTALL=1
	# [[ -e "$1" ]] && DIR_SOURCE="$1" && shift
	# [[ -e "$1" ]] && DIR_TARGET="$1" && shift
	# (( $# )) || die "Aucun parametre passé !"

	install_conf "${dir2install[@]}"
# 	install_conf "${files2install[@]}"
	if (( ! $NO_INSTALL )); then
		install $DIR_SCRIPTS/arch-utils.sh /usr/bin/dists-extra && 
		install $DIR_SCRIPTS/chroot_init.sh /usr/bin/chroot-extra && :
# 		cd $DIR_TARGET
# 		tar xzf $DIR_TARGET/confs.tar.gz 
# 		rm $DIR_TARGET/confs.tar.gz
	fi
fi
