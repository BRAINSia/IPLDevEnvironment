#!/bin/bash

MAIN_DIR=/ipldev/sharedopt
# Create the parent directory string
# Format: YYYY_Milestone
export PROC_ENV=`date +%Y`
month=`date +%m`
# Since winter starts in December, not January, this works better than a mod function
seasons=(WINTER WINTER SPRING SPRING SPRING SUMMER SUMMER SUMMER AUTUMN AUTUMN AUTUMN WINTER)
PROC_ENV=${PROC_ENV}_${seasons[$month]}

mkdir ${MAIN_DIR}
mkdir ${MAIN_DIR}/${PROC_ENV}
# There should be a desriptive README file:
touch ${MAIN_DIR}/${PROC_ENV}/README
echo "PI:
Short description:
Wiki page:" :>${MAIN_DIR}/${PROC_ENV}/README

# Directories should be named as follows
dirs=(src etc src/build_instructions)
# There should always be a "src" directory for common source files
mkdir -p ${MAIN_DIR}/${PROC_ENV}/src

# There should be an "etc" directory for reading configuraiton files
mkdir -p ${MAIN_DIR}/${PROC_ENV}/etc

# Some incomplete instructions on how the programs should be built
mkdir -p ${MAIN_DIR}/${PROC_ENV}/src/build_instructions

# Base directory for all the results files
mkdir -p ${MAIN_DIR}/${PROC_ENV}/$(uname -s)_$(uname -p)

chmod oug+rwX ${MAIN_DIR}/${PROC_ENV}/$(uname -s)_$(uname -p)

# Where:
# APP_NAME may or may not include version as appropriate
#
# Example:
# /ipldev/sharedopt/20110601/Linux_x86_64/freesurfer

