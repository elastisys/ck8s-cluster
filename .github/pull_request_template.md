**What this PR does / why we need it**:

**Which issue this PR fixes** *(use the format `fixes #<issue number>(, fixes #<issue_number>, ...)` to automatically close the issue when PR gets merged)*:
fixes #

**Special notes for reviewer**:

**Checklist:**

- [ ] Added relevant notes to [WIP-CHANGELOG.md](https://github.com/elastisys/ck8s-cluster/blob/master/WIP-CHANGELOG.md)
- [ ] Proper commit message prefix on all commits
- Is this changeset backwards compatible for existing clusters? Applying:
    - [ ] is completely transparent, will not impact the workload in any way.
    - [ ] requires running a migration script.
    - [ ] will create noticeable cluster degradation.
          E.g. logs or metrics are not being collected or Kubernetes API server
          will not be responding while upgrading.
    - [ ] requires draining and/or replacing nodes.
    - [ ] will change any APIs.
          E.g. removes or changes any CK8S config options or Kubernetes APIs.
    - [ ] will break the cluster.
          I.e. full cluster migration is required.


<!--
Here are the commit prefixes and comments on when to use them:
all: things that touch on more than one of the areas below, or don't fit any of them
tf: Terraform code that apply to more than one cloud
tf aws: Terraform code that apply only to AWS
tf exo: Terraform code that apply only to Exoscale
tf safe: Terraform code that apply only to Safespring
tf city: Terraform code that apply only to CityCloud
ansible: Ansible related changes, e.g. cluster initialization or join
docs: documentation
pipeline: the pipeline
release: anything release related

Example commit prefix usage:

git commit -m "docs: Add instructions for how to do x"
-->
