#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACKAGEDIR="$BASEDIR/../built_packages"

UBUDISTS="utopic precise trusty "  # Ubuntu Distributions
DEBDISTS="sid jessie wheezy "     # Debian Distributions

function clean() {
  rm -rf debian/dists debian/pool debian/db
  rm -rf ubuntu/dists ubuntu/pool ubuntu/db
  rm -f domjudge-repo.key
}

function usage() {
  echo "Usage: $0 [options]"
  echo " -c  Clean up the repository"
  echo
}

while getopts "c" opt; do
  case $opt in
    c)
      clean
      exit
      ;;
    \?)
      usage
      exit
      ;;
  esac
done


function testglob()
{
  if test -d $PACKAGEDIR/$1; then
    if test -n "$(find $PACKAGEDIR/$1 -name '*.deb' -print -quit)"; then
      return 0
    fi
  fi
  return 1
}

cd ubuntu
for DIST in $UBUDISTS; do
  testglob "*-0${DIST}*"  && reprepro includedeb "${DIST}"  $PACKAGEDIR/*-0${DIST}*/*.deb
done
cd ..

cd debian
for DIST in $DEBDISTS; do
  testglob "*-0${DIST}*"     && reprepro includedeb "${DIST}"     $PACKAGEDIR/*-0${DIST}*/*.deb
done
cd ..


cp ../support/signing-key_pub.gpg domjudge-repo.key
