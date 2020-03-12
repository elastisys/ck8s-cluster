FROM ubuntu:18.04

RUN  apt-get update \
  && apt-get install -y wget unzip ssh gettext-base jq curl python3.7 apache2-utils ansible=2.5.1+dfsg-1ubuntu0.1

# Terraform
RUN wget https://releases.hashicorp.com/terraform/0.12.19/terraform_0.12.19_linux_amd64.zip
RUN unzip terraform_0.12.19_linux_amd64.zip && \
    mv terraform /usr/local/bin/terraform

# RKE
RUN wget https://github.com/rancher/rke/releases/download/v1.0.0/rke_linux-amd64 && \
    chmod 755 rke_linux-amd64 && \
    mv rke_linux-amd64 /usr/local/bin/rke

# Kubectl
RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Helm
RUN wget https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz && \
    tar -zxvf helm-v2.14.3-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm

RUN mkdir -p $(helm home)/plugins

RUN wget https://github.com/databus23/helm-diff/releases/download/v2.11.0%2B5/helm-diff-linux.tgz && \
    tar -xzvf helm-diff-linux.tgz -C $(helm home)/plugins

# Helmfile
RUN wget https://github.com/roboll/helmfile/releases/download/v0.99.0/helmfile_linux_amd64 && \
    chmod +x helmfile_linux_amd64 && \
    mv helmfile_linux_amd64 /usr/local/bin/helmfile

# Vault
RUN wget https://releases.hashicorp.com/vault/1.2.2/vault_1.2.2_linux_amd64.zip
RUN unzip vault_1.2.2_linux_amd64.zip && \
    mv vault /usr/local/bin/vault

# Pipenv
RUN apt update && apt install python3-pip -y
RUN python3 -m pip install pip
RUN python3.6 -m pip install pipenv

# kustomize
RUN wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.5.4/kustomize_v3.5.4_linux_amd64.tar.gz && \
    tar -zxvf kustomize_v3.5.4_linux_amd64.tar.gz && \
    mv kustomize /usr/local/bin/kustomize

# s3cmd
RUN wget https://github.com/s3tools/s3cmd/releases/download/v2.0.2/s3cmd-2.0.2.tar.gz && \
    tar -zxvf s3cmd-2.0.2.tar.gz && \
    pip3 install setuptools==45.2.0 && \
    cd s3cmd-2.0.2 && \
    python3 setup.py install

