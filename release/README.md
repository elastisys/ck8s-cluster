# Release process

The releases will follow semantic versioning and be handled with git tags.
https://semver.org/

## Tracked releases

When ready to cut a new major or minor release create a release branch
`release-x.y` from the last minor release tag. For example:
```bash
git checkout v0.2.0
git checkout -b release-0.3
git push -u origin release-0.3
```
The rest of the workflow will be handled by a pipeline see
[Trigger a release](#trigger-a-release).

## Minor and Patch releases
For minor and patch releases pull in the desired changes to the existing release branch.
Minor changes can be pulled from feature branches and add new features while a patch
should only include hotfixes that does not require any downtime to be pulled in.

## Trigger a release
To trigger the release pipeline make sure you have the correct release branch checked out. Then create another branch called `pre-release-<patch|minor|major|version>`.
If the suffix is `patch`, `minor` or `major` then the version in `version.json` will be bumped. Otherwise the suffix must be a version following the semver standard.

When this pre-release branch is pushed a pipeline will be triggered which:

1. Tests the standard pipeline and creates a `version.json` with the running versions.
2. Increase the CK8S version in `version.json`
3. Append what ever is in `WIP-CHANGELOG.md` to `CHANGELOG.md`
4. Clear `WIP-CHANGELOG.md`
4. Create a git commit with message `release version vx.x.x`
5. Create a tag named `vx.x.x`
6. Creates a pr to the `release-x` branch.

When this is done review the new PR and merge it to finalize the release.


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
