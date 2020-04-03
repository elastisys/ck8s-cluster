#!/bin/bash

# Note: this migration is only meant to be run on clusters where the indices
#   - kubecomponents
#   - kubernetes
#   - kubeaudit
#   - other
# exsist in elasticsearch. If your elasticsearch cluster already have rollover enabled indices,
# you don't have to run this script.

# Note: this script modifies the elasticsearch ingress which makes elasticsearch not
# reachable through the domain name.
# Execute 'kubectl -n elastic-system port-forward svc/elasticsearch-es-http 9200:9200',
# in another shell on your host.
# set 'export ES_HOST=https://localhost:9200' if you ran the command above. 

# This scripts:
# 1. Disables logs to elasticsearch
# 2. For each index to migrate
#    - Reindex
#    - Removes original index
#    - Adds index alias to new index.
#    - Makes the new index the write index
# 3. Enables logs to elasticsearch fluentd

# This is what the indecies should look like after this script has run, granted
# that you passwed all of the 4 indices
## kubecomponents -> kubecomponents-default-$(date +%Y.%m.%d)-000001
## kubernetes     -> kubernetes-default-$(date +%Y.%m.%d)-000001
## kubeaudit      -> kubeaudir-default-$(date +%Y.%m.%d)-000001
## other          -> other-default-$(date +%Y.%m.%d)-000001

set -eu -o pipefail

# Elasticsearch variables.
: "${ES_HOST:?Missing ES_HOST}"
: "${ES_USER:?Missing ELASTIC_USER}"
: "${ES_PASSWORD:?Missing ES_PASSWORD}"

function disable_es_ingress () {
    echo "¤ Disabling elasticsearch ingress"
    kubectl -n elastic-system get ing elasticsearch -o json \
        | jq '(.spec.rules[].http.paths[].backend.serviceName | select(. == "elasticsearch-es-http")) |= "temp-nonexisting"' \
        | kubectl apply -f -
}

function enable_es_ingress () {
    echo "¤ Enabling elasticsearch ingress"
    kubectl -n elastic-system get ing elasticsearch -o json \
        | jq '(.spec.rules[].http.paths[].backend.serviceName | select(. == "temp-nonexisting")) |= "elasticsearch-es-http"' \
        | kubectl apply -f -
}

function pre_migrate_checks () {
    index="${1}"

    # Check that index exsists. 
    curl -ks -X GET "${ES_HOST}/${index}" \
        -u "${ES_USER}:${ES_PASSWORD}" \
        | grep "index_not_found_exception" >/dev/null 2>&1 \
        && echo "Skipping index \"${index}\" as it does not exsist!" && return 1

    # Check that there is no write index.
    # Assumes index name is the same as the desired alias.
    curl -ks -X GET "${ES_HOST}/_cat/aliases/${index}?v" \
        -u "${ES_USER}:${ES_PASSWORD}" \
        | grep "true" >/dev/null 2>&1 \
        && echo "Write index already exsist for alias \"${index}\"" && return 1
    
    return 0
}

function migrate_index () {
    src_index="${1}"
    dst_index="${src_index}-default-$(date +%Y.%m.%d)-000001"

    echo -e "#############################"
    echo "¤ Starting migration of \"${src_index}\" to \"${dst_index}\""
    
    # Create new index.
    echo "¤ Creating index \"${dst_index}\""
    curl -ks -X PUT "${ES_HOST}/%3C"${src_index}"-default-%7Bnow%2Fd%7D-000001%3E?pretty" \
        -u "${ES_USER}:${ES_PASSWORD}" \
        | tee /dev/stderr | grep "resource_already_exists_exception" >/dev/null 2>&1 && echo "Failed to create new index" && return 1

    # Reindex data to new index.
    echo "¤ Starting to reindex \"${src_index}\" to \"${dst_index}\""
    task=$(curl -ks -X POST "${ES_HOST}/_reindex?wait_for_completion=false" -H 'Content-Type: application/json' -u "${ES_USER}:${ES_PASSWORD}" -d'
    {
        "source": {
            "index": "'"${src_index}"'"
        },
        "dest": {
            "index": "'"${dst_index}"'"
        }
    }
    ' | tee /dev/stderr | jq -r '.task')
    
    echo

    while true; do
        status=$(curl -ks -X GET "${ES_HOST}/_tasks/${task}" -u "${ES_USER}:${ES_PASSWORD}" | jq '.completed')
        [ "${status}" = "true" ] && break;
        echo "¤ Waiting for reindexing to complete"
        sleep 5
    done

    echo "¤ Reindexing complete"

    # Show user status of reindex task
    echo "¤ Reindex task status. Check that it looks OK."
    curl -ks -X GET "${ES_HOST}/_tasks/${task}?pretty" -u "${ES_USER}:${ES_PASSWORD}"

    read -p "¤ Everything looks OK? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi

    # Remove old index
    read -p "¤ OK to delete index \"${src_index}\"? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi

    curl -ks -X DELETE -s "${ES_HOST}/${src_index}?pretty" \
    -u "${ES_USER}:${ES_PASSWORD}"

    # Add alias to new index.
    echo "¤ Adding alias \"${src_index}\" to \"${dst_index}\""
    curl -ks -X POST "${ES_HOST}/_aliases?pretty" \
        -u "${ES_USER}:${ES_PASSWORD}" \
        -H 'Content-Type: application/json' -d'
        {
            "actions" : [
                { "add" : 
                    { 
                        "index" : "'${dst_index}'", 
                        "alias" : "'${src_index}'",
                        "is_write_index" : true
                    } 
                }
            ]
        }
        '
    
    # The policy execution step may have executed and failed before the alias was added.
    ilm_step=$(curl -ks -X GET "${ES_HOST}/${dst_index}/_ilm/explain?pretty" -u "${ES_USER}:${ES_PASSWORD}" \
        | jq -r '.indices."'"${dst_index}"'".step')
    
    if [ "${ilm_step}" = "ERROR" ]; then
        echo "¤ Retrying policy execution step"
        curl -ks -X POST "${ES_HOST}/${dst_index}/_ilm/retry?pretty" -u "${ES_USER}:${ES_PASSWORD}"    
    fi

    echo "¤ Done migrating index \"${src_index}\""
}


[ "${#}" -lt 1 ] && echo "Usage ${0} <indices_to_migrate>" && exit 1

# Stop logs from going into elasticsearch.
disable_es_ingress

# Migrate indices.
for index in "${@}"; do
    if pre_migrate_checks "${index}"; then
        migrate_index "${index}"
    fi
done

# Start log flow again.
enable_es_ingress