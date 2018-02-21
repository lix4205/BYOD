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

# This script need futil
DIR_SRC="$(dirname $0)/.."
source $DIR_SRC/src/sources_files.sh $DIR_SRC/src/futil $DIR_SRC/src/bash-utils.sh
# source $(dirname $0)/futil
# source $(dirname $0)/bash-utils.sh

NAME_DIST="$( get_text "Indiquer le nom de la machine. (%s)" "$1" )"
# NAME_DIST="$( get_text "Indiquer le nom de la machine. (%s)" "$1" )"
PACKAGES_PLUS="$( rid "Ajouter des paquets supplémentaires en plus de l'environnement de bureau ?" )"
mkdir -p $1/$NAME_DIST

# TODO Monter le cache des paquets !!!
rid_continue "Monter le cache des paquers ?" && msg_n "Montez le cache dans %s puis deconnectez vous pour continuer." "/var/cache/pacman/pkg" && CACHE=1 && bash
# die "$(dirname $0)/anarchic/launchInstall.sh fr_FR -z Europe/Paris -k fr-latin9 -K fr -n nfsroot -g all -sbLT $1/$NAME_DIST $PACKAGES_PLUS"
if rid_continue "Lancer l'installation ?"; then
	if ! $DIR_SRC/anarchic/launchInstall.sh fr_FR -z Europe/Paris -k fr-latin9 -K fr -n nfsroot -h $NAME_DIST -g all $1/$NAME_DIST $PACKAGES_PLUS; then
		[[ ! -z $CACHE ]] && mountpoint -q /var/cache/pacman/pkg && umount /var/cache/pacman/pkg
		die "L'installation ne s'est pas terminée correctement !"
	fi
	[[ ! -z $CACHE ]] && mountpoint -q /var/cache/pacman/pkg && umount /var/cache/pacman/pkg

	source /tmp/anarchi-*.conf
	bash $(dirname $0)/genloader.sh "$NAME_MACHINE" "$ARCH" "$DE" "$1" "192.168.2.5"
	! grep -q "$1/$NAME_DIST" /etc/exports &&  echo "$1/$NAME_DIST *(rw,no_root_squash,no_subtree_check)" >> /etc/exports 
	# msg_n "ok les mecs !" 
	# Reload nfs exports
	exportfs -arv
	exist_install "nfsstat" "nfs-utils" && ! systemctl is-active nfs-server --quiet && rid_continue "Lancer nfs-server ?" && systemctl start nfs-server
	! systemctl is-enabled nfs-server --quiet && rid_continue "Lancer nfs-server au demarrage ?"  && systemctl enable nfs-server && caution "NetworkManager a été désactivé..."

fi
		
