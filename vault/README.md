Elastisys Compliant Kubernetes - Vault
======================================

# Overview

This module contains the means nessecary to install a single vault instance on a single node Kubernetes cluster with a NFS server for storage.

This is partly a clone of some of the stuff that we are using for ECK. 
This is a sparse readme because most of the information already is present in the main ECK readme. 
Besides this vault cluster should not be removed and meddled with unless nessecary.

**THIS IS A WORK IN PROGRESS**

By no means is it nessecary to have an automated setup of vault.
In fact, it should probably be done manually.
Using the `vault cli` and `ui` instead of the `REST api` can be more convenient, especially for creating policies. 

## Cloud infrastructure

To provision the cloud infrastructure set the following environment variables.

    TF_VAR_ssh_pub_key_file_vault=<..>
    TF_VAR_exoscale_api_key=<..>
    TF_VAR_exoscale_secret_key=<..>
    TF_VAR_dns_prefix=<..>

For other variables that can be changed look in the `terraform/variables.tf` file.

**Note**, only the **exoscale** terraform cloud provider can be used at the moment.

## Kubernetes, NFS, Cert-manager, and Vault

Now that the cloud infrastructure is up and running Kubernetes and Valut can be installed. Begin by setting the following variables.

    ECK_VAULT_DOMAIN=<domain>

Once the variables have been correctly set simply run the following commands.

    ./scripts/setup.sh

The script will generate **infra.json** from which it will build the cluster using **rke**.
Once Kubernetes is up and running **tiller** is installed in the cluster.
When tiller is installed a **NFS client provisioner** is installed.
**Cert-manager** is installed with a **self-signing** issuer.
Finally vault is installed.

The script will initialize and unseal vault.
The master key shards and the root token will be stored in the **keys-token** file.
A **kv** secrets engine is enabled at the path **secret/**.
**AppRole** authentication is enabled and an approle called **customer-rw** is created with a policy that gives permission to read, write, and list secrets in the path **secret/customer/***.

## Accessing vault

An ingress is deployed  in the cluster that gives access to vault at the following domain 

    vault.${ECK_VAULT_DOMAIN}

We probably don't want to expose vault through an ingress.
The reason why it is exposed is because it is easier to automate the set up compared to using `port-forward`. 
If we want to keep the ingress we should then at least restrict the IPs that can access the service.

## Issues and limitations

- No TLS
- No IP whitelisting on the ingress.
- The keys and the root token needs to be stored somewhere. 
Now they are just stored in a file `keys-token`.