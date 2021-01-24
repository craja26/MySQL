/******* MariaDB 10.3.27 | Installation | CentOS 7.9 **********/
# wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
# chmod +x mariadb_repo_setup
# sudo ./mariadb_repo_setup
# vim /etc/yum.repos.d/mariadb.repo
	# add below MariaDB repo and disable remaining rows
	[mariadb]
	name = MariaDB
	baseurl = http://yum.mariadb.org/10.3/centos7-amd64
	gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
	gpgcheck=1

# yum install MariaDB-server
# systemctl status mariadb
# systemctl start mariadb
# systemctl status mariadb
- Get temporary password
# grep 'A temporary password' /var/log/mysqld.log |tail -1
- Secure installation
# mysql_secure_installation
- Enable service to start automatically after reboot.
# systemctl enable --now mariadb



- Change directories
	## add new directories
	mkdir /data/mysql
	mkdir /data/mysql/scripts
	mkdir /data/mysql/binlog
	mkdir /data/mysql/logs
	mkdir /data/mysql/tmp
	mkdir /data/mysql/data
	##Assign mysql user as owner to all of the above directories.Ex. command.
		chown -R mysql:mysql /data/mysql
- Stop mariaDB Service
# systemctl stop mariadb

- Take a backup of old Directory
# cp -r /var/lib/mysql /var/lib/mysql.bak

- Move Data files to new directory
# rsync -av /var/lib/mysql/ /data/mysql/data

- Backup old my.cnf fille.
# cp /etc/my.cnf /etc/my.cnf.bak

- Replace standard cnf file.
## Please see my github

- Start mariaDB service

Note: Please verify SELinux contect. If it is missing, run below command to grant access.
	# getenforce
	# setenforce 0
	# getenforce
	- for permanent fix 
	# vim /etc/selinux/config
		SELINUX=permissive	(change like this)
- Increase open file limit.
vim /etc/security/limits.conf
# MariaDB Open File Limits
mysql   hard    nofile  65535
mysql   soft    nofile  65535
 
#mariabackup Open Files Limit
root    hard    nofile  65535
root    soft    nofile  65535
 
systemctl edit mysqld
 
[Service]
LimitNOFILE=65535
 
systemctl daemon-reload
systemctl restart mysqld
	
