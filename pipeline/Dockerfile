FROM ubuntu:18.10

RUN  apt-get update \
  && apt-get install -y wget unzip ssh gettext-base jq curl python3.7

#Terraform
RUN wget https://releases.hashicorp.com/terraform/0.12.6/terraform_0.12.6_linux_amd64.zip
RUN unzip terraform_0.12.6_linux_amd64.zip && \
    mv terraform /usr/local/bin/terraform

#RKE
RUN wget https://github.com/rancher/rke/releases/download/v0.2.8/rke_linux-amd64 && \
    chmod 755 rke_linux-amd64 && \
    mv rke_linux-amd64 /usr/local/bin/rke


# Kubectl
RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

#Helm
RUN wget https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz && \
    tar -zxvf helm-v2.14.3-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm

RUN mkdir -p $(helm home)/plugins

RUN wget https://github.com/databus23/helm-diff/releases/download/v2.11.0%2B5/helm-diff-linux.tgz && \
    tar -xzvf helm-diff-linux.tgz -C $(helm home)/plugins
    #helm plugin install diff/bin/diff

#Helmfile
RUN wget https://github.com/roboll/helmfile/releases/download/v0.81.0/helmfile_linux_amd64 && \
    chmod +x helmfile_linux_amd64 && \
    mv helmfile_linux_amd64 /usr/local/bin/helmfile

#Pipenv
RUN apt install python3-pip -y
RUN python3 -m pip install pip
RUN python3.6 -m pip install pipenv

ENTRYPOINT ["/bin/bash"]
