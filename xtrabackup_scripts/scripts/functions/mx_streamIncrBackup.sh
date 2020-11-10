function streamincrementalBackup()
{
    echo -e "\e[1;33m ********** Starting the incremental backup **********\e[0m"
    declare BACKUPNAME="$(date +%Y%m%d_%H%M)"
    declare BACKUPFILE=$BACKUPNAME-incremental.gz
    declare OPTIONS="$OPTIONS  --history=$BACKUPNAME  --extra-lsndir=$INCREMENTALDIR/checkpoints/$BACKUPNAME "
    declare RECENTFULL=$(find $FULLDIR/checkpoints -maxdepth 1 -mindepth 1 -type d | sort -nr | head -1)
    declare RECENTINCR=$(find $INCREMENTALDIR/checkpoints -maxdepth 1 -mindepth 1 -type d | sort -fnr | head -1)
        declare STARTTIME="$(date +%s)"
        declare -i i=0
        declare -i result=1
        declare -i restoreFromFull=0

    echo "IN ${FUNCNAME[0]} $OPTIONS"

    # Create a lockfile since we have the directory that we're going to work on
    touch $BACKUPDIR/.inc-lockfile

        # Handle the case that we have no incremental backup
        if [ "$RECENTINCR" == "" ] && [ -d "$RECENTFULL" ]; then
                restoreFromFull=1
                echo -e "\nRestoring from the last full backup.\n"
        elif [ "$RECENTFULL" == "" ] && [ -d "$RECENTINCR" ]; then
        # Handle the case that we have no full backup and an incremental exists
                restoreFromFull=0
        elif [ -f "$BACKUPDIR/.full-lockfile" ]; then
        # Handle the case that the full backup is running and we need to increment from the last incremental
                restoreFromFull=0
        # Else compare the full and incremental backups
        elif [ $(stat -c %Y $RECENTFULL) -gt $(stat -c %Y $RECENTINCR) ]; then
                restoreFromFull=1
                echo -e "\nRestoring from the last full backup.\n"
        fi

    # set basedir for incremental backup
    if [ $restoreFromFull -eq 1 ]; then
        BASEDIR=$RECENTFULL
     else
        BASEDIR=$RECENTINCR
    fi
        echo -e  "\e[1m Incremental backup Directory \e[33m $INCREMENTALDIR/$BACKUPFILE \e[0m"

        until [ $i -eq $INCRETRY  ] || [ $result -eq 0 ]; do
                # Attempt the incremental backup
        echo -e "\e[1m Taking the backup from: $BASEDIR \e[0m"
        "$BACKUP" $OPTIONS   --incremental-basedir=$BASEDIR  | "$COMPRESS_PRG" >  $INCREMENTALDIR/$BACKUPFILE

        # Grab the result
        result=$?

        if [ $result -ne 0 ]; then
            echo -e "\e[1;31m \nThe incremental backup failed, removing the following backup file:\n\e[0m"

            # Show the user what we'll remove
            find $INCREMENTALDIR/$BACKUPFILE  -maxdepth 1 -mindepth 1 -type f

            # Sleep for a 5 seconds
            sleep 5

            # Remove the backup file and checkpoint folder
            find $INCREMENTALDIR/$BACKUPFILE  -maxdepth 1 -mindepth 1 -type f   -exec rm -rf {} \;
            find $INCREMENTALDIR/checkpoints  maxdepth 1 -mindepth 1 -type d -name $BACKUPNAME  -exec rm -rf {} \;
        fi

                # Increment the counter
                i=$[$i+1]
        done

        # Grab the amount of time taken
        declare ENDTIME="$(($(date +%s)-$STARTTIME))"

        # If we're this far the incremental backup was a success, remove the lock file
        rm $BACKUPDIR/.inc-lockfile

        # Check if we failed and take action
        if [ $result -eq 1 ] ; then
                echo "The incremental backup failed after $INCRETRY attempts and $ENDTIME seconds. Emailing the DBA and exiting."
                emailStaff "Please review the logs in the log directory: $LOGDIR" "MySQL incremental backup failure on $HOSTNAME"
                exit 1
        fi

    echo -e "\e[1m ********** Incremental backup $BACKUPNAME completed in: ${ENDTIME} seconds **********\e[0m"

    #Send Completion Email
    echo "Sending Incremental Backup Completion Email."
    emailStaff "MySQL Incremental Backup Completed Successfully on $HOSTNAME in: ${ENDTIME} seconds **********" "MySQL Incremenatl backup Completed Successfully on $HOSTNAME"

}
# End Incremental backups
