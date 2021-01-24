/********* mydumper **********/

# Installing mydumper 10.1 in centOS
wget https://github.com/maxbube/mydumper/releases/download/v0.10.1/mydumper-10.1-1.el7.x86_64.rpm
yum install mydumper-10.1-1.el7.x86_64.rp


# create a table to store backup history. I am using "maint" database for logging DBA tasks.  
create table mydumper_history (       
	uuid        varchar(40)   not null,
	hostname    varchar( 128)  not null,
	dbname      varchar(64) not  null,
	options     text        default null,
	start_time  timestamp   not null,
	end_time    timestamp   not  null,
	binlog_pos  varchar(128) default null,
	primary key (hostname, dbname, start_time)
) engine=Innodb;

# Grant access.  
GRANT SELECT, INSERT, UPDATE ON maint.mydumper_history TO 'backup'@'localhost' IDENTIFIED BY '<password>';

# GRANT RELOAD, PROCESS, SUPER, LOCK TABLES, REPLICATION CLIENT, CREATE TABLESPACE ON *.* TO 'backup'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, REFERENCES, INDEX, ALTER, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, EVENT, TRIGGER, CREATE TABLESPACE ON *.* TO 'backup'@'localhost';

GRANT SELECT, INSERT, CREATE ON 'mait'.* TO 'backup'@'localhost';

flush privileges;


# create a cron jobs
/data/mysql/scripts/mydumper/backupDatabases.sh > /backup/mysql_backup/mydumper_backup/logs/fullbackup_run_log 2>&1
/data/mysql/scripts/mydumper/backup_binlogs.sh > /backup/mysql_backup/mydumper_backup/logs/binlog_backup.log 2>&1

##.mydefault.cnf file
[mysql]
user=backup
password=<password>
socket=/data/mysql/mysql.sock

[mydumper]
user=backup
password=<password>
socket=/data/mysql/mysql.sock



/******** backupDatabases.sh ***********/
##Change variable values as per environment.

#!/bin/bash

declare      runTime            # date backup run
declare      BACKUPHOME="/backup/mysql_backup"
declare      LOGHOME="$BACKUPHOME/logs"
declare      DATABASE="%"
declare      DBNAME
declare      BKP_TIME=$(date '+%Y%m%d%H%M')   # date and time of backup; forms part of backup file name
declare  -i  CPUS
declare  -i  LOCAL_RETAIN_DAYS=2
declare  -i  LOG_RETAIN_DAYS=7
declare      LOCKFILE=".backup-running"

declare     SKIP_COMPRESS=0
declare     COMPRESS_PRG="pigz"
declare     DEFAULT_FILE="/data/mysql/scripts/mydumper/.mydefault.cnf"
declare     LOGFILE="$LOGHOME/backup_$BKP_TIME.log"
declare     BINLOG_POS
declare     START_TIME
declare     END_TIME

## MYDUMPER_OPTIONS
# user, password, socket in default file
declare  -i  M_ROWS=100000
declare  -i  M_VERBOSITY=3
declare  -i  M_THREADS=4
declare  -i  P_THREADS=4
declare      M_EXCLUDE='^(?!(test|sys))'


check_for_default_file() {
# exit if not found
if [ ! -e "$DEFAULT_FILE" ]; then
    echo "$DEFAULT_FILE not found"  >> "$LOGFILE"
    exit
fi
}

 check_backup_running () {
 if [ -e "$BACKUPHOME/$LOCKFILE" ]; then
    echo "Backup already running" >> "$LOGFILE"
    exit 1
 fi
}


allocate_backup_threads() {
## get number of cpus and subtract 2.  If less than 2 allocate only 1 thread to mydumper
CPUS=$(lscpu | grep -E '^CPU\(' | cut -f 2 -d ':' | sed -e 's/^[ \t]*//')

if [ $((CPUS   )) -gt 1 ]; then
  let M_THREADS="$CPUS"/2
else
  M_THREADS=1
fi
}


run_backup() {
### EXECUTE
# start new binary log
mysql  --defaults-file="$DEFAULT_FILE"  -e "flush binary logs"
BINLOG_POS=$(mysql  --defaults-file="$DEFAULT_FILE"  -NBe "show master status" )
START_TIME=$(date +%Y-%m-%d" "%H:%M:%S)
COMMAND_OPTIONS="R -E -l 120 -c  -C --trx-consistency-only  -t "$M_THREADS"  -v "$M_VERBOSITY" -r "$M_ROWS"  "
for DBNAME  in $(mysql  --defaults-file="$DEFAULT_FILE"  -e "show databases like '$DATABASE'" -N  -B); do
   runTime=$(date)
   # create lockfile
   touch  "$BACKUPHOME/$LOCKFILE"
   BACKUPDIR="$BACKUPHOME/mydumper/$DBNAME/$DBNAME-$BKP_TIME"

   if [ ! -d "$BACKUPDIR" ]; then
        mkdir -p "$BACKUPDIR"
    fi

    printf "%s\n" "Starting backup of $DBNAME to $BACKUPDIR at $runTime"

    mydumper -B "$DBNAME"  -R -E -l 120 -c  -C --trx-consistency-only  -t "$M_THREADS" -x "$M_EXCLUDE" -v "$M_VERBOSITY"  -o "$BACKUPDIR" -L "$LOGFILE" --defaults-file="$DEFAULT_FILE" -r "$M_ROWS"
    #  pigz -p "$P_THREADS"  $BACKUPDIR/*  &> "$LOGFILE" 2>&1

# start file cleanup
    printf "%s\n" "Cleaning Up Files on $BACKDIR Older Than $LOCAL_RETAIN_DAYS days"
    find $BACKUPHOME/mydumper/$DBNAME  -type d  -mtime +"$LOCAL_RETAIN_DAYS"  | xargs rm -rf
done
END_TIME=$(date +%Y-%m-%d" "%H:%M:%S)
mysql  --defaults-file="$DEFAULT_FILE"  -Dpercona_schema  << EOF
insert into percona_schema.mydumper_history (uuid, hostname, dbname, options, start_time, end_time, binlog_pos)
values (uuid(), "$HOST", 'SUMMARY', "$COMMAND_OPTIONS", "$START_TIME", "$END_TIME", RTRIM("$BINLOG_POS") )

EOF
}

cleanup() {
#remove lockfile
if [ -e "$BACKUPHOME/$LOCKFILE" ]; then
    rm "$BACKUPHOME/$LOCKFILE"
fi

# cleanup backup logs
find "$LOGHOME" -type f -name *.log -mtime +"$LOG_RETAIN_DAYS" | xargs rm -f

}

##  Main Program

check_for_default_file
check_backup_running
allocate_backup_threads
run_backup
cleanup


#### LOG WHEN THE BACKUP HAS COMPLETED
runTime=$(date);
printf "%s\n" "Stopping backup at $runTime"

exit
/***************/
