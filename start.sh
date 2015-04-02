#!/bin/bash

LOG=/root/log_script.log
SYSCTL=/etc/sysctl.conf
MY_HTTPD=/etc/httpd/conf.d/zzz-p36.conf
MYSQL=/etc/my.cnf
MY_CNF=/etc/my.cnf.d/zzz-p36.cnf
MY_PHP=/etc/php.d/zzz-p36.ini
MY_MONIT=/etc/monit.d/zzz-p36

function install {
yum install -y $1 >> $LOG 2>&1
OUT=$?
if [ $OUT -eq 0 ]; then
 echo -e "[\033[32mX\033[0m] $1 installed ok"
else
  echo -e "[\033[31mX\033[0m] $1 install error"
fi
}

function pecl_install {
pecl install -y $1 >> $LOG 2>&1
OUT=$?
if [ $OUT -eq 0 ]; then
 echo -e "[\033[32mX\033[0m] $1 installed ok"
else
  echo -e "[\033[31mX\033[0m] $1 install error"
fi
}


function run {
$1 >> $LOG 2>&1
OUT=$?
if [ $OUT -eq 0 ]; then
 echo -e "[\033[32mX\033[0m] $1 run ok"
else
  echo -e "[\033[31mX\033[0m] $1 run error"
fi
}

yum updatue -y >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error in yum update"
timedatectl set-timezone Europe/Warsaw

cat >> $SYSCTL <<END
# When kernel panic's, reboot after 10 second delay
kernel.panic = 10
kernel.panic_on_oops = 1

# TCP SYN Flood Protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 3
END
sysctl -p >> $LOG 2>&1

install epel-release
install sudo
install curl
install htop
install mc
install iotop
install unzip
install iftop
install iptraf
install pwgen
install mlocate
run updatedb
install sysstat
install chronyd
wget http://www.pixelbeat.org/scripts/ps_mem.py -O ~/ps_mem.py >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
chmod u+x *.py >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Chmod error"
install rsyslog
install git
install gcc
install make
install jpegoptim

# Instalacja Apache2 na CentOS 7
install httpd
systemctl enable httpd.service
systemctl start httpd.service

cat > $MY_HTTPD <<END
ServerTokens Prod
KeepAlive Off
KeepAliveTimeout 1
<IfModule mpm_prefork_module>
	StartServers 25
	MinSpareServers 25
	MaxSpareServers 25
	MaxRequestWorkers 256
	MaxConnectionsPerChild 4000
</IfModule>
<Location /508-status>
	SetHandler server-status
	AuthType basic
	AuthName "Apache2 server status"
	AuthUserFile /etc/httpd/.htsecret
	Require valid-user
</Location>
<Location /508-info>
	SetHandler server-info
	AuthType basic
	AuthName "Apache2 server status"
	AuthUserFile /etc/httpd/.htsecret
	Require valid-user
</Location>
END
  
DOMAINNAME=$(hostname -f)
mkdir /var/www/$DOMAINNAME
echo "Witaj na $DOMAINNAME" >> /var/www/$DOMAINNAME/index.html
echo "<?php phpinfo(); ?>" >> /var/www/$DOMAINNAME/info.php
cat > /etc/httpd/conf.d/$DOMAINNAME.conf <<END
<VirtualHost *:80>
	ServerAdmin admin@$DOMAINNAME
	DocumentRoot /var/www/$DOMAINNAME
	ServerName $DOMAINNAME
	ServerAlias www.$DOMAINNAME
	#ErrorLog \${APACHE_LOG_DIR}/error.log
	#CustomLog \${APACHE_LOG_DIR}/access.log vhost_combined
	<Directory "/var/www/$DOMAINNAME">
		Options Indexes FollowSymLinks MultiViews
		Require all granted
		AllowOverride All
	</Directory>
</VirtualHost>
END
# You can see, the output Syntax OK is written to stderr,
# causes the ouput can not save to var variable.
# You can make it done, by redirect stderr to stdout.
if [[ $(apachectl configtest 2>&1) = "Syntax OK" ]]; then
  apachectl restart >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Apache restart error"
else
  apachectl configtest
fi

echo "Wprowadź hasło dostępu do statystyk serwera www"
htpasswd -c /etc/httpd/.htsecret monter
#echo 'monter:$apr1$s0h/6BzS$DcRU.....3MNXDxkoInSa/' > /etc/httpd/.htsecret
chmod 444 /etc/httpd/.htsecret

# MySQL 5.6
wget http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
rpm -Uvh mysql-community-release-el7-5.noarch.rpm
install mysql-community-server
cat >> $MYSQL <<END
!includedir /etc/my.cnf.d/
END
systemctl enable mysqld.service
systemctl start mysqld.service

mkdir /var/lib/mysql/binlogs
chmod 770 /var/lib/mysql/binlogs
chown mysql:mysql /var/lib/mysql/binlogs

echo "Podaj hasło dla MYSQL: "
read MYSQL_PASSWORD
cat > $HOME/.my.cnf <<END
[client]
user=root
password=$MYSQL_PASSWORD
END
chmod 400 $HOME/.my.cnf

mysql_secure_installation

echo "Sprawdzenie konfiguracji MySQL"
/usr/sbin/mysqld --help --verbose --skip-networking --pid-file=/var/run/mysqld/mysqld.pid 1>/dev/null

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
table-open-cache              = $TABLE-OPEN-CACHE
# INNODB #
innodb-flush-method            = O_DIRECT
innodb-log-files-in-group      = 2
innodb-log-file-size          = $INNODB-LOG-FILE-SIZE
innodb-flush-log-at-trx-commit = 1
innodb-file-per-table          = 1
innodb-buffer-pool-size       = $INNODB-BUFFER-POOL-SIZE
# LOGGING #
log-queries-not-using-indexes  = 1
slow-query-log                 = 1
# CHARACTER AND COLLATION #
character-set-server           = utf8
collation-server               = utf8_polish_ci
init-connect                   = 'SET NAMES utf8'
END

# mysqltuner.pl - skrypt sprawdzający konfigurację MySQ
cd /opt
git clone https://github.com/major/MySQLTuner-perl.git
ln -s /opt/MySQLTuner-perl/mysqltuner.pl ~/mysqltuner.pl

systemctl restart mysql
systemctl status mysql

####################################################################################################
# The table_open_cache and max_connections system variables affect the maximum number of files the server keeps open. 
# @see http://dev.mysql.com/doc/refman/5.6/en/table-cache.html

# table_open_cache - the number of open tables for all threads. Increasing this value increases 
# the number of file descriptors that mysqld requires. You can check whether you need to increase
# the table cache by checking the Opened_tables status variable.
# @see http://dev.mysql.com/doc/refman/5.6/en/server-status-variables.html

if [ $OUT -eq 0 ]; then
  TABLE-OPEN-CACHE=4096
  INNODB-LOG-FILE-SIZE=128M
  INNODB-BUFFER-POOL-SIZE=1456M
elif
  TABLE-OPEN-CACHE=4096
  INNODB-LOG-FILE-SIZE=128M
  INNODB-BUFFER-POOL-SIZE=2G
elif
  TABLE-OPEN-CACHE=10240
  INNODB-LOG-FILE-SIZE=256M
  INNODB-BUFFER-POOL-SIZE=12G

fi
}

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

# PHP5
rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    
install php56w
install php56w-opcache
install php56w-mysql
install php56w-gd
install php56w-pear
install php56w-devel

cat > $MY_PHP <<END
date.timezone = Europe/Warsaw
mbstring.language=UTF-8
mbstring.internal_encoding=UTF-8
mbstring.http_input=pass
mbstring.http_output=pass
mbstring.detect_order=auto
expose_php = Off
error_reporting = E_ALL
display_errors = On
upload_max_filesize = 20M
post_max_size = 20M
END

pecl_install uploadprogress
echo "extension=uploadprogress.so" > /etc/php.d/uploadprogress.ini
END

# cat >> /etc/php5.d/opcache.ini <<END
# opcache.memory_consumption=64
# opcache.max_accelerated_files=5000
# END

# install_opcache_monitor
cd /var/www/$(hostname -f)
wget https://raw.github.com/amnuts/opcache-gui/master/index.php -O php-op.php >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"

install phpmyadmin
apachectl restart

if [[ $(apachectl configtest 2>&1) = "Syntax OK" ]]; then
apachectl restart
apachectl status
else
apachectl configtest
fi

# Postfix
install postfix
install mailx
systemctl start postfix
systemctl enable postfix
echo "Podaj alias dla poczty do root'a: "
read ROOT_ALIAS
echo "root: $ROOT_ALIAS" >> /etc/aliases
run newaliases
#vi /etc/postfix/main.cf
# testowy email
echo "This will go into the body of the mail." | mail -s "Hello world" root

# Monit
install monit
systemctl enable monit
systemctl start monit

vi /etc/monitrc
# Komentujemy ten fragment:
<<FRAGMENT
set httpd port 2812 and
    use address localhost  # only accept connection from localhost
    allow localhost        # allow localhost to connect to the server and
    allow admin:monit      # require user 'admin' with password 'monit'
    allow @monit           # allow users of group 'monit' to connect (rw)
    allow @users readonly  # allow users of group 'users' to connect readonly
FRAGMENT

cat >> $MY_MONIT <<END
# przesłaniamy plik monitrc
set httpd port 2812 and
allow 0.0.0.0/0.0.0.0
allow admin:monit
set mailserver localhost
set alert root@localhost
# monitorowanie httpd
check process httpd with pidfile /var/run/httpd/httpd.pid
start program  "/usr/bin/systemctl start httpd.service"
stop program  "/usr/bin/systemctl stop httpd.service"
group www
# monitorowanie sshd
check process sshd with pidfile /var/run/sshd.pid
start program  "/usr/bin/systemctl start sshd.service"
stop program  "/usr/bin/systemctl stop sshd.service"
group system
# monistorwanie rsyslog
check process rsyslog with pidfile /var/run/syslogd.pid
start program  "/usr/bin/systemctl start rsyslog.service"
stop program  "/usr/bin/systemctl stop rsyslog.service"
group system
# monitorowanie cron
check process cron with pidfile /var/run/crond.pid
start program  "/usr/bin/systemctl start crond.service"
stop program  "/usr/bin/systemctl stop crond.service"
group system
END

if [[ $(monit -t 2>&1) = "Control file syntax OK" ]]; then
  monit reload
else
  monit -t
fi

monit status
