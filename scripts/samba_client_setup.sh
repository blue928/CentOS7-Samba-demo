#!/usr/bin/env bash

set -ex

echo '##########################################################################'
echo '############### About to run samba_client_setup.sh script ##################'
echo '##########################################################################'

yum -y install samba samba-client cifs-utils

mkdir -p /mnt/backups

groupadd --gid 2000 sambagroup
usermod -aG sambagroup root

# this checks for available shares
#smbclient -L //samba-storage.local -U samba_user1 <<EOF
#passowrd123
#EOF

# mount -t cifs -o user=samba_user1,password=password123 //samba-storage.local/export_rw /mnt/export/

echo '//samba-storage.local/bckp_storage /mnt/backups  cifs  username=samba_user1,password=password123,soft,rw  0 0' >> /etc/fstab
mount -a