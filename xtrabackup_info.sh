
1) xtrabackup Installation

Follow the link and install the supported version as per MySQL Version

https://www.percona.com/doc/percona-xtrabackup/2.4/installation.html


2)  Create MySQL backup User
Create Percona DB, Backupuser and assign privileges
	CREATE DATABASE [IF NOT EXISTS] PERCONA_SCHEMA;
	GRANT RELOAD, PROCESS, SUPER, LOCK TABLES, REPLICATION CLIENT, CREATE TABLESPACE ON *.* TO 'backup'@'localhost' IDENTIFIED BY PASSWORD '<password>';
	GRANT SELECT, INSERT, CREATE ON `PERCONA_SCHEMA`.* TO 'backup'@'localhost';
	Flush privileges;
	
3)  copy scripts without any changes
# Please ensure that directory "functions" exist under scripts. If not then create using
mkdir functions

#Copy below to /data/mysql/scripts
mx_backup.sh
mx_restoreBackup.sh

#Copy below to /data/mysql/scripts/functions
Copy mx_backupFunctions.sh
mx_cleanBackups.sh
mx_restoreFunctions.sh
mx_stageFunctions.sh
mx_streamfullBackup.sh
mx_streamIncrBackup.sh to

4) change parameters in accordance with the Environment
#Copy below to /data/mysql/scripts/functions

defaults.sh
get_backup_options.sh
get_restore_options.sh

Note: Scripts are using pigz for compression and decompression. Please install it or change zip mechanism according to current environment.


## Backup example:
  xtrabackup --backup --user=<user> --password=<password> --target-dir=/backup/mysql_backup/
## Restore sample steps:
1. We need to prepare backup file before run restore command.
  xtrabackup --prepare --user=<user> --password=<password> --target-dir=/backup/mysql_backup/
2. We can use --copy-back or --move-back parameter to restore databases.
  xtrabackup --move-back --user=rchikkala --password=D3v1l@27 --target-dir=/backup/mysql_backup/db9/


## Configure replication
- we can find bin-log number and master_log_position in xtrabackup backup file.
1. We need to create a replication user on master server.
  CREATE USER 'replication'@'<slave_ip>' IDENTIFIED BY '<password>';
	GRANT REPLICATION SLAVE ON *.* TO 'replication'@'<slave_ip>';
2. Run change master command.
  CHANGE MASTER TO MASTER_HOST='<master host ip>', MASTER_USER='replication', MASTER_PASSWORD='<password>', MASTER_LOG_FILE='mysql-binlog.000149', MASTER_LOG_POS=67598339;
3. Run start slave command.
  START SLAVE;
4. check replication status.
  SHOW SLAVE STATUS\G
 

## Backup and restore using xtrabackup XBStream and pigz.
# Backup using xbstream and pigz
	xtrabackup   --defaults-file=/etc/my.cnf  --backup  --user=backup --password=<password> --parallel=1  --stream=xbstream  --socket=/data/mysql/mysql.sock   --history=YYYYMMDD_HHMM  --extra-lsndir=/backup/mysql_backup/full/checkpoints/YYYYMMDD_HHMM   |  pigz  -1  > /backup/mysql_backup/full/YYYYMMDD_HHMM-full.gz
 
# Unzip backup file
	unpigz  -c  /backup/mysql_backup/full/YYYYMMDD_HHMM-full.gz | xbstream   -x -C  /backup/mysql_restore/full/YYYYMMDD_HHMM-full
 
# Prepare backup
	xtrabackup  --defaults-file=/etc/my.cnf  --socket=/data/mysql/mysql.sock  --prepare --target-dir=/backup/mysql_restore/full/YYYYMMDD_HHMM-full

# copy-back or move-back
	xtrabackup  --defaults-file=/etc/my.cnf  --socket=/data/mysql/mysql.sock  --move-back --target-dir=/backup/mysql_restore/full/YYYYMMDD_HHMM-full
