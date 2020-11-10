#!/bin/bash

#set -v
#set -x

PWD=$(cd `dirname $0` && pwd)
echo "Present Working Directory: ${PWD}"

# Include the Default File
source "$PWD"/functions/defaults.sh

# Include the Stage Functions
source "$PWD"/functions/mx_stageFunctions.sh

# Include the Restore Options
source "$PWD"/functions/get_restore_options.sh

# Include the Restore Functions
source "$PWD"/functions/mx_restoreFunctions.sh


RESTORE_TARGET=""

##########################################################################################################################
# Step 1: test for restore directories and create if needed. Check for backup directory is done in get_restore_options
checkDirectory "$RESTORE_FULL"
checkDirectory "$RESTORE_INCR"
##########################################################################################################################

##########################################################################################################################
# Step. 2 find required backups and uncompress to restore directories
##########################################################################################################################

findBackups
explainStageSteps
stageBackupFiles

##########################################################################################################################
# Step. 3 prepare backups
##########################################################################################################################

prepareBackups
    
##########################################################################################################################
# Step. 4 copy restored files to data directory 
##########################################################################################################################


# check that data directory is empty
if [ "$(ls -A $DATADIR)" ]; then
     echo -e "\e[1;31mThe $DATADIR must be empty to restore backup\e[0m"
     DATA_DIR_EMPTY="no"
fi
 
if [ "$PREPARE_ONLY" -eq 0  ]; then
   if [ "$DATA_DIR_EMPTY" == "no" ]; then
        exit 1
   fi
    echo -e "\e[1;33m Starting  $RESTORE_ACTION  from $RESTORE_TARGET to $DATADIR \e[0m"
    $BACKUP $OPTIONS  $RESTORE_ACTION  --target-dir=$RESTORE_TARGET
else
    echo -e "\e[1m To complete restore, run the command \e[0m"
    echo -e  "\e[1m $BACKUP $OPTIONS  $RESTORE_ACTION  --target-dir=$RESTORE_TARGET \e[0m"
fi 
exit 0

