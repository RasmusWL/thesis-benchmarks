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
mkdir -p "$SCRIPTDIR/bin-versioned"
mkdir -p "$SCRIPTDIR/bin-versionedANDsegredomap"

git reset --hard dd2d6651fd9ae9de6fcfe408ed02d54e4976b07e

git reset --hard
stack build --fast
stack install --local-bin-path "$SCRIPTDIR/bin-vanilla"

git apply "$SCRIPTDIR/enable-segredomap.patch"
stack build --fast
stack install --local-bin-path "$SCRIPTDIR/bin-segredomap"

git reset --hard
git apply "$SCRIPTDIR/enable-versionedCode.patch"
stack build --fast
stack install --local-bin-path "$SCRIPTDIR/bin-versioned"

git apply "$SCRIPTDIR/enable-segredomap.patch"
stack build --fast
stack install --local-bin-path "$SCRIPTDIR/bin-versionedANDsegredomap"
