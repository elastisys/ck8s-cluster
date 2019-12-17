#!/bin/bash

# This script exports the variables needed for vault.

set -e

# Vault and passwords
export ENVIRONMENT_NAME="pipeline-${BITBUCKET_BUILD_NUMBER}"
export VAULT_ADDR=https://vault.eck.elastisys.se
export BASE_PATH_META="eck/metadata/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}"