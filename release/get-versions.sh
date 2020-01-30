#!/bin/bash

file=version.json

# Get k8s version
tmp=$(mktemp)
K8S=`kubectl version -o json | jq -r '.serverVersion.gitVersion'`
jq --arg version $K8S '.k8s = $version' "$file" > "$tmp" && mv "$tmp" "$file"

# List of applications to look for
APPS="prometheus,grafana,harbor-core,falco,fluentd,velero,nginx-ingress-controller,elasticsearch,kibana"
# Get all kubernetes pods container images
list=`kubectl get pods --all-namespaces -o jsonpath="{..image}" |tr -s '[[:space:]]' '\n' |sort |uniq -d`

# Loop and put all versions from APPS into a json file under .services
for item in $list
do
  match=`echo "$item" | sed 's|.*/||'`
  name=`echo "$match" | sed 's/:.*//'`
  version=`echo "$match" | sed 's/^.*://'`
  if [[ $APPS =~ (^|,)$name($|,) ]]; then
    tmp=$(mktemp)
    echo "$name is a match"
    jq --arg version $version --arg name "$name" '.services[$name] = $version' "$file" > "$tmp" && mv "$tmp" "$file" 
  fi
done
