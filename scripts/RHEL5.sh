#!/bin/bash
SCRIPTNAME=$(basename ${0})
DEBUG=false
BUILD_CMAKE=true
BUILD_PYTHON=false
BUILD_QT=true
BUILD_VIRTUALENV=true
BUILD_NAMIC=true

REFRESH=false
VERBOSE=false
RUN_TESTS=false
CONTINUE=false

function usage ()
{
	echo "Usage: ${SCRIPTNAME} [-h] [-v] [-t] [-c] [-r] [-d DIR]" >&2
    echo "" >&2
    echo "  -h       print this message" >&2
    echo "  -v       verbose" >&2
    echo "  -t       testing on" >&2
    echo "  -c       continue previous build" >&2
    echo "  -r       refresh/redownload source files" >&2
    echo "  -d DIR   directory to create/continue (default:'YYYYMMDD')" >&2
    debug
    echo "Number of inputs is ${#}" >&2
	[[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}

function debug ()
{
    if [[ "${DEBUG}" == true ]]; then
        set | sort > set.sorted
        printenv | sort > printenv.sorted
        printf "\n--------------------DEBUG--------------------\n"
        diff set.sorted printenv.sorted | grep "<" | awk '{ print $2}'
        printf "\n---------------------------------------------\n"
    fi
}

download_source_code()
{
    if [[ "${BUILD_CMAKE}" == true ]]; then
        download_cmake
    fi
    if [[ "${BUILD_QT}" == true ]]; then
        download_qt
    fi
    if [[ "${BUILD_VIRTUALENV}" == true ]]; then
        download_virtualenv
    fi
    if [[ "${BUILD_NAMIC}" == true ]]; then
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
    if [[ "${CONTINUE}" == true && -f ${MYBUILD}/cmake-bin/bin/cmake ]]; then
        return 0
    fi
    echo "Building CMake (version ${CMAKE_VERSION})..."
    cd ${MYBUILD}
    tar -xzf ${MYSOURCE}/cmake-${CMAKE_VERSION}.tar.gz
    cd cmake-${CMAKE_VERSION}
    ./bootstrap --prefix=${MYBUILD}/cmake-bin 1>${MYBUILD}/.log/cmake.stdout 2> ${MYBUILD}/.log/cmake.stderr
    wait
    if make ; then
        if make install ; then
            export PATH=${MYBUILD}/cmake-bin/bin:${PATH}
            echo "Success! Added CMake bin to PATH."
        else
            echo "Failed to install CMake! ERROR CODE: $? Halting."
            return ${ERR_CMAKE_INSTALL}
        fi
    else
        echo "Failed to build CMake! ERROR CODE: $? Halting."
        return ${ERR_CMAKE_BUILD}
    fi
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
    if [[ "${CONTINUE}" == true && -f ${MYBUILD}/qt-bin/bin/qmake ]]; then
        return 0
    fi
    if ! which Xorg; then  # Verify you have X11 available
        echo "X11 not available on system.  Please try again with X11"
        return -2
    fi
    #NEON: qlogin -pe smp 16 -q HJ
    cd /tmp  # Builds faster on local drive
    mkdir ${MYBUILD}/qt-bin
    tar -xzf ${MYSOURCE}/qt-everywhere-opensource-src-${QT_VERSION}.tar.gz
    cd qt-everywhere-opensource-src-${QT_VERSION}
    ./configure --prefix=${MYBUILD}/qt-bin \
                -opensource \
                -qt-zlib \
                -qt-libtiff \
                -qt-libpng \
                -qt-libmng \
                -qt-libjpeg \
                -arch x86_64 \
                <<QTLicenseAgree
yes
QTLicenseAgree
    wait
    if gmake ; then
        if gmake install ; then
            export PATH=${MYBUILD}/qt-bin/bin:${PATH}
            return 0
        else
            echo "Failed to install Qt. ERROR CODE: $? Halting."
            return ${ERR_QT_INSTALL}
        fi
    else
        echo "Failed to build Qt. ERROR CODE: $? Halting."
        return ${ERR_QT_BUILD}
    fi
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
    if tar -xzf ${MYSOURCE}/virtualenv-${VENV_VERSION}.tar.gz ; then
        python ${MYBUILD}/virtualenv-${VENV_VERSION}/virtualenv.py --always-copy ${MYBUILD}/${MYENV}
        wait
    else
        echo "Could not uncompress virtualenv package!  Halting."
        return ${ERR_MISSING_DIR}
    fi
    if [[ -f ${MYBUILD}/${MYENV}/bin/activate ]]; then
        ln -s ${MYBUILD}/${MYENV}/bin/activate ${MYBUILD}/activate_${MYENV}
    else
        return ${ERR_MISSING_FILE}
    fi
    # On Medusa: no BLAS library!
    # build_ATLAS()
    source ${MYBUILD}/activate_${MYENV}
    pip install nose python-dateutil six wsgiref
    wait
    pip install numpy scipy matplotlib tornado pyzmq ipython
    wait
    pip install networkx nibabel traits
    wait
    pip install pydicom
    wait
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
   source ${MYBUILD}/activate_$1
   CC=/usr/bin/gcc \
   CXX=/usr/bin/g++ \
   cmake ${MYSOURCE}/NAMICExternalProjects/ \
    -DQT_QMAKE_EXECUTABLE:FILEPATH=${MYBUILD}/qt-bin/bin/qmake \
    -DPYTHON_EXECUTABLE:FILEPATH=$(which python) \
    -CMAKE_INSTALL_PREFIX:FILEPATH=${MYBUILD} \
    -DSITK_INT64_PIXELIDS:BOOL=OFF  # SimpleITK flag
   wait
   if make -j 16 -k ; then
       if make install ; then
           continue
       else
           echo "Failed to install NAMIC. ERROR CODE: $? Halting."
           return ${ERR_NAMIC_INSTALL}
       fi
   else
       echo "Failed to build NAMIC. ERROR CODE: $? Halting."
       return ${ERR_NAMIC_BUILD}
   fi
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
source codes.sh
while getopts ':o:vhd:tcr' OPTION ; do
    # debug
	case ${OPTION} in
		v)	VERBOSE=true
			;;
		h)	usage 0
			;;
        t)  RUN_TESTS=true
            ;;
        c)  CONTINUE=true
            ;;
        d)  export DATETAG=${OPTARG}  # TODO: verify correct date formatting
            ;;
        r)  REFRESH=true
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
source scripts/download.sh

if [[ "$CONTINUE" == true ]]; then
    if [[ ! -d ${BASEDIR}/${DATETAG} ]]; then
        echo "Directory ${DATETAG} not found in ${BASEDIR}!" >&2
        usage ${ERR_MISSING_DIR}
    fi
fi

if [[ "${CONTINUE}" == "false" ]]; then
    mkdir -p ${MYSOURCE}
    mkdir -p ${MYBUILD}/.log
fi

if [[ ! -d ${MYSOURCE} || ! -d ${MYBUILD}/.log ]]; then
    echo "Cannot find $MYSOURCE or $MYBUILD! Halting."
    exit ${ERR_MISSING_DIR}
fi

eval $(/opt/modules/Modules/3.2.7/bin/modulecmd bash load python_2.7so)
if [[ $? -ne 0 ]]; then
    exit ${ERR_MODULE_LOAD}
fi

if [[ "${CONTINUE}" == false || "${REFRESH}" == true ]]; then
    download_source_code  # TODO: download source code if not there OR 'refresh' option
fi

if [[ true ]]; then
    echo "Building CMake..."
    #build_cmake
    .CMAKE_STATUS=$?
    echo "Building Qt..."
    build_qt
    QT_STATUS=$?
    echo "Building Python..."
    build_python
    PYTHON_STATUS=$?
    echo "Creating virtualenv..."
    MYENV=python_HD
    build_virtualenv ${MYENV}
    VENV_STATUS=$?
    wait
    if [[ $(expr ${VENV_STATUS} + ${CMAKE_STATUS} + ${QT_STATUS} + ${PYTHON_STATUS}) -eq 0 ]]; then
        echo "Building NAMICExternalProjects..."
        build_NEP ${MYENV}
        NAMIC_STATUS=$?
        wait
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
