# README

```shell
# Fetch submodules
git submodule init
git submodule update

# Set up virtual env with requirements for kubespray
python3 -m virtualenv virtenv
source virtenv/bin/activate
pip install -r requirements.txt
```

See [terraform](/terraform) for how to create virtual machines and other resources needed to install Kubernetes.

Update `inventory/sample/inventory.ini` as needed and run kubespray:

```shell
ansible-playbook --become -i inventory/sample/inventory.ini kubespray/cluster.yml
```

Set up cluster wide helm/tiller:

```shell
# Generate certs in `certs` for admin1 and admin2 and deploy tiller
./scripts/initialize-cluster.sh certs "admin1 admin2"
# Check that you can access tiller
source scripts/helm-env.sh kube-system certs/kube-system/certs admin1
helm version
```

Deploy infrastructure applications:

```shell
./scripts/deploy-infra.sh
```
