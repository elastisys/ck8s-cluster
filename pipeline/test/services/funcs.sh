#Args:
#   1. kind
#   2. namespace
#   3. name of resource
function testResourceExistence {
    if kubectl get $1 -n $2 $3 &> /dev/null
    then
        echo -n -e "\texists ✔"; SUCCESSES=$((SUCCESSES+1))
        return 0
    else
        echo -n -e "\tmissing ❌"; FAILURES=$((FAILURES+1))
        return 1
    fi
}

#Args:
#   1. namespace
#   2. name of deployment
function testDeploymentStatus {
    kubectl rollout status deployment -n $1 $2 --timeout=1m > /dev/null
    if [ $? == 0 ]
    then echo -n -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
    else
        echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
        DEBUG_OUTPUT+=$(kubectl get deployment -n $1 $2 -o json)
    fi
}

#Args:
#   1. namespace
#   2. name of daemonset
function testDaemonsetStatus {
    DESIRED=$(kubectl get ds -n $1 $2 -o jsonpath="{.status.desiredNumberScheduled}")
    READY=$(kubectl get ds -n $1 $2 -o jsonpath="{.status.numberReady}")
    if [[ $DESIRED -eq $READY ]]
    then echo -n -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
    else
        echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
        DEBUG_OUTPUT+=$(kubectl get ds -n $1 $2 -o json)
    fi
}

#Args:
#   1. namespace
#   2. name of statefulset
function testStatefulsetStatus {
    kubectl rollout status statefulset -n $1 $2 --timeout=1m > /dev/null
    if [ $? == 0 ]
    then echo -n -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
    else
        echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
        DEBUG_OUTPUT+=($(kubectl get statefulset -n $1 $2 -o json))
    fi
}

# This function is required for statefulsets with update strategy OnDelete
# since `kubectl rollout status` doesn't work for them.
#Args:
#   1. namespace
#   2. name of statefulset
function testStatefulsetStatusByPods {
    REPLICAS=$(kubectl get statefulset -n $1 $2 -o jsonpath="{.status.replicas}")

    for replica in $(seq 0 $((REPLICAS - 1))); do
        POD_NAME=$2-$replica
        if ! kubectl wait -n $1 --for=condition=ready pod $POD_NAME --timeout=60s > /dev/null; then
            echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
            DEBUG_OUTPUT+=($(kubectl get statefulset -n $1 $2 -o json))
            return
        fi
    done
    echo -n -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
}

#Args:
#   1. namespace
#   2. name of job
#   3. Wait time for job to finish before marking failed
function testJobStatus {
    kubectl wait --for=condition=complete --timeout=$3 -n $1 job/$2 > /dev/null
    if [ $? == 0 ]; then
      echo -n -e "\tcompleted ✔"; SUCCESSES=$((SUCCESSES+1))
    else
      echo -n -e "\tnot completed ❌"; FAILURES=$((FAILURES+1))
      DEBUG_OUTPUT+=($(kubectl get -n $1 job $2 -o json))
      DEBUG_LOGS+=($(kubectl logs -n $1 job/$2))
    fi
}

#Args:
#   1. Name of endpoint to print
#   2. url
#   3. (optional) username and password, <username>:<password>
function testEndpoint {
    echo -e "Testing $1 endpoint"
    if [ -z $3 ]
    then
        RES=$(curl -ksIL -o /dev/null -X GET -w "%{http_code}" $2)
    else
        RES=$(curl -ksIL -o /dev/null -X GET -w "%{http_code}" -u $3 $2)
    fi
    if [[ $RES == "200" ]]
    then echo "success ✔"; SUCCESSES=$((SUCCESSES+1))
    else echo "failure ❌"; FAILURES=$((FAILURES+1))
    fi
}
