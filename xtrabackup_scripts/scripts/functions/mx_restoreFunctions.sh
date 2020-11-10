# Function to restore the database
############################################################################################################################################################################################
# Prepare backup files
############################################################################################################################################################################################
function prepareBackups()
{

# Setup Full and incremental backup variables #
    declare FULLBACKUP=$(find  "$RESTORE_FULL"    -maxdepth 1 -mindepth 1 -type d   | sort -nr | head -n 1)
    declare INCRBACKUPS=$(find  "$RESTORE_INCR" -maxdepth 1 -mindepth 1 -newer $FULLBACKUP -type d   | sort -n)
    
    RESTORE_TARGET="$FULLBACKUP"    
   
	# Full backup steps:
	echo -e "\n\e[01;33m-- Preparing the full backup --\e[00m\n"
    
    # 1. prepare full backup 
    if [ "$FULLONLY" -eq 1   -o   "$INCRBACKUPS"x == "x" ]; then 
         $BACKUP $OPTIONS  --prepare --target-dir="$FULLBACKUP"
    else 
	    $BACKUP $OPTIONS  --prepare --apply-log-only  --target-dir="$FULLBACKUP"   
     fi
	# Check if the previous action failed
	if [ $? -gt 0 ]; then
		echo -e "\e[1,31mPreparing the full backup failed. \e[0m"
        exit
	fi
	
    # 2 prepare incremental backups
    if [ $FULLONLY -eq  0 ]; then 
        echo -e "\n\e[01;33m-- Replaying the subsequent transactions --\e[00m\n"
        for INCDIR in $INCRBACKUPS; do
            # Replay the transactions against the full database order
            "$BACKUP" $OPTIONS  --prepare  --apply-log-only  --target-dir=$FULLBACKUP --incremental-dir=$INCDIR
            
            # Check if the previous action failed
            if [ $? -gt 0 ]; then
                echo "Rolling back the uncommitted transactions failed."
                exit
            fi
            
            sleep 5
        done
	fi
} # End prepare_backups
############################################################################################################################################################################################
# Explain the steps that will be taken by the restore script
############################################################################################################################################################################################
 
