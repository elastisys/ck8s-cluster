### Breaking changes

- PSPs cannot be disabled anymore. The effect has to be achieved by creating a permissive policy.
  After an update to v0.5.1, it is required to edit the manifest for the static apiserver pods to enable the `PodSecurityPolicy` admission plugin.

### Release notes

- The `ENABLE_PSP` value should be removed from the config, see breaking changes regarding PSPs.
  The static apiserver pod manifests should be edited to enable the `PodSecurityPolicy` admission plugin **after** the upgrade.
