#!/bin/bash

# Instalujemy po MySQL i Apache2

rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    
yum install php56w php56w-opcache php56w-mysql php56w-gd php56w-pear php56-devel
# @see https://webtatic.com/packages/php56/

cat > /etc/php.d/zzz-p36.ini <<END
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


pecl install uploadprogress
cat > /etc/php.d/uploadprogress.ini <<END
extension=uploadprogress.so
END

cat >> /etc/php5/mods-available/opcache.ini <<END
opcache.memory_consumption=64
opcache.max_accelerated_files=5000
END

if [[ $(apachectl configtest 2>&1) = "Syntax OK" ]]; then
apachectl restart
else
apachectl configtest
fi

# install_opcache_monitor
cd /var/www/$(hostname -f)
wget https://raw.github.com/amnuts/opcache-gui/master/index.php -O php-op.php

yum install phpmyadmin
apachectl graceful
# konfiguracja:
# https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-with-apache-on-a-centos-7-server
# Change any lines that read Require ip 127.0.0.1 or Allow from 127.0.0.1
# to refer to your home connection's IP address. 
# vi /etc/httpd/conf.d/phpMyAdmin.conf

# We want to disable these specific aliases since they are heavily targeted by bots and malicious users.
# Instead, we should decide on our own alias. It should be easy to remember, but not easy to guess.
# It shouldn't indicate the purpose of the URL location. In our case, we'll go with /nothingtosee.
# To apply our intended changes, we should remove or comment out the existing lines and add our own:

# Alias /phpMyAdmin /usr/share/phpMyAdmin
# Alias /phpmyadmin /usr/share/phpMyAdmin
# niżej przykładowy alias:
# Alias /mysql-admin /usr/share/phpmyadmin
