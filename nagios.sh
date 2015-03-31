#!/bin/bash

# Nagios (EPEL)

yum install nagios
yum install nagios-plugins-all

htpasswd -s -c /etc/nagios/passwd nagiosadmin

# W CentOS7 ping nie ma ustawionego SUID (Set owner User ID up on execution).
# Inni użytkownicy nie mogą uruchomić poloecenia ping, min. nagios
chmod u+s $(which ping)

# autostart włączamy tak:
/sbin/chkconfig nagios on

# http://linoxide.com/how-tos/install-configure-nagios-centos-7/


# zmieniamy port ssh
# i włączamy powiadomienia dla ssh i http
#vi /etc/nagios/objects/localhost.cfg
define service{
    ...
    check_command			check_ssh!-p 2202
    notifications_enabled   1
}
# notifications_enabled   1 :też dla http
# zmodyfikować też program pocztowy w SAMPLE NOTIFICATION COMMANDS
# sprawdzić poleceniem which mail

vi /etc/nagios/objects/contacts.cfg
# pocztę kierować do roota
# email root
