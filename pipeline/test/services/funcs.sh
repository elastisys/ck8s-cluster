#Args:
#   1. namespace
#   2. name of deployment
function testDeploymentStatus {
    echo $2
    kubectl rollout status deployment -n $1 $2 --timeout=1m > /dev/null
    if [ $? == 0 ]
    then echo "ready"; SUCCESSES=$((SUCCESSES+1))
    else echo "not ready"; FAILURES=$((FAILURES+1))
    fi
}

#Args:
#   1. namespace
#   2. name of daemonset
function testDaemonsetStatus {
    echo $2
    DESIRED=$(kubectl get ds -n $1 $2 -o jsonpath="{.status.desiredNumberScheduled}")
    READY=$(kubectl get ds -n $1 $2 -o jsonpath="{.status.numberReady}")
    if [[ $DESIRED -eq $READY ]]
    then echo "ready"; SUCCESSES=$((SUCCESSES+1))
    else echo "not ready"; FAILURES=$((FAILURES+1))
    fi
}

#Args:
#   1. namespace
#   2. name of statefulset
function testStatefulsetStatus {
    echo $2
    kubectl rollout status statefulset -n $1 $2 --timeout=1m > /dev/null
    if [ $? == 0 ]
    then echo "ready"; SUCCESSES=$((SUCCESSES+1))
    else echo "not ready"; FAILURES=$((FAILURES+1))
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
    then echo "success"; SUCCESSES=$((SUCCESSES+1))
    else echo "failure"; FAILURES=$((FAILURES+1))
    fi
}