#!/bin/bash

: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"

OLD_CONFIG="${CK8S_CONFIG_PATH}/config.sh"
NEW_CONFIG="${CK8S_CONFIG_PATH}/config.yaml"

cp ${OLD_CONFIG} ${NEW_CONFIG}

sed -i 's/export \([^=]\+\)/\L\1/' ${NEW_CONFIG}
sed -i 's/tf_var_//' ${NEW_CONFIG}
sed -i 's/=/: /' ${NEW_CONFIG}
