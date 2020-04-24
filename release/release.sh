#!/bin/bash
# Only usable from within pipeline
# Usage ./release.sh patch|minor|major
# This script will bump then patch, minor or major version in version.json and
# add the WIP-CHANGELOG ontop of the existing CHANGELOG.md

set -e
file="${GITHUB_WORKSPACE}/release/version.json"
changelog="${GITHUB_WORKSPACE}/CHANGELOG.md"
wip="${GITHUB_WORKSPACE}/WIP-CHANGELOG.md"
if [[ ! -f "$file" ]]; then
  echo "ERROR:  $file does not exist"
  exit 1
fi

if [[ -z "${GITHUB_REF}" ]]; then
    echo "Missing HEAD REF"
    exit 1;
fi

arg=$(echo ${GITHUB_REF/refs\/heads\/pre-release-} )
# Regex found from https://gist.github.com/rverst/1f0b97da3cbeb7d93f4986df6e8e5695
function check_version() {
  if [[ $1 =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$ ]]; then
    echo "$1"
  else
    echo ""
  fi
}

# Getting current version of version.json
prev_version=$(jq -r '.ck8s' "$file")
if [[ ! $(check_version ${prev_version}) ]]; then
    echo "ERROR: $prev_version from version.json does not match semantic versioning"
    #exit 1
fi

### Calculating new version and updating version.json ###
a=( ${prev_version//./ } )
if [[ "$arg" == "patch" ]]; then
    echo "bumping patching version"
    ((++a[2]))
    new_version="${a[0]}.${a[1]}.${a[2]}"
elif [[ "$arg" == "minor" ]]; then
    echo "bumping minor version"
    ((++a[1]))
    a[2]=0
    new_version="${a[0]}.${a[1]}.${a[2]}"
elif [[ "$arg" == "major" ]]; then
    echo "bumping major version"
    ((++a[0]))
    a[1]=0
    a[2]=0
    new_version="${a[0]}.${a[1]}.${a[2]}"
else
    if [[ $(check_version ${arg}) ]]; then
        echo "setting version $arg"
        new_version=$arg
    else
        echo "ERROR: Invalid argument. must be according to semantic versioning"
        echo "example: $0 1.2.4"
        exit 1
    fi
fi
short_version="${new_version//./}"
DATE=$(date +'%Y-%m-%d')
echo "replacing previous version: $prev_version with new version: $new_version"
tmp=$(mktemp)
jq --arg version $new_version '.ck8s = $version' "$file" > "$tmp" && mv "$tmp" "$file"

### Generating new changelog by combining CHANGELOG.md and WIP-CHANGELOG.md ###
echo "generating new changelog"

# Split Changelog and Table of contents(TOC) into seperate files
sed -n '/<!-- BEGIN TOC -->/,/<!-- END TOC -->/{ /<!--/d; p }' ${changelog} > temp-toc.md
sed '1,/^<!-- END TOC -->$/d' ${changelog} > temp-cl.md

# Adding version to changelog
echo -e "## v${new_version} - ${DATE}\n" | cat - ${wip} temp-cl.md > temp-cl2.md
# Adding link to TOC
echo -e "- [v${new_version}](#v${short_version}---${DATE})" | cat - temp-toc.md > temp-toc2.md
echo -e "<!-- END TOC -->" >> temp-toc2.md
echo -e "<!-- BEGIN TOC -->" | cat - temp-toc2.md > temp-toc.md
echo -e "\n-------------------------------------------------" >> temp-toc.md
# Creating new changelog
echo -e "# Compliant Kubernetes changelog" > ${changelog}
cat temp-toc.md temp-cl2.md >> ${changelog}
rm temp*
# Clearing WIP-CHANGELOG.md
> ${wip}

remote_repo="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

git config --local user.email "techteam@elastisys.com"
git config --local user.name "Elastisys"
git add ${file} ${changelog} ${wip}
git commit -m "Release v${new_version}"
git push "${remote_repo}" HEAD:${GITHUB_REF}

# Sets output to github actions
v=( ${new_version//./ } )
merge_branch="release-${v[0]}.${v[1]}"
echo ::set-output name=MERGE_BRANCH::${merge_branch}
echo ::set-output name=RELEASE_VERSION::${new_version}
