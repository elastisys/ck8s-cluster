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
    else echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
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
    else echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
    fi
}

#Args:
#   1. namespace
#   2. name of statefulset
function testStatefulsetStatus {
    kubectl rollout status statefulset -n $1 $2 --timeout=1m > /dev/null
    if [ $? == 0 ]
    then echo -n -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
    else echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
    fi
}

#Args:
#   1. namespace
#   2. name of job
#   3. Wait time for job to finish before marking failed
function testJobStatus {
    WAIT_TIME=$3

    while [[ $SECONDS -lt $WAIT_TIME ]]; do
      COMPLETED=$(kubectl get job -n $1 $2 -o jsonpath="{.status.succeeded}")
      if [[ $COMPLETED > 0 ]]; then
        SECONDS=$WAIT_TIME
      fi
      sleep 2
    done
    if [[ $COMPLETED > 0 ]]; then 
      echo -n -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
    else
      echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
      kubectl logs -n $1 $2
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
