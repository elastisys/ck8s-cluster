#!/bin/bash
# Script to get versions from current kubeconfig and post to json file.
set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
file=${SCRIPTS_PATH}/version.json

# Get k8s version
tmp=$(mktemp)
K8S=`kubectl version -o json | jq -r '.serverVersion.gitVersion'`
jq --arg version $K8S '.k8s = $version' "$file" > "$tmp" && mv "$tmp" "$file"

list=`kubectl get pods --all-namespaces -o jsonpath="{..image}" |tr -s '[[:space:]]' '\n' |sort |uniq -d`

# Loop and put all versions from APPS into a json file under .services
# Todo improve and create a better "tree" output.
for item in $list
do
  name=`echo "$item" | sed 's/:.*//'`
  version=`echo "$item" | sed 's/^.*://'`
  tmp=$(mktemp)
  echo "$name is a match"
  jq --arg version $version --arg name "$name" '.services[$name] = $version' "$file" > "$tmp" && mv "$tmp" "$file" 
done
