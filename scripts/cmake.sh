#!/bin/bash
download_cmake ()
{
    FILENAME=cmake-${VERSION_CMAKE}.tar.gz
    if [[ -f ${MYSOURCE}/${FILENAME} && "${FORCE}" == false ]]; then
        return ${SUCCESS}
    fi
    MAJOR_MINOR=$(expr "${VERSION_CMAKE}" : '\(^[0-9]*\.[0-9]*\)')
    ADDRESS=http://www.cmake.org/files/v${MAJOR_MINOR}/${FILENAME}
    if download_file ${FILENAME} ${ADDRESS} ; then
        return $(cp ${MYSOURCE}/${FILENAME} ${TMPDIR})
    else
        return ${ERR_DOWNLOAD}
    fi
}

build_cmake () {
    if [[ "${CONTINUE}" == true && -f ${MYBUILD}/cmake-bin/bin/cmake ]]; then
        return 0
    fi
    echo "Decompressing CMake (version ${VERSION_CMAKE})..." >&2
    if [[ -d ${MYBUILD}/cmake-${VERSION_CMAKE} ]]; then
        mv ${MYBUILD}/cmake-${VERSION_CMAKE} /tmp/junk_cmake
    fi
    cd ${TMPDIR}
    tar -xzf ${MYSOURCE}/cmake-${VERSION_CMAKE}.tar.gz
    wait
    cd cmake-${VERSION_CMAKE}
    echo "Building CMake (version ${VERSION_CMAKE})..." >&2
    ./bootstrap --prefix=${MYBUILD}/cmake-bin 1>${MYBUILD}/.log/cmake.stdout 1>&2  #2>${MYBUILD}/.log/cmake.stderr
    # FIXME: --prefix=${MYBUILD}/bin
    wait
    if make -j8 ; then
        if make install ; then
            # export PATH=${MYBUILD}/cmake-bin/bin:${PATH}
            # echo "Success! Added CMake bin to PATH."
            return ${SUCCESS}
        else
            echo "Failed to install CMake! ERROR CODE: $? Halting."
            return ${ERR_INSTALL}
        fi
    else
        echo "Failed to build CMake! ERROR CODE: $? Halting."
        return ${ERR_BUILD}
    fi
}

function usage () {
    echo "Usage: ${0} [-h] [-v] [-c] [-r] -V VERSION -s SOURCE -b BUILD" >&2
    echo "" >&2
    echo "  -b BUILD    directory to build in" >&2
    echo "  -c          continue previous build" >&2
    echo "  -s SOURCE   directory to create/continue" >&2
    echo "  -h          print this message" >&2
    echo "  -r          refresh/redownload source files" >&2
    echo "  -v          verbose" >&2
    echo "  -V VERSION  Version to build" >&2
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
while getopts ':o:b:cfhrs:vV:' OPTION ; do
	case ${OPTION} in
        b)  MYBUILD=${OPTARG}
            ;;
        c)  CONTINUE=true
            ;;
        f)  FORCE=true
            ;;
		h)	usage ${SUCCESS}
			;;
        r)  REFRESH=true
            ;;
        s)  MYSOURCE=${OPTARG}
            ;;
		v)	VERBOSE=true
			;;
        V)  VERSION_CMAKE=${OPTARG}
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

if [[ ! ${VERSION_CMAKE} ]]; then
    echo "ERROR: Must provide version" >&2
    usage ${EXIT_ERROR}
fi

if download_cmake ; then
    if build_cmake ; then
        exit ${SUCCESS}
    else
        exit $?
    fi
else
    exit ${ERR_DOWNLOAD}
fi
