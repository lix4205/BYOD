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

DIR_SCRIPTS="$( dirname "$0" )" 
[[ "$0" == "/usr/bin/chroot-extra" || "$0" == "/bin/chroot-extra" ]] && DIR_SCRIPTS="/usr/share/dists-extra/extras"

source $DIR_SCRIPTS/src/sources_files.sh chroot_common.sh info2show

# (( ! EUID == 0 )) && die "You have to log root !\n" && exit 1; 
[[ -z "$1" ]] && die "No directory specified !"
# On vérifie que ce n'est pas "/" puis qu'on est bien sur un système...
if [[ -e "$1" ]] && [[ "$1" != "/" ]]; then
	if [[ -e "$1/bin" ]] && [[ -e "$1/dev" ]] && [[ -e "$1/proc" ]] && [[ -e "$1/sys" ]] && [[ -e "$1/run" ]] && [[ -e "$1/tmp" ]]; then 
		[[ -d $1/bin ]] && PATH=$PATH:/bin:/sbin:/usr/sbin
		msg_info -n "Setup chroot to \"$1\"\r"
		init_chroot "$1" || die "Failed to setup chroot in /"
		msg_info "Setup chroot to \"$1\"...ok"
		msg_info "Chrooting to \"$1\""
		chroot "$1"
	else
		die "Unable to find a valid system in \"$1\"!"
	fi
else
	die "\"$1\" is not valid directory !"
fi
# echo "ok"
exit 0
