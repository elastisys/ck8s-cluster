package kubernetes.admission

import data.kubernetes.networkpolicies


operations = {"UPDATE", "CREATE"}
data = input.request.object.spec.template.metadata

###### TODO: Skriva matchExpressionser
            # om namespace inte är satt

deny[msg] {
    input.request.kind.kind == "Deployment"
    operations[input.request.operation] 
    namespace := input.request.object.metadata.namespace
    namespace == "opa-test"
    
    res = [x | x := allChecks(networkpolicies[namespace][_])]
    all(res) #all networkpolicies failed to match
    msg := sprintf("No matching networkpolicy found", []) #: %v", ["error"]
}

#Check one networkpolicy, returns true if it does not match
allChecks(netwPolicy) = res {
    r1 := matchLabelsMissingKeys(netwPolicy)
    r2 := any(matchLabelsValues(netwPolicy))
    r3 := matchExpressionsExists(netwPolicy)
    r4 := matchExpressionsDoesNotExist(netwPolicy)
    r5 := any(matchExpressionsIn(netwPolicy))
    r6 := any(matchExpressionsNotIn(netwPolicy))
    #return true if any part of the networkpolicy does not match
    res := any({r1, r2, r3, r4, r5, r6})
}

matchLabelsMissingKeys(netwPolicy) = res {
    res3 := {key | netwPolicy.spec.podSelector.matchLabels[key]}
    res4 := {key | data.labels[key]}
    res := count(res3 - res4) != 0
}

matchLabelsValues(netwPolicy) = res {
    res := [x | 
        data.labels[key1] != netwPolicy.spec.podSelector.matchLabels[key3];
        x := key1 == key3]
}

matchExpressionsExists(netwPolicy) = res {
    keys := { key | 
        netwPolicy.spec.podSelector.matchExpressions[i].operator == "Exists"
        key := netwPolicy.spec.podSelector.matchExpressions[i].key}
    inputKeys := {key | data.labels[key]}
    res := count(keys - inputKeys) != 0
}

matchExpressionsDoesNotExist(netwPolicy) = res {
    keys := { key | 
        netwPolicy.spec.podSelector.matchExpressions[i].operator == "DoesNotExist"
        key := netwPolicy.spec.podSelector.matchExpressions[i].key}
    inputKeys := {key | data.labels[key]}
    res := count(keys & inputKeys) != 0
}

matchExpressionsIn(netwPolicy) = res {
    res := [ x | 
        netwPolicy.spec.podSelector.matchExpressions[i].operator == "In"
        key := netwPolicy.spec.podSelector.matchExpressions[i].key
        x := false == any([y | y := data.labels[key] == netwPolicy.spec.podSelector.matchExpressions[i].values[_]])]
}

matchExpressionsNotIn(netwPolicy) = res {
    res := [ x | 
        netwPolicy.spec.podSelector.matchExpressions[i].operator == "NotIn"
        key := netwPolicy.spec.podSelector.matchExpressions[i].key
        x := any([y | y := data.labels[key] == netwPolicy.spec.podSelector.matchExpressions[i].values[_]])]
}