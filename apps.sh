#!/bin/bash

yum install -y epel-release
yum install -y sudo
yum install -y curl
yum install -y htop
yum install -y mc
yum install -y iotop
yum install -y unzip

# @see http://blog.nexcess.net/2011/10/04/monitoring-linux-bandwidth-utilization-with-iptraf-and-iftop/
yum install -y iftop
yum  install -y iptraf

yum install -y pwgen
yum install -y mlocate
updatedb
yum install -y sysstat

if [ -z "`which rsyslogd 2>/dev/null`" ]; then
yum install -y chronyd
fi

wget http://www.pixelbeat.org/scripts/ps_mem.py -O ~/ps_mem.py
chmod u+x *.py
# ./ps_mem.py

if [ -z "`which rsyslogd 2>/dev/null`" ]; then
yum install -y rsyslog
fi

yum install -y git
#git config --global user.name "m...a"
#git config --global user.email p...com

yum install -y gcc make

yum install -y jpegoptim



# yum groupinstall "Development Tools"


# ------------------------------------------------------------------------
# Zmanda Recovery Manager for MySQL (EPEL)
# ------------------------------------------------------------------------
# yum install MySQL-zrm
