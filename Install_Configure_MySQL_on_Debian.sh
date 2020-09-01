MySQL Installation on Debian Linux
-----------------------------------
#1. Prerequisites
	Run below commands to upgrade the current packages to the latest version.
		sudo apt update 
		sudo apt upgrade
#2.	Configure MySQL PPA
	MySQL team provides official MySQL PPA for Debian Linux. You can download and install the package on your Debian system, which will add PPA file to your system.
		wget http://repo.mysql.com/mysql-apt-config_0.8.13-1_all.deb
		sudo dpkg -i mysql-apt-config_0.8.13-1_all.deb
	During the installation of MySQL apt config package, It will prompt to select MySQL version to install. Select the MySQL 8.0 or 5.7 option to install on your system.
#3.	Install MySQL
	Now, The system is ready for the MySQL installation. Run the following commands to install MySQL.
		sudo apt install mysql-server
	The installation process will prompt for the root password to set as default. Input a secure password and same to confirm password window. This will be MySQL root user password required to log in to MySQL server.
	The next window will ask to re-enter the same password.Then, Let the installation complete.
	Now, start the MysQL service if not started:
		sudo systemctl restart mysql.service
#4.	Secure MySQL Installation
	Execute the below command on your system to make security changes on your Database Server. This will prompt some questions.
		sudo mysql_secure_installation
	Select a password validation policy to MEDIUM where we can have both less complex and complex passwords for users.
	Now, Enable MySQL to startup after restart.Run following command.
		systemctl enable mysql
#5.	MySQL Configuration
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
		systemctl stop mysql
		systemctl status mysql
	Take a backup of old Directory
		cp -r /var/lib/mysql /var/lib/mysql.bak
	Move Data files to new directory
		rsync -av /var/lib/mysql/ /data/mysql/data
	Backup old my.cnf fille.
		cp /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
	Change Configuration File with New Settings. Use this standard configuration file my.cnf
	Now start mysql service.
		systemctl start mysql
		systemctl status mysql


	 
