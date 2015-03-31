#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Uruchom skrypt podając email będący alaisem root'a"
    exit 1
fi


if [ -f /etc/debian_version ]; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y postfix
    apt-get install -y mailutils
    # Postfix: Internet site
    update-rc.d postfix defaults
    service postfix start
elif [ -f /etc/centos-release ]; then
    yum -y install postfix mailx
    systemctl start postfix
    systemctl enable postfix
else
OS=$(uname -s)
VER=$(uname -r)
exit 1
fi
echo "root: $1" >> /etc/aliases
newaliases
#vi /etc/postfix/main.cf
# testowy email
echo "This will go into the body of the mail." | mail -s "Hello world" root
