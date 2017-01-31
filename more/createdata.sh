#!/bin/bash

NUM=20

if [ $# -eq 1 ]; then
   NUM="$1"
fi

DATATYPE="f32"

################################################################################

echo "Creating data for [0-$NUM][$NUM-0]$DATATYPE"

nums=$(seq 0 ${NUM})

function generate_data () {
    futhark-dataset --generate=[$(python -c "print(2**$i)")][$(python -c "print(2**$j)")]$DATATYPE
}

function run_tests () {
    local prog="$1"
    local res_file=$(mktemp /tmp/rasmus-runtest.XXXXXX)
    "$prog" -r "$RUNS_PER_TEST" -t "$res_file" < $infile &> /dev/null
    if [ $? -ne 0 ]; then
        >&2 echo -e "\nFailure when executing '$prog'"
        exit -1
    fi
    awk '{ total += $1 } END { printf " %.2f", total/NR }' "$res_file"
    rm "$res_file"
}

# Handle normal reduce case
infile="/tmp/$DATATYPE-2pow${NUM}.dat"

echo -n "Creating $infile ..."

if [ ! -f "$infile" ]; then
    futhark-dataset --generate=[$(python -c "print(2**$NUM)")]$DATATYPE > "$infile"
fi

echo " finished"

for i in ${nums}; do
    j=$((NUM-i));
    infile="/tmp/$DATATYPE-2pow${i}_2pow${j}.dat"

    echo -n "Creating $infile ..."

    if [ ! -f "$infile" ]; then
        #>&2 echo "generating input $infile"
        generate_data $i $j > "$infile"
    fi

    echo " finished"
done
