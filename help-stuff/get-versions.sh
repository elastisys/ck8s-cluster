#!/bin/bash

file=version.json
APPS="prometheus,grafana,harbor-core,falco,fluentd,velero,nginx-ingress-controller,elasticsearch,kibana"
list=`kubectl get pods --all-namespaces -o jsonpath="{..image}" |tr -s '[[:space:]]' '\n' |sort |uniq -d`
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
