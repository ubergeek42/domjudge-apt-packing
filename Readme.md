Packaging Scripts for DOMjudge
==============================
This set of scripts/configuration/etc are to be used for packaging DOMjudge on
a regular basis in a clean environment.

In the support directory, you will need to place your signing keys as
`signing-key_pub.gpg` and `signing-key_sec.gpg`.  You'll be prompted for your
passphrase during the build process.


Requirements:
* docker
* gpg key
* reprepro (`apt-get install reprepro`)


Create a keypair, then export it in the appropriate location
```
$ gpg --gen-key # Use the defaults
$ gpg --export -a > support/signing-key_pub.gpg
$ gpg --export-secret-key -a > support/signing-key_sec.gpg

```
