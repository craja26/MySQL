#! /bin/bash

echo "******************  Loading Default Values ***********************************"

declare HOST=$(hostname -s)
 
# The DBA to email upon error
declare ADMINEMAIL="<dba group email address>"			
declare EMAILADMINS=TRUE

# Set the database user and password
declare DBUSER="backup"
declare DBUSERPASS="<password>"					

# Set the retention policy for backups - in days
declare RETENTIONDAYS=3							
#declare OFFSITERETENTIONDAYS=7

# Set the number of times we retry a backup if it fails
declare FULLRETRY=2
declare INCRETRY=2

declare -l BACKUPTYPE="full"
declare -l DEFAULT_FILES="/etc/my.cnf"				

#declare -l GALERA_NODE
declare -l SLAVE_NODE
declare OPTIONS=""

# paths for backups and restores
declare BACKUPHOME="/backup/mysql_backup"
#declare OFFSITEDIR="/mnt/share"
declare RESTOREHOME="/mysql_backup/mysql_restore"
declare FULLDIR=""
declare INCREMENTALDIR=""
declare LOGDIR=""

declare DATADIR="/data/mysql/data"
declare SOCKET="/data/mysql/mysql.sock"

# compute number of threads the backup program can use
declare CPUS=$(grep -c ^processor /proc/cpuinfo )
declare USE_CPU=1
if (( 1 <="$CPUS" && "$CPUS" <= 7 ))
   then
        MXTHREADS=1
elif (( 8 <="$CPUS" && "$CPUS" <= 15 ))
   then
        MXTHREADS=4
else
        MXTHREADS=8
fi

echo "******************** Finished Loading Default Values ***************************"
