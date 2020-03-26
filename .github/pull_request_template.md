**What this PR does / why we need it**:

**Which issue this PR fixes** *(use the format `fixes #<issue number>(, fixes #<issue_number>, ...)` to automatically close the issue when PR gets merged)*: fixes #

**Special notes for reviewer**:

**Checklist:**

- [ ] Added relevant notes to [WIP-CHANGELOG.md](https://github.com/elastisys/ck8s/blob/master/WIP-CHANGELOG.md)
- [ ] Proper commit message prefix on all commits

<!--
Here are the commit prefixes and comments on when to use them:
all: (things that touch on more than one of the areas below, or don't fit any of them)
infra: (changes to our infrastructure code that apply to more than one cloud)
infra aws (changes to our infrastructure code that apply only to AWS)
infra exo: (changes to our infrastructure code that apply only to Exoscale)
infra safe: (changes to our infrastructure code that apply only to Safespring)
lb: (things related to the HAProxy load balancer)
k8s: (kubernetes related changes, e.g. cluster initialization or join)
apps: (changes to the applications running in both/all clusters)
apps sc: (changes to applications in the service cluster)
apps wc: (changes to applications in the workload cluster)
docs: (documentation)
pipeline: (the pipeline)
config: (configuration, e.g. add/remove/rename a parameter, this is not for changes to the default values for an application that would go into `apps [sc/wc]`)
release: (anything release related)

Example commit prefix usage:

git commit -m "docs: Add instructions for how to do x"
-->
