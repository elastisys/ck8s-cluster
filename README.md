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

## Harbor

Prepare the Harbor demo in the following way.

- Go to the [harbor GUI](https://core.harbor.demo.compliantk8s.com).
- Login with `admin:Elastisys123`
- Create a project named `test`
- Push nginx to the private registry:
    ```shell
    docker pull nginx
    docker tag nginx:latest core.harbor.demo.compliantk8s.com/test/nginx:test-01
    docker login core.harbor.demo.compliantk8s.com
    docker push core.harbor.demo.compliantk8s.com/test/nginx:test-01
    ```
- Select the container image in harbor and scan it.

To take this container image for a test drive in the cluster do the following:

```shell
kubectl create ns test
kubectl -n test create secret docker-registry regcred \
  --docker-server=core.harbor.demo.compliantk8s.com --docker-username=admin \
  --docker-password=Elastisys123 --docker-email=admin@example.com
kubectl apply -f manifests private-reg-pod.yaml
```
