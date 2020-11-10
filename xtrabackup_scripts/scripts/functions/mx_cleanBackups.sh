function cleanBackups()
{
        echo -e "\e[1m ********** Cleaning out the old backups and logs **********\e[0m"

        # Find the newest full backup that be removed
        declare oldFullFile=$(find $FULLDIR -maxdepth 1 -mindepth 1 -mtime +$RETENTIONDAYS  -type f  -name *-full.gz     | sort -nr | head -1)

        if [ -z "$oldFullFile" ]; then
       echo "No incremental backups to remove."
    else
                # Find the next newest full directory so that we can remove all of the incremental backups based on the oldest full
            declare nextOldFullFile=$(find $FULLDIR -maxdepth 1 -mindepth 1 -type f   -newer $oldFullFile  | sort -n | head -1)
                echo "Incremental backups to be removed:"
                find $INCREMENTALDIR -maxdepth 1 -mindepth 1 ! -newer $nextOldFullFile   -type f  -name *-incremental.gz

                # Re-find and delete the files
                find $INCREMENTALDIR -maxdepth 1 -mindepth 1 ! -newer $nextOldFullFile  -type f  -name *-incremental.gz   -exec rm -rf {} \;

                # Check if we failed and take action
                if [ $? -eq 1 ] ; then
                        echo "Unable to clean the incremental backups, emailing the admins"
                        emailStaff "Unable to clear out the old backups in: $INCREMENTALDIR. Please review the logs in $LOGDIR." "Unable to remove the old MySQL backups on: $HOSTNAME"
                fi
        fi

        # Find the old backups to remove
        echo "Full backups to be removed:"
        find $FULLDIR -maxdepth 1 -mindepth 1 -mtime +$RETENTIONDAYS   -type f  -name *-full.gz

        echo "Logs to be removed:"
        find $LOGDIR -maxdepth 1 -mindepth 1 -type f -mtime +$RETENTIONDAYS

#       echo "Offsite backups to be removed:"
#       find $OFFSITEDIR -maxdepth 1 -mindepth 1 -type f -mtime +$OFFSITERETENTIONDAYS

        # Re-find and delete the files
        find $FULLDIR -maxdepth 1 -mindepth 1 -mtime +$RETENTIONDAYS  -type f   -name *-full.gz   -exec rm -rf {} \;

        # Check if we failed and take action
        if [ $? -eq 1 ] ; then
                echo "Unable to clean the full backups, emailing the DBAs"
                emailStaff "Unable to clear out the old backups in: $FULLDIR. Please review the logs in $LOGDIR." "Unable to remove the old MySQL backups on: $HOSTNAME"
        fi

        find $LOGDIR -maxdepth 1 -mindepth 1 -type f -mtime +$RETENTIONDAYS -exec rm -rf {} \;

        # Check if we failed and take action
        if [ $? -eq 1 ] ; then
                echo "Unable to clean the logs, emailing the DBAs"
                emailStaff "Unable to clear out the old logs in: $LOGDIR. Please review the logs in $LOGDIR." "Unable to clean the MySQL backup logs on: $HOSTNAME"
        fi

#       find $OFFSITEDIR -maxdepth 1 -mindepth 1 -type f -mtime +$OFFSITERETENTIONDAYS -exec rm -rf {} \;

        # Check if we failed and take action
#       if [ $? -eq 1 ] ; then
#               echo "Unable to clean the offsite backups, emailing the DBAs"
#               emailStaff "Unable to clear out the offsite backups in: $BACKUPDIR. Please review the logs in $LOGDIR." "Unable to clean the offsite MySQL backups for $HOSTNAME"
#       fi

        echo "********** End backup and log cleaning **********"
}
