/************ Point-in-Time Recovery ************/

# here is the sample code for point-in-time recovery after restoring a full backup.
# Filtered binlog commands for a single database.

# searching drop database command in binlog file. 
# mysqlbinlog -v /data/mysql/binlog/mysql-binlog.000003 | grep -i "drop database sqllogging"

# extracting binlog data to text file then searching drop database command
# mysqlbinlog -v /data/mysql/binlog/mysql-binlog.000002 > master-bin.txt
# mysqlbinlog -v /data/mysql/binlog/mysql-binlog.000003 >> master-bin.txt
# grep -B 7 -A 1 "drop database" master-bin.txt

# setting pager even in mysql
mysql> pager grep -A 1 -B 2 'sqllogging' | grep -B 4 drop
mysql> show binlog events in 'mysql-binlog.000003'

# restoring bin log before drop database command.
# mysqlbinlog --start-position=154 /data/mysql/binlog/mysql-binlog.000002 | mysql -u root -p 
# mysqlbinlog --stop-position=1244  /data/mysql/binlog/mysql-binlog.000003 | mysql -u root -p 
