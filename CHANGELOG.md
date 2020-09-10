# Compliant Kubernetes changelog
<!-- BEGIN TOC -->
- [v0.5.1](#v051---2020-09-10)
- [v0.5.0](#v050---2020-08-06)
<!-- END TOC -->

-------------------------------------------------
## v0.5.1 - 2020-09-10

### Breaking changes

- PSPs cannot be disabled anymore. The effect has to be achieved by creating a permissive policy.
  After an update to v0.5.1, it is required to edit the manifest for the static apiserver pods to enable the `PodSecurityPolicy` admission plugin.

### Release notes

- The `ENABLE_PSP` value should be removed from the config, see breaking changes regarding PSPs.
  The static apiserver pod manifests should be edited to enable the `PodSecurityPolicy` admission plugin **after** the upgrade.

-------------------------------------------------
## v0.5.0 - 2020-08-06

# Initial release

First release of the cluster installer for Compliant Kubernetes.

The cluster installer features a go cli that can create kubernetes clusters. It will both provision the necessary cloud infrastructure and install Kubernetes on top of the virtual machines. It is primarily intended for use in Compliant Kubernetes.
