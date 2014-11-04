#!/bin/bash -x

DISTS="utopic precise trusty "  # Ubuntu Distributions
DISTS+="sid jessie wheezy "     # Debian Distributions

# Set to 1 to install a hook to give you a shell on error
DEVEL=1

DOMJUDGE_DEPENDENCIES="libcurl4-gnutls-dev libboost-regex-dev libgmp3-dev "
DOMJUDGE_DEPENDENCIES+="apache2-utils libcgroup-dev zip libjsoncpp-dev "
DOMJUDGE_DEPENDENCIES+="linuxdoc-tools transfig"

mkdir -p /pbuilder/hook.d
cat <<-EOF > ~/.pbuilderrc
HOOKDIR="/pbuilder/hook.d/"
EXTRAPACKAGES="$DOMJUDGE_DEPENDENCIES"
EOF

if [ "$DEVEL" -eq 1 ]; then
  cat <<-EOF > /pbuilder/hook.d/C10shell
#!/bin/sh
# invoke shell if build fails.
export PS1="pbuilder-chroot # "
apt-get install -y --force-yes vim less bash
cd /tmp/buildd/*/debian/..
/bin/bash < /dev/tty > /dev/tty 2> /dev/tty
EOF
  chmod +x /pbuilder/hook.d/C10shell
fi

# Create a pbuilder chroot for each distribution
for DIST in $DISTS; do
  pbuilder-dist "$DIST" create
done
