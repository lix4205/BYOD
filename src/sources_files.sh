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

# Source files passed in arguments
[[ ! -z "$DIR_SCRIPTS" ]] && _dir_src="$DIR_SCRIPTS/src/"
[[ ! -z "$DIR_SCR" ]] && _dir_src="$DIR_SCR/src/"

for _file in "$@"; do 
	if [[ -e  "$_file" ]]; then
		source "$_file";  
	else	
		if [[ -e "$_dir_src$_file" ]]; then
			source "$_dir_src$_file";  
		else
			printf "==> ERROR: File \"%s\" not found\n" "$_dir_src$_file"; 
			exit 1; 
		fi
	fi

done;
