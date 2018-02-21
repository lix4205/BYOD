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

function echo_f() { echo -ne "${@}" >> $LOG_FILE; }

function nodeslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
	cp "$file" /tmp/.$USER.jpg
}

function fluxslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
	export DISPLAY=:0.0
	fbsetbg -a "$file" >> $LOG_CMD
}

function lxslide() {
	(( $PREV )) && file="$( prev_slide )" || file="$( next_slide )"
	export DISPLAY=:0
	pcmanfm$1 -w  "$file" --wallpaper-mode=screen >> $LOG_CMD
}

# Work with gnome, cinnamon, mate, xfce
function mateslide() {
    file="$( next_slide )"
	cp "$file" ~/.bg.jpg
}


function next_slide() {
	[[ -z $1 ]] && echo_f "\nDE   | " || echo_f "\n$1"
	file="$( imgs $PATTERN_DIR )"
	[[ $? -gt 0 ]] && echo_f "==> ERROR: Fichiers inaccessibles ($DIR_IMGS -> $PATTERN_DIR ) !" && exit 1
	echo "$file"
	echo_f "$( date "+%H:%M:%S" ) = \"$file\" $PREV_IMG"
}

function check_action() {
    tail -n 1 $LOG_FILE | grep -q "^_$1_$"
    [[ $? -gt 0 ]] && return 0 || return 1
}

# echo "WTF" && exit 0
function make_action() { echo_f "\n_$1_"; }

function start_slide() {
    echo "Lancement..."
}

DIR_SCR="$(dirname $0)"
LOG_FILE="$HOME/img.log"
LOG_CMD="/tmp/comm_imgs.log"
SLEEP_TIME=30
NAME_USER="$USER"
ACTION="$1"
shift
DIR_IMGS="$1"
PATTERN_DIR="$2"

declare -A de=(
    ["nom_de_1"]="lxqt-session"
    ["nom_de_2"]="lxsession"
    ["nom_de_3"]="mate-session"
    ["nom_de_4"]="gnome-shell"
    ["nom_de_5"]="cinnamon-session"
    ["nom_de_6"]="xfce.*-session"
    ["nom_de_7"]="fluxbox"
    ["nom_de_8"]="startdde"
    
    ["cmd_de_1"]="lxslide \"-qt\""
    ["cmd_de_2"]="lxslide"
    ["cmd_de_3"]="mateslide"
    ["cmd_de_4"]="${de[cmd_de_3]}"
    ["cmd_de_5"]="${de[cmd_de_3]}"
    ["cmd_de_6"]="${de[cmd_de_3]}"
    ["cmd_de_7"]="fluxslide"
    ["cmd_de_8"]="${de[cmd_de_3]}"
)
# Si aucun parametre, alors on lance le diapo avec $0 init
if [[ -z "$ACTION" ]]; then
	echo "\nDémarrage - $( date "+%H:%M:%S" )"
    nohup bash "$0" "init"
    exit $?;
else
    CONTINUE_DIAPO=$(check_action "STOP" && echo 1 || echo 0)
#     Gestion de l'actions stop
    [[ "$ACTION" == "stop" ]] && make_action "STOP" && exit
    
    
    source "$DIR_SCR/rdm_img.sh"

    if [[ -z "$DIR_IMGS" ]] || [[ ! -e "$DIR_IMGS" ]]; then
        echo "Aucun répertoire d'images défini !" 
        [[ -e "/home/$NAME_USER/Pictures" ]] && DIR_IMGS="/home/$NAME_USER/Pictures"
        [[ -e "/home/$NAME_USER/Images" ]] && DIR_IMGS="/home/$NAME_USER/Images"
        [[ -z $DIR_IMGS ]] && exit 2;
        echo "Utilisation de $DIR_IMGS"
    fi
    
    # Selection automatique de l'environnement de bureau
    i=1;
    while [[ -z "$CMD_DE" ]] && [[ ! -z "${de[nom_de_$i]}" ]]; do
        ps -aux | grep -v grep | grep -q "${de[nom_de_$i]}" && CMD_DE="${de[cmd_de_$i]}" && break
#         ps -e | grep -q "${de[nom_de_$i]}" && CMD_DE="${de[cmd_de_$i]}" && break
        i=$((i+1))
    done
    [[ -z $CMD_DE ]] && echo "Impossible de trouver un environnement de bureau compatible."
    
#     NEXT
    if [[ "$ACTION" == "next" ]]; then
#         On verifie qu'on est pas déjà en train de chercher
        if tail -n 1 $LOG_FILE | grep -q "=" && check_action "NEXT"; then
            make_action "NEXT"
    #         Si le diaporama est stoppé, on cherche quand même une nouvelle image
            (( ! $CONTINUE_DIAPO )) && echo_f "\n$( imgs "jpg" )" && make_action "STOP"
        fi
        exit;
    fi

#     Demarrage
    if [[ "$ACTION" == "init" ]]; then
        CONTINUE_DIAPO=1
        make_action "START"
    fi
    
    while (( $CONTINUE_DIAPO )); do
        CONTINUE_DIAPO=$(check_action "STOP" && echo 1 || echo 0)
        TIME2CHANGE=$(($(date +%s)+$SLEEP_TIME))
        (( $CONTINUE_DIAPO )) && $CMD_DE
        while [[ $(date +%s) -lt $TIME2CHANGE ]] && (( $CONTINUE_DIAPO )); do
#             Si on est en plein changement alors on sort de la boucle
        	! check_action "NEXT" && break;
            sleep 1
        done
    done
fi
exit 0;
