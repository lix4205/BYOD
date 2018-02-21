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

# Count the "1" in a IPv4 adress
# eg : $1=255.255.255.0 return 24
mask2bits() { local count=0; for nb in $(echo "$1" | sed "s/\./ /g"); do count=$((count+$(($(echo "obase=2;$nb" | bc | sed "s/0//g" | wc -m)-1)))); done; echo $count; }
# Return true if $1 match an ip adress
# Accept network adress endind with "0"
# eg: 192.168.1.0
isIPv4() { local zero="1"; [[ "$1" == "0" ]] && zero="0" && shift; if [[ $# = 1 ]]; then printf $1 | grep -Eq "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-4]|2[0-4][0-9]|[01]?[$zero-9][0-9]?)$"; return $?; else return 2; fi; }

# Return true if $2 is set and $1 > $2
# TODO A Verifier...
is_sup() { [[ ! -z $2 && $1 -gt $2 ]] && return 1; return 0; }

# Return true if $1 is bloc device and display error message if not
is_blockdev() { local valid=0; [[ ! -b "$1" ]] && choix2error "\"%s\" n'est pas un peripherique de blocs !" "$1" && valid=1; return $valid; }
# Return true if $1 exists and display error message if not
is_existpath() { local valid=0; [[ ! -e "$1" ]] && choix2error "\"%s\" n'existe pas !" "$1" && valid=1; return $valid; }
# 
str2ssl() { echo "$1" | openssl enc -base64; }

## Waits until a statement succeeds or a timeout occurs
# $1: timeout in seconds
# $2...: condition command
timeout_wait() {
    local timeout=$1
    (( timeout *= 5 ))
    shift
    until eval "$*"; do
        (( timeout-- > 0 )) || return 1
        sleep 0.2
    done
    return 0
}
# Helper function to run make_*() only one time it's finished with result 0.
run_once() {
	if (( $NO_EXEC )); then
		${@}
		return $?
	fi
	if [[ ! -e ${work_dir}/done/${1} ]]; then
		${@}
		RES_RUN=$?
		[[ ! -e ${work_dir}/done ]] && mkdir ${work_dir}/done
		[[ $RES_RUN -eq 0 ]] && touch ${work_dir}/done/${1}
		return $RES_RUN
	fi
	return 0
}
