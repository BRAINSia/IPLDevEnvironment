#!/bin/bash

function debug () {
    # Usage:
    #    debug true
    #    debug false
    #
    if [[ "${1}" == true ]]; then
        set | sort > set.sorted
        printenv | sort > printenv.sorted
        printf "\n--------------------DEBUG--------------------\n" >&2
        diff set.sorted printenv.sorted | grep "<" | awk '{ print $2}' >&2
        printf "\n---------------------------------------------\n" >&2
    fi
}

download_file () {
    # Generic downloader for curl/wget
    # Usage:
    #    download_file ${FILENAME} ${ADDRESS}
    #
    if [[ ${#} -lt 2 ]]; then
        return ${ERR_DOWNLOAD}
    fi
    cd ${MYSOURCE}
    FILENAME=$1
    ADDRESS=$2
    if [[ ${#} -eq 3 ]]; then
        FLAGS=$3
    else
        FLAGS=""
    fi
    if [[ ! -f ${FILENAME} ]]; then
        if ! wget ${FLAGS} ${ADDRESS}; then
            return ${ERR_DOWNLOAD}
        fi
    fi
    return 0
}

load_modules () {
    if [[ ${#} -eq 0 ]]; then
        echo "No modules given!" >&2
        return ${ERR_MODULES}
    fi
    if [[ ! ${MODULESHOME} ]]; then
        echo "Cannot find Module command in environment" >&2
        return ${ERR_MODULES}
    fi
    source ${MODULESHOME}/init/bash
    module load ${@}
    return $?
}

download_python ()
{
    FILENAME=Python-${VERSION_PYTHON}.tgz
    ADDRESS=wget https://www.python.org/ftp/python/${VERSION_PYTHON}/${FILENAME}
    download_file ${FILENAME} ${ADDRESS}
}
