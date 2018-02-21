#!/bin/bash

die() {
	msg_error "" 
	exit 1
}

DIR_SCRIPTS="$( dirname $0 )" 
[[ "$0" == "/usr/bin/dists-extra" || "$0" == "/bin/dists-extra" ]] && DIR_SCR="/usr/share/dists-extra/extras"

source $DIR_SCRIPTS/src/sources_files.sh chroot_common.sh info2show


[[ -z "$1" ]] && die "Aucun répertoire spécifié !" && exit
if [[ -e "$1" ]]; then
	if [[ -e "$1/bin" ]] && [[ -e "$1/dev" ]] && [[ -e "$1/proc" ]] && [[ -e "$1/sys" ]] && [[ -e "$1/run" ]] && [[ -e "$1/tmp" ]]; then 
	
		[[ -d $1/bin ]] && PATH=$PATH:/bin:/sbin:/usr/sbin
		init_chroot "$1"
		trap "chroot_teardown" EXIT
		chroot "$1"
	else
		die "Aucun système !" && exit
	fi
else
	die "Répertoire non valide !" && exit
fi
# echo "ok"
exit 0
