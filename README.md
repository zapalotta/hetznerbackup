Table of Contents
=================

   * [Purpose](#purpose)
      * [What this role does](#what-this-role-does)
   * [Prerequisites](#prerequisites)
   * [Supported Distros](#supported-distros)
   * [Storagebox Layout:](#storagebox-layout)
   * [Example hosts file](#example-hosts-file)
   * [Example playbook](#example-playbook)
   * [Usage](#usage)
      * [Creating the first backup](#creating-the-first-backup)
      * [Pre and post executing](#pre-and-post-executing)
   * [Installed scripts](#installed-scripts)
   * [Known Issues](#known-issues)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Purpose
Backup a linux machine to hetzner StorageBox using borg backup

Multiple machines can be backupped to the same storagebox. Each machine gets its own subaccount with its own password and ssh key.


## What this role does
* Create a Subaccount on the storage box
* Add neccessary ssh keys to the subaccount
* install borg backup on the target host
* install some helper scripts on the target host
* initialize borg backup repo on the storage box
* install cronjob for backup
* install some borg management scripts
* Set up logrotation for backup logs

# Prerequisites

* Hetzner Storagebox
* Ansible

# Supported Distros

It was tested on the following distros:
* debian 10
* univention corporate server 4.4
* ubuntu 20.04

It should be working on other distros, too, though the packagename `borgbackup` may need some changes.


# Storagebox Layout:

```
/.ssh/id_rsa_hetznerbackup              # Key to access the complete storage box. MUST exist before using this role. Variable: hetznerbackup_default_rsakey
/backups/				# Folder in the storagebox where all subaccounts are created. MUST exist before using this role. Variable: hetznerbackup_maindir
/backups/host1				# Folder for the host to be backupped, created by this role. Root folder of the machine's subaccount. Name is the hostname of the target machine
/backups/host1/.ssh                     
/backups/host1/.ssh/authorized_keys	# Created by this role. Allows access for borg from the target machine
/backups/host1/backup/			# Created by this role. Folder for the borg repo
/backups/host1/backup/<borg_repo>

```

# Example hosts file

```yaml
backuphosts:
  hosts:
    targethost
  vars:
    hetzner_webservice_user: "XXXXXXX"                                # Get from hetzner robot -> Settings -> Webservice user
    hetzner_webservice_pass: "XXXXXXX"
    hetzner_server_id: "123456"                                       # Get from hetzner robot -> Server. e.g. EX41S #123456
#    hetzner_storagebox_id: "98765"                                   # Optional, will be fetched automatically from the server ID
    hetznerbackup_master_user: uXXXXXXX                               # User of the main storagebox, usually someting like u123456
    hetznerbackup_master_storagebox: uXXXXXXX.your-backup.de          # Storagebox Hostname, usually the masterusername.your-backup.de
    hetznerbackup_default_rsakey: ~/.ssh/id_rsa_hetznerbackup         # Default rsa key for accessing the storagebox
    hetznerbackup_additional_include_dirs:                            # List of additional dirs to be backupped
      - "/tmp"
    hetznerbackup_additional_exclude_dirs:                            # List of additional dirs NOT to be backupped
      - "/foo"
    hetznerbackup_cron_hour: 1                                        # Hour for the backup cronjob
    hetznerbackup_cron_minute: 0                                      # Minute for the backup cronjob

    hetznerbackup_keydir: /tmp/hetznerbackup_keys                     # Directory on the admin host for secrets storage
```

# Example playbook


```yaml
#!/bin/env ansible-playbook

- name: Hetznerbackup
  hosts: all
  remote_user: root
  gather_facts: yes
  roles:
    - hetznerbackup

```

# Usage

Make sure that you can ssh to the master storagebox from the ansible machine. 

```
./ansible-playbook -i hosts.yml 
```

After running the playbook you will get some secrets on the ansible machine, see the last debug message. Keep them at a safe place

* ```host1.borgkey```
  * Borg keyfile
* ```host1_pass.txt```
  * Borg repo password
* ```id_rsa_host1```
* ```id_rsa_host1.pub```
  * Storagebox Subaccount ssh keypair

## Creating the first backup

Just run /usr/local/bin/borg_backup.sh on the target host to create the first backup. You can also leave this job to cron ...

## Pre and post executing 

Place executable scrips in ```/etc/borg_backup.d/preexec/```, these will be executed before the backup, e.g. DB dumps.

Place executable scrips in ```/etc/borg_backup.d/postexec/```, these will be executed after the backup, e.g. start services again


# Installed scripts

All scripts are installed in ```/usr/local/bin/```

* ```borg_backup.sh```
  * Create a backup
* ```borg_info.sh```
  * Get info of the existing backups
* ```borg_init.sh```
  * Initialize the repo
* ```borg_keyexport.sh /tmp/keyfile```
  * Export the borg key to the file
* ```borg_list.sh```
  * List existing backups
* ```borg_mount.sh /mnt```
  * Mount the borg repo 

All these scripts make use of the config file ```/etc/borg_backup.conf```. 

# Known Issues

* Borg-Backup 1.0 issues
  * Due to using UCS4 (Based on Debian 9) the scripts don't use features from Borg 1.1. Using 1.0 with a storagebox may produce issues. I need to implement a version check and add the borg version string to the scripts
* Only tested with root as ssh user (become should work, too, though I am running backups as root anyway)
* Monitoring is yet to come

