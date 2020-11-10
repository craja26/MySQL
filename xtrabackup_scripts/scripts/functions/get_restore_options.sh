echo "*************************** Loading Restore Options *************************************"
TODAY=$(date +%Y%m%d)

declare HAS_PIGZ=0
declare BACKUP="xtrabackup"
declare COMPRESS_PRG="pigz"
declare FULLONLY=0
declare USE_RECENT_FULL=1
declare STOPAT=""
declare EPOCH_STOPAT
declare DEFAULT_FILES="/etc/mysql/my.cnf"
declare PREPARE_ONLY=0
declare RESTORE_ACTION=" --copy-back " 

declare  FULLBACKUP 
declare  INCRBACKUPS
 

##############################################################################################################
# parse options  
 ##############################################################################################################
OPTS=$(getopt -o h:   --long "fullonly,prepare-only,use-xtrabackup,--move-back, backupdate:,stopat:,default-files:,backuphome:" -n "$0"    -- "$@")
eval set -- "$OPTS"
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
# extract options and their arguments into variables.
while true ; do
    case "$1" in
        --fullonly ) FULLONLY=1 ; shift ;;
        --use-xtrabackup ) BACKUP="xtrabackup" ; shift ;;
        --prepare-only ) PREPARE_ONLY=1; shift ;;
        --move-back) RESTORE_ACTION=" --move-back " ; shift  ;;
        --backupdate ) USE_RECENT_FULL=0  ;BACKUPDATE="$2";  shift 2 ;;
        --stopat) STOPAT=$2 ; shift 2 ;;
        --default-files ) DEFAULT_FILES=$2 ; shift 2 ;;
        --backuphome) BACKUPHOME=$2 ; shift 2 ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done
 
################################################################################################

# Setup  backup filesystem paths
 
declare FULLDIR="$BACKUPHOME/full"
declare INCREMENTALDIR="$BACKUPHOME/incremental"
declare RESTORE_FULL="$RESTOREHOME/full"
declare RESTORE_INCR="$RESTOREHOME/incremental"

################################################################################################

# check selected backup program is installed
command -v "$BACKUP"  > /dev/null 2>&1 ||  { echo "$BACKUP  not found. Aborting; exit" ;}   
command -v pigz  > /dev/null 2>&1  || { echo "pigz not found using gzip" ; COMPRESS_PRG="gzip" ;}

# this must be first option" 
OPTIONS+=" --defaults-file=$DEFAULT_FILES "
#OPTIONS+=" --user=$DBUSER"
#OPTIONS+=" --password=$DBUSERPASS"
OPTIONS+=" --socket=$SOCKET" 

# stat --file-system --format=%T /var/

echo "*************************** Completed Loading Restore Options *************************************"
