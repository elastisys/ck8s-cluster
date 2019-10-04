#!/bin/bash

# This script exports the variables needed for vault.

set -e

# Vault and passwords
export CUSTOMER_ID="pipeline-${BITBUCKET_BUILD_NUMBER}"
export VAULT_ADDR=https://vault.eck.elastisys.se
export PWD_LENGTH=16
export BASE_PATH="eck/data/v1/${CUSTOMER_ID}/1"
export BASE_PATH_META="eck/metadata/v1/${CUSTOMER_ID}/1"