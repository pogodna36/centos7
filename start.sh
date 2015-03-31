#!/bin/bash

LOG=/root/log_script.log
yum updatue -y >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error in yum update"
timedatectl set-timezone Europe/Warsaw

cat >> /etc/sysctl.conf <<END
# When kernel panic's, reboot after 10 second delay
kernel.panic = 10
kernel.panic_on_oops = 1

# TCP SYN Flood Protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 3
END
sysctl -p >> $LOG 2>&1

yum install -y epel-release >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y sudo >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y curl >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y htop >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y mc >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y iotop >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y unzip >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y iftop >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum  install -y iptraf >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y pwgen >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y mlocate >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
updatedb >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Updatedb error"
yum install -y sysstat >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y chronyd >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
wget http://www.pixelbeat.org/scripts/ps_mem.py -O ~/ps_mem.py >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
chmod u+x *.py >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Chmod error"
yum install -y rsyslog >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y git >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y gcc >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y make >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
yum install -y jpegoptim >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"

# Instalacja Apache2 na CentOS 7
yum install -y httpd >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Install error"
systemctl enable httpd.service
systemctl start httpd.service

cat > /etc/httpd/conf.d/zzz-p36.conf <<END
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


