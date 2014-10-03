#!/bin/bash

if [ $(lsb_release -is) = 'Ubuntu' ]; then
    sudo service mysql start
elif [ $(lsb_release -is) = 'Fedora' -o $(lsb_release -is) = 'CentOS' -o $(lsb_release -is) = 'RedHatEnterpriseServer' ]; then
    sudo service mysqld start
fi
