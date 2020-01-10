#!/bin/bash

if [[ ! -f VERSION.md ]]; then
  echo "ERROR:  VERSION.md does not exist"
  exit 1
fi

prev_version=$(head -n 1 VERSION.md | sed 's/^.*-\ \([0-9.]*\).*/\1/')
a=( ${prev_version//./ } ) 
if [[ "$1" == "patch" ]]; then
    echo "bumping patching version"
    ((a[2]++))
elif [[ "$1" == "minor" ]]; then
    echo "bumping minor version"
    ((a[1]++))
elif [[ "$1" == "major" ]]; then
    echo "bumping major version"
    ((a[0]++))
else
    echo "ERROR: Invalid command"
    echo "usage: $0 patch|minor|major"
    exit 1
fi
new_version="${a[0]}.${a[1]}.${a[2]}"
echo "replacing previous version: $prev_version with new version: $new_version"
sed -i "1!b;s/${prev_version}/${new_version}/" VERSION.md