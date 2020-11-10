echo "*************************** Loading Backup Options *************************************"

OPTS=`getopt -o h::  --long backuphome:,offsitehome:,default-files:,database:,full,incremental,skip-compress,use-xtrabackup  -n 'driver'  -- "$@"`
eval set -- "$OPTS"

declare  SKIP_COMPRESS=0
declare  USE_GZIP=0
declare  HAS_PIGZ=0
declare  BACKUP="xtrabackup"
declare  COMPRESS_PRG="pigz"
declare  DATABASE=""

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        --backuphome) BACKUPHOME=$2 ; shift 2 ;;
        --offsitehome) OFFSITEDIR=$2 ; shift 2 ;;
        --default-files) DEFAULT_FILES=$2 ; shift 2 ;;
        --database) DATABASE=$2; shift 2;;
        --full)  BACKUPTYPE="full"  ; shift 1 ;;
        --incremental) BACKUPTYPE="incremental"  ; shift 1 ;; 
        --use-xtrabackup ) BACKUP="xtrabackup" ; shift 1;;
        --skip-compress) SKIP_COMPRESS=1; shift 1;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done # end option selection

TODAY=$(date +%Y%m%d)
 
# check if host is: a slave or a member of a Galera cluster and has qpress installed
#IS_SLAVE_NODE=$(mysql -u "$DBUSER" -p"$DBUSERPASS" -sN -e "select variable_value from information_schema.global_status where variable_name = 'Slave_running'" )
#IS_GALERA_NODE=$(mysql -u "$DBUSER" -p"$DBUSERPASS" -sN -e "select variable_value from information_schema.global_status where variable_name = 'wsrep_connected'")

# check if pigz is installed.
command -v pigz  > /dev/null 2>&1  || { echo "pigz not found using gzip" ; COMPRESS_PRG="gzip" ;}
command -v "$BACKUP"  > /dev/null 2>&1 ||  { echo "$BACKUP  not found. Aborting; exit" ;}   


# this must be first option
OPTIONS+=" --defaults-file=$DEFAULT_FILES "
OPTIONS+=" --backup "

OPTIONS+=" --user=$DBUSER"
OPTIONS+=" --password=$DBUSERPASS"
OPTIONS+=" --parallel=$MXTHREADS "
OPTIONS+=" --stream=xbstream "
OPTIONS+=" --socket=$SOCKET " 


if [  "$DATABASE"x != "x" ]; then
   OPTIONS+=" --databases=$DATABASE "
fi

#if [ "$IS_GALERA_NODE" == "on" ]; then
#      OPTIONS+=" --galera-info" 
#  fi

#if [ "$IS_SLAVE_NODE" == "on" ]; then
#    OPTIONS+=" --safe-slave-backup --slave-info "
#fi

    
# Set the directory for backups
declare BACKUPDIR=$BACKUPHOME
declare FULLDIR=$BACKUPHOME/full
declare INCREMENTALDIR=$BACKUPHOME/incremental
declare LOGDIR=$BACKUPHOME/logs 

# stat --file-system --format=%T /var/

echo "*************************** Completed Loading Backup Options*************************************"
