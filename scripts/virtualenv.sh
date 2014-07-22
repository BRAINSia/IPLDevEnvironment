#!/bin/bash
unset PYTHONPATH

download_virtualenv () {
    FILENAME=virtualenv-${VERSION_VIRTUALENV}.tar.gz
    if [[ -f ${MYSOURCE}/${FILENAME} && "${FORCE}" == false ]]; then
        return ${SUCCESS}
    fi
    FLAGS="--no-check-certificate"
    ADDRESS=https://pypi.python.org/packages/source/v/virtualenv/${FILENAME}
    if download_file ${FILENAME} ${ADDRESS} ${FLAGS} ; then
        return $(cp ${MYSOURCE}/${FILENAME} ${TMPDIR})
    else
        return ${ERR_DOWNLOAD}
    fi
}

build_virtualenv() {
    if [[ -z $1 ]]; then
        usage
        return ${ERR_VIRTUALENV}
    else
        if [[ ${#} -eq 1 ]]; then
            MYENV=$1
        else
            MODULES=$1
            MYENV=$2
            if ! load_modules ${MODULES} ; then
                return $?
            fi
        fi
    fi
    if [[ "${CONTINUE}" == true && -f ${MYBUILD}/activate_${MYENV} ]]; then
        return 0
    fi
    if [[ -d ${MYBUILD}/virtualenv-${VERSION_VIRTUALENV} ]]; then
        mv ${MYBUILD}/virtualenv-${VERSION_VIRTUALENV} /tmp/junk_cmake
    fi
    cd ${TMPDIR}
    echo "Decompressing virtualenv (version ${VERSION_VIRTUALENV})..." >&2
    if tar -xzf ${MYSOURCE}/virtualenv-${VERSION_VIRTUALENV}.tar.gz ; then
        echo "Building virtualenv (version ${VERSION_VIRTUALENV})..." >&2
        cd ${TMPDIR}/virtualenv-${VERSION_VIRTUALENV}
        COMMAND="python virtualenv.py --always-copy ${MYBUILD}/${MYENV}"
        if ! ${COMMAND} >&2 ; then
            echo "ERROR during virtualenv creation." >&2
            echo "Rerun: " >&2
            echo "     ${COMMAND} " >&2
            echo " to diagnose the issue." >&2
            return ${ERR_VIRTUALENV}
        fi
    else
        echo "Could not uncompress virtualenv package!  Halting."
        return ${ERR_MISSING_DIR}
    fi
    if [[ -f ${MYBUILD}/${MYENV}/bin/activate ]]; then
        ln -s ${MYBUILD}/${MYENV}/bin/activate ${MYBUILD}/activate_${MYENV}
    else
        return ${ERR_MISSING_FILE}
    fi
    source ${MYBUILD}/activate_${MYENV}
    # ORDER OF PACKAGES IS IMPORTANT! TEST BEFORE REARRANGING/DELETING!!!
    PACKAGES='nose python-dateutil six wsgiref numpy scipy matplotlib tornado ipython networkx nibabel traits pydicom'
    echo "Installing Python packages..." >&2
    for PACKAGE in ${PACKAGES} ; do
        pip install ${PACKAGE} >&2
        if [[ $? -ne 0 ]]; then
            echo "Pip failed to install ${PACKAGE}"
            return ${ERR_VIRTUALENV}
        fi
    done
    return ${SUCCESS}
}

function usage () {
    echo "Usage: ${0} [-h] [-v] [-c] [-r] [-m MODULES] -V VERSION -s SOURCE -b BUILD" >&2
    echo "" >&2
    echo "  -b BUILD    directory to build in" >&2
    echo "  -c          continue previous build" >&2
    echo "  -m MODULES  Python/virtualenv modules to load" >&2
    echo "  -h          print this message" >&2
    echo "  -r          refresh/redownload source files" >&2
    echo "  -s SOURCE   directory to create/continue" >&2
    echo "  -v          verbose" >&2
    echo "  -V VERSION  Virtualenv version to build variable: VERSION_VIRTUALENV" >&2
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
while getopts ':o:b:cfhm:rs:vV:' OPTION ; do
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
		v)	VERBOSE=true
			;;
        V)  VERSION_VIRTUALENV=${OPTARG}
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

if [[ ! ${VERSION_VIRTUALENV} ]]; then
    echo "ERROR: Must provide version if VERSION_VIRTUALENV variable is not defined!" >&2
    usage ${EXIT_ERROR}
fi

if download_virtualenv ; then
    if build_virtualenv ${MODULES} python_HD; then
        exit ${SUCCESS}
    fi
fi

exit $?
