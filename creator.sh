#!/bin/sh

# GLOBAL ENV variables
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
unset LD_LIBRARY_PATH

# System ENV variables
export DATETAG=$(date "+%Y%m%d")
SYSTEM=$(uname -s)
if [[ ${SYSTEM} -eq "Darwin" ]]; then
    # SYSTEM=$(sw_vers | awk '"ProductName:" == $1 {print $3$4}')  # OSX
    VERSION=$(sw_vers | awk '"ProductVersion:" == $1 {split($2,version,"."); print version[1]"."version[2]}')  # 10.9
    OSTAG=${SYSTEM}_${VERSION}  #Darwin_10.9
elif [[ ${SYSTEM} -eq "Linux" ]]; then
    OSTAG=$(lsb_release -d | awk '{print substr($2,0,1)substr($3,0,1)substr($4,0,1)substr($5,0,1)substr($8,0,1)}')  # RHEL6
else
    echo "System is not one recognized by creator.sh.  Quiting"
    return 1
fi
BASEDIR=/Shared/sinapse/sharedopt
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

exec "$@"
