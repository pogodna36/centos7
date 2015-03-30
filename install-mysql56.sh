#!/bin/bash

# w ten sposób możemy zalogowac się jako user mysql
# su - mysql -s /bin/bash

#-----------------------------------------------------------------------
# MySQL 5.6
#-----------------------------------------------------------------------
if [ $# -eq 0 ]
  then
    echo "Uruchom skrypt podając hasło"
    exit 1
fi

if [ -f /etc/debian_version ]; then
DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server-5.6
update-rc.d mysql defaults
service mysql start
elif [ -f /etc/centos-release ]; then
wget http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
rpm -Uvh mysql-community-release-el7-5.noarch.rpm
yum install mysql-community-server
cat >> /etc/my.cnf <<END
!includedir /etc/my.cnf.d/
END
systemctl enable mysqld.service
systemctl start mysqld.service
else
OS=$(uname -s)
VER=$(uname -r)
exit 1
fi

mkdir /var/lib/mysql/binlogs
chmod 770 /var/lib/mysql/binlogs
chown mysql:mysql /var/lib/mysql/binlogs

cat > $HOME/.my.cnf <<END
[client]
user=root
password=$1
END
chmod 400 $HOME/.my.cnf

mysql_secure_installation

echo "Sprawdzenie konfiguracji"
echo "------------------------"
/usr/sbin/mysqld --help --verbose --skip-networking --pid-file=/var/run/mysqld/mysqld.pid 1>/dev/null

if [ -f /etc/debian_version ]; then
MY_CNF=/etc/mysql/conf.d/p36.cnf
elif [ -f /etc/centos-release ]; then
MY_CNF=/etc/my.cnf.d/p36.cnf
else
OS=$(uname -s)
VER=$(uname -r)
exit 1
fi
cat >> $MY_CNF <<END
[mysqld]
# MyISAM #
key-buffer-size                = 32M
myisam-recover                 = FORCE,BACKUP
# SAFETY #
max-allowed-packet             = 16M
max-connect-errors             = 1000000
# BINARY LOGGING #
log-bin                        = /var/lib/mysql/binlogs/binlog
expire-logs-days               = 14
sync-binlog                    = 1
ignore-db-dir                  = lost+found
ignore-db-dir                  = binlogs
# CACHES AND LIMITS #
tmp-table-size                 = 32M
max-heap-table-size            = 32M
query-cache-type               = 0
query-cache-size               = 0
max-connections                = 500
thread-cache-size              = 50
open-files-limit               = 65535
table-definition-cache         = 4096
#table-open-cache               = 4096
# INNODB #
innodb-flush-method            = O_DIRECT
innodb-log-files-in-group      = 2
#innodb-log-file-size           = 128M
innodb-flush-log-at-trx-commit = 1
innodb-file-per-table          = 1
#innodb-buffer-pool-size        = 2G
# LOGGING #
log-queries-not-using-indexes  = 1
slow-query-log                 = 1
# CHARACTER AND COLLATION #
character-set-server           = utf8
collation-server               = utf8_polish_ci
init-connect                   = 'SET NAMES utf8'
END

# mysqltuner.pl - skrypt sprawdzający konfigurację MySQ
cd $HOME
git clone https://github.com/major/MySQLTuner-perl.git
ln -s ~/MySQLTuner-perl/mysqltuner.pl ~/mysqltuner.pl

systemctl restart mysql
systemctl status mysql

####################################################################################################
# The table_open_cache and max_connections system variables affect the maximum number of files the server keeps open. 
# @see http://dev.mysql.com/doc/refman/5.6/en/table-cache.html

# table_open_cache - the number of open tables for all threads. Increasing this value increases 
# the number of file descriptors that mysqld requires. You can check whether you need to increase
# the table cache by checking the Opened_tables status variable.
# @see http://dev.mysql.com/doc/refman/5.6/en/server-status-variables.html

## Konfiguaracja dla 2core 2G
# table-open-cache               = 4096
# innodb-log-file-size           = 128M
# innodb-buffer-pool-size        = 1456M

## Konfiguracja dla 4core 4G
# table-open-cache               = 4096
# innodb-log-file-size           = 128M
# innodb-buffer-pool-size        = 2G

## Konfiguracja dla 8core 16G
# table-open-cache               = 10240
# innodb-log-file-size           = 256M
# innodb-buffer-pool-size        = 12G



# show_mysql_variables
echo -n -e '\e[1;36m'
echo -n Wartości wybranych zmiennych globalnych MySQL
echo -e '\e[0m'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'version'"

echo $'\n[mysql]'

echo $'\n# CLIENT #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'port' 
OR Variable_Name LIKE 'socket'"

echo $'\n[mysqld]'

echo $'\n# GENERAL #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'user' 
OR Variable_Name LIKE 'default_storage_engine'
OR Variable_Name LIKE 'socket'
OR Variable_Name LIKE 'pid_file'"

echo $'\n# MyISAM #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'key_buffer_size' 
OR Variable_Name LIKE 'myisam_recover_options'"

echo $'\n# SAFETY #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'max_allowed_packet' 
OR Variable_Name LIKE 'max_connect_errors'"

echo $'\n# DATA STORAGE #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'datadir'"

echo $'\n# BINNARY LOGGING #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'log_bin' 
OR Variable_Name LIKE 'expire_logs_days'
OR Variable_Name LIKE 'binlog_format'
OR Variable_Name LIKE 'sync_binlog'"

echo $'\n# CACHES AND LIMITS #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'tmp_table_size' 
OR Variable_Name LIKE 'max_heap_table_size'
OR Variable_Name LIKE 'query_cache_type'
OR Variable_Name LIKE 'query_cache_size'
OR Variable_Name LIKE 'max_connections'
OR Variable_Name LIKE 'thread_cache_size'
OR Variable_Name LIKE 'open_files_limit'
OR Variable_Name LIKE 'table_definition_cache'
OR Variable_Name LIKE 'table_open_cache'"

echo $'\n# INNODB #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'innodb_flush_method' 
OR Variable_Name LIKE 'innodb_log_files_in_group'
OR Variable_Name LIKE 'innodb_log_file_size'
OR Variable_Name LIKE 'innodb_flush_log_at_trx_commit'
OR Variable_Name LIKE 'innodb_file_per_table'
OR Variable_Name LIKE 'innodb_buffer_pool_size'"

echo $'\n# LOGGING #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'log_error' 
OR Variable_Name LIKE 'log_queries_not_using_indexes'
OR Variable_Name LIKE 'slow_query_log'
OR Variable_Name LIKE 'slow_query_log_file'"

echo $'\n# CHARACTER AND COLLATION #'
mysql -e "SHOW GLOBAL VARIABLES WHERE Variable_Name LIKE 'character_set%' 
OR Variable_Name LIKE 'collation%'
OR Variable_Name LIKE 'init_connect'"

# $@
