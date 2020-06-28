Elastisys Compliant Kubernetes Cluster
======================================

## Build status

![Exoscale-pipeline](https://github.com/elastisys/ck8s/workflows/Exoscale-pipeline/badge.svg)
![AWS-pipeline](https://github.com/elastisys/ck8s/workflows/AWS-pipeline/badge.svg)
![Matrix-pipeline](https://github.com/elastisys/ck8s/workflows/Matrix-pipeline/badge.svg)

## Overview

TODO

### Cloud providers

Currently we support three cloud providers: Exoscale, Safespring, an
CityCloud.

### Requirements

- [BaseOS](https://github.com/elastisys/ck8s-base-vm) (tested with 0.0.6)
- [terraform](https://www.terraform.io/downloads.html) (tested with 0.12.19)
- [kubectl](https://github.com/kubernetes/kubernetes/releases) (tested with 1.15.2)
- [helm](https://github.com/helm/helm/releases) (tested with 3.2.4)
- [helmfile](https://github.com/roboll/helmfile) (tested with v0.119.1)
- [helm-diff](https://github.com/databus23/helm-diff) (tested with 3.1.1)
- [jq](https://github.com/stedolan/jq) (tested with jq-1.5-1-a5b5cbe)
- htpasswd available directly in ubuntus repositories
- [sops](https://github.com/mozilla/sops) (tested with 3.5.0)
- [s3cmd](https://s3tools.org/s3cmd) (tested with 2.0.2)
- [ansible](https://www.ansible.com) (tested with 2.5.1)

Note that you will need a [BaseOS](https://github.com/elastisys/ck8s-base-vm)
VM template available at your cloud provider of choice!
See the [releases](https://github.com/elastisys/ck8s-base-vm/releases) for
available VM images that can be uploaded to the cloud provider.

### Terraform Cloud

The Terraform state is stored in the
[Terraform Cloud remote backend](https://www.terraform.io/docs/backends/types/remote.html).
If you haven't done so already, you first need to:

1. [Create an account](https://app.terraform.io/signup/account) and request to
be added to the
[Elastisys organization](https://app.terraform.io/app/elastisys).

2. Add your
[authentication token](https://app.terraform.io/app/settings/tokens)
in the `.terraformrc` file.
[Read more here](https://www.terraform.io/docs/enterprise/free/index.html#configure-access-for-the-terraform-cli).

### PGP

Configuration secrets in ck8s are encrypted using
[SOPS](https://github.com/mozilla/sops). We currently only support using PGP
when encrypting secrets. Because of this, before you can start using ck8s,
you need to generate your own PGP key:

```bash
gpg --full-generate-key
```

Note that it's generally preferable that you generate and store your primary
key and revocation certificate offline. That way you can make sure you're able
to revoke keys in the case of them getting lost, or worse yet, accessed by
someone that's not you.

Instead create subkeys for specific devices such as your laptop that you use
for encryption and/or signing.

If this is all new to you, here's a
[link](https://riseup.net/en/security/message-security/openpgp/best-practices)
worth reading!

## Usage

### Quickstart

To build the cli simply run the following:

```
make build
```

The binary can then be found in `dist/ck8s_linux_amd64`.

In order to setup a new Compliant Kubernetes cluster you will need to do the following.

TODO


### DNS

The domain name will be automatically created with the name
`${TF_VAR_dns_prefix}[.ops].a1ck.io` for Exoscale and
`${TF_VAR_dns_prefix}[.ops].elastisys.se` for Safespring and Citycloud.
In Exoscale we use Exoscale's own DNS features while for Safespring and Citycloud we use AWS.

For Safespring and Citycloud the domain can be changed by setting the Terraform variable
`aws_dns_zone_id` to an id of another hosted zone in AWS Route 53.

## Development

When developing the cli the most convenient way of running the cli is:

```
go run ./cmd/ck8s
```

## Known issues

### SOPS exec-[file|env] subcommands does not propagate exit code

SOPS is used to encrypt and decrypt secrets in the CK8S configuration.
`sops exec-[file|env] [secret-file] [command]` is used to temporarily decrypt
secrets and make them available when running a command. However, as of writing,
in the latest stable version this method does not propagate the exit code to
the caller which prevents them from being caught and be handled properly.

To work around this issue, install SOPS from the development branch where a fix
has been commited.
See: https://github.com/mozilla/sops/issues/626
