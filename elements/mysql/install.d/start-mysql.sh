#!/bin/bash

if [ "${DIB_DEBUG_TRACE:-0}" -gt 0 ]; then
    set -x
fi
set -eu
set -o pipefail

if [ $(lsb_release -is) = 'Ubuntu' ]; then
    sudo service mysql start
elif [ $(lsb_release -is) = 'Fedora' -o $(lsb_release -is) = 'CentOS' -o $(lsb_release -is) = 'RedHatEnterpriseServer' ]; then
    sudo service mysqld start
fi
