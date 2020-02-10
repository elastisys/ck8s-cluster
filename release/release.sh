#!/bin/bash
# Usage ./release.sh patch|minor|major
# This script will bump then patch, minor or major version in version.json and
# add the WIP-CHANGELOG ontop of the existing CHANGELOG.md

set -e
SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
file=${SCRIPTS_PATH}/version.json
CHANGELOG=${SCRIPTS_PATH}/../CHANGELOG.md
WIP=${SCRIPTS_PATH}/WIP-CHANGELOG.md
if [[ ! -f "$file" ]]; then
  echo "ERROR:  $file does not exist"
  exit 1
fi

# Regex found from https://gist.github.com/rverst/1f0b97da3cbeb7d93f4986df6e8e5695
function check_version() {
  if [[ $1 =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$ ]]; then
    echo "$1"
  else
    echo ""
  fi
}

# Getting current version of VERSION.json
prev_version=$(jq -r '.ck8s' "$file")
if [[ ! $(check_version ${prev_version}) ]]; then
    echo "ERROR: $prev_version from version.json does not match semantic versioning"
    #exit 1
fi

### Calculating new version and updating VERSION.json ###
a=( ${prev_version//./ } ) 
if [[ "$1" == "patch" ]]; then
    echo "bumping patching version"
    ((++a[2]))
    new_version="${a[0]}.${a[1]}.${a[2]}"
elif [[ "$1" == "minor" ]]; then
    echo "bumping minor version"
    ((++a[1]))
    a[2]=0
    new_version="${a[0]}.${a[1]}.${a[2]}"
elif [[ "$1" == "major" ]]; then
    echo "bumping major version"
    ((++a[0]))
    a[1]=0
    a[2]=0
    new_version="${a[0]}.${a[1]}.${a[2]}"
elif [[ "$1" == "-v" ]]; then
    if [[ $(check_version ${2}) ]]; then
        echo "setting version $2"
        new_version=$2
    else
        echo "ERROR: when -v is specified arg2 must be according to semantic versioning"
        echo "example: $0 -v 1.2.4"
        exit 1 
    fi
else
    echo "ERROR: Invalid command"
    echo "usage: $0 [patch|minor|major|-v version]"
    exit 1
fi
short_version="${new_version//./}"
DATE=$(date +'%Y-%m-%d')
echo "replacing previous version: $prev_version with new version: $new_version"
tmp=$(mktemp)
jq --arg version $new_version '.ck8s = $version' "$file" > "$tmp" && mv "$tmp" "$file"

### Generating new changelog by combining CHANGELOG.md and WIP-CHANGELOG.md ###
echo "generating new changelog"

# Split Changelog and Table of contents(TOC) into seperate files
sed -n '/<!-- BEGIN TOC -->/,/<!-- END TOC -->/{ /<!--/d; p }' ${CHANGELOG} > temp-toc.md
sed '1,/^<!-- END TOC -->$/d' ${CHANGELOG} > temp-cl.md

# Adding version to changelog
echo -e "## v${new_version} - ${DATE}\n" | cat - ${WIP} temp-cl.md > temp-cl2.md
# Adding link to TOC
echo -e "- [v${new_version}](#v${short_version}---${DATE})" | cat - temp-toc.md > temp-toc2.md
echo -e "<!-- END TOC -->" >> temp-toc2.md
echo -e "<!-- BEGIN TOC -->" | cat - temp-toc2.md > temp-toc.md
echo -e "\n-------------------------------------------------" >> temp-toc.md
# Creating new changelog
echo -e "# Compliant Kubernetes Changelog" > ${CHANGELOG}
cat temp-toc.md temp-cl2.md >> ${CHANGELOG}
rm temp*
# Clearing WIP-CHANGELOG.md
> ${WIP}

git add version.json ${CHANGELOG} ${WIP}
git commit -m "Releasing v${new_version}"
git tag -a "v${new_version}" -m "releasing version ${new_version}"

echo ""
echo "finish release with:"
echo ""
echo "  git push; git push --tags"
echo ""