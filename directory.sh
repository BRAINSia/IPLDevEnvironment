#!/bin/bash

# For testing:
MAIN_DIR=$PWD
# MAIN_DIR=/ipldev/sharedopt
# Create the parent directory string
# Format: YYYY_Milestone
PROC_ENV=$(date +%Y)
month=$(( $(date +%-m) - 1 ))
# Since winter starts in December, not January, this works better than a mod function
seasons=(WINTER WINTER SPRING SPRING SPRING SUMMER SUMMER SUMMER AUTUMN AUTUMN AUTUMN WINTER)
PROC_ENV=${PROC_ENV}_${seasons[$month]}

echo "Who is/are the principle investigator(s): "
read -a PI
echo "Enter a short description of this directory: "
read -a DESCRIPTION
echo "Enter the wiki page for this directory: "
read -a WIKIPAGE
mkdir ${MAIN_DIR}
mkdir ${MAIN_DIR}/${PROC_ENV}
# There should be a desriptive README file:
touch ${MAIN_DIR}/${PROC_ENV}/README
echo "PI: $PI
Short description: $DESCRIPTION
Wiki page: $WIKIPAGE" >${MAIN_DIR}/${PROC_ENV}/README

# Directories should be named as follows
dirs=(src etc src/build_instructions "$(uname -s)_$(uname -p)")
index=0
while [ "$index" -lt "${#dirs[@]}" ]; do
    echo "Making directory "${MAIN_DIR}/${PROC_ENV}/${dirs[$index]}"..."
    mkdir -p ${MAIN_DIR}/${PROC_ENV}/${dirs[$index]}
    ((index++))
done

chmod oug+rwX ${MAIN_DIR}/${PROC_ENV}/$(uname -s)_$(uname -p)

# Where:
# APP_NAME may or may not include version as appropriate
#
# Example:
# /ipldev/sharedopt/20110601/Linux_x86_64/freesurfer

