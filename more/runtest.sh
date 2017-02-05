#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTDIR=`pwd`
popd > /dev/null

OPTIRUN=

if [[ $(hostname) == "RasmusWL-S430" ]]; then
   OPTIRUN="optirun"
fi

RUNS_PER_TEST=5
NUM=20
DATATYPE="f32"

while getopts 'n:r:' flag; do
  case "${flag}" in
    n) NUM="${OPTARG}" ;;
    r) RUNS_PER_TEST="${OPTARG}" ;;
    *) echo "ERROR: Unexpected option ${flag}"; exit -1 ;;
  esac
done

bins="${@:$OPTIND}"

# TODO: this is kinda hacky ... will probably not survive space in SCRIPTDIR
if [[ -z $bins ]]; then
    bins="$SCRIPTDIR/$DATATYPE-segreduce-comm.bin $SCRIPTDIR/$DATATYPE-mapinloop.bin"
fi

################################################################################

echo "Running performance tests for [0-$NUM][$NUM-0]$DATATYPE (each $RUNS_PER_TEST times)"

nums=$(seq 0 ${NUM})

function generate_data () {
    futhark-dataset --generate=[$(python -c "print(2**$i)")][$(python -c "print(2**$j)")]$DATATYPE
}

function run_tests () {
    local prog="$1"
    local res_file=$(mktemp /tmp/rasmus-runtest.XXXXXX)
    ${OPTIRUN} "$prog" -r "$RUNS_PER_TEST" -t "$res_file" < $infile &> /dev/null
    if [ $? -ne 0 ]; then
        >&2 echo -e "\nFailure when executing '$prog'"
        exit -1
    fi
    awk '{ total += $1 } END { printf " %.2f", total/NR }' "$res_file"
    rm "$res_file"
}

# Handle normal reduce case
infile="/tmp/$DATATYPE-2pow${NUM}.dat"
if [ ! -f "$infile" ]; then
    futhark-dataset --generate=[$(python -c "print(2**$NUM)")]$DATATYPE > "$infile"
fi

echo -n "reduce-nocomm on [2^$NUM]$DATATYPE"
run_tests $SCRIPTDIR/$DATATYPE-reduce-nocomm.bin
echo ""

echo -n "reduce-comm on [2^$NUM]$DATATYPE"
run_tests $SCRIPTDIR/$DATATYPE-reduce-comm.bin
echo ""

# Output header for graph

echo -n "row label"
for bin in $bins; do
    echo -n " $(basename $bin)"
done
echo ""

# Go though each combination, and run each of the binaries supplied

for i in ${nums}; do
    j=$((NUM-i));
    infile="/tmp/$DATATYPE-2pow${i}_2pow${j}.dat"

    if [ ! -f "$infile" ]; then
        #>&2 echo "generating input $infile"
        generate_data $i $j > "$infile"
    fi

    echo -n "$i \$[2^{$i}][2^{$j}]\$"

    for bin in $bins; do
        # Fix path if ./ is not included
        if [[ "$bin" =~ ^/|^./ ]]; then
            true
        else
            bin="./$bin"
        fi
        run_tests $bin
    done

    echo ""
done