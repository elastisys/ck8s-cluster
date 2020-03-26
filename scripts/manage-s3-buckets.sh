#!/bin/bash

set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"
: "${S3COMMAND_CONFIG_FILE:?Missing S3COMMAND_CONFIG_FILE}"

buckets=("S3_HARBOR_BUCKET_NAME" "S3_VELERO_BUCKET_NAME" "S3_ES_BACKUP_BUCKET_NAME" "S3_INFLUX_BUCKET_NAME" "S3_SC_FLUENTD_BUCKET_NAME")

s3cmd='s3cmd --config '"${S3COMMAND_CONFIG_FILE}"

# check if all the environment variables with S3 backet names are set
for bucket in ${buckets[@]}
do
    : "${!bucket:?Missing $bucket}"
done

CREATE_ACTION="create"
DELETE_ACTION="delete"
ABORT_UPLOAD_ACTION="abort"

while [ "$1" != "" ]; do
    case $1 in
        -c | --create )             ACTION=$CREATE_ACTION
                                    ;;
        -d | --delete )             ACTION=$DELETE_ACTION
                                    ;;
        -a | --abort  )             ACTION=$ABORT_UPLOAD_ACTION
                                    ;;
    esac
    shift
done

function create_bucket() { # arguments: bucket name
    local bucket_name="$1"

    echo "checking status of bucket ["${!bucket_name}"] at [$CLOUD_PROVIDER]" >&2
    BUCKET_EXISTS=$(echo "$S3_BUCKET_LIST" | awk "\$3~/^s3:\/\/${!bucket_name}$/ {print \$3}")

    if [ $BUCKET_EXISTS ]; then
        echo "bucket [${!bucket_name}] already exists at [$CLOUD_PROVIDER], do nothing" >&2
    else
        echo "bucket [${!bucket_name}] does not exist at [$CLOUD_PROVIDER], creating it now" >&2
        ${s3cmd} mb s3://${!bucket_name}
    fi
}

function delete_bucket() { # arguments: bucket name
    local bucket_name="$1"

    echo "checking status of bucket ["${!bucket_name}"] at [$CLOUD_PROVIDER]" >&2
    BUCKET_EXISTS=$(echo "$S3_BUCKET_LIST" | awk "\$3~/^s3:\/\/${!bucket_name}$/ {print \$3}")

    if [ $BUCKET_EXISTS ]; then
        echo "bucket [${!bucket_name}] exists at [$CLOUD_PROVIDER], deleting it now" >&2
        ${s3cmd} rb s3://${!bucket_name} --force --recursive
    else
        echo "bucket [${!bucket_name}] does not exist at [$CLOUD_PROVIDER], do nothing" >&2
    fi
}

function abort_multipart_uploads() { # arguments: bucket name
    local bucket_name="$1"

    echo "checking status of bucket ["${!bucket_name}"] at [$CLOUD_PROVIDER]" >&2
    ONGOING_UPLOADS=$(${s3cmd} multipart s3://${!bucket_name} | \
                      awk 'FNR > 2 { print $2 " " $3 }') # header has two lines

    if [ -n "$ONGOING_UPLOADS" ]; then
        echo "The are ongoing multipart uploads, aborting them now"
        echo "$ONGOING_UPLOADS" | while read line ; do
            echo "Aborting $line"
            ${s3cmd} abortmp $line
        done
    fi
}

# get a list of all the S3 buckets
# S3 configuration is set in gen-s3cfg.sh script
S3_BUCKET_LIST=$(${s3cmd} ls)

if [[ "$ACTION" == "$CREATE_ACTION" ]] ; then
    echo 'Create buckets (only if they do not exist)' >&2

    for bucket in ${buckets[@]}
    do
        create_bucket $bucket
    done
elif [[ "$ACTION" == "$DELETE_ACTION" ]] ; then
    echo 'Delete buckets' >&2

    for bucket in ${buckets[@]}
    do
        delete_bucket $bucket
    done
elif [[ "$ACTION" == "$ABORT_UPLOAD_ACTION" ]] ; then
    echo 'Abort mutlipart uploads to buckets' >&2

    for bucket in ${buckets[@]}
    do
        abort_multipart_uploads $bucket
    done
else
    echo 'Unknow action. Aborting!' >&2
    exit 1
fi
