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

# Transform an Arch classic distribution to be bootable on pxe via NFS
# Set a /etc/mkinitcpio.conf to compile kernel for booting via network
#

arch2nfsroot() {
# 	CONFIGURATION NFS ROOT

	sed s/nfsmount/mount.nfs4/ "/usr/lib/initcpio/hooks/net" > "/usr/lib/initcpio/hooks/net_nfs4" &&
	cp /usr/lib/initcpio/install/net{,_nfs4} &&
	sed -i "s/BINARIES=(/BINARIES=(\/usr\/bin\/mount.nfs4 /g" /etc/mkinitcpio.conf &&
    sed -i "s/MODULES=(/MODULES=($LIST_MODULES /g" /etc/mkinitcpio.conf &&
	sed -i "s/ fsck//" /etc/mkinitcpio.conf &&
	sed -i "s/HOOKS=(/HOOKS=(net_nfs4 /g" /etc/mkinitcpio.conf &&

# sed -i "s/BINARIES=\"\"/BINARIES=\"\/usr\/bin\/mount.nfs4\"/g" /etc/mkinitcpio.conf
# sed -i "s/MODULES=\"\"/MODULES=\"$LIST_MODULES\"/g" /etc/mkinitcpio.conf
# sed -i "s/HOOKS=\"/HOOKS=\"net_nfs4 /g" /etc/mkinitcpio.conf

#	LOG CONFIG FOR NFS
	mv /var/log /var/_log &&
# 	rmdir /var/_log
	mkdir /var/log &&
	echo "tmpfs   /var/log        tmpfs     nodev,nosuid    0 0" >> /etc/fstab &&
# 	FOR CUPSD
	echo -e "# For Cups :\n#tmpfs   /var/spool/cups tmpfs     nodev,nosuid    0 0" >> /etc/fstab &&

	
	mkinitcpio -p linux &&

    return 0;
}

LIST_MODULES="nfsv4 atl1c forcedeth 8139too 8139cp r8169 e1000 e1000e broadcom tg3 sky2"

arch2nfsroot
