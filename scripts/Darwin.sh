#!/bin/bash

create_dirs() {
    local BASEDIR=$1
    local DATETAG=$2
    local OSTAG=$(sw_vers | awk '"ProductName:" == $1 {print $3$4}')_$(sw_vers | awk '"ProductVersion:" == $1 {print $2}')  #OSX_10.8.4
    MYSOURCE=${BASEDIR}/${DATETAG}/source  # global
    MYBUILD=${BASEDIR}/${DATETAG}/${OSTAG}  # global
    mkdir -p ${MYSOURCE}
    local retval=$?
    if [[ -d ${MYSOURCE} ]]; then
        mkdir -p ${MYBUILD}
        return $?
    else
        return $retval
    fi
}

build_Qt ()
{
    # Go to http://qt-project.org/doc/qt-4.7/install-x11.html for directions...
    local VERSION=v$1
    local QTREPO=git://gitorious.org/qt/qt.git
    local QTSOURCE=${MYSOURCE}/qt
    local QTTEMP=${MYBUILD}/qt-${VERSION}
    local QTBUILD=${MYBUILD}/qt-bin
    echo "Building Qt version "${VERSION}"..."
    if [[ ! -d /Applications/Utilities/XQuartz.app ]]; then
        echo "X11 not found!"
        return 1
    fi
    if [[ ! -d ${QTBUILD} ]]; then
        if [[ ! -d ${QTTEMP} ]]; then
            if [[ ! -d ${QTSOURCE} ]]; then
                cd ${MYSOURCE}
                local retval=$(git clone ${QTREPO})
                if [[ -d ${QTSOURCE} ]]; then
                    echo "Qt Git initialization complete!"
                    cd ${QTSOURCE}
                else
                    echo "Error: 'git clone ${QTREPO} returns code ${retval}"
                    return 1
                fi
                git checkout ${VERSION}  #TODO: Check for success
            fi
            echo "Syncing repositiory to temp folder for in-source build..."
            rsync -av ${QTSOURCE} ${QTTEMP}
        fi
        cd ${QTTEMP}
        echo "Configuring project..."
        ./configure --prefix=${QTBUILD} -opensource -qt-zlib -qt-libtiff -qt-libpng -qt-libmng -qt-libjpeg -arch x86_64
        echo "Building project (single thread only)..."
        gmake && gmake install
    fi
    return $?
}

build_CMake ()
{
    cd ${MYSOURCE}
    curl -OL http://www.cmake.org/files/v2.8/cmake-$1.tar.gz
    cd ${MYBUILD}
    tar -xvf cmake-$1.tar.gz
    cd cmake-${MYCMAKEVERSION}/
    ./bootstrap --prefix=${MYBUILD}/cmake-bin
    make && make install
    return 0
}

#########################
# Make sure that your environment is sane
# export PATH=/bin:/sbin:/usr/bin:/usr/sbin
unset DYLD_LIBRARY_PATH
unset PYTHONPATH
unset FREESURFER_HOME
#########################
BASEDIR=/Volumes/scratch  #/Shared/sinapse/sharedopt
DATETAG='test' #$(date "+%Y%m%d")
MYQTVERSION=4.8.5
MYCMAKEVERSION=2.8.12

create_dirs ${BASEDIR} ${DATETAG}
build_Qt ${MYQTVERSION}
if [[ ! $? -eq 0 ]]; then
    echo "Qt build failed..."
    exit 1
fi

#if [[ build_CMake ${MYCMAKEVERSION} -eq 0 ]]; then
#    echo "CMake build failed..."
#    exit 1
#fi

export PATH=${MYBUILD}/cmake-bin/bin:$PATH

exit $?
