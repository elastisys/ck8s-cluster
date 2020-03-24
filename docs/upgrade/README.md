Upgrading Compliant Kubernetes
==============================

## General guidelines

The following document describes general guidelines for what to consider when
upgrading to a new version of Compliant Kubernetes (CK8S).

### Breaking changes

For CK8S, "breaking changes" is separated into two distinct groups: "API
breaking changes" and "internal breaking changes".

Always read the changelog. Any breaking changes and/or release notes will be
clearly stated at the top of each release section.

**CK8S API**

The CK8S API is constituted by all the user facing APIs in the CK8S stack. The
final API is not yet finalized and will change until v1.0.0 but can currently
be seen as the sum of:

* CK8S configuration
* CK8S dashboard
* Kubernetes API
    * cert-manager API
    * Velero API
* Harbor API
* Elasticsearch API
* Kibana API
* Prometheus API
* Grafana API
* Dex API

**Internal changes**

There is a lot of internal APIs, functionality and state that are not publicly
facing. Any changes to these systems could impact the CK8S clusters in various
degree from a complete loss of availability to smaller performance disruptions
or even be completely transparent changes from the user's perspective.

Any major changes will be described in the release notes and is usually
accompanied by a migration script that helps operators perform the upgrade.

### Versions

CK8S adheres to the [semantic versioning][semver] specification.

**Major versions**

When v1.0.0 is released, any non-backwards compatible changes to the CK8S API
defined above will be indicated by a major version increment and could require
operators and/or users to take actions to migrate their workloads if they are
using a dropped API.

Major versions might also require a full cluster migration where a new cluster
needs to be deployed. Being able to migrate data between the old cluster and
the new cluster might be possible, but it's not guaranteed.

**Minor versions**

API deprecations can be introduced in minor versions and will be clearly stated
in the release notes in the changelog. Additional features can also be
introduced as part of a minor version release.

Each CK8S version only guarantees non-breaking upgrades between two minor
versions, e.g. v1.5.0 to v1.6.0. Therefore, to upgrade a CK8S environment
between more than one minor version, sequential upgrades of minor versions
might be required.

*Note: Until CK8S has reached v1.0.0 breaking changes can be introduced in
minor version releases as well. However, this is something that is being
actively avoided and will be kept to a minimum to reduce the number of cluster
disruptions.*

**Patch versions**

Patch versions generally should not have any impact on the cluster when
applied since they in most cases include fixes from the previous release.
However, there are circumstances when this is not feasible such as when
severe security patches are released that involve breaking changes. Always
read the changelog.

### General upgrade steps

1. Before upgrading make sure your config and the cluster is in sync by
   executing a dry-run (you should not see any pending changes):

```
ck8s dry-run
```

2. Carefully read the changelog to be aware of any patch notes relevant for
   your cluster.

3. Checkout the new CK8S release.

```
git checkout [version]
```

4. Execute another dry-run to view the changes that will be applied. This will
   give you an indication of what will happen when applying the changes.

```
ck8s dry-run
```

5. If a migration script is available for the version, run it.

```
./migration/[old_version]->[new_version]/migrate.bash
```

6. Apply the changes to the CK8S environment.

```
ck8s apply all
```

## Workload

### Node draining

It's crucial that the workload can handle Kubernetes node draining, that is,
pods running on one node being terminated and started on a new node. Without
this, any CK8S upgrades could cause a temporary outage while the pod is
restarting.

To handle nodes being drained it's important to consider the following:

* Run [more than][k8s-run-stateless] [one replica][k8s-run-repl-stateful]
  of each workload that can't be tolerated being temporarily down.
* Use the [PreStop][k8s-container-hooks] container hook and set the
  [terminationGracePeriodSeconds][k8s-container-hook-exec] to terminate pods
  [without application interruptions][k8s-pod-term].
* Use [PodDistruptionBudgets][k8s-pdb].

These points are not only good for node draining but also when upgrading your
Kubernetes workload in general or for unexpected infrastructure outages.

## Infrastructure

Some versions might involve a change to the infrastructure. This could be, for
example, changes in the Terraform configuration, a new BaseOS image version or
object storage changes.

Even though the general guidelines described above promises upgrade guarantees
it's a good practice to read through the diff from the dry-run command output.

Any changes that will require infrastructure changes are generally seen as
breaking, therefore if you see a diff in the Terraform state during a dry-run
it's likely that you first need to run a migration script or you are doing a
major version upgrade.

Underlying cloud provider changes could cause changes to the infrastructure as
well and it might be best to hold off on upgrading if the Terraform plan looks
like it's going to change something not mentioned in the changelog.

## Kubernetes

Kubernetes upgrades could vary from simple configuration changes to API
breaking changes. It's very important to read the changelog carefully before
applying a version mentioning Kubernetes as it might impact your workload.

If the workload is running with Kubernetes resources using an old or deprecated
Kubernetes API version make sure to upgrade that before upgrading CK8S.

A new version of Kubernetes will also require a new CK8S BaseOS image. That
means that the machines that runs the Kubernetes nodes will have to be replaced
as well. See notes about node draining above.

## Applications

All the application releases running in CK8S are managed by Helm. When a new
CK8S release includes a new application or changes to an existing application it will be described as a diff in the dry-run output.

Some changes might cause a temporary degradation of parts of the CK8S stack
while the upgrade takes place. Most outages should be mitigated by migration
scripts as best as possible, but in case of unexpected cluster degradation
rolling back a certain deployment is possible using Helm. It's also important
that the incident is reported back to the CK8S team so that it can be fixed in
a subsequent patch release.

[semver]: https://semver.org/
[k8s-run-stateless]: https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/
[k8s-run-repl-stateful]: https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/
[k8s-container-hooks]: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#container-hooks
[k8s-container-hook-exec]: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#hook-handler-execution
[k8s-pod-term]: https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods
[k8s-pdb]: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
