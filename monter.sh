#!/bin/bash

sed -i '1i export PATH="$HOME/.composer/vendor/bin:$PATH"' $HOME/.bashrc
source $HOME/.bashrc
composer global require drush/drush:dev-master
drush status
drush dl drush_language


cd ~
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
# echo "gem: --no-document" >> ~/.gemrc   
\curl -sSL https://get.rvm.io | bash -s stable --rails
#source /home/monter/.rvm/scripts/rvm
source ~/.rvm/scripts/rvm
source ~/.bashrc
rvm list
