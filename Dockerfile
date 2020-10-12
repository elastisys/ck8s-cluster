FROM golang:1.14.2-alpine3.11 as builder

RUN apk add --no-cache make git

WORKDIR /ck8s
COPY . /ck8s
RUN make build

FROM ubuntu:18.04

ARG ANSIBLE_VERSION="2.9.14-1ppa~bionic"
ARG JQ_VERSION="1.6"
ARG KUBECTL_VERSION="1.15.2"
ARG S3CMD_VERSION="2.0.2"
ARG SOPS_VERSION="3.6.1"
ARG TERRAFORM_VERSION="0.12.29"
ARG YQ_VERSION="3.2.1"

RUN apt-get update && \
    apt install -y software-properties-common && \
    add-apt-repository --yes --update ppa:ansible/ansible-2.9 && \
    apt-get install -y \
        python3-pip wget \
        unzip ssh  \
        curl python3.7 \
        ansible="${ANSIBLE_VERSION}" \
        python-netaddr && \
    rm -rf /var/lib/apt/lists/*

# Terraform
RUN wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    mv terraform /usr/local/bin/terraform && \
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Kubectl
RUN wget "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# s3cmd
RUN wget "https://github.com/s3tools/s3cmd/releases/download/v${S3CMD_VERSION}/s3cmd-${S3CMD_VERSION}.tar.gz" && \
    tar -zxvf "s3cmd-${S3CMD_VERSION}.tar.gz" && \
    pip3 install setuptools==45.2.0 && \
    cd "s3cmd-${S3CMD_VERSION}" && \
    python3 setup.py install && \
    cd ../ && \
    rm "s3cmd-${S3CMD_VERSION}.tar.gz"

# yq
RUN wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" && \
    chmod +x yq_linux_amd64 && \
    mv yq_linux_amd64 /usr/local/bin/yq

# sops
RUN wget https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux && \
    mv ./sops-v${SOPS_VERSION}.linux /usr/local/bin/sops && \
    chmod +x /usr/local/bin/sops

# jq
RUN wget "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" && \
    chmod +x jq-linux64 && \
    mv jq-linux64 /usr/local/bin/jq

COPY --from=0 /ck8s/dist/ck8s_linux_amd64 /usr/local/bin/ckctl
