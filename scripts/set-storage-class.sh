#!/bin/bash
# Sets storage classes of the current workspace.

set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

case $CLOUD_PROVIDER in

  safespring | citycloud)
    export STORAGE_CLASS=cinder-storage
    export ES_STORAGE_CLASS=cinder-storage
    ;;

  exoscale)
    export STORAGE_CLASS=nfs-client
    export ES_STORAGE_CLASS=local-storage
    ;;

  *)
    echo "ERROR: Unknown CLOUD_PROVIDER [$CLOUD_PROVIDER], STORAGE_CLASS value could not be set."
    exit 1
    ;;
esac