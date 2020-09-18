#!/bin/bash

set -e -o pipefail

for CK8S_CLUSTER in sc wc; do
    export CK8S_CLUSTER
    go run . machine list | \
        awk '{print $2" "$3}' | \
        xargs -l go run . k8s replace --auto-approve
done
