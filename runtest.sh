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
start=
end=

DIMS="2"
OUT=
POW="2" # the power to use

while getopts '12n:r:s:e:o:p:' flag; do
  case "${flag}" in
    1) DIMS="1" ;;
    2) DIMS="2" ;;
    n) NUM="${OPTARG}" ;;
    r) RUNS_PER_TEST="${OPTARG}" ;;
    s) start="${OPTARG}" ;;
    e) end="${OPTARG}" ;;
    o) OUT="${OPTARG}" ;;
    p) POW="${OPTARG}" ;;
    *) echo "ERROR: Unexpected option ${flag}"; exit -1 ;;
  esac
done

bins="${@:$OPTIND}"

if [[ -z $bins ]]; then
    echo "You must provide binaries to run!"
fi

if [[ -z $start ]]; then
    start=0
fi

if [[ -z $end ]]; then
    end=$NUM
fi

################################################################################

>&2 echo "Running performance tests for [0-$NUM][$NUM-0]$DATATYPE (each $RUNS_PER_TEST times)"

function run_tests () {
    local prog="$1"
    local res_file=$(mktemp /tmp/rasmus-runtest.XXXXXX)
    local out="/dev/null"
    if [[ ! -z $OUT ]]; then
        out="$OUT/$i-$j"
    fi
    $header | cat - $infile | ${OPTIRUN} "$prog" -r "$RUNS_PER_TEST" -t "$res_file" > $out
    if [ $? -ne 0 ]; then
        >&2 echo -e "\nFailure when executing '$prog'"
        exit -1
    fi
    awk '{ total += $1 } END { printf " %.2f", total/NR }' "$res_file"
    rm "$res_file"
}

# Handle normal reduce case
infile="/tmp/$DATATYPE-bin-${POW}pow${NUM}.dat"
if [ ! -f "$infile" ]; then
    >&2 echo "Generating data"
    futhark-dataset --binary-no-header --generate=[$(python -c "print(${POW}**$NUM)")]$DATATYPE > "$infile"
fi

if [[ $DIMS -eq "1" ]]; then
    echo "ONLY ONE DIMENSION!"
    header="futhark-dataset --binary-only-header --generate=[$(python -c "print(${POW}**$NUM)")]$DATATYPE"

    for bin in $bins; do
        echo -n "$bin on [${POW}^$NUM]$DATATYPE"
        run_tests $bin
        echo ""
    done

    exit 0
fi

# Output header for graph

echo -n "row label"
for bin in $bins; do
    echo -n " $(basename $bin)"
done
echo ""

# Go though each combination, and run each of the binaries supplied
nums=$(seq $start $end)

for i in ${nums}; do
    j=$((NUM-i));

    if [ ! -f "$infile" ]; then
        #>&2 echo "generating input $infile"
        generate_data $i $j > "$infile"
    fi

    echo -n "$i \$[${POW}^{$i}][${POW}^{$j}]\$"

    header="futhark-dataset --binary-only-header --generate=[$(python -c "print(${POW}**$i)")][$(python -c "print(${POW}**$j)")]$DATATYPE"
    for bin in $bins; do
        run_tests $bin
    done

    echo ""
done
