#!/bin/bash


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

function usage ()
{
	echo "Usage: ${SCRIPTNAME} [-h] [-v] [-t] [-c] [-r] [-d DIR] CONFIG" >&2
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

# MAIN
OLD_PATH=${PATH}
SCRIPTNAME=$(basename ${0})
DIRNAME=$(dirname ${0})
source ${DIRNAME}/codes.sh
source ${DIRNAME}/functions.sh

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

OPTIONS=$*
while getopts ':o:vhd:tcr' OPTION ; do
    debug ${DEBUG}
	case ${OPTION} in
		v)	VERBOSE=true
			;;
		h)	usage 0
			;;
        t)  RUN_TESTS=true
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
source ${1}

if [[ ! ${MYBUILD} ]]; then
    source ${DIRNAME}/directory.sh
fi

# Build all as parallel multithreaded subprocesses

${DIRNAME}/cmake.sh -s ${MYSOURCE} -b ${MYBUILD} -V ${VERSION_CMAKE} ${OPTIONS}
CMAKE_BUILD=$?
# CMAKE_BUILD=0

${DIRNAME}/qt.sh -s ${MYSOURCE} -b ${MYBUILD} -V ${VERSION_QT} ${OPTIONS}
QT_BUILD=$?
# QT_BUILD=0

${DIRNAME}/virtualenv.sh -m "python_2.7so" -s ${MYSOURCE} -b ${MYBUILD} -V ${VERSION_VIRTUALENV} ${OPTIONS}
VENV_BUILD=$?
# VENV_BUILD=0

# END HACK

export PATH=${MYBUILD}/cmake-bin/bin:${MYBUILD}/qt-bin/bin:${PATH}
${DIRNAME}/namic.sh -m "python_2.7so git_1.7.1 gcc_${GCC}" -s ${MYSOURCE} -b ${MYBUILD} -t ${TAG_NAMIC} -V ${MYBUILD}/activate_python_HD ${OPTIONS}

if [[ ${CMAKE_BUILD} -ne 0 ]]; then
    echo "CMake failed to build!" >&2
    exit ${CMAKE_BUILD}
elif [[ ${QT_BUILD} -ne 0 ]]; then
    echo "QT failed to build!" >&2
    exit ${QT_BUILD}
elif [[ ${VENV_BUILD} -ne 0 ]]; then
    echo "Python virtualenv failed to build!" >&2
    exit ${VENV_BUILD}
fi


echo "Run this command: " >&2
echo "export PATH=${MYBUILD}/cmake-bin/bin:${MYBUILD}/qt-bin/bin:"'$PATH' >&2

# HACK:
exit ${SUCCESS}



# if [[ "$CONTINUE" == true ]]; then
#     if [[ ! -d ${BASEDIR}/${DATETAG} ]]; then
#         echo "Directory ${DATETAG} not found in ${BASEDIR}!" >&2
#         usage ${ERR_MISSING_DIR}
#     fi
# fi

# if [[ "${CONTINUE}" == "false" ]]; then
#     mkdir -p ${MYSOURCE}
#     mkdir -p ${MYBUILD}/.log
# fi

# if [[ ! -d ${MYSOURCE} || ! -d ${MYBUILD}/.log ]]; then
#     echo "Cannot find $MYSOURCE or $MYBUILD! Halting."
#     exit ${ERR_MISSING_DIR}
# fi

# if [[ "${CONTINUE}" == false || "${REFRESH}" == true ]]; then
#     download_source_code  # TODO: download source code if not there OR 'refresh' option
# fi

# if [[ true ]]; then
#     if [[ $(expr ${VENV_STATUS} + ${CMAKE_STATUS} + ${QT_STATUS} + ${PYTHON_STATUS}) -eq 0 ]]; then
#         echo "Building NAMICExternalProjects..."
#         build_NEP ${MYENV}
#         NAMIC_STATUS=$?
#         wait
#         if ${NAMIC_STATUS}; then
#             deactivate
#             if ${RUN_TESTS}; then
#                 source ${MYBUILD}/activate_${MYENV}
#                 test_nipype
#                 test_sitk
#             fi
#         else
#             exit ${ERR_NAMIC}
#         fi
#     else
#         exit `expr ${VENV_STATUS} + ${CMAKE_STATUS} + ${QT_STATUS} + ${PYTHON_STATUS}`
#     fi
#     echo "To activate virtualenv: \n\$ . ${MYBUILD}/activate_${MYENV} \n\nTo deactivate virtualenv:\n\$ deactivate\n\nDon't forget to load the Python module FIRST: \n\$ module load python/2.7"
# else
#     exit ${ERR_DOWNLOAD}
# fi
# exit ${SUCCESS}
