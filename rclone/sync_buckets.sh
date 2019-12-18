#!/bin/bash

set -e

# Fail if remotes and sync buckets is empty
: "${REMOTE_SRC:?Missing REMOTE_SRC}"
: "${REMOTE_SRC:?Missing REMOTE_DST}"
: "${BUCKETS_TO_SYNC:?Missing BUCKETS_TO_SYNC}"

readonly cmd="sync"
extra_args="$EXTRA_ARGS"
remote_src="$REMOTE_SRC"
remote_dst="$REMOTE_DST"
buckets="$BUCKETS_TO_SYNC"

for bucket in $buckets; do
    rclone "${cmd}" "${remote_src}:${bucket}" "${remote_dst}:${bucket}" --log-level DEBUG ${extra_args}
done
