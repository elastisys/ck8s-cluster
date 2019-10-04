#!/bin/bash

set -e

if [[ "$#" -lt 1 ]]
then 
  >&2 echo "Usage: gen-pwd.sh pwd_length"
  exit 1
fi

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

pwd_length="$1"

# Generates and outputs random password of desired length.
< /dev/urandom tr -dc A-Za-z0-9 | head -c${pwd_length}; echo
