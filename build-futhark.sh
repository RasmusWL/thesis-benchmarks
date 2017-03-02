#!/bin/bash

set -e

pushd `dirname $0` > /dev/null
SCRIPTDIR=`pwd`
popd > /dev/null

CURDIR=$(pwd)

if [ $CURDIR != $(stack path --project-root)  ]; then
    echo "You're not in the top level of a stack project"
    exit 1
fi

if [ ! -f futhark.cabal ]; then
    echo "You're not in the futhark repo"
    exit 1
fi

echo "Will generate binaries for vanilla and segredomap, and put them in your current directory"

mkdir -p "$SCRIPTDIR/bin-vanilla"
mkdir -p "$SCRIPTDIR/bin-segredomap"

git reset --hard
stack build --fast
stack install --local-bin-path "$SCRIPTDIR/bin-vanilla"

git apply "$SCRIPTDIR/enable-segredomap.patch"
stack build --fast
stack install --local-bin-path "$SCRIPTDIR/bin-segredomap"
