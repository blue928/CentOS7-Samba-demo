#!/usr/bin/env bash

set -ex

echo '##########################################################################'
echo '##### About to run samba_server_setup.sh script ##################'
echo '##########################################################################'


yum -y install samba samba-client

mkdir -p /samba/export_rw

setsebool -P samba_export_all_ro on
setsebool -P samba_export_all_rw on
setsebool -P samba_share_nfs on

semanage fcontext -at samba_share_t "/samba/export_rw(/.*)?"

restorecon -R /samba/export_rw

groupadd --gid 2000 sambagroup
chown nobody:sambagroup /samba/export_rw
chmod g+rwx /samba/export_rw

firewall-cmd --permanent --add-service=samba
systemctl restart firewalld

# this is to avoid an alias. 
/bin/cp -f /vagrant/files/smb.conf /etc/samba/smb.conf

useradd samba_user1
usermod -aG sambagroup samba_user1
usermod -aG sambagroup root


smbpasswd -a samba_user1 <<EOF
password123
password123
EOF

systemctl enable smb
systemctl start smb

exit 0