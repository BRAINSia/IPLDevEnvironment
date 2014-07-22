#!/bin/sh

# RHEL
OSTAG=$(lsb_release -d | awk '{print substr($2,0,1)substr($3,0,1)substr($4,0,1)substr($5,0,1)substr($8,0,1)}')  # RHEL%

if [[ ${OSTAG:0:4} != "RHEL" ]]; then
    # CentOS
    if [[ $(lsb_release -d | awk '{print $2}') == 'CentOS' ]]; then
        echo "WARNING: Found CentOS" 1>&2
        VERSION_OS=$(lsb_release -d | awk '{print substr($4, 0, 1)}')
        OSTAG=$(echo "RHEL${VERSION_OS}")
    else
        exit $ERR_UNKNOWN_OS
    fi
fi
echo $OSTAG
