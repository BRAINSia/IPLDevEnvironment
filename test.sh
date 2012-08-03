#!/bin/bash

test_proc_env () {
    MILESTONE=(WINTER WINTER SPRING SPRING SPRING SUMMER SUMMER SUMMER AUTUMN AUTUMN AUTUMN WINTER)
    for ((m=0; m<=11; m++)); do
        OUTPUT=$(./proc_env.sh -t $(($m+1)) 2012 2012-${MILESTONE[$m]})
        if [[ "$?" = "1" ]]; then
            echo "Test failed: ./proc_env.sh $(($m+1)) 2012 2012-"${MILESTONE[$m]}
            echo $OUTPUT
        fi
    done
}

test_directory () {
    OUTPUT=$(./directory.sh -t)
    if [[ "$?" = "1" ]]; then
        echo -e "Test failed: ./directory.sh -t"
    fi
}

test_proc_env
test_directory
echo "Tests complete"
