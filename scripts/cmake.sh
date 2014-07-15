#!/bin/bash
source codes.sh
source functions.sh

download_cmake ()
{
    FILENAME=cmake-${CMAKE_VERSION}.tar.gz
    MAJOR_MINOR=$(expr "${CMAKE_VERSION}" : '\(^[0-9]*\.[0-9]*\)')
    ADDRESS=http://www.cmake.org/files/v${MAJOR_MINOR}/${FILENAME}
    return download_file ${FILENAME} ${ADDRESS}
}

build_cmake () {
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
            return 0
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
    echo "Usage: ${0} [-h] [-v] [-t] [-c] [-r] [-V VERSION] -s SOURCE -b BUILD" >&2
    echo "" >&2
    echo "  -b BUILD    directory to build in" >&2
    echo "  -c          continue previous build" >&2
    echo "  -d SOURCE   directory to create/continue" >&2
    echo "  -h          print this message" >&2
    echo "  -r          refresh/redownload source files" >&2
    echo "  -t          testing on" >&2
    echo "  -v          verbose" >&2
    echo "  -V VERSION  CMake version to build variable: CMAKE_VERSION" >&2
    echo "Number of inputs is ${#}" >&2
	[[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}

# MAIN
while getopts ':o:vhd:tcr' OPTION ; do
	case ${OPTION} in
        b)  MYBUILD=${OPTARG}
            ;;
        c)  CONTINUE=true
            ;;
        d)  MYSOURCE=${OPTARG}
            ;;
		h)	usage ${SUCCESS}
			;;
        r)  REFRESH=true
            ;;
        t)  RUN_TESTS=true
            ;;
		v)	VERBOSE=true
			;;
        V)  CMAKE_VERSION=${OPTARG}
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

# if [[ ! ${MYBUILD} || ${#MYBUILD} -eq 0 || ! ${MYSOURCE} || ${#MYSOURCE} -eq 0 ]]; then
#     source directory.sh
# fi

if [[ ! ${CMAKE_VERSION} ]]; then
    echo "ERROR: Must provide version if CMAKE_VERSION variable is not defined!" >&2
    usage ${EXIT_ERROR}
fi

if download_cmake; then
    exit build_cmake
else
    exit ${ERR_DOWNLOAD}
fi
