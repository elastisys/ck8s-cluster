# A1-demo dex installation 

## 1. Create credentials at provider

First step is to create your credentials at a provider such as google. Go to https://console.developers.google.com/apis/credentials  and  create credentials with Application Type: Other.
    
## 2. Set up the cluster with the oidc flags

Following flags are added to configure the api-server to use oidc.

```yaml
extra_args:
      oidc-issuer-url: https://accounts.google.com
      oidc-client-id: YOUR_CLIENT_ID.apps.googleusercontent.com
      oidc-username-claim: email
      oidc-groups-claim: groups
```
Generate the config by running and set up the cluster by running.
``` sh
./gen-rke-conf-ss.sh 
rke up --config cluster-ss.yaml
```
Move contents of kube_config_cluster-ss.yaml to ~/.kube/config

## 3. Create certificates,install helm and apply psp.

``` sh
kubectl create ns dex
kubectl apply -f manifests/podSecurityPolicy/psp-access-ss.yaml
cd scripts
./initialize-cluster.sh certs "helm admin1 admin2"
source helm-env.sh kube-system certs/kube-system/certs helm
helm upgrade dex ../charts/dex --install --namespace dex \ -f ../helm-values/dex-values.yaml
``` 
If for some reason the dex installation did not go trough you can uninstall dex by running:

``` sh

helm delete --purge dex
kubectl delete jobs -n dex dex-grpc-certs 
kubectl delete -n dex configmaps dex-openssl-config 
``` 

## 4. Set credentials,Rolebinding and update kubernetes config.

Make sure you have the correct permissions for the account. 

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: oidc-admin-group
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: User
  name: https://accounts.google.com#GOOGLE_ACCOUNT_ID
```

Set the credentials

``` sh
kubectl config set-credentials developer \
  --auth-provider oidc \
  --auth-provider-arg idp-issuer-url=https://accounts.google.com \
  --auth-provider-arg client-id=YOUR_CLIENT_ID.apps.googleusercontent.com \
  --auth-provider-arg client-secret=CREDENTIALS_SECRET
  
kubectl config set-context google --user=developer --cluster=eck-system-services
kubectl config use-context google
``` 

Use kubelogin to open up a browser and then authenticate trough the browser to get a token.

``` sh
kubelogin
``` 
After this run a generic kubectl command to confirm  that everything is working. 




