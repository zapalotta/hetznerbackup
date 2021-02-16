#!/usr/bin/env bash

##
## Setzten von Variablen
##



. /etc/borg_backup.conf


##
## Setzten von Umgebungsvariablen
##

## falls nicht der Standard SSH Key verwendet wird können
## Sie hier den Pfad zu Ihrem private Key angeben
# export BORG_RSH="ssh -i /home/userXY/.ssh/id_ed25519"


# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM



## Damit das Passwort vom Repository nicht eingegeben werden muss
## kann es in der Umgepungsvariable gesetzt werden
#export BORG_RSH='ssh -i /root/.ssh/id_rsa_hetznerbackup-sub2'
export BORG_RSH="${REPOSITORY_KEY}"

export BORG_PASSPHRASE="${REPOSITORY_PASS}"

## Hinweis: Für die Verwendung mit einem Backup-Account muss
## 'your-storagebox.de' in 'your-backup.de' geändert werden.

REPOSITORY="ssh://${BACKUP_USER}@${REPOSITORY_HOST}:${REPOSITORY_PORT}/./${REPOSITORY_DIR}"

#echo $REPOSITORY

#exit

##
## Ausgabe in Logdatei schreiben
##

exec > >(tee -i ${LOG})
exec 2>&1

echo "###### Backup gestartet: $(date) ######"

info "###### Backup gestartet: $(date) ######"

EXCLUDE_ARRAY=$(echo $EXCLUDE_FOLDERS | tr ' ' '\n')
EXCLUDE_PARAMS=""
for param in $EXCLUDE_ARRAY;
do
  EXCLUDE_PARAMS="$EXCLUDE_PARAMS --exclude ${param}"
done


##
## An dieser Stelle können verschiedene Aufgaben vor der
## Übertragung der Dateien ausgeführt werden, wie z.B.
##
## - Liste der installierten Software erstellen
## - Datenbank Dump erstellen
##

##
## Dateien ins Repository übertragen
## Gesichert werden hier beispielsweise die Ordner root, etc,
## var/www und home
## Ausserdem finden Sie hier gleich noch eine Liste Excludes,
## die in kein Backup sollten und somit per default ausgeschlossen
## werden.
##

echo "Übertrage Dateien ..."

borg create $REPOSITORY::"{$BACKUP_TIMESTAMP}" $INCLUDE_FOLDERS $EXCLUDE_PARAMS -v --stats 2>&1

#echo borg create                    \
#    $REPOSITORY::'{now:%Y-%m-%d_%H:%M}'  \
#    /root                                \
#    /etc                                 \
#    /var				 \
#    /boot				 \
#    /home                                \
#    /opt				 \
#    --exclude /dev                       \
#    --exclude /proc                      \
#    --exclude /sys                       \
#    --exclude /var/run                   \
#    --exclude /run                       \
#    --exclude /lost+found                \
#    --exclude /mnt                       \
#    --exclude /var/lib/libvirt           \
#    -v --stats 2>&1


# backup_exit=$?

echo "###### Backup beendet: $(date) ######"

echo "###### Pruning Backup: $(date) ######"

info "Pruning main repository"

borg prune                          \
    --list                          \
    --show-rc                       \
    --keep-daily    $KEEP_DAYLY     \
    --keep-weekly   $KEEP_WEEKLY    \
    --keep-monthly  $KEEP_MONTHLY   \
    $REPOSITORY

# prune_exit=$?

borg list $REPOSITORY

# Unset pass
export BORG_PASSPHRASE=''



