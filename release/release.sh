#!/bin/bash
# Usage ./release.sh patch|minor|major

if [[ ! -f VERSION.md ]]; then
  echo "ERROR:  VERSION.md does not exist"
  exit 1
fi
semver_regex='^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[a-zA-Z\d][-a-zA-Z.\d]*)?(\+[a-zA-Z\d][-a-zA-Z.\d]*)?$'
prev_version=$(head -n 1 VERSION.md | sed 's/^.*-\ \([0-9.]*\).*/\1/')
if [[ ! "$prev_version" =~ ${semver_regex} ]]; then
    echo "ERROR: $prev_version from VERSION.md does not match semantic versioning"
    exit 1
fi
a=( ${prev_version//./ } ) 
if [[ "$1" == "patch" ]]; then
    echo "bumping patching version"
    ((a[2]++))
    new_version="${a[0]}.${a[1]}.${a[2]}"
elif [[ "$1" == "minor" ]]; then
    echo "bumping minor version"
    ((a[1]++))
    new_version="${a[0]}.${a[1]}.${a[2]}"
elif [[ "$1" == "major" ]]; then
    echo "bumping major version"
    ((a[0]++))
    new_version="${a[0]}.${a[1]}.${a[2]}"
elif [[ "$1" == "-v" ]]; then
    if [[ "$2" =~ ${semver_regex} ]]; then
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
echo "replacing previous version: $prev_version with new version: $new_version"
sed -i "1!b;s/${prev_version}/${new_version}/" VERSION.md


echo "generating new changelog"
sed -n '/^<!-- BEGIN TOC -->/,/^<!-- END TOC -->/!p' CHANGELOG.md > temp-cl.md
sed -n '/<!-- BEGIN TOC -->/,/<!-- END TOC -->/{ /<!--/d; p }' CHANGELOG.md > temp-toc.md

echo -e "# v${new_version}\n" | cat - WIP-CHANGELOG.md temp-cl.md > temp-cl2.md
echo -e "- [v${new_version}](#v${short_version})" | cat - temp-toc.md > temp-toc2.md
echo -e "<!-- END TOC -->" >> temp-toc2.md
echo -e "<!-- BEGIN TOC -->" | cat - temp-toc2.md > temp-toc.md
echo -e "\n-------------------------------------------------" >> temp-toc.md
cat temp-toc.md temp-cl2.md > CHANGELOG.md
rm temp*

> WIP-CHANGELOG.md

#git add VERSION.md CHANGELOG.md WIP-CHANGELOG.md
#git commit -m "Releasing v${new_version}"
#git tag -a "v${new_version}" -m "releasing version ${new_version}"

echo ""
echo "finish release with:"
echo ""
echo "  git push; git push --tags"
echo ""
