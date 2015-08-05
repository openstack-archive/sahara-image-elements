#!/bin/bash
# dib-lint: disable=executable

if [ "${DIB_DEBUG_TRACE:-0}" -gt 0 ]; then
    set -x
fi
set -eu
set -o pipefail

DISTRO="$(lsb_release -is)"

case "$DISTRO" in
    Ubuntu )
        sudo service mysql start
        ;;
    Fedora | RedHatEnterpriseServer )
        sudo service mysqld start
        ;;
    CentOS )
        case "$(lsb_release -rs)" in
            7.*)
                sudo service mariadb start
                ;;
            6.*)
                sudo service mysqld start
                ;;
        esac
        ;;
esac
