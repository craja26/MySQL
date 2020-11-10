############################################################################################################################################################################################
# check if directory exists
############################################################################################################################################################################################
function checkDirectory()  
{
  local  DIRECTORY=$1
  
    echo -e "\e[1m ********** Checking if the directories exist **********\e[0m"
	# Check if the full directory exist
	# and create it if it doesn't
	if [ ! -d "$DIRECTORY" ]; then
		# Control will enter here if $DIRECTORY doesn't exist.
		echo "Creating $DIRECTORY."
		mkdir $DIRECTORY
	fi
    if [ "$?" -ne 0 ]; then 
        echo -e "\e[1;31m $ Error creating $DIRECTORY \e[0m"
        exit
    fi
  }
 ############################################################################################################################################################################################ 
 
############################################################################################################################################################################################
# collects paths of backup files needed for restore
############################################################################################################################################################################################
function findBackups ()
{

# Setup Full and incremental backup variables #
if [ $USE_RECENT_FULL -eq 1 ]
then
     echo "Pulling Most Recent Full Backup"
     FULLBACKUP=$(find $FULLDIR -maxdepth 1 -mindepth 1 -type f -name *full*.* -printf "%f\n" | sort -nr | head -n 1)
else
      echo "Pulling full backup from $BACKUPDATE"
      FULLBACKUP=$(find $FULLDIR -maxdepth 1 -mindepth 1 -type f -newermt "$BACKUPDATE"  -name "*full*.gz" -printf "%f\n" | sort  | head -n 1)
      NEXTFULLBACKUP=$(find $FULLDIR  -maxdepth 1 -mindepth 1 -type f -newermt "$BACKUPDATE" -name "*full*.gz" | sort  | head -n2 | sort -r  | head -n 1)
      EPOCH_STOPAT=$(stat -c %Y $NEXTFULLBACKUP)
fi
# compute STOPAT date and time for incremental backups.  
#      echo " elements ${#FULLBACKUP[@]}"
if [  "$STOPAT"x == x ]; then
	if [ $USE_RECENT_FULL -eq 1 ];
	  then
		STOPAT="2050-12-31 23:59"
	  else 
		STOPAT=`date -d@"$EPOCH_STOPAT"` 
	fi 
fi
 
if [ $FULLONLY -eq 0 ];
then
  INCRBACKUPS=$(find $INCREMENTALDIR -maxdepth 1 -mindepth 1  -type f -newer "$FULLDIR/$FULLBACKUP" -name '*incr*.gz'   ! -newermt "$STOPAT"  -printf "%f\n" | sort)
fi

}
############################################################################################################################################################################################
# explain in the steps that will be taken by the restore script
############################################################################################################################################################################################
function explainStageSteps()
{

    if [ $FULLONLY -eq 0 ];
    then
       BACKUPTYPE="Full and Incremental "
    else
       BACKUPTYPE="Full Only"
    fi

    # Explain to the user the steps that will be implemented
    echo -e "\n\n\e[01;31m#### These are the actions that will be taken: ####\e[00m"
 
    echo -e "Backup Type: \e[1;33m$BACKUPTYPE\e[0m"
    if [ "$BACKUPDATE"x != x ]; then 
    echo -e "Backup from \e[1;33m$BACKUPDATE\e[0m"
    fi 
    echo -e "Ignore Backups older than \e[1;33m $STOPAT \e[0m"

    # Full backup to process:
    echo -e "\n\e[01;33m-- Full backup file --\e[00m\n"
    echo -e "\e[01;34m$FULLDIR/$FULLBACKUP\e[00m"

    # Incremental backups:
    echo -e "\n\e[01;33m-- Transaction files --\e[00m\n"
    for INCDIR in $INCRBACKUPS; do
            echo -e "\e[00;36m$INCREMENTALDIR/$INCDIR\e[00m"
    done

        # Ask the user if they want to continue
    echo -en "\n\e[01;31mDo you want to continue? (yes/no): \e[00m"
    read CONTINUE
    # Parse the user response
    if [ "$CONTINUE" == "yes" ]; then
        echo -e "\n\e[01;33mStarting the file prepare for database restorations...\e[00m\n"
    elif [ "$CONTINUE" == "no" ]; then
        echo "Exiting."
        exit 0
    else
        echo "Please respond with either yes or no."
        echo "Exiting."
        exit 0
fi

} # End explainSteps()

############################################################################################################################################################################################
# unzip and stream backup files to restore area
############################################################################################################################################################################################
function stageBackupFiles()
{

# delete old files from restore directories
    echo -e "\n\e[01;33m-- Deleting Old Backup files in $RESTORE_FULL --\e[00m\n"
    if [ "$(ls -A $RESTORE_FULL)" ];then
      rm -rf $RESTORE_FULL/*
    fi
    if [ "$(ls -A $RESTORE_INCR)" ];then
      rm -rf $RESTORE_INCR/*
    fi

    RESTORE_FOLDER="${FULLBACKUP%.*}"
    checkDirectory $RESTORE_FULL/$RESTORE_FOLDER
      
    echo -e "\n\e[01;33m-- copy the full backup $FULLDIR/$FULLBACKUP to $RESTORE_FULL/$RESTORE_FOLDER --\e[00m\n"
    unpigz  -c  $FULLDIR/$FULLBACKUP | xbstream   -x -C  $RESTORE_FULL/$RESTORE_FOLDER
    if [ "$?"  -gt 0 ]; then
        echo -e "\n\e[01;31m Staging of full backup failed \e[0m"
    exit 1
    fi 
    echo -e "\n\e[01;32m-- Staging of  $FULLDIR/$FULLBACKUP Completed Successfully --\e[00m\n"
    
    if [ $FULLONLY -eq 1 ]; then
      return  0
    fi

    echo -e "\n\e[01;33m-- Copying the subsequent transactions --\e[00m\n"
        for file in $INCRBACKUPS; do
             FOLDERNAME="${file%.*}"
             checkDirectory  $RESTORE_INCR/$FOLDERNAME
             unpigz  -c  $INCREMENTALDIR/$file | xbstream    -x -C  $RESTORE_INCR/$FOLDERNAME
             if [ "$?" -gt 0 ]; then
               echo -e "\n\e[01;31m Staging of transaction backup failed \e[0m"
               exit 1
             fi 
             echo -e "\n\e[01;32m-- Staging of  $INCREMENTALDIR/$file  Completed Successfully --\e[00m\n"
        done
    echo -e "\n\e[01;32m-- Staging of Backups Completed Successfully --\e[00m\n"
}
############################################################################################################################################################################################

