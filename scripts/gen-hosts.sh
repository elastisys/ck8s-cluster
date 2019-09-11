#!/bin/bash

# Generates hosts.json from terraform output.

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

cd "${SCRIPTS_PATH}/../terraform/"
tf_out=$(terraform output -json)
cd "${SCRIPTS_PATH}/../"

echo "$tf_out" > hosts.json