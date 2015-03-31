#!/bin/bash

# install tcpdf
cd /var/www/$(hostname -f)
wget http://sourceforge.net/projects/tcpdf/files/tcpdf_6_0_099.zip
unzip tcpdf*
rm -f tcpdf_6_0_*.zip
mkdir tcpdf/images
chmod 777 /var/www/$(hostname -f)/tcpdf/images
