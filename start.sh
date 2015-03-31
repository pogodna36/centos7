#!/bin/bash

yum --security check-update

cat /etc/redhat-release
# CentOS Linux release 7.0.1406 (Core) 

# netstat -pantu

#-----------------------------------------------------------------------
# timezone
#-----------------------------------------------------------------------

# @todo Nie każdy Ubuntu 14.04 ma timedatectl. VPS'y OVH Classic nie mają tej komendy,
# natomiast VPS'y Cloud mają. Zapewne chodzi o sposób wirualizacji.
# Please note that timedatectl command can be used only on a system booted with systemd.

# Jaka strefa czasowa:
# cat /etc/timezone
# lub
# timedatectl

# Zmiana strefy czasowej w skrypcie:
timedatectl set-timezone Europe/Warsaw
# Można też w sposób:
# tzselect
# dpkg-reconfigure tzdata


#-----------------------------------------------------------------------
# ssh port
#-----------------------------------------------------------------------
# Zmiana portu SSH
vi /etc/ssh/sshd_config
# If you want to change the port on a SELinux system, you have to tell
# SELinux about this change.
# semanage port -a -t ssh_port_t -p tcp #PORTNUMBER
# Port 22022
# AddressFamily any
# ListenAddress 0.0.0.0
# ListenAddress ::

# ------------------------------------------------------------------------
# Klucze ssh
# ------------------------------------------------------------------------
# Generujemy klucze na serwerze lokalnym:
#ssh-keygen -t rsa
# Kopiujemy klucz publiczny na serwer zdalny:
#ssh-copy-id -i root@217.160.90.142

#-----------------------------------------------------------------------
# Linux tunnig
#-----------------------------------------------------------------------
cat >> /etc/sysctl.conf <<END
# When kernel panic's, reboot after 10 second delay
kernel.panic = 10
kernel.panic_on_oops = 1

# TCP SYN Flood Protection
#
# Wartość syn_backlog standardowo posiada wartość równą „1024”, a synack_retries „5”.
# Pierwsza z nich określa maksymalną ilość zapamiętanych żądań połączeń, które nadal nie zostały potwierdzone.
# Druga zmienna określa ile pakietów SYN,ACK system wyśle zanim uzna, że połączenie nie może zostać zrealizowane.
# Poprzez zwiększenie limitu oraz obniżenie ilości pakietów wartości te potrafią wpłynąć na optymalizację
# mechanizmu SYN Cookies.
# Należy jednak być ostrożnym przy ustawianiu w/w parametrów ze względu na fakt, iż pierwszy wpływa na zużycie
# pamięci RAM (domyślna wartość 1024 jest właściwa dla systemów z pamięcią powyżej 128MB, a 128 jest dobre
# dla komputerów z mniejszą ilością pamięci), a drugi może sprawić kłopoty z komunikacją za pomocą wolniejszych łączy.
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 3
END

sysctl -p

# Nie zapominij o edycji pliku /etc/sysctl.conf

echo "@see https://computing.llnl.gov/linux/slurm/high_throughput.html"
echo "/proc/sys/fs/file-max: The maximum number of concurrently open files."
echo "We recommend a limit of at least 32832."
echo "Na tym serwerze:"
sysctl fs.file-max
echo "If your Linux server is opening lots of outgoing network connection,"
echo "you need to increase local port range. By default range is small." 
echo "Na tym serwerze:"
sysctl net.ipv4.ip_local_port_range
echo "/proc/sys/net/core/somaxconn: Limit of socket listen() backlog, known in userspace as SOMAXCONN."
echo "Defaults to 128. The value should be raised substantially to support bursts of request."
echo "For example, to support a burst of 1024 requests, set somaxconn to 1024."
echo "Na tym serwerze:"
sysctl net.core.somaxconn
