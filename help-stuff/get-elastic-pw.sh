#This script will get the password for elasticsearch/kibana
#Uses the default kubeconfig

kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode