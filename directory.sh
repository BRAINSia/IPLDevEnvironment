#!/bin/bash

usage() {
    echo -e "Usage:\n\tdirectory.sh\n\t\tCreates a directory in /ipldev/sharedopt/\n\tdirectory.sh $DIR\n\t\tCreates a directory in $DIR"
}

testing () {
    MAIN_DIR=/var/tmp
    RESULT_LIST=( $( create_dirs $MAIN_DIR "YYYY-TEST" ) )
    if [[ "$?" -ne 0 ]]; then
        exit 1
    fi
    LENGTH_1=${#RESULT_LIST[@]}
    DIR_LIST=( $( ls -R $MAIN_DIR/YYYY-TEST ) )
    LENGTH_2=${#DIR_LIST[@]}
    COUNT=0
    for ((ii=0; ii<$LENGTH_1; ii++)); do
        for ((jj=0; jj<$LENGTH_2; jj++)); do
            if [[ ${RESULT_LIST[$ii]} = ${DIR_LIST[$jj]} ]]; then
                (( COUNT++ ))
                echo "Directory found: "${RESULT_LIST[$ii]}
                break
            fi
        done
    done
    if [[ $COUNT = $LENGTH_1 ]]; then
        echo "Cleaning up /var/tmp/YYYY-TEST"
        rm -rf ${MAIN_DIR}/YYYY-TEST
        exit $?
    fi
    exit 1
}

create_dirs () {
    MAIN_DIR=$1
    PROC_ENV=$2
    mkdir ${MAIN_DIR}/${PROC_ENV}
    # Directories should be named as follows
    BINARY=$(uname -s)-$(uname -p)
    DIR_LIST=( etc src src/build_instructions $BINARY )
    index=0
    while [ "$index" -lt "${#DIR_LIST[@]}" ]; do
        # echo "Making directory "${MAIN_DIR}/${PROC_ENV}/${DIR_LIST[$index]}"..."
        mkdir -p ${MAIN_DIR}/${PROC_ENV}/${DIR_LIST[$index]}
        ((index++))
    done
    chmod oug+rwX ${MAIN_DIR}/${PROC_ENV}/${BINARY}
    echo ${DIR_LIST[@]}
}

while getopts 'th' OPTION; do
    case ${OPTION} in
        h) usage; exit 0
            ;;
        t) testing
            ;;
        \?) echo "unknown option \"-${OPTARG}\"." >&2
			usage; exit 1
			;;
    esac
done

if [[ $# -eq 1 ]]; then
    MAIN_DIR=$1
else
    MAIN_DIR=/ipldev/sharedopt
fi

PROC_ENV=$(./proc_env.sh)
create_dirs $MAIN_DIR $PROC_ENV

echo "Who is/are the principle investigator(s): "
read -a PI
echo "Enter a short description of this directory: "
read -a DESCRIPTION
echo "Enter the wiki page for this directory: "
read -a WIKIPAGE

echo "PI: $PI
Short description: $DESCRIPTION
Wiki page: $WIKIPAGE" >${MAIN_DIR}/${PROC_ENV}/README
# There should be a desriptive README file:
touch ${MAIN_DIR}/${PROC_ENV}/README


# Where:
# APP_NAME may or may not include version as appropriate
#
# Example:
# /ipldev/sharedopt/20110601/Linux_x86_64/freesurfer

