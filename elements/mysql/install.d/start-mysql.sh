#!/bin/bash
if [ $(lsb_release -is) = 'Ubuntu' ]; then
  sudo service mysql start
elif [ $(lsb_release -is) = 'Fedora' ]; then
  sudo service mysqld start
fi
