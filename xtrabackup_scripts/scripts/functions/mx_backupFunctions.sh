# Email functionality
##
function emailStaff()
{
	# Placeholder
	if [ $EMAILADMINS == TRUE ]; then
		echo "$1" | mail -s "$2" $ADMINEMAIL
	else
		echo "No emails will be sent for the error, per configuration setting."
	fi
}

# Check for running full backups
##
function isFullRunning()
{
	# Check if we're already taking a backup
	echo "********** Checking if a backup is already running **********"
	
	# Check if the full backup is running
	if [ -f "$BACKUPDIR/.full-lockfile" ]; then
		echo "********** Backup currently running, exiting. **********"
		exit 1
    fi

}

# Check for running incremental backups
##
function isIncrementalRunning()
{
	# Check if we're already taking a backup
	echo "********** Checking if a backup is already running **********"
	
	# Sleep for a bit - just to make sure we don't trip up a full
    ## This is also because we can't be sure that a full won't start slower
    sleep 10
	
	# Check if the incremental backup is running
	if [ -f "$BACKUPDIR/.inc-lockfile" ] || [ -f "$BACKUPDIR/.full-lockfile" ]; then
		echo "********** Backup currently running, exiting. **********"
		exit 1
    fi

}

# Check if the backup directories exist
##
function checkDirectories()
{
	echo "********** Checking if the directories exist **********"
	# Check if the full directory exist
	# and create it if it doesn't
	if [ ! -d "$FULLDIR" ]; then
		# Control will enter here if $DIRECTORY doesn't exist.
		echo "Making a full backup directory."
		mkdir -p $FULLDIR
	fi
	
    # Check if the full checkpoints directory exist
	# and create it if it doesn't
	if [ ! -d "$FULLDIR/checkpoints" ]; then
		# Control will enter here if $DIRECTORY doesn't exist.
		mkdir -p $FULLDIR/checkpoints
	fi
    
	# Check if the incremental directory exists
	# and create it if it doesn't
	if [ ! -d "$INCREMENTALDIR" ]; then
		# Control will enter here if $DIRECTORY doesn't exist.
		echo "Making an incremental backup directory."
		mkdir -p  $INCREMENTALDIR
	fi
	
    # Check if the incremental checkpoints directory exists
	# and create it if it doesn't
	if [ ! -d "$INCREMENTALDIR/checkpoints" ]; then
		# Control will enter here if $DIRECTORY doesn't exist.
		echo "Making an incremental backup directory."
		mkdir -p $INCREMENTALDIR/checkpoints
     fi
        
	# Check if the log directory exists
	# and create it if it doesn't
	if [ ! -d "$LOGDIR" ]; then
		# Control will enter here if $DIRECTORY doesn't exist.
		mkdir -p $LOGDIR
	fi
	echo "********** End directory checks **********"
}

# Move the previous log to log.txt-todays-date
##
function manageLogs()
{
	echo "********** Managing the log files **********"
	
	# Move the log file to log-$date
	echo "Moving the old logfile."
	
	mv $LOGDIR/log.txt $LOGDIR/log.txt-`date '+%m-%d-%y'`	

	# Create the new log file
	touch $LOGDIR/log.txt
	
	echo "********** End log file management **********"
}

 
# Actual code to compress and move the backups offsite
## 
function moveBackupActions()
{
	# Change directory to the one given by moveBackups()
	cd $1
	
	# Declare the most recent backup in the directory
	declare TEMPDIR=$(find . -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort -nr | head -n 1)
	
	# Tar the file and verify the contents of the tar file versus those on disk
	echo "*** Taring and compressing the most recent backup ***"
	time tar   -czvpf "$TEMPDIR-$2.tar.gz" "$TEMPDIR"
	
	# Test writing to the offsite directory
	touch $OFFSITEDIR/.offsite-test
	
	# Offsite directory check - see if the offsite directory is writable
	if [ $? -ne 0 ]; then
		emailStaff "Unable to write to the remote directory, exiting" "Offsite copy issue"
		exit 1
	else
		rm $OFFSITEDIR/.offsite-test
	fi
	
	# Move the backups
	for fileName in $(find . -maxdepth 1 -mindepth 1 -name "*.tar.gz" -type f -printf "%f\n" | sort -nr); do
		
		echo "The next file to move offsite is: $fileName\n"
		
		# Declare the local backup sum
		declare LOCALBACKUPSUM=`md5sum $fileName | awk '{print $1}'`
		
		# Copy the gziped tar offsite
		echo "*** Copying the compressed local backup offsite ***"
		rsync --verbose --progress "$fileName" $OFFSITEDIR
		
		# Check if we failed and take action
		if [ $? -eq 1 ] ; then
			echo "There was an issue when trying to copy the backup offsite, emailing the admin and exiting."
			emailStaff "Please review the offsite in the log directory: $LOGDIR" "MySQL incremental backup failure on $HOSTNAME"
			return 1
		fi
		
		# Create the remote backup sum
		declare REMOTEBACKUPSUM=`md5sum $OFFSITEDIR/$fileName | awk '{print $1}'`
		
		echo "*** Comparing the offsite backup to the on-disk backup ***"
		echo "MD5 sum on disk: $LOCALBACKUPSUM and offsite: $REMOTEBACKUPSUM"
		
		# Check if the md5 sum of the files are the same
		if [ "$LOCALBACKUPSUM" == "$REMOTEBACKUPSUM" ]; then
			# Since they are the same we'll remove the local zipped file
			echo "The files are identical, removing the local copy"
			rm -v "$fileName"
			
		else # Alert the support staff
			echo "Emailing the staff as the local backup and offsite copy don't match."
			emailStaff "The local and offsite backups have different checksums, please review the backup logs: $LOGDIR" "Offsite MySQL backup copy issues on $HOSTNAME"
		fi
	done
	
	# Since they were the same and we have the backup offsite clean out the backup directory
	## check to make sure it isn't already removed
	echo "*** Removing files that are unnecessary for the next backup ***"
	for i in `ls $TEMPDIR | grep -v xtrabackup_checkpoints`; do
		echo "Removing: $TEMPDIR/$i"
		rm -rf $TEMPDIR/$i
		sleep 1
	done
	
	# Now remove any older directories
	echo "*** Removing files that are unnecessary for the next backup and leaving .tar.gz files in case of previous errors ***"
	for i in `ls . | grep -v $TEMPDIR | grep -v .tar.gz`; do
		echo "Removing: $i"
		rm -rf $i 
		sleep 1
	done
	
}

# moveBackups contains the logic to compress and move the files offsite
##
function moveBackups()
{
	echo "********** Starting to move the backups offsite **********"
	
	# We need to figure out which directory contains the newer file
	declare RECENTFULL=$(find $FULLDIR/checkpoints -maxdepth 1 -mindepth 1 -type d | sort -nr | head -1) # Grab the most recent full
    declare RECENTINCR=$(find $INCREMENTALDIR/checkpoints -maxdepth 1 -mindepth 1 -type d | sort -nr | head -1) # Grab the most recent incremental
	
	# If they both exist, compare and take a backup
	if [ -d "$RECENTFULL" ] && [ -d "$RECENTINCR" ]; then
		#Check if the full backup is newer - if so we're working with a full backup
		if [ $(stat -c %Y $RECENTFULL) -gt $(stat -c %Y $RECENTINCR) ]; then
			moveBackupActions $FULLDIR full
		else # We're working with an incremental backup
			moveBackupActions $INCREMENTALDIR incremental
		fi
	# If we don't have both directories check if we have a full and no incremental
	## and use the full backup
	elif [ -d "$RECENTFULL" ] && [ ! -d "$RECENTINCR" ]; then
		moveBackupActions $FULLDIR full
	# Else check if we have an incremental and no full and work with the incremental
	elif [ ! -d "$RECENTFULL" ] && [ -d "$RECENTINCR" ]; then
		moveBackupActions $INCREMENTALDIR incremental
	else # We have nothing to work with - it'd be weird to get this far
		echo "There appear to be no backups to move offsite. Exiting."
	fi
	
	echo "********** End backup moving **********"
}

function removeCheckpoints ()
{ 

# Step 1:  delete existing files in $FULLDIR/check points and $INCREMENTALDIR/checkpoints
rm -rf $FULLDIR/checkpoints/*
rm -rf $INCREMENTALDIR/checkpoints/*
    
}

# Include Directories

source "$PWD"/functions/mx_cleanBackups.sh
source "$PWD"/functions/mx_streamfullBackup.sh
source "$PWD"/functions/mx_streamIncrBackup.sh
