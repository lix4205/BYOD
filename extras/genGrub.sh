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

declare -A tab_disk=( [a]="0" [b]="1" [c]="2" [d]="3" [e]="4" [f]="5" [g]="6"	[h]="7" [i]="8" [j]="9"	[k]="10" [l]="11"	[m]="12" [n]="13" 	[o]="14" [p]="15" [q]="16" [r]="17" [s]="18" [t]="19" [u]="20" [v]="21" [w]="22" [x]="23" [y]="24" [z]="25" )

declare -A tab_part_type=(
	[vfat]="part_msdos\n\tinsmod fat"
	[ext4]="ext2"
# 	[]=""
# 	[]=""
# 	[]=""
# 	[]=""
# 	[]=""	
)

get_infos () {
	findmnt -ecvruno SOURCE,TARGET,FSTYPE,OPTIONS "$1" |
	while read -r src target fstype opts; do
	
#		lsblk didn't return UUIDs...
#		so we have to run genGrub with root permission
# 		UUID="$( blkid | grep $src | sed "s/.* UUID=\"/UUID=/" | sed "s/\".*//"  )"
		UUID="$( lsblk -rno UUID "$src" )"
		case $2 in
			id) echo $UUID;;
			format) echo $fstype ;;
			disk) echo $src;;
		esac
	done
}

RACINE="$1"
UUID_ROOT=
PATH_KERNEL=

[ "$2" != "" ] && NAME_MACHINE=" ( $2 )"

# if [ ! -e $RACINE/boot ];then
# 	printf "==> ERROR : Can't find boot directory !"
# 	exit 1
# fi<

! mountpoint -q $RACINE && printf "Aucun point de montage trouvé sur \"%s\"\n" "$RACINE" && exit 1
if mountpoint -q $RACINE/boot; then
	GRUB_ROOT="$RACINE/boot"
else
	GRUB_ROOT="$RACINE"
	PATH_KERNEL="/boot"
fi
UUID=$( get_infos "$GRUB_ROOT" "id" )
TYPE_PART=$( get_infos "$GRUB_ROOT" "format" )
DISK=$( get_infos "$GRUB_ROOT" "disk" )  
# echo "dsdd $GRUB_ROOT"
UUID_ROOT=$( get_infos "$RACINE" "id" )
GRUB_PARTITION="${DISK:${#DISK}-1:${#DISK}-1}"
# GRUB_DISK=${tab_disk[$( echo ${DISK:${#DISK}-2:${#DISK}-1} | sed "s/$GRUB_PARTITION//" )]}
WIN_LETTER=${DISK:${#DISK}-2:${#DISK}-1}
GRUB_DISK=${tab_disk[${WIN_LETTER//$GRUB_PARTITION/}]}

# findmnt -ecvruno SOURCE,TARGET,FSTYPE,OPTIONS "$GRUB_ROOT"
# echo $WIN_LETTER | sed "s/$GRUB_PARTITION//" 
# echo ${WIN_LETTER//$GRUB_PARTITION/}
# # | sed "s/$GRUB_PARTITION//" 
# exit
# 	echo $UUID_ROOT
# echo "$TYPE_PART"
# echo "$UUID"
# echo "$DISK"
		
DISK="hd$GRUB_DISK,msdos$GRUB_PARTITION"
	
cat <<EOF 
# ==> Add this in /etc/grub.d/40_custom and update GRUB

menuentry 'Arch Linux$NAME_MACHINE' --class arch --class gnu-linux --class gnu --class os \$menuentry_id_option 'gnulinux-linux-advanced-$UUID_ROOT' {
	load_video
	set gfxpayload=keep
	insmod gzio
	insmod $( echo -e ${tab_part_type[$TYPE_PART]})
	set root='$DISK'
	if [ x\$feature_platform_search_hint = xy ]; then
	search --no-floppy --fs-uuid --set=root --hint-bios=$DISK --hint-efi=$DISK --hint-baremetal=ahci$GRUB_DISK,msdos$GRUB_PARTITION $UUID
	else
	search --no-floppy --fs-uuid --set=root $UUID
	fi
	echo    'Chargement de Linux linux…'
	linux   $PATH_KERNEL/vmlinuz-linux root=UUID=$UUID_ROOT rw quiet
	echo    'Chargement du disque mémoire initial…'
	initrd   $PATH_KERNEL/initramfs-linux.img
}

submenu 'Arch Linux$NAME_MACHINE' {
	menuentry 'Arch Linux$NAME_MACHINE' --class arch --class gnu-linux --class gnu --class os \$menuentry_id_option 'gnulinux-linux-advanced-$UUID_ROOT' {
		load_video
		set gfxpayload=keep
		insmod gzio
		insmod $( echo -e ${tab_part_type[$TYPE_PART]})
		set root='$DISK'
		if [ x\$feature_platform_search_hint = xy ]; then
		search --no-floppy --fs-uuid --set=root --hint-bios=$DISK --hint-efi=$DISK --hint-baremetal=ahci$GRUB_DISK,msdos$GRUB_PARTITION $UUID
		else
		search --no-floppy --fs-uuid --set=root $UUID
		fi
		echo    'Chargement de Linux linux…'
		linux   $PATH_KERNEL/vmlinuz-linux root=UUID=$UUID_ROOT rw quiet
		echo    'Chargement du disque mémoire initial…'
		initrd   $PATH_KERNEL/initramfs-linux.img
	}
	
	menuentry 'Arch Linux$NAME_MACHINE' --class arch --class gnu-linux --class gnu --class os \$menuentry_id_option 'gnulinux-linux-advanced-$UUID_ROOT' {
		load_video
		set gfxpayload=keep
		insmod gzio
		insmod $( echo -e ${tab_part_type[$TYPE_PART]})
		set root='$DISK'
		if [ x\$feature_platform_search_hint = xy ]; then
		search --no-floppy --fs-uuid --set=root --hint-bios=$DISK --hint-efi=$DISK --hint-baremetal=ahci$GRUB_DISK,msdos$GRUB_PARTITION $UUID
		else
		search --no-floppy --fs-uuid --set=root $UUID
		fi
		echo    'Chargement de Linux linux…'
		linux   $PATH_KERNEL/vmlinuz-linux root=UUID=$UUID_ROOT rw quiet
		echo    'Chargement du disque mémoire initial…'
		initrd   $PATH_KERNEL/initramfs-linux-fallback.img
	}
}
EOF
exit
cat <<EOF 
menuentry 'Arch Linux$NAME_MACHINE' --class arch --class gnu-linux --class gnu --class os \$menuentry_id_option 'gnulinux-linux-advanced-$UUID_ROOT' {
	load_video
	set gfxpayload=keep
	insmod gzio
	insmod $( echo -e ${tab_part_type[$TYPE_PART]})
	set root='$DISK'
	if [ x\$feature_platform_search_hint = xy ]; then
          search --no-floppy --fs-uuid --set=root --hint-bios=$DISK --hint-efi=$DISK --hint-baremetal=ahci$GRUB_DISK,msdos$GRUB_PARTITION $UUID
	else
          search --no-floppy --fs-uuid --set=root $UUID
	fi
	echo    'Chargement de Linux linux…'
	linux   $PATH_KERNEL/vmlinuz-linux root=UUID=$UUID_ROOT rw quiet
	echo    'Chargement du disque mémoire initial…'
	initrd   $PATH_KERNEL/initramfs-linux.img
}
EOF
exit
