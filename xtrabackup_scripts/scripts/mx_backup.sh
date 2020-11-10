#!/bin/bash

## Master Script for Backup

# Print out command traces prior to execution
set -u

TEMP=`getopt -o h: --long BACKUPHOME:,default-file:,full,incremental -n 'driver'  -- "$@"`
 
PWD=$(cd `dirname $0` && pwd)
echo "Present Working Directory: ${PWD}"

# Include the Default File
source "$PWD"/functions/defaults.sh

# Include the Backup Options
source "$PWD"/functions/get_backup_options.sh

# Include the Backup Functions
source "$PWD"/functions/mx_backupFunctions.sh

 
declare DEBUG="no"

# Switch statement to allow us to pick a backup method
case "$BACKUPTYPE" in
    full)

        # Check if we have a backup running
        isFullRunning

        # Check if the working directories exist
        # and create them if they don't
        checkDirectories
        
        # remove existing checkpoint directories
        removeCheckpoints

        # Recreate the log file and rename the old log
        manageLogs

        # Take a full backup
        streamfullBackup

        # Move the backup off site
        # moveBackups

        # Clean the old backups
        cleanBackups
            ;;
    incremental)
      # Check if we have a backup running
        isIncrementalRunning

        # Check if the working directories exist
        # and create them if they don't
        checkDirectories

        # Take an incremental backup
        streamincrementalBackup

        # Move the backup off site
        # moveBackups
                ;;
esac # End the case

# Shift to the next command argument

exit 0

