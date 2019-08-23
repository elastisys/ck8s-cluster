# Configuring kubelogin for OIDC authentication

## Additional requirements

- [kubelogin](https://github.com/int128/kubelogin) (tested with 1.14.2) 

## Registering a kubectl client in dex
In the [dex.yaml.gotmpl](../helmfile/values/dex.yaml.gotmpl) file, add a
`staticClients` entry for kubectl:

```yaml
ingress: ...

certs: ...

config:
  ...

  staticClients:
    - id: kubernetes
      name: Kubernetes
      secret: ZXhhbXBsZS1zZWNyZXQK  # example-secret
      redirectURIs:
      - http://localhost:8000
      - http://localhost:18000  # if port 8000 is in use

  issuer: ...
```

If the Kubernetes Dashboard has been registered, that client id and secret can
be used for kubectl as well.

## Configure the kubeconfig file

In the kubeconfig file, configure the user entry to use kubelogin with dex:

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    api-version: v1
    certificate-authority-data: ...
    server: ...
  name: example-cluster
contexts:
- context:
    cluster: example-cluster
    user: example-user
  name: example-context
current-context: example-context
users:
- name: example-user
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: kubelogin
      args:
      - get-token
      - --oidc-issuer-url=https://dex.example.com
      - --oidc-client-id=kubernetes
      - --oidc-client-secret=ZXhhbXBsZS1zZWNyZXQK  # example-secret
      - --oidc-extra-scope=email
```

## Log in and out

Login by running a kubectl command:

```bash
% kubectl get nodes
Open http://localhost:8000 for authentication
You got a valid token until 2019-08-24 16:15:50 +0200 CEST
NAME              STATUS   ROLES               AGE    VERSION
...
```

To log out, remove the token file or the token cache directory
(`~/.kube/cache/oidc-login` by default).

## Create a role binding

A role binding is required to have any permissions.
For example, create a `ClusterRoleBinding`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dex-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: admin@example.com
```

The role binding is in this case bound to the user `admin@example.com`.

### Group roles
[G Suite Google Groups](https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control)
can be used for group roles with Google accounts.
