#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOMJUDGE_SRC="$BASEDIR/../domjudge"
DOMJUDGE_PKG_SRC="$BASEDIR/../domjudge-packaging"

function usage() {
  echo "Usage: $0 [options]"
  echo " -a  Build for all distrubtions"
  echo " -f  Force rebuilding the docker container"
  echo " -t  Specify a specific tag to build"
  echo
}


FULL="0"
FORCE_BUILD="0"
TAG="master"

while getopts "aft:" opt; do
  case $opt in
    a)
      FULL='1'
      ;;
    f)
      FORCE_BUILD='1'
      ;;
    t)
      TAG="$OPTARG"
      ;;
    \?)
      usage
      exit
      ;;
  esac
done


DO_BUILD="0"
# check output of this command for date/timestamp to decide whether to rebuild
docker inspect dj-base > /dev/null 2>&1
if [[ $? -eq 1 ]]; then
  DO_BUILD="1"
fi

if [[ "$DO_BUILD" -eq 1 || "$FORCE_BUILD" -eq 1 ]]; then
  echo "Removing old image"
  docker rmi dj-base
  echo "Building image"
  docker build -t dj-base .

  echo "Setting up pbuilder environments"
  docker run -v "$BASEDIR"/support:/support:ro -it --privileged --name dj-base-temp dj-base bash -x /support/setup_pbuilder.sh
  docker commit dj-base-temp dj-base
  docker rm dj-base-temp
fi

if [ "$FULL" -eq 1 ]; then
  echo "Building packages(Full)"
  BUILD_ARGS=""
else
  echo "Building packages(Quick)"
  BUILD_ARGS="-d trusty"
fi

BUILD_ARGS="$BUILD_ARGS -t $TAG"

docker run \
    -v "$BASEDIR"/built_packages:/packages \
    -v "$BASEDIR"/support:/support:ro \
    -v "$DOMJUDGE_SRC":/domjudge:ro \
    -v "$DOMJUDGE_PKG_SRC":/domjudge-packaging:ro \
    --rm --privileged -it dj-base bash -x /support/build_packages.sh \
    $BUILD_ARGS

# we need to make sure our signing key is set up
# make sure we have the key in the right place
export GNUPGHOME="$BASEDIR/apt/gpghome"
gpg --import "$BASEDIR/support/signing-key_pub.gpg"
gpg --allow-secret-key-import --import "$BASEDIR/support/signing-key_sec.gpg"

# update the apt repository itself(with reprepro)
cd apt
./update_repo.sh
