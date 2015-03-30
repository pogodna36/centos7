#!/bin/bash

if [ $UID -ne 0 ]; then
  echo Użytkownik inny niż root. Uruchom jako użytkownik root.
  exit 1
fi

echo "Please enter DOMAINNAME: "
read DOMAINNAME
echo "Please enter account-name: "
read A
echo "Please enter account-pass: "
read B
echo "Please enter account-mail: "
read C

echo $DOMAINNAME
echo $A
echo $B
echo $C

# DOMAINNAME=xx.xx.loc
USER=monter
APACHE_GROUP=apache
# LIBRARY_SERVER=http://212.227.105.148/

DOCUMENTROOT=/var/www/$DOMAINNAME
if [ -d "$DOCUMENTROOT" ]; then
  echo "Katalog $DOCUMENTROOT istnieje"
  exit 1
fi

if [ -z "`which pwgen 2>/dev/null`" ]; then
yum install -y pwgen
fi
DBU=$(pwgen -n 8 1)
DBP=$(pwgen -n 8 1)
DBN=$(echo $DOMAINNAME | sed 's/\./_/g')
DBN=$(echo $DBN | sed 's/\-/__/g')

mkdir -p $DOCUMENTROOT

# --account-name
# A=xxxx
# --account-pass
# B=xxxx
# --account-mail
# C=xx@xx.xx
# --site-mail
D=admin@$DOMAINNAME

#echo "$(ifconfig eth0 | grep "inet " | awk -F " " '{print $2}') $DOMAINNAME" >> /etc/hosts
echo "127.0.0.1 $DOMAINNAME" >> /etc/hosts

# ------------------------------------------------------------------------
# Baza danych
# ------------------------------------------------------------------------
E_BADARGS=65
MYSQL=$(which mysql)
Q1="CREATE DATABASE IF NOT EXISTS $DBN;"
Q2="GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON $DBN.* TO '$DBU'@'localhost' IDENTIFIED BY '$DBP';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
# hasło w $HOME/.my.cnf 
# echo "Podaj hasło administratora MYSQL ....."
#$MYSQL -uroot -p -e "$SQL"
$MYSQL -e "$SQL"
echo "DBN: $DBN DBU: $DBU DBP: $DBP" >> $DBN.pass


# ------------------------------------------------------------------------
# Apache2
# ------------------------------------------------------------------------
cat > /etc/apache2/sites-available/$DOMAINNAME.conf <<END
<VirtualHost *:80>
  ServerAdmin admin@$DOMAINNAME
  DocumentRoot $DOCUMENTROOT
  ServerName $DOMAINNAME
  ServerAlias www.$DOMAINNAME
  ErrorLog \${APACHE_LOG_DIR}/$DOMAINNAME-error.log
  CustomLog \${APACHE_LOG_DIR}/access.log vhost_combined
  # ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/$DOMAINNAME
  <Directory "$DOCUMENTROOT">
    Options Indexes FollowSymLinks MultiViews
    Require all granted
    AllowOverride All
  </Directory>
</VirtualHost>
END

a2ensite $DOMAINNAME
service apache2 reload

# ------------------------------------------------------------------------
# is drush?
# ------------------------------------------------------------------------
if [ -z "`which drush 2>/dev/null`" ]; then
install_drush7
fi

# ------------------------------------------------------------------------
# Pobranie Drupala
# ------------------------------------------------------------------------
cd /var/www
drush dl -y drupal-8 --drupal-project-rename=$DOMAINNAME
cd $DOCUMENTROOT
mkdir sites/default/files
chmod a+w sites/default/files
cp sites/default/default.settings.php sites/default/settings.php
cp sites/default/default.services.yml sites/default/services.yml
chmod a+w sites/default/settings.php
chmod a+w sites/default/services.yml



#cp sites/default/default.settings.php sites/default/settings.php
#chmod a+w sites/default/settings.php
#chmod a+w sites/default
#mkdir sites/all/libraries


# ------------------------------------------------------------------------
# Instalacja Drupala poprzez drush'a'
# ------------------------------------------------------------------------
drush site-install -y standard --db-url=mysql://$DBU:$DBP@localhost:3306/$DBN --site-name="$DOMAINNAME" --site-mail=$D --account-mail=$C --account-name=$A --account-pass=$B
#echo "\$base_url = 'http://$DOMAINNAME';" >> sites/default/settings.php

# https://www.drupal.org/node/1992030
echo "\$settings['trusted_host_patterns'] = array('^localhost$', '^$(echo $DOMAINNAME | sed 's/\./\\./g')$',);" >> $DOCUMENTROOT/sites/default/settings.php

#ln -s /home/marek/Git/p36_karol/current/d8/karol $DOCUMENTROOT/themes
#ln -s /home/marek/Git/p36_karol/current/d8/karolmod $DOCUMENTROOT/modules
#ln -s /home/marek/Git/p36_karol/current/d8/pogodna $DOCUMENTROOT/modules
#ln -s /home/marek/Git/p36_karol/current/d8/karol_slider $DOCUMENTROOT/modules

#drush en -y karol
#drush en -y karolmod
#drush en -y pogodna
#drush en -y karol_slider

#cp /home/marek/Git/p36_karol/current/d8/jquery.min.map $DOCUMENTROOT/core/assets/vendor/jquery

drush pmu -y quickedit
drush pmu -y contextual rdf

# ------------------------------------------------------------------------
# Zabezpieczanie katalogów i plików
# ------------------------------------------------------------------------
cd $DOCUMENTROOT
chown -R $USER:$APACHE_GROUP .
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;
find . -type f -exec chmod u=rw,g=r,o= '{}' \;

cd $DOCUMENTROOT/sites
find . -type d -name files -exec chmod ug=rwx,o= '{}' \;
for d in ./*/files
do
   find $d -type d -exec chmod ug=rwx,o= '{}' \;
   find $d -type f -exec chmod ug=rw,o= '{}' \;
done


drush cache-rebuild
echo "Zainstalowano $DOMAINNAME"


function install_drush7 {
  # Install Composer globally (if needed).
  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer
  # Add Composer's global bin directory to the system PATH (recommended):
  sed -i '1i export PATH="$HOME/.composer/vendor/bin:$PATH"' $HOME/.bashrc
  source $HOME/.bashrc
  # To install Drush 7.x (dev) which is required for Drupal 8:
  composer global require drush/drush:dev-master

  drush status
  drush dl drush_language
}
