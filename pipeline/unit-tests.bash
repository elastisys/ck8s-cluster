#!/bin/bash

set -e

here="$(dirname "$(readlink -f "$0")")"

pushd "${here}/.."
make test
popd
