#!/usr/bin/env bash

set -ex

echo '##########################################################################'
echo '##### About to run samba_server_setup.sh script ##################'
echo '##########################################################################'


yum -y install samba samba-client

setsebool -P samba_export_all_ro on
setsebool -P samba_export_all_rw on
setsebool -P samba_share_nfs on

firewall-cmd --permanent --add-service=samba
systemctl restart firewalld


mv /etc/samba/smb.conf /etc/samba/smb.conf-orig
# this is to avoid an alias. 
/bin/cp -f /vagrant/files/smb.conf /etc/samba/smb.conf

useradd samba_user1
# note: need to sort out content of smb.conf before using the smbpasswd command. 
smbpasswd -a samba_user1 <<EOF
password123
password123
EOF


mkdir -p /samba/export_rw
semanage fcontext -at samba_share_t "/samba/export_rw(/.*)?"
restorecon -Rv /samba/export_rw

chown samba_user1:samba_user1 /samba/export_rw
chmod 775 /samba/export_rw


systemctl enable smb
systemctl start smb

exit 0