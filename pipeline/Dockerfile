FROM ubuntu:18.04

ENV ANSIBLE_VERSION "2.5.1+dfsg-1ubuntu0.1"

RUN  apt-get update && \
     apt-get install -y \
         python3-pip make git wget \
         unzip ssh gettext-base \
         jq curl python3.7 apache2-utils \
         ansible="${ANSIBLE_VERSION}" \
         net-tools iputils-ping && \
     rm -rf /var/lib/apt/lists/*

# sops
# TODO: Use release when exit code propagation is released.
#       See: https://github.com/mozilla/sops/issues/626
#RUN wget https://github.com/mozilla/sops/releases/download/vX.Y.Z/sops-vX.Y.Z.linux && \
#    chmod +x sops-vX.Y.Z.linux && \
#    mv sops-vX.Y.Z.linux /usr/local/bin/sops && \
ENV GO_VERSION "1.14"
ENV SOPS_VERSION "v3"
ENV SOPS_COMMIT "7f350d81b50926a1a07294b6b8d8bb6ed3428186"
RUN wget "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -xvzf "go${GO_VERSION}.linux-amd64.tar.gz" > /dev/null && \
    export PATH="/go/bin:$PATH" && \
    rm -rf "/go${GO_VERSION}.linux-amd64.tar.gz"
ENV PATH="/go/bin:${PATH}"
RUN go get "go.mozilla.org/sops/${SOPS_VERSION}" && \
    cd "/root/go/src/go.mozilla.org/sops/${SOPS_VERSION}" && \
    git checkout "${SOPS_COMMIT}" && \
    make install && \
    mv /root/go/bin/sops /usr/local/bin && \
    rm -rf /root/go

# Terraform
ENV TERRAFORM_VERSION "0.12.19"
RUN wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
RUN unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    mv terraform /usr/local/bin/terraform && \
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Kubectl
ENV KUBECTL_VERSION "v1.15.2"
RUN wget "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Helm
ENV HELM_VERSION "v3.2.0"
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
ENV S3CMD_VERSION "2.0.2"
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

# opa
ENV OPA_VERSION "v0.17.2"
RUN wget "https://github.com/open-policy-agent/opa/releases/download/${OPA_VERSION}/opa_linux_amd64" && \
    chmod +x opa_linux_amd64 && \
    mv opa_linux_amd64 /usr/local/bin/opa
