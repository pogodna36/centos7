#!/bin/bash

#-------------------------------
# Instalacja Apache2 na CentOS 7
#------------------------------- 

yum install -y httpd
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
  apachectl restart
    else
      apachectl configtest
    fi
    
htpasswd -c /etc/httpd/.htsecret monter
#echo 'monter:$apr1$s0h/6BzS$DcRU.....3MNXDxkoInSa/' > /etc/httpd/.htsecret
chmod 444 /etc/httpd/.htsecret
 
# wyłączyć moduły niepotrzebne



# ------------------------------------------------------------------------
# SELinux i Apache
# ------------------------------------------------------------------------
getsebool -a | grep httpd
setsebool -P httpd_can_network_connect_db=1
setsebool -P httpd_can_sendmail=1
setsebool -P httpd_unified=1
setsebool -P httpd_can_network_connect=1
