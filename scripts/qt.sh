#!/bin/bash
unset QTLIB
unset QTINC
unset QTDIR

download_qt ()
{
    FILENAME=qt-everywhere-opensource-src-${VERSION_QT}.tar.gz
    if [[ -f ${MYSOURCE}/${FILENAME} && "${FORCE}" == false ]]; then
        return ${SUCCESS}
    fi
    MAJOR_MINOR=$(expr "${VERSION_QT}" : '\(^[0-9]*\.[0-9]*\)')
    ADDRESS=http://download.qt-project.org/official_releases/qt/${MAJOR_MINOR}/${VERSION_QT}/${FILENAME}
    if download_file ${FILENAME} ${ADDRESS} ; then
        return $(cp ${MYSOURCE}/${FILENAME} ${TMPDIR})
    else
        return ${ERR_DOWNLOAD}
    fi
}

build_qt()
{
    if [[ "${CONTINUE}" == true && -f ${MYBUILD}/qt-bin/bin/qmake ]]; then
        return 0
    fi
    if [[ ! -f $(which Xorg) ]] ; then  # Verify you have X11 available
        echo "X11 not available on system.  Please try again with X11" >&2
        echo "##############################################################################" >&2
        echo "#  If on a cluster, are you building on a machine other than the head node?  #" >&2
        echo "##############################################################################" >&2
        return ${ERR_MISSING_X11}
    fi
    if [[ "${REFRESH}" == true && -d ${TMPDIR}/${FILE} ]] ; then
        cd ${TMPDIR}/${FILE}
        make confclean
    fi
    echo "Decompressing QT (version ${VERSION_QT})..." >&2
    FILE=qt-everywhere-opensource-src-${VERSION_QT}
    if [[ -d ${MYBUILD}/${FILE} ]]; then
        mv ${MYBUILD}/${FILE} /tmp/junk_cmake
    fi
    cd ${TMPDIR}
    tar -xzf ${MYSOURCE}/${FILE}.tar.gz
    wait
    cd ${TMPDIR}/${FILE}
    echo "Building QT (version ${VERSION_QT})..." >&2
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
    # 1>${MYBUILD}/.log/qt.stdout 1>&2 \ #2>${MYBUILD}/.log/qt.stderr
    # FIXME: --prefix=${MYBUILD}/bin
    wait
    if make -j8 ; then
        if make install ; then
            #export PATH=${MYBUILD}/qt-bin/bin:${PATH}
            return ${SUCCESS}
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
        V)  VERSION_QT=${OPTARG}
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

if [[ ! ${VERSION_QT} ]]; then
    echo "ERROR: Must provide version" >&2
    usage ${EXIT_ERROR}
fi

if download_qt ; then
    if build_qt ; then
        exit ${SUCCESS}
    else
        exit $?
    fi
else
    exit ${ERR_DOWNLOAD}
fi
