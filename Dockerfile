FROM ubuntu:14.04
MAINTAINER Keith Johnson <kjohns07@cs.fit.edu>

ENV DEBIAN_FRONTEND non-interactive

RUN apt-get update

# this forces dpkg not to call sync() after package extraction and speeds up install
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup
# we don't need an apt cache in a container
RUN echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

# DOMjudge build requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
  texlive-latex-recommended texlive-latex-extra \
  texlive-fonts-recommended texlive-lang-dutch \
  linuxdoc-tools \
  php5-cli \
  zip \
  groff \
  flexc++ bisonc++ \
  \
  packaging-dev gnupg-agent debian-archive-keyring

RUN apt-get autoclean

WORKDIR /tmp

