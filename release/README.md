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

## While developing

When a feature or change is developed on a branch fill out some human readable
bullet points in the `WIP-CHANGELOG.md` this will make it easier to track the changes.
Once the release is done this will be appended to the main changelog. Add the bullet points
in some subsections for example:

* Added
* Removed
* Changes
* Fixes

You can link comments to related pull requests with `PR#pr-number`. Commit ids can be linked
by just writing that commits short hash or full hash.


Exact format of CHANGELOG is yet to be determined.
