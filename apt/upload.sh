#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 user@dest:/path/"
    exit
fi
rsync -av --exclude '*.sh' --exclude "*/conf" --exclude "*/db" ubuntu debian domjudge-repo.key $1
