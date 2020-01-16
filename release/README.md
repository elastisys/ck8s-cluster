# Release process

The releases will follow semantic versioning and be handled with git tags.
When all the desired changes for a certain release is done run: 
```./release.sh [patch|minor|major|-v verion]```

`patch, minor or major` will bump the current version found in `VERSION.md` while
using `-v version` will set a specific version.

The script will do the following:

1. Increase the version in `VERSION.md`
2. Append what ever is in `WIP-CHANGELOG.md` to `CHANGELOG.md`
3. Clear `WIP-CHANGELOG.md`
4. Create a git commit with message `release version vx.x.x`
5. Create a tag named `vx.x.x`

OBS! the release must be done from someone with write access to the master branch.

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

When creating a major (and perhaps minor) release a section of `Release highlights` can be added at the top with a summary of all the patch notes.

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
