#!/bin/bash

# @see http://www.tecmint.com/how-to-install-and-setup-monit-linux-process-and-services-monitoring-program/

yum install monit
systemctl enable monit
systemctl start monit



# Sprawdzanie poprawności konfiguracji:
monit -t

# Edytujemy plik konfiguracyjny:
#vi /etc/monitrc
# Komentujemy ten fragment:
<<FRAGMENT
set httpd port 2812 and
    use address localhost  # only accept connection from localhost
    allow localhost        # allow localhost to connect to the server and
    allow admin:monit      # require user 'admin' with password 'monit'
    allow @monit           # allow users of group 'monit' to connect (rw)
    allow @users readonly  # allow users of group 'users' to connect readonly
FRAGMENT

# Tworzymy własny plik konfiguracyjny

cat >> /etc/monit.d/my <<END
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
  exit 1
fi

# Można też np. coś takiego
#check file nazwa_pliku path /tmp/nazwa_pliku
#if does not exist then alert
#alert root@localhost


# Status:
monit status
