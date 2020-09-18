#!/bin/bash

: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"

OLD_SECRETS="${CK8S_CONFIG_PATH}/secrets.env"
NEW_SECRETS="${CK8S_CONFIG_PATH}/secrets.yaml"

sops -d ${OLD_SECRETS} | \
    sed 's/^\([^=]\+\)/\L\1/' | \
    sed 's/tf_var_//' | \
    sed 's/=/: /' | \
    sops --config "${CK8S_CONFIG_PATH}/.sops.yaml" --input-type yaml --output-type yaml -e /dev/stdin > ${NEW_SECRETS}
