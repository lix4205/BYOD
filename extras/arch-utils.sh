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

# chroot_loading() { loading "Preparation de l'environnement..." "Preparation de l'environnement...ok" chroot_prepare "$1"; }
run_or_chroot() {
	toexec="${@}"
	if [[ "$ROOT" == "/" ]]; then
# 	exit
		msg_info "$toexec"
		run_or_su "${toexec}"
# 		&& {
# 		[[ $ROOT != "/" ]] && DIR_SCR_INITX="/tmp/extras/$INITX"

		
	else
		msg_info "chroot $ROOT $toexec"
		arch_chroot "$ROOT" "${@}" 
	fi
	return $?
}

chroot_prepare() {
	! mountpoint -q "$1" && die "\"%s\" n'est pas un point de montage !" "$1"
	init_chroot "$1" || return 1
# 	cp $DIR_SCR/src/net-utils $ROOT/tmp || msg_error "$DIR_SCR/src/net-utils manquant !"
# 	cp $DIR_SCR/src/bash-utils.sh $ROOT/tmp || msg_error "$DIR_SCR/src/net-utils manquant !"
# 	cp $DIR_SCR/src/futil $ROOT/tmp || msg_error "$DIR_SCR/src/net-utils manquant !"
# 	bash $DIR_SCR/install_extras.sh $ROOT/tmp
# 	cp -R $DIR_SCR/src $ROOT/tmp || msg_error "$DIR_SCR/src manquant !"
	cp -Rf $DIR_SCR/.. $ROOT/tmp || msg_error "$DIR_SCR/extras manquant !"
# 	cp -R $DIR_SCR/services $ROOT/tmp || msg_error "$DIR_SCR/services manquant !"
# 	cp -R $DIR_SCR/desktop $ROOT/tmp || msg_error "$DIR_SCR/desktop manquant !"
# # 	cp -R $DIR_SCR/node.sh $ROOT/tmp || msg_error "$DIR_SCR/node.sh manquant !"
# 	cp -R $0 $ROOT/tmp || msg_error "$0 manquant !"
	
# 	cp -R $DIR_SCR/anarchic $ROOT/tmp
# 	cp $DIR_SCR_DNSMASQ $ROOT/tmp
# 	cp $DIR_SCR_WIFI $ROOT/tmp
# 	cp -v $DIR_SCR_ANARCHI $ROOT/tmp
# 	cp $DIR_SCR_INITX $ROOT/tmp
[[ -e $DIR_SCR/anarchic ]] && 
mkdir -p $ROOT/tmp/anarchic && {
cp -RfL $DIR_SCR/anarchic/{pacinstall.sh,launchInstall.sh,files} $ROOT/tmp/anarchic || msg_error "$DIR_SCR/anarchic manquant !"; ln -s $ROOT/tmp/anarchi; }
# || die "$_install_copie"

	chroot_add_resolv_conf "$1"
	msg_info "Ready to chroot to $ROOT"
}

chroot2root() {
# 	loading "Preparation de l'environnement..." "Preparation de l'environnement...ok" chroot_prepare "$1"
# 	chroot_prepare "$1"
	msg_n "32" "32" "Entre dans l'environnement chroot sur %s\n%s Déconnectez vous en lancant \"%s\" ou \"%s\"." "$1" "==>" "exit" "CTRL + D"
	[[ -d $1/bin ]] && PATH=$PATH:/bin:/sbin:/usr/sbin
	arch_chroot "$1" "/bin/bash" 
# 	echo $?
# 	chroot_teardown "reset" 
# 	choix2do
}

chroot2exec () {
# msg_n $ROOT
# msg_n "arch_chroot \"${1}\" $ROOT----%s" "${CHROOT_ACTIVE_MOUNTS}"
	arch_chroot "${1}" $ROOT
	shift
	[[ ! -z $FILE_COMMANDS ]] && echo "${@}" >> $FILE_COMMANDS
# 	lix_chroot $ROOT "${1}" 
# 	echo $?
# 	chroot $ROOT_CALUX ${1}
}
set_path() {
	local txt2return="$1";
	if [[ "$txt2return" == "" ]]; then
		txt2return=$( get_text "$2" ) || return 1;
	fi
	if ! is_existpath "$txt2return" || ! is_blockdev "$txt2return"; then
		txt2return=$( set_path "" "$2" ) || return 1;
	fi
	echo $txt2return
}

grub2root() {
# 	chroot_prepare "$ROOT" || die "Ehh !"
# 	! cat $ROOT/etc/grub.d/40_custom | grep -q "System shutdown" && rid_continue "Ajouter \"%s\" et \"%s\" dans le menu de GRUB ?" "shutdown" "reboot" && 
	if ! cat $ROOT/etc/grub.d/40_custom | grep -q "ipxe" && rid_continue "Ajouter \"%s\" dans le menu de GRUB ?" "Ipxe"; then
		if cp $DIR_SCR/ipxe* $ROOT/boot/; then
			PXE_ENTRY="\n\nmenuentry \"ipxe\" {\n\tset root='(hd0,1)'\n\tlinux16  /ipxe.lkrn\n}"
			if ! mountpoint -q /boot; then
				PXE_ENTRY="\n\nmenuentry \"ipxe\" {\n\tset root='(hd0,1)'\n\tlinux16  /boot/ipxe.lkrn\n}"
			fi
			echo -e "$PXE_ENTRY" >> $ROOT/etc/grub.d/40_custom
		fi
	fi	

		# random BACKGROUND IMAGE
	if ! cat $ROOT/etc/default/grub | grep -q "^GRUB_BACKGROUND" && rid_continue "Ajouter un fond d'écran ?"; then
		IMG_AP_HOME=$(find "$DIR_SCR/../imgs/" -type f | shuf | head -n 1 )
		EXT_BG_NAME=$( echo "$IMG_AP_HOME" | sed "s/.*\.//")
		BG_NAME="bg.$EXT_BG_NAME"
		cp "$IMG_AP_HOME" $ROOT/boot/$BG_NAME
		sed -i "s/#GRUB_BACKGROUND=.*/GRUB_BACKGROUND=\"\/boot\/$BG_NAME\"/" $ROOT/etc/default/grub
	fi

	if ! cat $ROOT/etc/grub.d/40_custom | grep -q "System rebooting..."; then
		echo -e "\\n\\nmenuentry \"System shutdown\" {\\n\\techo \"System shutting down...\"\\n\\thalt\\n}" >> "$ROOT/etc/grub.d/40_custom" &&
		echo -e "\\n\\nmenuentry \"System restart\" {\\n\\techo \"System rebooting...\"\\n\\treboot\\n}" >> "$ROOT/etc/grub.d/40_custom"
		msg_n "32" "32" "Ajout des entrées \"%s\" et \"%s\"" "reboot" "shutdown"
	fi
	
	rid_continue "Installer GRUB sur %s" "$DISK2GRUB" && loading "Installation de GRUB sur le disque %s..." "Grub à été installé sur %s." "$1"  run_or_chroot grub-install --recheck $1
		loading "Création du fichier de configuration GRUB" "Fichier de configuration GRUB créé." run_or_chroot grub-mkconfig -o /boot/grub/grub.cfg
		res2return=$?
# 	if [[ $ROOT == "/" ]]; then
# 	else
# 		loading "Installation de GRUB sur le disque %s..." "Grub à été installé sur %s." "$1" chroot2exec "grub-install --recheck $1"
# 		loading "Création du fichier de configuration GRUB" "Fichier de configuration GRUB créé." chroot2exec "grub-mkconfig -o /boot/grub/grub.cfg" 
# 		res2return=$?
# 	fi
# 	chroot_teardown "reset" 
	return $res2return
}

# init_files2edit() {
# 	local i=0;
# # 	msg_edit="Quel fichier éditer ?"
# 	for a2d in "${_ask_2do[@]}"; do 
# # 		if [[ -e "$ROOT$f2e" ]]; then
# 			i=$((i+1));
# 			aa2dd+=( [$i]="$a2d" )
# # 			file2print=( "${file2print[@]}" "$ROOT$f2e" )
# # 		fi
# # 		msg_edit+="\n\t$i) $ROOT$f2e"
# 	done
# 	show_a2d="$( print_menu "${file2print[@]}")"
# 
# }



init_files2edit() {
	local i=0;
	file2print=();
	# Netctl files
	for dir2edit in "${dirs_files2edit[@]}"; do
# 		msg_n "$ROOT2SHOW$dir2edit"
		ls "$ROOT2SHOW$dir2edit" >> /dev/null 2>&1 && for nf2e in $(ls "$ROOT2SHOW$dir2edit"); do 
# 		msg_n "$ROOT2SHOW$dir2edit/$nf2e"
			[[ -f "$ROOT2SHOW$dir2edit/$nf2e" ]] && files2edit=( "${files2edit[@]}" "$dir2edit/$nf2e" )
		done
	done

	# Users home files
	for uf2e in ${users_files2edit[@]}; do
		if ls $ROOT2SHOW/home/*/$uf2e >> /dev/null 2>&1; then
			for lf in $(dirname $ROOT2SHOW/home/*/$uf2e); do
				uf2e="${lf//${ROOT2SHOW//\//\\\/}/}/$uf2e"
				files2edit=( "${files2edit[@]}" "$uf2e" )
			done
		fi
	done
	for f2e in "${files2edit[@]}"; do 
		if [[ -e "$ROOT2SHOW$f2e" ]]; then
			i=$((i+1));
			ff2ee+=( [$i]="$f2e" )
			file2print=( "${file2print[@]}" "$ROOT2SHOW$f2e" )
		fi
	done
	
	
	show_files="$( rid_menu -q "Quel fichier éditer ?" "${file2print[@]}")"

}
edit_file() {
# 	msg_edit+="\n\tq) Exit\n\t->"
	choix_edit=$(rid "\t->" )

	[[ "$choix_edit" == "q" ]] && return 0
# 	[[ $choix_edit -eq $((i+1)) ]] && nano "$ROOT${files2edit[*]}"
	[[ "$choix_edit" != "" ]] && [[ ! -z ${ff2ee[$choix_edit]} ]] && nano "$ROOT${ff2ee[$choix_edit]}" 
	edit_file
}
search_user() {
	local nb=0 _theuser=1;
	declare user2auto;
	# On cherche les users avec id > 100*
	users=($(awk -F":" '/x:100/ { print $1 }' $ROOT2SHOW/etc/passwd)); 
	# Liste les clés du tableau...
	for u2a in ${users[@]}; do 
		nb=$((nb+1));
		user2auto[$nb]="$u2a"
	done
	if [[ $nb -gt 1 ]]; then 
		_theuser=
		msg_info "%s a été trouvé !" "${users[@]}">&2 && 
		msg_nn "$( rid_menu "Veuillez choisir l'utilisateur a connecter automatiquement" "${users[@]}" )" 
		while [[ -z "$_theuser" || -z ${user2auto[$_theuser]} ]]; do
			[[ "$_theuser" == "q" ]] && return 1
			_theuser="$(rid "\t->")"; 
		done
	fi
	[[ $nb -eq 0 ]] && error "Aucun utilisateur trouvé !" && return 1
	echo "${user2auto[$_theuser]}"
}

search_de() {
	local nb=0 d2return=1;
	envir=(); 
	# Liste les clés du tableau...
	for d2e in ${!de2auto[*]}; do 
		if [[ -e "$ROOT2SHOW${de2auto[$d2e]}" ]]; then
			nb=$((nb+1));
			de2auto[$nb]="$d2e"
			envir=( "${envir[@]}" "$d2e" )
		fi
	done
	if [[ $nb -gt 1 ]]; then 
		d2return=
		msg_info "%s a été trouvé !" "${envir[@]}">&2 && 
		msg_nn "$( rid_menu "Veuillez choisir parmis les environnement installés" "${envir[@]}" )" &&
		while [[ -z "$d2return" || -z ${de2auto[$d2return]} ]]; do 
			[[ "$d2return" == "q" ]] && return 1
			d2return="$(rid "\t->")"; 
		done
	fi
	[[ $nb -eq 0 ]] && error "Aucun environnement de bureau supporté !" && return 1
	echo "${de2auto[$d2return]}"
}

search_dm() {
	for f2e in "${dm2edit[@]}"; do 
		if [[ -e "$ROOT2SHOW$f2e" ]]; then
			echo "$f2e"
			break
		fi
	done
}

choose_dm() {
	:
	local choix_dm
	declare -A envir
	i=0
	msg_nn "Choisissez un DM"
	for dm_dispo in ${DISPLAYMANAGER[@]}; do 
		i=$((i+1));
		envir[dm_$i]="$dm_dispo"
# 		envir[$env_dispo]="$env_dispo"
# 		msg_edit+="\n\t$i) $RACINE$f2e"
	done
	while [[ "$choix_dm" == "" ]] || [[ -z ${envir[dm_$choix_dm]} ]]; do
		echo -e "$( print_menu "${DISPLAYMANAGER[@]}")"
		choix_dm=$(rid "$_choix_de")
	done
	envir[syst_$DE]="${envir[dm_$choix_dm]}"
	msg_n "32" "32" "$_selected" "${envir[dm_$choix_dm]}"
	[[ ! -z "${envir[pack_${envir[dm_$choix_dm]}]}" ]] && envir[dm_$choix_dm]="${envir[pack_${envir[dm_$choix_dm]}]}"
	envir[dm_$DE]="${envir[dm_$choix_dm]}"
# 	die "ok %s ok %s" "$choix_dm" "${envir[dm_$choix_dm]}"
}

choix2do() {
	local choix_fin="$1"
# 	clear
	[[ "$ROOT" != "/" ]] && caution "%s" "Vous travaillez sur le système situé dans $ROOT" || caution "%s" "$_caution_current"
# 	msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER
	[[ "$choix_fin" == "" ]] && msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER && choix_fin=$(rid "\t->" )
	while [[ "$choix_fin" != "q" ]]; do
		[[ "$choix_fin" == "" ]] && choix_fin=$(rid "\t->")
		case $choix_fin in
			$NUM_CHROOT|chroot) 				
				[[ "$ROOT" != "/" ]] && chroot2root "$ROOT"
				[[ "$ROOT" == "/" ]] && msg_error "\"%s\" n'est pas une action valide pour / !" "$choix_fin"
				msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
				choix_fin=""
			;;
			$((NUM_CHROOT+1))|grub) 
				if [[ -e $ROOT/etc/grub.d/40_custom ]]; then
					DISK2GRUB=$( set_path "$2" "Indiquez le disque sur lequel installer GRUB." ) || exit 1;
					grub2root "$DISK2GRUB"
				else
					error "Grub n'est pas installé dans \"%s\"" "$ROOT"
				fi
				init_files2edit
				msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
				choix_fin=""
			;;
			$((NUM_CHROOT+2))|wifi) 
# 				is_root "bash $DIR_SCR_WIFI" && {
					[[ $ROOT != "/" ]] && DIR_SCR_WIFI="/tmp/extras/$WIFI"
					run_or_chroot "bash $DIR_SCR_WIFI"
# 				}
				init_files2edit
				msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
				choix_fin=""
			;;
			$((NUM_CHROOT+3))|dnsmasq) 
# 				is_root "bash $DIR_SCR_DNSMASQ" && {
				[[ $ROOT != "/" ]] && DIR_SCR_DNSMASQ="/tmp/extras/$DNSMASQ"
				run_or_chroot "bash $DIR_SCR_DNSMASQ"
# 				}
				init_files2edit
				msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
				choix_fin=""
			;;
			$((NUM_CHROOT+4))|anarchi) 
				bash $DIR_SCR_ANARCHI $PATH2ROOT
				choix_fin="q"
			;;
			$((NUM_CHROOT+5))|anarchi_nfs) 
				PATH2NFSROOT=$( get_text "Indiquez la racine de votre serveur PXE" ) || exit 1;
				if [[ -e $PATH2NFSROOT ]] && [[ -d $PATH2NFSROOT ]]; then
# 					is_root "bash /tmp/extras/$ANARCHI_NFS $PATH2NFSROOT" && {
					[[ $ROOT != "/" ]] && DIR_SCR_ANARCHI_NFS="/tmp/extras/$ANARCHI_NFS"
					run_or_chroot "bash $DIR_SCR_ANARCHI_NFS $PATH2NFSROOT"
# 					}
				else
					choix2error "$PATH2NFSROOT n'est pas un chemin valide !"; 
				fi
				msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
				choix_fin=""
			;;
			$((NUM_CHROOT+6))|xauto) 
				if [[ "$DISPLAYMANAGER" != "?" ]]; then
					DESKTOPENVIRONNEMENT=$(search_de) || exit					
					THEUSER=$(search_user) || exit
					# Mon service perso
					if rid_continue "Connecter automatiquement l'utilisateur \"%s\" à \"%s\" avec \"%s\" ?" "$THEUSER" "$DESKTOPENVIRONNEMENT" "auto-launcher"; then
# 						if cp $DIR_SCR/services/auto-launcher.service $ROOT/etc/systemd/system/$THEUSER.service && cp $DIR_SCR/auto_launcher.sh $ROOT/usr/bin/; then
						if cp $DIR_SCR/services/auto-launcher.service $ROOT/etc/systemd/system/$THEUSER.service; then
						
							sed -i "s/ExecStart.*auto_launcher.sh .*/ExecStart=\/usr\/share\/dists-extra\/extras\/auto_launcher.sh $NAME_USER $DM $DE/" $ROOT/etc/systemd/system/$THEUSER.service
							[[ "$DISPLAYMANAGER" == "lightdm" || "$DISPLAYMANAGER" == "lxdm" ]] && sed -i "s/BusName=org.freedesktop.DisplayManager/#BusName=org.freedesktop.DisplayManager/" $ROOT/etc/systemd/system/$THEUSER.service

							cp $ROOT/etc/systemd/system/$THEUSER.service $ROOT/etc/systemd/system/auto-launcher\@.service
							sed -i "s/auto_launcher.sh .*/auto_launcher.sh $THEUSER $DISPLAYMANAGER $DESKTOPENVIRONNEMENT/" $ROOT/etc/systemd/system/$THEUSER.service
							sed -i "s/auto_launcher.sh .*/auto_launcher.sh %I $DISPLAYMANAGER $DESKTOPENVIRONNEMENT/" $ROOT/etc/systemd/system/auto-launcher\@.service
							
							[[ $ROOT != "/" ]] && DIR_SCR_INSTALL_EXTRAS="/tmp/extras/$INSTALL_EXTRAS"
							run_or_chroot bash $DIR_SCR_INSTALL_EXTRAS

							run_or_chroot systemctl disable $DISPLAYMANAGER
# 							echo "systemctl disable $DISPLAYMANAGER"
							run_or_chroot systemctl enable $THEUSER.service
# 							echo "systemctl enable $THEUSER.service"
						fi

					else
# 				\nbash $DIR_SCR_INITX 1 $THEUSER $DISPLAYMANAGER $DESKTOPENVIRONNEMENT
						if rid_continue "Connecter automatiquement l'utilisateur \"%s\" à \"%s\" avec \"%s\" ?" "$THEUSER" "$DESKTOPENVIRONNEMENT" "$DISPLAYMANAGER"; then
# 							is_root "bash $DIR_SCR_INITX 1 $THEUSER $DISPLAYMANAGER $DESKTOPENVIRONNEMENT" && {
								[[ $ROOT != "/" ]] && DIR_SCR_INITX="/tmp/extras/$INITX"
								run_or_chroot bash $DIR_SCR_INITX $THEUSER $DISPLAYMANAGER $DESKTOPENVIRONNEMENT && msg_n "32" "32" "L'utilisateur %s se connectera avec l'environnement %s avec %s !" "$THEUSER" "$DESKTOPENVIRONNEMENT" "$DISPLAYMANAGER"
								msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
# 							}
						fi
					fi
				else
					error "Aucun Display Manager supporté !" 
				fi
				choix_fin="" 

			;;
			$((NUM_CHROOT+7))|passroot) 
			
				run_or_chroot passwd 
# 				choix_fin

				;;
			$((NUM_CHROOT+8))|sudo) 
# 				exists
				if [[ -e $ROOT2SHOW/usr/bin/sudo ]]; then
					THEUSER=$(search_user) || exit 				:
					run_or_chroot "echo \"$THEUSER   ALL=(ALL) ALL\" >> $ROOT2SHOW/etc/sudoers.d/users"
				else
					choix2error "Sudo est introuvable dans \"%s\"" "$ROOT2SHOW/usr/bin"
				fi
			;;
			$((NUM_CHROOT+9))|node) 
				if [[ "$DISPLAYMANAGER" != "?" ]]; then
					[[ "$DISPLAYMANAGER" == "slim" || "$DISPLAYMANAGER" == "nodm" ]] && { THEUSER=$(search_user) || exit; }
					[[ $ROOT != "/" ]] && DIR_SCR_NODESKTOP="/tmp/extras/$NODESKTOP"
					run_or_chroot bash $DIR_SCR_NODESKTOP $DISPLAYMANAGER $THEUSER && rid_continue "Lancer la connexion automatique ?" && choix2do "xauto"
				else
					error "Aucun Display Manager supporté !" 
	# 				fi
				fi
				choix_fin="" 
			;;
			$((NUM_CHROOT+10))|edit) 
				msg_nn "$show_files"
				edit_file;
				msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
				choix_fin="" 
			;;
			$((NUM_REBOOT-1))|dists-extra) 
				if (( ! $OPT_INSTALL_EXTRAS )); then
					[[ $ROOT != "/" ]] && DIR_SCR_INSTALL_EXTRAS="/tmp/extras/$INSTALL_EXTRAS"
					run_or_chroot bash $DIR_SCR_INSTALL_EXTRAS
					msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
				else
					choix2error "\"%s\" n'est pas une action valide !" "$choix_fin"
				fi
				choix_fin="" 
			;;
			99|dux) 
# 				aneble_dux() {  }
				run_or_chroot "systemctl disable display-manager && systemctl enable dux"
				choix_fin=""
			;;
			$NUM_REBOOT) [[ -z $NO_REBOOT ]] && { is_root "reboot" && rid_continue "Reboot ?" && reboot; break; } || choix2error "\"%s\" n'est pas une action valide !" "$choix_fin"
				msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
				choix_fin="" 
				;;
			$((NUM_REBOOT+1))) [[ -z $NO_REBOOT ]] && { is_root "poweroff" && rid_continue "Poweroff ?" && poweroff; break; } || choix2error "\"%s\" n'est pas une action valide !" "$choix_fin"
				msg_nb msg_nn "$show_a2d" "$ROOT" $ROOT2SHOW $DISPLAYMANAGER 
				choix_fin="" 
				;;
# 			9) tail -n 50 $LOG_FILE ;;
# 			4) # echo "$LAUNCH_COMMAND -i"
# 				sed -i "s/PACSTRAP_OPTIONS=\"/PACSTRAP_OPTIONS=\"-i/" /tmp/arch-$NAME_MACHINE-$LA_LOCALE.conf 
# 				sed -i "s/SHOW_COMMANDE=\"/SHOW_COMMANDE=\"-i/" /tmp/arch-$NAME_MACHINE-$LA_LOCALE.conf
# 				$LAUNCH_COMMAND
# 			;;
# 			5) 
# 				rm /tmp/done.anarchi_* 
# 				$LAUNCH_COMMAND;;
# 			6)
# 	# 			source files/chroot_common.sh
# 				msg_n "32" "32" "Entre dans l'environnement chroot sur %s" "$ROOT"
# 				init_chroot "$ROOT"
# 				chroot_add_resolv_conf "$ROOT"
# 				arch_chroot "/bin/bash" "$ROOT"
# 				chroot_teardown "reset" 
# 	# 			choix_fin=""
# 				termine
# 			;;
			q) break ;;
			*) 
				[[ "$choix_fin" != "" ]] && choix2error "\"%s\" n'est pas une action valide !" "$choix_fin"
				choix_fin="" 
# 				choix2do
			;;
		esac
		clear_line
		[[ "$choix_fin" == "q" ]] && exit || choix_fin="" 
	done
}

declare -A ff2ee
declare -A de2auto=(
	[plasma]="/usr/bin/startkde"
# 	[e_kde4]="/usr/bin/kate"
	[gnome]="/usr/bin/gnome-session"
	[cinnamon]="/usr/bin/cinnamon-session"
	[mate]="/usr/bin/mate-session"
	[lxde]="/usr/bin/startlxde"
	[xfce]="/usr/bin/startxfce4"
	[lxqt]="/usr/bin/startlxqt"
	[fluxbox]="/usr/bin/startfluxbox"
	[enlightenment]="/usr/bin/enlightenment_start"
	[node]="/usr/bin/node"
	)
# Desktop binaries
# de2auto=( "/usr/bin/startkde" "/usr/bin/cinnamon-session" "/usr/bin/startlxde" "/usr/bin/gnome-session" "/usr/bin/mate-session" "/usr/bin/startxfce4" "/usr/bin/startlxqt" "/usr/bin/startfluxbox" "/usr/bin/enlightenment_start" )
# Display Manager configuration files
dm2edit=( "/etc/lightdm/lightdm.conf" "/etc/lxdm/lxdm.conf" "/etc/sddm.conf" "/etc/slim.conf" "/etc/nodm.conf" "/etc/mdm/mdm.conf" )
# Packages manager configuration files
pm2edit=( "/etc/pacman.conf" "/etc/pacman.d/mirrorlist" "/etc/apt/sources.list" )
# System configuration files...
files2edit=( "${pm2edit[@]}" "/etc/vconsole.conf" "/etc/locale.conf" "/etc/locale.gen" "/etc/hostname" "/etc/hosts" "/etc/fstab" "/etc/default/grub" "/etc/grub.d/40_custom" "/etc/sudoers.d/users" "/etc/X11/xorg.conf.d/00-keyboard.conf" "/etc/systemd/system/display-manager.service" ${dm2edit[@]} "/etc/dnsmasq.conf" "/etc/iptables/iptables.rules" );
# Users files configuration ( search for file in /home/*)...
users_files2edit=(".xinitrc" ".dmrc");
# DISPLAYMANAGER=("sddm" "gdm" "lightdm" "lxdm" "slim" "nodm")
dirs_files2edit=("/etc/wpa_supplicant" "/etc/netctl" "/etc/NetworkManager/system-connections");

WIFI="wifi-utils.sh"
DNSMASQ="dnsmasq-pxe.sh"
ANARCHI="prepare_anarchi"
ANARCHI_NFS="arch-diskless.sh"
INITX="init_x.sh"
NODESKTOP="install_node.sh"
INSTALL_EXTRAS="install_extras.sh"

DIR_SCR="$(dirname $0)"
[[ "$0" == "/usr/bin/dists-extra" || "$0" == "/bin/dists-extra" ]] && DIR_SCR="/usr/share/dists-extra/extras"
DIR_SCR_WIFI="$DIR_SCR/$WIFI"
DIR_SCR_DNSMASQ="$DIR_SCR/$DNSMASQ"
DIR_SCR_ANARCHI="$DIR_SCR/../anarchi/tool/$ANARCHI"
DIR_SCR_ANARCHI_NFS="$DIR_SCR/$ANARCHI_NFS"
DIR_SCR_INITX="$DIR_SCR/$INITX"
DIR_SCR_NODESKTOP="$DIR_SCR/$NODESKTOP"
DIR_SCR_INSTALL_EXTRAS="$DIR_SCR/$INSTALL_EXTRAS"
NAME_SCRIPT2CALL="pacinstall.sh,launchInstall.sh"
ROOT="/"
NUM_CHROOT=0
OPT_INSTALL_EXTRAS=1
FILE_COMMANDS="/tmp/µtricks.log"
_caution_current="Vous travaillez sur le système courant (/)"
files2source="info2show doexec bash-utils.sh chroot_common.sh futil"
_ask_2do=( "Installer GRUB sur %s" "Créer une connexion WiFi" "Installer un serveur PXE (dnsmasq)" "Installer ArchLinux avec Anarchi" "Installer ArchLinux diskless" "Activer la connexion automatique (%s)" "Affecter un mot de passe a root" "Créer un compte sudo." "Installer NoDE" "Consulter les fichiers" )

source $DIR_SCR/src/sources_files.sh $files2source 
# die "$DIR_SCR --> $0 "
# echo  "$DIR_SCR --> $0 " && exit
# exit

# msg_info "SAlut !"
# || { printf "\"%s\" est introuvable !" "$REP_SCRIPT/files/bash-utils.sh" && exit 1; }

[[ ! -z $1 ]] && [[ "$1" == "--no-reboot" ]] && NO_REBOOT="$1" && shift
[[ ! -z $1 ]] && [[ -e "$1" ]] && [[ ! -b "$1" ]] && ROOT="$1" && shift
[[ "$ROOT" != "/" ]] && _ask_2do=( "Chroot %s" "${_ask_2do[@]}" ) && NUM_CHROOT=1
[[ "$DIR_SCR" != "/usr/share/dists-extra/extras" ]] && _ask_2do=( "${_ask_2do[@]}" "Installer Arch-extras" ) && OPT_INSTALL_EXTRAS=0

# On calcule le nombre d"éléments pour ne pas a décaler reboot et poweroff dans la liste quand on ajoute une entrée dans ${_ask_2do...
NUM_REBOOT="$((${#_ask_2do[*]}+1))"
[[ -z $NO_REBOOT ]] && _ask_2do=( "${_ask_2do[@]}" "Redémarrer" "Éteindre"  )

# msg_nn2 "$_ask_2do" "$ROOT" "$ROOT"
# [[ ! -z $1 ]] && OP="$1"

# files2edit=("${files2edit[@]}" )
[[ "$ROOT" != "/" ]] && [[ "${ROOT:${#ROOT}-1}" == "/" ]] && ROOT="${ROOT:0:${#ROOT}-1}" 
ROOT2SHOW="$ROOT"
[[ "$ROOT" == "/" ]] && ROOT2SHOW=""

init_files2edit
# init_ask2do
# die "$DISPLAYMANAGER"
show_a2d="$( rid_menu -q "Que voulez vous faire ?" "${_ask_2do[@]}")"
# On prepare le chroot
if [[ "$ROOT" != "/" ]]; then
 	is_root 1 "/bin/bash $0 $NO_REBOOT $ROOT2SHOW ${@}" && { chroot_prepare "$ROOT" || die "Impossible de préparer le chroot !"; }
fi
(( ! EUID == 0 )) && caution "Dist-Extras est executé en tant qu'utilisateur..."
DISPLAYMANAGER=$( search_dm | sed "s/.*\/\(.*\).conf/\1/g" ) 
[[ -z $DISPLAYMANAGER ]] && DISPLAYMANAGER="?" && msg_info "Display manager not found ! (sddm/lightdm/lxdm/slim/nodom)"
# msg_n "%s" "$NUM_REBOOT"
choix2do "$@"
exit 0; 
# decompte "3" "%s" "Termine !"
