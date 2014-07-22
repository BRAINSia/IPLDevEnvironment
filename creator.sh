#!/bin/bash

# GLOBAL ENV variables
# export PATH=/bin:/sbin:/usr/bin:/usr/sbin
# unset LD_LIBRARY_PATH

function usage ()
{
	echo "Usage: ${SCRIPTNAME} [-h] [-v] [-t] [-c] [-r] [-d DIR] CONFIG" >&2
    echo "" >&2
    echo "  -h      print this message" >&2
    echo "  -v      verbose" >&2
    echo "  -t      testing on" >&2
    echo "  -c      continue previous build" >&2
    echo "  -r      refresh/redownload source files" >&2
    echo "  -d DIR  directory to create/continue (default:'/Shared/sinapse/sharedopt/YYYYMMDD')" >&2
    debug ${DEBUG}
    echo "Number of inputs is ${#}" >&2
	[[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}



# MAIN
SCRIPTNAME=$(basename ${0})
DIRNAME=$(dirname ${0})
DEBUG=false
REFRESH=false
VERBOSE=false
TESTING=false
CONTINUE=false

source ${DIRNAME}/scripts/codes.sh
source ${DIRNAME}/scripts/functions.sh
OPTIONS=$*
while getopts ':o:vhd:tcr' OPTION ; do
    debug ${DEBUG}
	case ${OPTION} in
		v)	VERBOSE=true
			;;
		h)	usage 0
			;;
        t)  TESTING=true
            ;;
        c)  CONTINUE=true
            ;;
        d)  export BASEDIR=${OPTARG}  # TODO: verify correct date formatting
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
shift $(($OPTIND - 1))
#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non-option item supplied on the command-line
#+ if one exists.
CONFIG=${1}

source ${DIRNAME}/scripts/directory.sh ${TESTING}

if [[ ! -d ${MYBUILD} ]]; then
    mkdir -p ${MYBUILD}/.log
fi
if [[ ! -d ${MYSOURCE} || "${FORCE}" == "true" ]]; then
    mkdir -p ${MYSOURCE}
fi
if [[ ! -d ${MYSOURCE} ]] ; then
    echo "ERROR: Missing source directory!" >&2
    exit ${ERR_MISSING_DIR}
fi

export TMPDIR=/tmp/$(basename $(dirname ${MYBUILD}))_build
mkdir -p $TMPDIR

# TODO: REFRESH option, etc...
if [[ "${TESTING}" == "true" ]]; then
    echo "MYBUILD = $MYBUILD" >&2
    echo "MYSOURCE = $MYSOURCE" >&2
    echo "OSTAG = ${OSTAG}" >&2
fi
${DIRNAME}/scripts/${OSTAG}.sh ${CONFIG}
exit $?
