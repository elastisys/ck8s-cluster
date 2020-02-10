# Release process

The releases will follow semantic versioning and be handled with git tags.
https://semver.org/

## Major releases
When ready to cut a new major release create a release branch `release-x`.
This will when pushed trigger the pipeline to create and test a new cluster. 
Run all tests necessary and if everything passes get the artifact version.json from
the pipeline and update the local version.json. 
When everything else is done run: 
```./release.sh [patch|minor|major|-v verion]```

`patch, minor or major` will bump the current version found in `version.json` while
using `-v version` will set a specific version.

The script will do the following:

1. Increase the CK8S version in `version.json`
2. Append what ever is in `WIP-CHANGELOG.md` to `CHANGELOG.md`
3. Clear `WIP-CHANGELOG.md`
4. Create a git commit with message `release version vx.x.x`
5. Create a tag named `vx.x.x`

The last step is running `git push; git push --tags` manually then opening a pull request
back to master.

## Minor and Patch releases
For minor and patch releases pull in the desired changes to the existing release branch.
Minor changes can be pulled from feature branches and add new features while a patch 
should only include hotfixes that does not require any downtime to be pulled in.

The rest follows the workflow from a major release.

## While developing

When a feature or change is developed on a branch fill out some human readable
bullet points in the `WIP-CHANGELOG.md` this will make it easier to track the changes.
Once the release is done this will be appended to the main changelog. 

## Structure

The structure follow the guidelines of [keepachangelog](https://keepachangelog.com/en/1.0.0/).

Changelogs are for humans, not machines. Keep messages in human readable form rather
than commits or code. Commits or pull requests can off course be linked. Add messages
as bullet points under one of theese categories:

* Added
* Changed
* Deprecated
* Removed
* Fixed
* Security

When creating a major release a section of `Release highlights` should be added
on top of the WIP-changelog with a summary of the most important changes.

You can link comments to related pull requests with `PR#pr-number`. Commit ids can be linked
by just writing that commits short hash or full hash.

# Example changelog

## v0.1.2 - 2020-01-14  (OBS! this line is automatically added by script)

### Added

* Option to add prometheus scrape endpoints
* Retetion for elasticsearch

### Changed

* Updated grafana version to 6.7.0
* Changed manifests for deploying ck8sdash into a helm chart PR#120

### Deprecated

* Option to disable OPA with `ENABLE_OPA` variable. Now always true

### Removed

* Curator has been removed. Now retention is configured with ILM.

### Fixed

* bugfix deploying elasticsearch operator 2310e74
