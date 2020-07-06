#!/usr/bin/env bash

#Args:
#   1. verb
#   2. resource
#   3. namespace
#   4. user
function testCanUserDoInNamespace {
    echo -n "$4 $1 $2 in $3"
    if kubectl auth can-i "$1" "$2" -n "$3" --as "$4" > /dev/null 2>&1;
    then echo -e "\tauthorized ✔"; SUCCESSES=$((SUCCESSES+1))
    else
        echo -e "\tnot authorized ❌"; FAILURES=$((FAILURES+1))
    fi
}

#Args:
#   1. verb
#   2. resource
#   3. user
function testCanUserDo {
    echo -n -e "$3 $1 $2"
    if kubectl auth can-i "$1" "$2" --as "$3" > /dev/null 2>&1;
    then echo -e "\tauthorized ✔"; SUCCESSES=$((SUCCESSES+1))
    else
        echo -e "\tnot authorized ❌"; FAILURES=$((FAILURES+1))
    fi
}


echo
echo
echo "Testing customer RBAC"
echo "=================="

: "${CUSTOMER_NAMESPACES:?Missing CUSTOMER_NAMESPACES}"
: "${CUSTOMER_ADMIN_USERS:?Missing CUSTOMER_ADMIN_USERS}"

for user in ${CUSTOMER_ADMIN_USERS}; do
    testCanUserDo "get" "node" "$user"
    testCanUserDo "get" "namespace" "$user"
done

VERBS=(
    create
    delete
)
RESOURCES=(
    deployments
)

for user in ${CUSTOMER_ADMIN_USERS}; do
    for namespace in ${CUSTOMER_NAMESPACES}; do
        for resource in "${RESOURCES[@]}"; do
            for verb in "${VERBS[@]}"; do
                testCanUserDoInNamespace "$verb" "$resource" "$namespace" "$user"
            done
        done
    done
done

FLUENTD_VERBS=(
    patch
)
FLUENTD_RESOURCES=(
    configmaps/fluentd-extra-config
    configmaps/fluentd-extra-plugins
)

for user in ${CUSTOMER_ADMIN_USERS}; do
    for resource in "${FLUENTD_RESOURCES[@]}"; do
        for verb in "${FLUENTD_VERBS[@]}"; do
            testCanUserDoInNamespace "$verb" "$resource" "fluentd" "$user"
        done
    done
done

if [[ $ENABLE_CUSTOMER_ALERTMANAGER == "true" ]]
then
    ALERTMANAGER_SECRET_VERBS=(
        update
    )
    ALERTMANAGER_SECRET_RESOURCES=(
        secret/alertmanager-alertmanager
        secret/customer-alertmanager-auth
    )

    for user in ${CUSTOMER_ADMIN_USERS}; do
        for resource in "${ALERTMANAGER_SECRET_RESOURCES[@]}"; do
            for verb in "${ALERTMANAGER_SECRET_VERBS[@]}"; do
                testCanUserDoInNamespace "$verb" "$resource" "monitoring" "$user"
            done
        done
    done

    ALERTMANAGER_ROLEBINDING_VERBS=(
        create
    )
    ALERTMANAGER_ROLEBINDING_RESOURCES=(
        rolebinding/alertmanager-configurer
    )

    for user in ${CUSTOMER_ADMIN_USERS}; do
        for resource in "${ALERTMANAGER_ROLEBINDING_RESOURCES[@]}"; do
            for verb in "${ALERTMANAGER_ROLEBINDING_VERBS[@]}"; do
                testCanUserDoInNamespace "$verb" "$resource" "monitoring" "$user"
            done
        done
    done
fi
