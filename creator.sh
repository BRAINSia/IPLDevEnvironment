#!/bin/sh

# GLOBAL ENV variables
# export PATH=/bin:/sbin:/usr/bin:/usr/sbin
# unset LD_LIBRARY_PATH

# System ENV variables
if [[ ! ${DATETAG} ]]; then
    export DATETAG=$(date "+%Y%m%d")
fi

SYSTEM=$(uname -s)
if [[ ${SYSTEM} == "Darwin" ]]; then
    OSTAG=$(scripts/osx.sh)
elif [[ ${SYSTEM} == "Linux" ]]; then
    OSTAG=$(scripts/linux.sh)
else
    echo "System is not one recognized by creator.sh.  Quiting"
    exit $ERR_UNKNOWN_SYS
fi
# HACK
if [[ ${OSTAG} != "RHEL6" ]]; then
    echo "Error: OSTAG not set correctly!"
    exit $ERR_UNKNOWN_OS
fi
# END HACK

BASEDIR=/Shared/sinapse/sharedopt
if [[ ! -d ${BASEDIR} ]]; then
    exit $ERR_MISSING_DIR
fi
export MYSOURCE=${BASEDIR}/$DATETAG/source
export MYBUILD=${BASEDIR}/$DATETAG/$OSTAG

# Application variables
## CMake
export CMAKE_MAJOR_MINOR=2.8
CMAKE_BUILD_REV=12.2
export CMAKE_VERSION=${CMAKE_MAJOR_MINOR}.${CMAKE_BUILD_REV}
# Python
export PYTHON_MAJOR_MINOR=2.7
PYTHON_REV=7
export PYTHON_VERSION=${PYTHON_MAJOR_MINOR}.${PYTHON_REV}
unset PYTHONPATH
# Virtualenv
VENV_VERSION=1.11.6
# QT
export QT_MAJOR_MINOR=4.8
QT_REV=6
export QT_VERSION=${QT_MAJOR_MINOR}.${QT_REV}
unset QTLIB
unset QTINC
unset QTDIR
# FreeSurfer
unset FREESURFER_HOME
