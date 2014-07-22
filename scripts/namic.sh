#!/bin/bash
unset PYTHONPATH

download_namic ()
{
    cd ${MYSOURCE}
    DIRECTORY=NAMICExternalProjects
    if [[ ! -d ${DIRECTORY} ]]; then
        if ! git clone https://github.com/BRAINSia/${DIRECTORY}.git; then
            return ${ERR_DOWNLOAD}
        fi
    fi
    cd ${DIRECTORY}
    if ! git checkout ${TAG_NAMIC} ; then
        echo "Git checkout failed! Please verify the TAG_NAMIC hash in the config file" >&2
        return ${ERR_DOWNLOAD}
    else
        return ${SUCCESS}
    fi
}

build_namic()
{
    if [[ -h  ${VIRTUALENV} || -f ${VIRTUALENV} ]]; then
        source ${VIRTUALENV}
    else
        echo "Cannot find a virtualenv for ${VIRTUALENV}" >&2
        exit ${ERR_NAMIC_BUILD}
    fi
    mv ${MYBUILD}/NAMIC-build ${MYBUILD}/.NAMIC-build.temp
    rm -rf ${MYBUILD}/.NAMIC-build.temp &
    #TODO: CONTINUE AND REFRESH cases...
    #       -DPYTHON_INCLUDE_DIR:DIRPATH="" \
    #      -DPYTHON_LIBRARY:FILEPATH="" \
    mkdir ${MYBUILD}/NAMIC-build
    cd ${MYBUILD}/NAMIC-build
    # NOTE: PATH should be modified BEFORE running this function!
    CC=$(which gcc) \
    CXX=$(which g++) \
    cmake ${MYSOURCE}/NAMICExternalProjects/ \
      -DQT_QMAKE_EXECUTABLE:FILEPATH=$(which qmake) \
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
export PATH" >> ${VIRTUALENV}
    return $?
}

function usage () {
    echo "Usage: ${0} [-h] [-v] [-c] [-r] [-m MODULES...] -t TAG -s SOURCE -b BUILD -V VENV" >&2
    echo "" >&2
    echo "  -b BUILD    directory to build in" >&2
    echo "  -c          continue previous build" >&2
    echo "  -m MODULES  Python/virtualenv modules to load" >&2
    echo "  -h          print this message" >&2
    echo "  -r          refresh/redownload source files" >&2
    echo "  -s SOURCE   directory to create/continue" >&2
    echo "  -t TAG      Git tag to use"
    echo "  -v          verbose" >&2
    echo "  -V VENV     virtualenv source file"
    echo "Number of inputs is ${#}" >&2
	[[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}

# MAIN
SCRIPTNAME=$(basename ${0})
DIRNAME=$(dirname ${0})
source ${DIRNAME}/codes.sh
source ${DIRNAME}/functions.sh

CONTINUE=false
REFRESH=false
VERBOSE=false
FORCE=false
while getopts ':o:b:cfhm:rs:t:vV:' OPTION ; do
	case ${OPTION} in
        b)  MYBUILD=${OPTARG}
            ;;
        c)  CONTINUE=true
            ;;
        f)  FORCE=true
            ;;
		h)	usage ${SUCCESS}
			;;
        m)  MODULES=${OPTARG}
            ;;
        r)  REFRESH=true
            ;;
        s)  MYSOURCE=${OPTARG}
            ;;
        t)  TAG_NAMIC=${OPTARG}
            ;;
		v)	VERBOSE=true
            ;;
		V)  VIRTUALENV=${OPTARG}
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

if [[ ! ${TAG_NAMIC} ]]; then
    echo "ERROR: Must provide Git tag" >&2
    usage ${EXIT_ERROR}
fi

if ! load_modules ${MODULES} ; then
    return $?
fi

if download_namic ; then
    if build_namic ${VIRTUALENV}; then
        exit ${SUCCESS}
    else
        exit $?
    fi
else
    exit ${ERR_DOWNLOAD}
fi
