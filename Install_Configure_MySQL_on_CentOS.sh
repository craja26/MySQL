Install MySQL on CentOs-7
-------------------------
1. Run below commands to upgrade the current packages to the latest version.
	sudo yum update 
	sudo yum upgrade
2. Execute the following command to enable MySQL yum repository on CentOS/RHEL
	wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
			or
	yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
3. Install MySQL community server
	sudo yum install mysql-community-server
4.	Start mysql server
	systemctl start mysqld
5. MySQL Secure Installation.
	Before beginning with secure installation run below command to get the default root password.
	grep 'A temporary password' /var/log/mysqld.log |tail -1
	
	execute secure installation command.
	mysql_secure_installation
6.	Restart and enable the MySQL service
	service mysqld restart
	chkconfig mysqld on
7.	MySQL configurations
	Create following directories to segregate MySQL DB related files across disk.
		mkdir /data/mysql
		mkdir /data/mysql/scripts
		mkdir /data/mysql/binlog
		mkdir /data/mysql/logs
		mkdir /data/mysql/tmp
		mkdir /data/mysql/data
	Assign mysql user as owner to all of the above directories.Ex. command.
		chown -R mysql:mysql /data/mysql
	Move existing mysql DB files to the newly create above directories as per below steps.
		systemctl stop mysqld
		systemctl status mysql
	Take a backup of old Directory
		cp -r /var/lib/mysql /var/lib/mysql.bak
	Move Data files to new directory
		rsync -av /var/lib/mysql/ /data/mysql/data
	Backup old my.cnf fille.
		cp /etc/my.cnf /etc/my.cnf.bak
	Replace standard cnf file. 
		Please see my github
	Start mysql service

Note: SELinux might blocks start mysql service with below error.
----------------------------------------------------------------
	[Warning] Can't create test file /folder/data/servername.lower-test
	[Warning] Can't create test file /folder/data/servername.lower-test
	[ERROR] /usr/sbin/mysqld: Can't create/write to file
Eventhough if you grant proper access, will get this error message. SELinux is blocking mysqld service.
Here is command to unblock it.
		setenforce 0
		getenforce
	This is unblock until reboot. If you want to fix it perminantly follow below steps.
		vim /etc/selinux/config
	uncomment SELINUX(might be at line #07) and update this line like below
		SELINUX=permissive


vim /etc/security/limits.conf
# MySQL Open File Limits
mysql   hard    nofile  65535
mysql   soft    nofile  65535
 
#XtraBackup Open Files Limit
root    hard    nofile  65535
root    soft    nofile  65535
 
systemctl edit mysqld
 
[Service]
LimitNOFILE=65535
 
systemctl daemon-reload
systemctl restart mysqld

