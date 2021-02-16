#!/usr/bin/env bash

# Source config file

. /etc/borg_backup.conf


info() { 
	printf "\n%s %s\n\n" "$( date )" "$*" >&2; 
}



export BORG_RSH="${REPOSITORY_KEY}"
export BORG_PASSPHRASE="${REPOSITORY_PASS}"

REPOSITORY="ssh://${BACKUP_USER}@${REPOSITORY_HOST}:${REPOSITORY_PORT}/./${REPOSITORY_DIR}"

exec > >(tee -i ${LOG})
exec 2>&1

echo "====== Starting Backup: $(date) ======"
info "====== Starting Backup: $(date) ======"


# Create list of exclude dirs

EXCLUDE_ARRAY=$(echo $EXCLUDE_FOLDERS | tr ' ' '\n')
EXCLUDE_PARAMS=""
for param in $EXCLUDE_ARRAY;
do
  EXCLUDE_PARAMS="$EXCLUDE_PARAMS --exclude ${param}"
done

echo "====== Starting pre exec scripts: $(date) ======"
info "====== Starting pre exec scripts: $(date) ======"

run-parts /etc/borg_backup.d/preexec/


borg create $REPOSITORY::"{$BACKUP_TIMESTAMP}" $INCLUDE_FOLDERS $EXCLUDE_PARAMS -v --stats 2>&1

echo "====== Backup finished: $(date) ======"

echo "====== Starting post exec scripts: $(date) ======"
info "====== Starting post exec scripts: $(date) ======"

run-parts /etc/borg_backup.d/postexec/

echo "====== Pruning Backup: $(date) ======"
info "====== Pruning Backup: $(date) ======"


borg prune                          \
    --list                          \
    --show-rc                       \
    --keep-daily    $KEEP_DAYLY     \
    --keep-weekly   $KEEP_WEEKLY    \
    --keep-monthly  $KEEP_MONTHLY   \
    $REPOSITORY

echo "====== Pruning finished: $(date) ======"
info "====== Pruning finished: $(date) ======"


echo "====== Status: $(date) ======"
info "====== Status: $(date) ======"

borg list $REPOSITORY

# create statusfiles for monitoring
borg list $REPOSITORY --short > $BORG_STATUSFILE 2>/dev/null
borg info $REPOSITORY::$(tail -n1 /var/borgstatus) > ${BORG_STATUSFILE}_info 2>/dev/null

# Unset pass
export BORG_PASSPHRASE=''


