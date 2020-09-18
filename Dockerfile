FROM golang:1.14.2-alpine3.11 as builder

RUN apk add --no-cache make git

# TODO: Remove when exit code propagation is released.
#       See: https://github.com/mozilla/sops/issues/626
RUN go get go.mozilla.org/sops/v3
RUN cd $(go env GOPATH)/src/go.mozilla.org/sops/v3 && \
    git checkout 7f350d81b50926a1a07294b6b8d8bb6ed3428186 && \
    CGO_ENABLED=0 GOOS=linux go install -a -ldflags '-extldflags "-static"' go.mozilla.org/sops/v3/cmd/sops && \
    mv $(go env GOPATH)/bin/sops /sops

WORKDIR /ck8s
COPY . /ck8s
RUN make build

FROM ubuntu:18.04

ARG ANSIBLE_VERSION="2.5.1+dfsg-1ubuntu0.1"
ARG KUBECTL_VERSION="v1.15.2"
ARG S3CMD_VERSION="2.0.2"
ARG TERRAFORM_VERSION="0.12.19"

RUN  apt-get update && \
     apt-get install -y \
         python3-pip make git wget \
         unzip ssh gettext-base \
         jq curl python3.7 apache2-utils \
         ansible="${ANSIBLE_VERSION}" \
         net-tools iputils-ping && \
     rm -rf /var/lib/apt/lists/*

# Terraform
RUN wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
RUN unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    mv terraform /usr/local/bin/terraform && \
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Kubectl
RUN wget "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Helm
ENV HELM_VERSION "v3.2.4"
RUN wget "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    tar -zxvf "helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64/ "helm-${HELM_VERSION}-linux-amd64.tar.gz"
# We need to use this variable to override the default data path for helm
# TODO Change when this is closed https://github.com/helm/helm/issues/7919
# Should come with v3.3.0, see https://github.com/helm/helm/pull/7983
ENV XDG_DATA_HOME=/root/.config
RUN helm plugin install https://github.com/databus23/helm-diff --version v3.1.1

# Helmfile
ENV HELMFILE_VERSION "v0.119.1"
RUN wget "https://github.com/roboll/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_linux_amd64" && \
    chmod +x helmfile_linux_amd64 && \
    mv helmfile_linux_amd64 /usr/local/bin/helmfile

# Pipenv
RUN python3 -m pip install pip
RUN python3.6 -m pip install pipenv

# s3cmd
RUN wget "https://github.com/s3tools/s3cmd/releases/download/v${S3CMD_VERSION}/s3cmd-${S3CMD_VERSION}.tar.gz" && \
    tar -zxvf "s3cmd-${S3CMD_VERSION}.tar.gz" && \
    pip3 install setuptools==45.2.0 && \
    cd "s3cmd-${S3CMD_VERSION}" && \
    python3 setup.py install && \
    cd ../ && \
    rm "s3cmd-${S3CMD_VERSION}.tar.gz"

# yq
ENV YQ_VERSION "3.2.1"
RUN wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" && \
    chmod +x yq_linux_amd64 && \
    mv yq_linux_amd64 /usr/local/bin/yq

# sops
# TODO: Use release when exit code propagation is released.
#       See: https://github.com/mozilla/sops/issues/626
#RUN wget https://github.com/mozilla/sops/releases/download/vX.Y.Z/
COPY --from=0 /sops /usr/local/bin/sops

COPY --from=0 /ck8s/dist/ck8s_linux_amd64 /usr/local/bin/ckctl
