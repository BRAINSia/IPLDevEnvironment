#!/bin/sh

download_source_code() {
    cd ${MYSOURCE}
    curl -OL http://www.cmake.org/files/v${CMAKE_MAJOR_MINOR}/cmake-${CMAKE_VERSION}.tar.gz
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
    curl -O https://pypi.python.org/packages/source/v/virtualenv/virtualenv-${VENV_VERSION}.tar.gz
    wget http://download.qt-project.org/official_releases/qt/${QT_MAJOR_MINOR}/${QT_VERSION}/qt-everywhere-opensource-src-${QT_VERSION}.tar.gz
    # wget http://netlib.org/atlas/atlas3.6.0.tgz
    # wget http://www.netlib.org/lapack/lapack-3.5.0.tgz
    # wget http://netlib.org/blas/blas.tgz

}
build_cmake() {
    echo "Building CMake (version ${CMAKE_VERSION})..."
    cd ${MYBUILD}
    tar -xzf ${MYSOURCE}/cmake-${CMAKE_VERSION}.tar.gz
    cd cmake-${CMAKE_VERSION}
    ./bootstrap --prefix=${MYBUILD}/cmake-bin 1>${MYBUILD}/.log/cmake.stdout 2> ${MYBUILD}/.log/cmake.stderr
    gmake && gmake install
    export PATH=${MYBUILD}/cmake-bin/bin:${PATH}
    echo "Success! Added CMake bin to PATH."
}

build_python() {
    module load python/2.7
    # cd ${MYBUILD}
    # tar -xzf ${MYSOURCE}/Python-${PYTHON_VERSION}.tgz
    # cd Python-${PYTHON_VERSION}
    # CC=/usr/bin/gcc; CPP=/usr/bin/g++; ./configure --prefix=${MYBUILD}/python-bin --enable-shared
    # make
    # make test  ## Will throw error on NFS mounted filesystems: http://bugs.python.org/issue21483
    # make install
    # ln -s ${MYBUILD}/python_bin/bin/python${PYTHON_MAJOR_MINOR} ${MYBUILD}/python_bin/bin/python
    # echo "Success! Adding Python bin to PATH."
    # export PATH=${MYBUILD}/python_bin/bin:${PATH}
    # # Add Python libraries to env
    # export LD_LIBRARY_PATH=${MYBUILD}/python_bin/lib
    # export DYLD_LIBRARY_PATH=${MYBUILD}/python_bin/lib
}

build_qt() {
    if ! which Xorg; then  # Verify you have X11 available
        echo "X11 not available on system.  Please try again with X11"
        return -2
    fi
    #NEON: qlogin -pe smp 16 -q HJ
    cd /tmp  # Builds faster on local drive
    tar -xzf ${MYSOURCE}/qt-everywhere-opensource-src-${QT_VERSION}.tar.gz
    cd qt-everywhere-opensource-src-${QT_VERSION}
    ./configure --prefix=${MYBUILD}/qt-bin -opensource -qt-zlib -qt-libtiff -qt-libpng -qt-libmng -qt-libjpeg -arch x86_64
    gmake && gmake install
    export PATH=${MYBUILD}/qt-bin/bin:${PATH}
}

build_virtualenv() {
    cd ${MYBUILD}
    tar -xzf ${MYSOURCE}/virtualenv-${VENV_VERSION}.tar.gz
    MYENV=${MYBUILD}/python_HD
    python ${MYBUILD}/virtualenv-${VENV_VERSION}/virtualenv.py --always-copy ${MYENV}
    source ${MYENV}/bin/activate
    # Medusa: no BLAS library!
    # build_ATLAS()
    pip install nose python-dateutil six wsgiref
    pip install numpy scipy matplotlib tornado pyzmq ipython
    pip install networkx nibabel traits
    pip install pydicom
}

build_ATLAS() {
    echo "DEPRECATED"
    ## tar -xzf ${MYSOURCE}/blas.tgz
    ## export BLAS_SRC=${MYBUILD}/BLAS
    # tar -xzf ${MYSOURCE}/atlas3.6.0.tgz
    # cd ATLAS
    # make # --with-netlib-lapack-tarfile=${MYSOURCE}/lapack-3.5.0.tgz
    # make install arch=RHEL6_Medusa# --prefix=${MYBUILD}/atlas-bin
}

build_NEP() {
   mkdir ${MYBUILD}/NAMIC-build
   cd ${MYBUILD}/NAMIC-build
   CC=/usr/bin/gcc \
     CXX=/usr/bin/g++ \
     ccmake ${MYSOURCE}/NAMICExternalProjects/ \
     -DQT_QMAKE_EXECUTABLE:FILEPATH=${MYBUILD}/qt-bin/bin/qmake \
     -DPYTHON_EXECUTABLE:FILEPATH=$(which python) \
     -CMAKE_INSTALL_PREFIX:FILEPATH=${MYBUILD} \
     #-DPYTHON_LIBRARY:PATH=${MYBUILD}/python_bin/lib/ \
     #-DPYTHON_INCLUDE_DIR:PATH=${MYBUILD}/python_bin/include/ \
     #-D_python_h:FILEPATH=${MYBUILD}/python_bin/include/python${PYTHON_MAJOR_MINOR}/pythonrun.h \
     -DSITK_INT64_PIXELIDS:BOOL=OFF  # SimpleITK flag
   make -j 12 -k
   make install
   echo "PYTHONPATH=${MYBUILD}/NAMIC-build/SimpleITK-build/Wrapping/:${MYBUILD}/NAMIC-build/NIPYPE \
export PYTHONPATH \
PATH=${MYBUILD}/NAMIC-build/bin:$PATH \
export PATH" >> ${MYENV}/bin/activate
}

# MAIN
mkdir -p $MYSOURCE
mkdir -p $MYBUILD/.log

# download_source_code()
# build_cmake()
# build_python()
# build_virtualenv()
# build_qt()
# build_NEP()
env
