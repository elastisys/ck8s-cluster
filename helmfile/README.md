## Helmfile 

### Getting started
- Get Helmfile 

        wget https://github.com/roboll/helmfile/releases/download/v0.80.2/helmfile_linux_amd64 -O helmfile
        chmod +x helmfile

- Install helm `diff` plugin
        
        helm plugin install https://github.com/databus23/helm-diff --version 2.11.0+5

### Further instructions

#### Check status
helmfile -e customer -f helmfile.yaml status
helmfile -e system-services -f helmfile.yaml status

#### Note 
Helm does not support --kubeconfig which means that a user must manually 



