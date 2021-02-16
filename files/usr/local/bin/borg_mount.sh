#!/usr/bin/env bash

##
## Source configuration
##

. /etc/borg_backup.conf

export BORG_RSH="${REPOSITORY_KEY}"

export BORG_PASSPHRASE="${REPOSITORY_PASS}"

REPOSITORY="ssh://${BACKUP_USER}@${REPOSITORY_HOST}:${REPOSITORY_PORT}/./${REPOSITORY_DIR}"

borg mount $REPOSITORY $1

export BORG_PASSPHRASE=''


