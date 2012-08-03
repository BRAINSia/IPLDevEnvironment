#!/bin/bash

usage () {
    echo -e "Usage:\n\tproc_env.sh\n\t\tPrints out the folder name\n\tproc_env.sh -t <MONTH> <YEAR> <RESULT>\n\t\tTests the output against <RESULT> using the given date information\n\tproc_env.sh -h\n\t\tPrints help text"
}

testing () {
    echo "Testing proc_env..."
    MONTH=$(( $1 - 1 )) # Testing input is 1=Jan, not zero-indexed (i.e. is human-readable)
    YEAR=$2
    FULLDIR=$3
    RESULT=$(month_map $MONTH $YEAR)
    if [[ $RESULT = $FULLDIR ]]; then
        echo "Passed"
        exit 0
    else
        echo "Failed: RESULT = "$RESULT
        exit 1
    fi
}

month_map () {
    MONTH=$1
    YEAR=$2
    # Since winter starts in December, not January, this works better than a mod function
    MILESTONE=(WINTER WINTER SPRING SPRING SPRING SUMMER SUMMER SUMMER AUTUMN AUTUMN AUTUMN WINTER)
    PROC_ENV=${YEAR}"-"${MILESTONE[$MONTH]}
    echo $PROC_ENV
}

while getopts 'th' OPTION; do
    case ${OPTION} in
        t) testing $2 $3 $4
            ;;
        h) usage
           exit 0
            ;;
        \?) echo "Unknown option \"-${OPTARG}\"." >&2
            usage
            exit 1
            ;;
    esac
done

# Create the parent directory string using the current date
# Format: YYYY-Milestone
YEAR=$(Date +%Y)
MONTH=$(( $(date +%-m) - 1 ))
echo $(month_map $MONTH $YEAR)
