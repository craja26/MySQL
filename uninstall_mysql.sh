# yum list installed | grep mysql
# yum remove mysql mysql-server
# mv /var/lib/mysql /var/lib/mysql_bkup
# yum clean all

## check below files and folders after unintall mysql
# whereis mysql
# find / -name mysql
- Remove files and folder based on find result.
rm -rf /etc/selinux/targeted/active/modules/100/mysql
rm -rf /etc/selinux/targeted/tmp/modules/100/mysql
rm -rf /var/lib/mysql.bak/mysql
rm -rf /var/lib/mysql_bkup/mysql
rm -rf /usr/lib64/perl5/vendor_perl/auto/DBD/mysql
rm -rf /usr/lib64/perl5/vendor_perl/DBD/mysql
rm -rf /usr/lib64/mysql
rm -rf /usr/share/mysql
rm -rf /data/mysql
rm -rf /data/mysql/data/mysql
rm -rf /backup/mysql_backup/mydumper_backup/mydumper/mysql

- checking rpm repository
# rpm -qa | grep mysql
- remove without dependencies for above resulted list
# rpm -ev --nodeps mysql-community-libs-compat-5.7.33-1.el7.x86_64
