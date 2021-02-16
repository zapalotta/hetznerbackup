#!/usr/bin/env bash

##
## Source configuration
##

. /etc/borg_backup.conf



export BORG_RSH="${REPOSITORY_KEY}"

export BORG_PASSPHRASE="${REPOSITORY_PASS}"

# We need the host key
# The ssh-keyscan and the known_hosts module won't work properly with a custom ssh port

ssh -p ${REPOSITORY_PORT} -i ~/.ssh/id_rsa_${BACKUP_USER} -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${REPOSITORY_HOST} > /dev/null 2>&1 

REPOSITORY="ssh://${BACKUP_USER}@${REPOSITORY_HOST}:${REPOSITORY_PORT}/./${REPOSITORY_DIR}"

borg init --encryption=repokey $REPOSITORY

export BORG_PASSPHRASE=''


