<<COMMENT1 The MySQL servers can be upgraded by performing either an INPLACE upgrade or LOGICAL upgrade.
The INPLACE upgrade involves shutting down the MySQL 5.7 server, replacing the old binaries with MySQL 8.0 binaries and then starting the MySQL 8.0 server on the old data directory.
The LOGICAL upgrade involves exporting SQL from the MySQL 5.7 version using a backup or export utility such as mysqldump/xtrabackup/mydumper installing the MySQL 8.0 binaries, and then applying the SQL to the new MySQL version.
COMMENT1
Following are the steps involved in to upgrade MySQL 5.7 to MySQL 8.0

Step 1. Run MySQL upgrade checker
The first step in upgrading to MySQL 8.0 is checking the upgrade preparedness of the existing MySQL 5.7 server.
Ensure the upgrade readiness of your current MySQL 5.7 server instance by performing the preliminary checks described below.
Run following command to check for any potential compatibility issues wrt databases.

# mysqlcheck -u root -p --all-databases --check-upgrade

If the utility did report any errors then needs to be fixed. If no errors then can be proceed with the upgrade of the server to MySQL 8.0.

Step 2. Backing up the Databases 
Take full backup of all the databases.

Step 3. Stop mysqld service of 5.7
# systemctl stop mysqld

Step 4. Rename MySQL data directory and backup configuration file
Now, backup data directory by running below command
	# mv /data/mysql /data/mysql_bak
Backup current configuration file 
	#mv /etc/my.cnf /etc/my_bk.cnf

Step 5. Install MySQL 8.0.x
Run following commands to install and update current MySQL 5.7.x version to MySQL 8.0.x version.
Below command will download the latest MySQL 8.0.x version shell software
#  wget https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell-8.0.22-1.el7.x86_64.rpm

Now, Install the downloaded MySQL shell
# rpm -ivh mysql-shell-8.0.22-1.el7.x86_64.rpm

Next, update the current 5.7.x version software to MySQL 8.0.x version by running following command.
# yum update --enablerepo=mysql80-community mysql-community-server

Step 6. Stop MySQL 8.0.x if already started and rename data directory and configuration file
# systemctl stop mysqld

Rename data directories back
# mv /data/mysql_bak /data/mysql

Rename configuration file
# mv /etc/my_bak.cnf /etc/my.cn

Step 7. Start MySQL service
Now, Start MySQL service and it will automatically upgrade 5.7.x version to 8.0.x version. No need to run  "mysql_upgrde" utility command specifically while upgrading it to 8.0.x!
# systemctl start mysqld
