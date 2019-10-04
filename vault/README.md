Elastisys Compliant Kubernetes - Vault
======================================

# Overview

This module contains the means nessecary to install a single vault instance on a single node Kubernetes cluster with a NFS server for storage.

This is partly a clone of some of the stuff that we are using for ECK. 
This is a sparse readme because most of the information already is present in the main ECK readme. 


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
**Cert-manager** is installed with a **prod** cluster issuer.
Finally vault is installed.

The script will initialize and unseal vault.
The master key shards and the root token will be stored in the **keys-token** file.
A **kv** version **2** secrets engine is enabled at the path **eck/**.
**AppRole** authentication is enabled and an approle called **eck-aa** is created with a policy that grants all permissions to secrets in `eck/*`.


## Accessing vault

An ingress is deployed in the cluster that gives access to vault at the following domain 

    vault.${ECK_VAULT_DOMAIN}


## Issues and limitations

- No IP whitelisting on the ingress. We probably want this if we are going to expose vault through an ingress.
- No HA.
- The keys and the root token needs to be stored somewhere. 
Now they are just stored in a file `keys-token`.