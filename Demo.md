# Demonstration of compliance features

## Detect opened shell in container

```
# Tail logs from falco
kubectl -n falco logs -l app=falco -f
# In another terminal, open a shell in the tiller container
kubectl -n kube-system exec -it tiller-deploy-5dffbf79b7-kv6t -- sh
```

**What happened?**
- You opened a shell inside a container
- Falco detected this and notified operators
- Extension: Falco can take action and delete the affected pod.

**What problems does this solve?**
- Detect (and stop) intrusions
- Keep cluster in known state, no manual fixes should be done outside of version control.
- Detect tampering with logs, history, sensitive files and similar

## Scan container images for vulnerabilities

- Go to the [harbor GUI](https://core.harbor.demo.compliantk8s.com).
- Login with `admin:Elastisys123`
- Show a list of found vulnerabilities for a container

**What happened?**
- Harbor scanned the image for known vulnerabilities
- Vulnerabilities are ordered by severity and link to detailed explanations

**What problems does this solve?**
- Avoid running insecure container images
- Gives you an overview of vulnerabilities in your cluster and their severity
- A good reminder to keep up to date

## Kubernetes dashboard login experience

- Go to the [demo dashboard](https://dashboard.demo.compliantk8s.com).
- Note that you are redirected to login through dex.
- Login with `admin@example.com:password`
- Note that this user lacks permissions to view anything.
- Apply cluster-admin privileges: `kubectl apply -f manifests/rbac.yaml`
- Refresh the page and note that the user now can see (and do) anything.
- Remove privileges: `kubectl delete -f manifests/rbac.yaml`

**What happened?**
- A user logged in through dex instead of copying a token from the kubeconfig file.
- The user was only granted their normal privileges, the dashboard does not have cluster-admin rights.
- Dex can use LDAP/AD or other backends so you can reuse existing user databases.

**What problems does this solve?**
- Secure access to the dashboard.
- A nice user experience.
- Consistent permissions across `kubectl` and the dashboard.

## Enforce network policies with OPA

- Try to create a deployment without a network policy.
- Create a network policy
- Try again to create the same deployment

**What happened?**
- OPA is programmed with a rule that prevents deployments not selected by any network policy.
- OPA stopped the first deployment since no network policy existed yet.
- OPA allowed the second deployment since it was targeted by a network policy.

**What problems does this solve?**
- Make sure you have network policies for all deployments/pods.
- Prevent mistakes such as a typo in the labels that can make a network policy useless.
