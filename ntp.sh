#!/bin/bash

if [ -f /etc/debian_version ]; then
  apt-get install ntp
  update-rc.d ntp defaults
  service ntp start
elif [ -f /etc/centos-release ]; then
  yum install ntp
  systemctl start ntpd
  systemctl enable ntpd
else
  OS=$(uname -s)
  VER=$(uname -r)
  exit 1
fi
ntpq -p
# NTP i iptables
# @see http://superuser.com/questions/141772/what-are-the-iptables-rules-to-permit-ntp
