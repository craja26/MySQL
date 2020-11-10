
MySQL upgrade from 5.7 to 8.0 steps:
------------------------------------
Note: take full backup before starting upgrade steps.

mysqlcheck -u <username> -p --all-databases --check-upgrade

wget https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell-8.0.22-1.el7.x86_64.rpm

rpm -ivh mysql-shell-8.0.22-1.el7.x86_64.rpm

yum update --enablerepo=mysql80-community mysql-community-server

