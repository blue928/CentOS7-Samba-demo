#!/usr/bin/env bash

set -ex

echo '##########################################################################'
echo '############### About to run samba_client_setup.sh script ##################'
echo '##########################################################################'

yum -y install samba samba-client

mkdir -p /mnt/backups





