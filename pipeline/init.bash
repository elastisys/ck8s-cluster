#!/bin/bash
# Usage: ./init.sh <Environment name> <Cloud provider>
# The env variable CK8S_PGP_FP will be available in this script

set -e

ckctl init $1 $2
