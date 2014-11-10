#!/bin/bash -x
# Builds a bunch of packages for DOMjudge

DISTRIBUTIONS="utopic trusty precise "
DISTRIBUTIONS+="sid jessie wheezy "

DOMJUDGE_GIT="http://github.com/DOMjudge/domjudge.git"
DOMJUDGE_BRANCH="master"
DOMJUDGE_PACKAGING_GIT="http://github.com/DOMjudge/domjudge-packaging.git"
#DOMJUDGE_PACKAGING_GIT="http://github.com/ubergeek42/domjudge-packaging.git"
DOMJUDGE_PACKAGING_BRANCH="master"

DEBIANREVNUM="1"

function usage() {
  echo "Usage: $0 [options]"
  echo " -d dist        distribution to build for(utopic,jessie,etc)"
  echo " -t tag/branch  domjudge tag/branch to build(default: master)"
  echo " -r num         debian package revision number, to bump without source changes"
  echo
}

while getopts "d:t:r:" opt; do
  case $opt in
    d) # What distribtion to build
      DISTRIBUTIONS="$OPTARG"
      ;;
    t) # What tag to use
      DOMJUDGE_BRANCH="$OPTARG"
      ;;
    r) # what debian package revision number
      DEBIANREVNUM="$OPTARG"
      ;;
    \?)
      usage
      exit
      ;;
  esac
done

PACKAGE_DIR="/packages"

# import signing keys
gpg --import /support/signing-key_pub.gpg
gpg --allow-secret-key-import --import /support/signing-key_sec.gpg

GPGOUTPUT=$(gpg --with-fingerprint /support/signing-key_pub.gpg)
KEYID=$(echo "$GPGOUTPUT" | grep "pub  2048R" | cut -f2 -d/ | cut -f1 -d " ")
KEY_FINGERPRINT=$(echo "$GPGOUTPUT" | grep 'Key fingerprint' | cut -f2 -d= | tr -d " ")

# start gpg-agent to save us typing our key password
eval "$(gpg-agent --daemon --allow-preset-passphrase)"
echo -n "Enter gpg password: "
read -s GPG_PASSWORD
echo "$GPG_PASSWORD" | /usr/lib/gnupg2/gpg-preset-passphrase --preset "$KEY_FINGERPRINT"
unset GPG_PASSWORD

# Set some defaults for when we make the debian changelog
export DEBEMAIL="domjudge@a-eskwadraat.nl"
export DEBFULLNAME="DOMjudge Developers"
export DEBSIGN_KEYID="$KEYID"


# Clone the DOMjudge main source
if [ -d /tmp/dj-clone ]; then
  cd /tmp/dj-clone
  git pull
else
  cd /tmp
  git clone $DOMJUDGE_GIT /tmp/dj-clone
fi
cd /tmp/dj-clone
git checkout "$DOMJUDGE_BRANCH"

# DOMjudge packaging branch
if [ -d /tmp/domjudge-packaging ]; then
  cd /tmp/domjudge-packaging
  git pull
else
  git clone $DOMJUDGE_PACKAGING_GIT /tmp/domjudge-packaging
fi
cd /tmp/domjudge-packaging
git checkout $DOMJUDGE_PACKAGING_BRANCH


GITVERSION=$(cd /tmp/dj-clone && git describe)
DOMVERSION="${GITVERSION}"
TGZNAME="domjudge_${DOMVERSION}"


# Prepare a dist tarball
rm -rf /tmp/domjudge-src

cd /tmp
(cd dj-clone && git archive --prefix=domjudge-src/ --format=tar "HEAD") | tar x
cd /tmp/domjudge-src
make dist

cd /tmp
tar czf "${TGZNAME}.orig.tar.gz" domjudge-src
cp "${TGZNAME}.orig.tar.gz" "${PACKAGE_DIR}/${TGZNAME}.tar.gz"
chown 1000:1000 "${PACKAGE_DIR}/${TGZNAME}.tar.gz"

for DISTRIBUTION in $DISTRIBUTIONS; do
    DEBIANREV="-0${DISTRIBUTION}${DEBIANREVNUM}"
    DIRNAME="domjudge-${DOMVERSION}${DEBIANREV}"
    PKGNAME="domjudge_${DOMVERSION}${DEBIANREV}"

    # Unpack the source code, and copy in the debian packaging information
    cd /tmp
    rm -rf "/tmp/${DIRNAME}" && mkdir -p "/tmp/${DIRNAME}"
    tar xf "${TGZNAME}.orig.tar.gz" -C "/tmp/${DIRNAME}/" --strip-components=1
    cp -a /tmp/domjudge-packaging/debian "/tmp/${DIRNAME}/debian"

    # Update the changelog
    cd "/tmp/$DIRNAME"

    DCHDISTRO="$DISTRIBUTION"
    case "$DISTRIBUTION" in
        sid)
            DCHDISTRO="unstable"
            ;;
        jessie)
            DCHDISTRO="testing"
            ;;
        wheezy)
            DCHDISTRO="stable"
            ;;
    esac
    dch --force-bad-version \
        --newversion "${DOMVERSION}${DEBIANREV}" \
        --distribution $DCHDISTRO \
        "Development Snapshot($DOMJUDGE_BRANCH) - $GITVERSION"

    # build the source package
    debuild -k"$DEBSIGN_KEYID" -S -sa -i
    pbuilder-dist ${DISTRIBUTION} build --buildresult "/pbuilder/${DISTRIBUTION}_result/" --hookdir "/pbuilder/hook.d" "../${PKGNAME}.dsc"

    # Clean up a little bit
    cd /tmp
    rm -rf "/tmp/${DIRNAME}"

    # Copy package out to the host(removing any previous versions)
    rm -rf ${PACKAGE_DIR}/*${DISTRIBUTION}*/
    cp -a "/pbuilder/${DISTRIBUTION}_result/" "${PACKAGE_DIR}/${DOMVERSION}${DEBIANREV}"
    chown -R 1000:1000 "${PACKAGE_DIR}/${DOMVERSION}${DEBIANREV}"
done
