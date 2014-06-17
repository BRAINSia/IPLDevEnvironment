#!/bin/bash

download_file ()
{
    # Generic downloader for curl/wget
    # Usage:
    #    download_file ${FILENAME} ${ADDRESS}
    #
    if [[ ${#} -ne 2 ]]; then
        return ${ERR_DOWNLOAD}
    fi
    cd ${MYSOURCE}
    FILENAME=$1
    ADDRESS=$2
    if [[ ! -f ${FILENAME} ]]; then
        if ! wget ${ADDRESS}; then
            return ${ERR_DOWNLOAD}
        fi
    fi
    return 0
}

download_cmake ()
{
    FILENAME=cmake-${CMAKE_VERSION}.tar.gz
    ADDRESS=http://www.cmake.org/files/v${CMAKE_MAJOR_MINOR}/${FILENAME}
    download_file ${FILENAME} ${ADDRESS}
}

download_qt ()
{
    FILENAME=qt-everywhere-opensource-src-${QT_VERSION}.tar.gz
    ADDRESS=http://download.qt-project.org/official_releases/qt/${QT_MAJOR_MINOR}/${QT_VERSION}/${FILENAME}
    download_file ${FILENAME} ${ADDRESS}
}

download_virtualenv ()
{
    FILENAME=virtualenv-${VENV_VERSION}.tar.gz
    ADDRESS=https://pypi.python.org/packages/source/v/virtualenv/${FILENAME}
    download_file ${FILENAME} ${ADDRESS}
}

download_namic ()
{
    cd ${MYSOURCE}
    DIRECTORY=NAMICExternalProjects
    if [[ ! -d ${DIRECTORY} ]]; then
        git clone https://github.com/BRAINSia/${DIRECTORY}.git
    else
        cd ${DIRECTORY}
        git checkout master
    fi
    return 0
}

download_python ()
{
    FILENAME=Python-${PYTHON_VERSION}.tgz
    ADDRESS=wget https://www.python.org/ftp/python/${PYTHON_VERSION}/${FILENAME}
    download_file ${FILENAME} ${ADDRESS}
}
