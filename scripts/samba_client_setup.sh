#!/usr/bin/env bash

set -ex

echo '##########################################################################'
echo '############### About to run samba_client_setup.sh script ##################'
echo '##########################################################################'

yum -y install samba samba-client cifs-utils

mkdir -p /mnt/backups

groupadd --gid 2000 sambagroup
usermod -aG sambagroup root

# mount -t cifs -o user=samba_user1,password=password123 //samba-storage.local/export_rw /mnt/export/
