# Migration v0.1.0 -> v0.2.0

**1. Initialize shell with v0.1.0 config**

```bash
cd [v0.1.0-cluster-config-repo-path]

export VAULT_TOKEN=...
source config.sh
source secrets/env/env.sh
source init.sh
```

**2. Check current state**

Make sure your cluster currently is running v0.1.0 and does not have any diffs.
You should be able to do this by checking out v0.1.0 in your config repo and
then running `terraform plan` and `helmfile diff`.

**3. Checkout v0.2.0**

```bash
cd [ck8s-path]

git checkout v0.2.0
```

**4. Migrate InfluxDB**

```bash
export KUBECONFIG=[v0.1.0-cluster-config-repo-path]/secrets/rke/kube_config_eck-sc.yaml

./migration/v0.1.0-v0.2.0/influxdb.bash
```

**5. Migrate config**

First, open new shell to use a clear environment. Then migrate the old
configuration to the new v0.2.0 config.

Note that the old and the new paths should to be different.

```bash
cd [ck8s-path]

export CK8S_CONFIG_PATH_OLD=[v0.1.0-cluster-config-repo-path]
export CK8S_CONFIG_PATH_NEW=[v0.2.0-cluster-config-path]
export SOPS_PGP_FP=[fingerprint of PGP key to encrypt secrets with]
export TF_TOKEN=...
export VAULT_TOKEN=..

./migration/v0.1.0-v0.2.0/config.bash
```

**6. Migrate Harbor**

A few new Harbor secret options has been introduced with v0.2.0. These will
most likely not align with the previous secrets you had set in your cluster.

It does not seem like you are able to upgrade (some of) the Harbor secrets
in-place, therefore the most straightforward way to migrate Harbor is to set
the secrets to their previous value.

Proper secret rotation will have to be done by hand for now and is out of
scope for this migration path.

You can use the dry-run command to easily find differences in Harbor secrets
and then update them in the secrets.env file accordingly.

These are the newly introduced secret options that you need to set:

```
HARBOR_DB_PWD
HARBOR_XSRF
HARBOR_CORE_SECRET
HARBOR_JOBSERVICE_SECRET
HARBOR_REGISTRY_SECRET
```

**7. Migrate configure-es**

Currently, the configure-es job is not re-run when updated. Because of this you
have to destroy the release before the migration for it to take effect.

Due to the lack of direct Helmfile access a helper script has been added for
this purpose.

```bash
export CK8S_CONFIG_PATH=[v0.2.0-cluster-config-path]
export SOPS_PGP_FP=[fingerprint of PGP key to encrypt secrets with]
./migration/v0.1.0-v0.2.0/destroy-configure-es.bash
```

**8. Migrate the remaining changes**

Before applying the rest of the changes it's good practice to first execute a
dry-run. Make sure you don't have any difference in the Terraform plan and that
the other Helmfile diffs will not impact the cluster negatively when applied.

```bash
./bin/ck8s dry-run
```

When you're ready, migrate the remaining application changes by running:

```bash
./bin/ck8s apply apps
```

Finish off with another dry-run to make sure no diffs remain.


```bash
./bin/ck8s dry-run
```
