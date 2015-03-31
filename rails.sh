#!/bin/bash

# Skrypt instalujący frameworka Ruby on Rails (w skrócie Rails).
#
# Wymagania:
# Zainstalowany pakiet sudo.
# Oprogramowanie instaluje użytkownik w katalogu domowym.
# Użytkownik musi należeć do grupy wheel dla Centos'a lub sudo dla Debian'a.
cd ~

if [ ! -L /dev/fd ]; then
echo 'Nie istnieje link /dev/fd'
exit 1
fi

if [ -z "`which sudo 2>/dev/null`" ]; then
yum install -y sudo
fi

id | grep wheel 1>/dev/null
OUT=$?
if [ $OUT -ne 0 ]; then
  echo "Użytkownik nie należy do grupy wheel"
  exit 1
fi

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
# echo "gem: --no-document" >> ~/.gemrc   
\curl -sSL https://get.rvm.io | bash -s stable --rails
#source /home/monter/.rvm/scripts/rvm
source ~/.rvm/scripts/rvm
source ~/.bashrc
rvm list
    
gem install compass
gem install bundler

# Inne polecenia:
# rvm reload
# rvm list known
# rvm install 1.9.3

#
# Tworzymy testowy projekt Compass, który dodajemy do bundle (paczki)
#
cd ~
# tworzymy projekt Compass'a
compass create test

# tak tworzy się gema
# bundle gem marko
    
# przechodzimy do katalogu projektu test
cd test

# inicjujemy bundla:
bundle init
    
# Bundler utworzył plik Gemfile, dodajemy przykładowe kompnenty (compass, susy i singularitygs)
cat >> Gemfile <<END
gem 'compass'
gem 'susy'
gem 'singularitygs'
END

# Compass jest niezbędny, inaczej przy próbie kompilacji (np. bundle exec compass watch)
# dostaniemy komunikat: compass is not part of the bundle. Add it to Gemfile.

# instalujemy bundla, teraz zainstalowane zostaną komponenty wymienione w pliku Gemfile
# oraz ich zależności.
bundle install

# po zainstalowaniu bundla tworzony jest plik Gemfile.lock
# zaierający wykaz zainstalowanych komponentów wraz z ich numerami wersji.
