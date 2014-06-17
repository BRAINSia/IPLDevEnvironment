#!/bin/bash
SCRIPTNAME=$(basename ${0} .sh)

BUILD_CMAKE=$(true)
BUILD_PYTHON=$(false)
BUILD_QT=$(true)
BUILD_VENV=$(true)
BUILD_NAMIC=$(true)

VERBOSE=$(false)
RUN_TESTS=$(true)

function usage ()
{
	echo "Usage: ${SCRIPTNAME} [-h] [-v] [-t] " >&2
    debug
	[[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}

function debug ()
{
    if [[ "$DEBUG" == "ON" ]]; then
        set | sort > set.sorted
        printenv | sort > printenv.sorted
        printf "\n--------------------DEBUG--------------------\n"
        diff set.sorted printenv.sorted | grep "<" | awk '{ print $2}'
        printf "\n---------------------------------------------\n"
    fi
}

download_source_code()
{
    if $BUILD_CMAKE; then
        download_cmake
    fi
    if $BUILD_QT; then
        download_qt
    fi
    if $BUILD_VIRTUALENV; then
        download_virtualenv
    fi
    if $BUILD_NAMIC; then
        download_namic
    fi
    return 0
    # el
    # wget http://netlib.org/atlas/atlas3.6.0.tgz
    # wget http://www.netlib.org/lapack/lapack-3.5.0.tgz
    # wget http://netlib.org/blas/blas.tgz
}

build_cmake()
{
    echo "Building CMake (version ${CMAKE_VERSION})..."
    cd ${MYBUILD}
    tar -xzf ${MYSOURCE}/cmake-${CMAKE_VERSION}.tar.gz
    cd cmake-${CMAKE_VERSION}
    ./bootstrap --prefix=${MYBUILD}/cmake-bin 1>${MYBUILD}/.log/cmake.stdout 2> ${MYBUILD}/.log/cmake.stderr
    gmake && gmake install
    export PATH=${MYBUILD}/cmake-bin/bin:${PATH}
    echo "Success! Added CMake bin to PATH."
    return 0
}

build_python()
{
    echo "DEPRECATED"
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
    return 0
}

build_qt()
{
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
    return 0
}

build_virtualenv()
{
    if [[ -z $1 ]]; then
        return $ERR_VIRTUALENV
    else
        MYENV=$1
    fi
    cd ${MYBUILD}
    tar -xzf ${MYSOURCE}/virtualenv-${VENV_VERSION}.tar.gz
    python ${MYBUILD}/virtualenv-${VENV_VERSION}/virtualenv.py --always-copy ${MYBUILD}/${MYENV}
    ln -s ${MYBUILD}/${MYENV}/bin/activate ${MYBUILD}/activate_${MYENV}
    # Medusa: no BLAS library!
    # build_ATLAS()
    source ${MYBUILD}/activate_${MYENV}
    pip install nose python-dateutil six wsgiref
    pip install numpy scipy matplotlib tornado pyzmq ipython
    pip install networkx nibabel traits
    pip install pydicom
    return 0
}

build_ATLAS()
{
    echo "DEPRECATED"
    ## tar -xzf ${MYSOURCE}/blas.tgz
    ## export BLAS_SRC=${MYBUILD}/BLAS
    # tar -xzf ${MYSOURCE}/atlas3.6.0.tgz
    # cd ATLAS
    # make # --with-netlib-lapack-tarfile=${MYSOURCE}/lapack-3.5.0.tgz
    # make install arch=RHEL6_Medusa# --prefix=${MYBUILD}/atlas-bin
    return 0
}

build_NEP()
{
   mkdir ${MYBUILD}/NAMIC-build
   cd ${MYBUILD}/NAMIC-build
   CC=/usr/bin/gcc \
     CXX=/usr/bin/g++ \
     ccmake ${MYSOURCE}/NAMICExternalProjects/ \
     -DQT_QMAKE_EXECUTABLE:FILEPATH=${MYBUILD}/qt-bin/bin/qmake \
     -DPYTHON_EXECUTABLE:FILEPATH=$(which python) \
     -CMAKE_INSTALL_PREFIX:FILEPATH=${MYBUILD} \
     -DSITK_INT64_PIXELIDS:BOOL=OFF  # SimpleITK flag
   make -j 12 -k
   make install
   echo "\
# --- SINAPSE-specific modifications ---
PYTHONPATH=${MYBUILD}/NAMIC-build/SimpleITK-build/Wrapping/:${MYBUILD}/NAMIC-build/NIPYPE \
export PYTHONPATH \
PATH=${MYBUILD}/NAMIC-build/bin:$PATH \
export PATH" >> ${MYBUILD}/${MYENV}/bin/activate
   return 0
}

test_nipype()
{
    if [[ ! -f ${MYBUILD}/activate_${MYENV} ]]; then
        return $ERR_LINKING
    fi
    if python -c "import nipype" ; then
        echo "import nipype: PASS"
    else
        echo "import nipype: FAIL"
        return $ERR_TESTING
    fi
    return 0
}

test_sitk()
{
    if [[ ! -f ${MYBUILD}/activate_${MYENV} ]]; then
        return $ERR_LINKING
    fi
    if python -c "import SimpleITK" ; then
        echo "import SimpleITK: PASS"
    else
        echo "import SimpleITK: FAIL"
        return $ERR_TESTING
    fi
    return 0
}

# MAIN
while getopts ':o:vht' OPTION ; do
    debug
	case ${OPTION} in
		v)	VERBOSE=$(true)
			;;
		h)	usage ${EXIT_SUCCESS}
			;;
        t)  RUN_TESTS=$(true)
            ;;
		\?)	echo "unknown option \"-${OPTARG}\"." >&2
			usage ${EXIT_ERROR}
			;;
		:)	echo "option \"-${OPTARG}\" requires an argument." >&2
			usage ${EXIT_ERROR}
			;;
		*)	echo "Impossible error. parameter: ${OPTION}" >&2
			usage ${EXIT_BUG}
			;;
	esac
done
source creator.sh
source $PWD/scripts/download.sh

if [[ -d ${MYSOURCE} ]]; then
    rm -rf ${MYSOURCE}  # TODO: Add option flag
fi
mkdir -p ${MYSOURCE}
if [[ ! -d ${MYSOURCE} ]]; then
    exit ${ERR_MISSING_DIR}
fi

if [[ -d ${MYBUILD} ]]; then
    rm -rf ${MYBUILD}  # TODO: Add option flag
fi
mkdir -p ${MYBUILD}/.log
if [[ ! -d ${MYBUILD}/.log ]]; then
    exit ${ERR_MISSING_DIR}
fi

if ! module load python/2.7; then
    exit ${ERR_MODULE_LOAD}
fi
if download_source_code ; then
    build_cmake;                     CMAKE_STATUS=$?
    build_qt;                        QT_STATUS=$?
    build_python;                    PYTHON_STATUS=$?
    MYENV=python_HD
    build_virtualenv ${MYENV};    VENV_STATUS=$?
    if [[ expr ${VENV_STATUS} + ${CMAKE_STATUS} + ${QT_STATUS} + ${PYTHON_STATUS} ]]; then
        source ${MYBUILD}/activate_${MYENV}
        build_NEP;                   NAMIC_STATUS=$?
        if ${NAMIC_STATUS}; then
            deactivate
            if ${RUN_TESTS}; then
                source ${MYBUILD}/activate_${MYENV}
                test_nipype
                test_sitk
            fi
        else
            exit ${ERR_NAMIC}
        fi
    else
        exit `expr ${VENV_STATUS} + ${CMAKE_STATUS} + ${QT_STATUS} + ${PYTHON_STATUS}`
    fi
    echo "To activate virtualenv: \n\$ . ${MYBUILD}/activate_${MYENV} \n\nTo deactivate virtualenv:\n\$ deactivate\n\nDon't forget to load the Python module FIRST: \n\$ module load python/2.7"
else
    exit ${ERR_DOWNLOAD}
fi
exit ${SUCCESS}
