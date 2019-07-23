
# NOTE: Script cannot be run as is, but has to be run manually, step by step. 

# Export environement variables 
# NOTE: TF_VAR_exoscale_api_key and TF_VAR_exoscale_secret_key have to be set in your environment
export CERT_FOLDER=staging-certs
export WORKSPACE=/home/erik/a1-demo

# Prepare to create certificates 
mkdir -p ${CERT_FOLDER}/kube-system/certs
kubectl apply -f ${WORKSPACE}/manifests/podSecurityPolicy/psp-access.yaml

# Start helm
sh ${WORKSPACE}/scripts/initialize-cluster.sh staging-certs "helm admin1 admin2"
source helm-env.sh kube-system staging-certs/kube-system/certs helm

#
# Namespaces 
#

# Create the namespace for cert-manager
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -

# Create the namespace for harbor
kubectl create ns harbor --dry-run -o yaml | kubectl apply -f -

#
# Labels
# 

# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite

# Add additional PSP 
kubectl apply -f ${WORKSPACE}/manifests/podSecurityPolicy/psp-access.yaml

#
# Cert-manager 
#

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install cert-manager
helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.1

# Create letsencrypt-staging and prod ClusterIssuers
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-staging.yaml
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-prod.yaml

# 
# Harbor 
# 

# Create PersistentVolume and claiming it for harbor persistence. 
# NOTE: IP addresses of nodes have to be manually configured in storage.yaml  
kubectl apply -f ${WORKSPACE}/harbor/storage.yaml
kubectl apply -f ${WORKSPACE}/harbor/pv-claim.yaml

# Create rolebindings for harbor
kubectl -n harbor create rolebinding harbor-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=harbor:default \
    --dry-run -o yaml | kubectl apply -f -

# Deploying harbor 
# NOTE: TF_VAR_exoscale_api_key and TF_VAR_exoscale_secret_key have to be set in your environment
helm upgrade harbor ./../backup_OLD/charts/harbor \
  --install \
  --namespace harbor \
  --values ${WORKSPACE}/helm-values/harbor-values.yaml \
  --set persistence.imageChartStorage.s3.secretkey=$TF_VAR_exoscale_secret_key \
  --set persistence.imageChartStorage.s3.accesskey=$TF_VAR_exoscale_api_key

# Annotate certmanager for harbor 
kubectl -n harbor annotate ingress harbor-harbor-ingress certmanager.k8s.io/cluster-issuer=letsencrypt-prod
