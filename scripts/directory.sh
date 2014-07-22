#!/bin/sh

TESTING=${1}
DIRNAME=$(dirname ${0})

if [[ ! ${BASEDIR} ]]; then
    if [[ ! ${DATETAG} ]]; then
        DATETAG=$(date "+%Y%m%d")
    fi
    BASEDIR=/Shared/sinapse/sharedopt/${DATETAG}
fi

SYSTEM=$(uname -s)
if [[ ${SYSTEM} == "Darwin" ]]; then
    OSTAG=$(${DIRNAME}/scripts/osx.sh)
elif [[ ${SYSTEM} == "Linux" ]]; then
    OSTAG=$(${DIRNAME}/scripts/linux.sh)
else
    echo "System is not one recognized by ${0}.  Quiting"
    exit $ERR_UNKNOWN_SYS
fi

if [[ ! ${MYSOURCE} || ${#MYSOURCE} -eq 0 ]]; then
    export MYSOURCE=${BASEDIR}/source
fi

if [[ ! ${MYBUILD} || ${#MYBUILD} -eq 0 ]]; then
    export MYBUILD=${BASEDIR}/${OSTAG}
else
    # VERIFY BUILD SYSTEM MATCHES BUILD DIR NAME
    echo "TODO: VERIFY BUILD SYSTEM MATCHES BUILD DIR NAME"
fi
