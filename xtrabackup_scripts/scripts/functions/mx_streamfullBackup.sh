function streamfullBackup()
{
    echo "********** Starting the full backup **********"
    
 echo "${OPTIONS}" 
    # Variable declarations
     declare BACKUPNAME="$(date +%Y%m%d_%H%M)"
     declare BACKUPFILE=$BACKUPNAME-full.gz
    # declare OPTIONS+=" --history=$BACKUPNAME " 
    # declare OPTIONS+=" --extra-lsndir=$FULLDIR/checkpoints/$BACKUPNAME "
     declare OPTIONS="$OPTIONS  --history=$BACKUPNAME  --extra-lsndir=$FULLDIR/checkpoints/$BACKUPNAME "
     declare STARTTIME="$(date +%s)"
     declare -i i=0
     declare -i result=1
   
echo "${OPTIONS}"
 # Create a lockfile since we have the directory that we're going to work on
    touch $BACKUPDIR/.full-lockfile
    echo -e  "\e[1m Full backup Directory \e[33m $FULLDIR/$BACKUPFILE \e[0m"    
    
    until [ $i -eq $FULLRETRY  ] || [ $result -eq 0 ]; do
        # Attempt a full backup
        "$BACKUP"  $OPTIONS  |  "$COMPRESS_PRG"  -1  > "$FULLDIR/$BACKUPFILE"

        # Grab the result
        # result=$?

        # Checking if a new checkpoint directory got created. This is to vaerify if the backup is successfull

        if [ -d "$FULLDIR/checkpoints/$BACKUPNAME" ]; then
        result=0
        fi


        if [ $result -ne 0 ]; then
                echo -e "\nThe full backup failed, removing the following directory:\n"
                # Show the user what we'll remove
                find $FULLDIR/$BACKUPFILE -maxdepth 1 -mindepth 1 -type f -mmin -1

                #Sleep for a 5 seconds
                sleep 5

                # Remove the backup file and checkpoint folders
                find $FULLDIR -name $BACKFILE -type f   -exec rm -rf {} \;
                find $FULLDIR/checkpoints  -type d -name $BACKUPNAME   -exec rm -rf {} \;
                
                # Remove lock file
                rm -f $BACKUPDIR/.full-lockfile
        fi
        # Increment the counter
        i=$[$i+1]
    done

        # Grab the amount of time taken
    declare ENDTIME="$(($(date +%s)-$STARTTIME))"

        # Remove the lock file
        rm $BACKUPDIR/.full-lockfile

        # Check if we fail and take action
        if [ $result -ne 0 ] ; then
                echo "The full backup failed after $FULLRETRY attempts and $ENDTIME seconds. Emailing the admin and exiting."
                emailStaff "Please review the logs in the log directory: $LOGDIR" "MySQL full backup failure on $HOSTNAME"
                exit 1
        fi
    # save backup_name for use by incremental backups
    
    echo "$BACKUPNAME" > $FULLDIR/checkpoints/$BACKUPNAME/backup_name
    echo "********** Full backup $BACKUPNAME completed in: ${ENDTIME} seconds **********"

    #Send Completion Email
    echo "Sending Full Backup Completion Email"
    emailStaff "MySQL full backup Completed Successfully on $HOSTNAME in: ${ENDTIME} seconds **********" "MySQL full backup Completed Successfully on $HOSTNAME"

} # End Full backups
 
