FROM ubuntu:18.04

RUN  apt-get update && \
     apt-get install -y \
         python3-pip make git wget \
         unzip ssh gettext-base \
         jq curl python3.7 apache2-utils \
         ansible=2.5.1+dfsg-1ubuntu0.1 && \
     rm -rf /var/lib/apt/lists/*

# sops
# TODO: Use release when exit code propagation is released.
#       See: https://github.com/mozilla/sops/issues/626
#RUN wget https://github.com/mozilla/sops/releases/download/vX.Y.Z/sops-vX.Y.Z.linux && \
#    chmod +x sops-vX.Y.Z.linux && \
#    mv sops-vX.Y.Z.linux /usr/local/bin/sops && \
RUN wget https://dl.google.com/go/go1.14.linux-amd64.tar.gz && \
    tar -xvzf go1.14.linux-amd64.tar.gz > /dev/null && \
    export PATH=/go/bin:$PATH && \
    rm -rf /go1.14.linux-amd64.tar.gz
ENV PATH="/go/bin:${PATH}"
RUN go get go.mozilla.org/sops/v3 && \
    cd /root/go/src/go.mozilla.org/sops/v3 && \
    git checkout 7f350d81b50926a1a07294b6b8d8bb6ed3428186 && \
    make install && \
    mv /root/go/bin/sops /usr/local/bin && \
    rm -rf /root/go

# Terraform
RUN wget https://releases.hashicorp.com/terraform/0.12.19/terraform_0.12.19_linux_amd64.zip
RUN unzip terraform_0.12.19_linux_amd64.zip && \
    mv terraform /usr/local/bin/terraform && \
    rm terraform_0.12.19_linux_amd64.zip

# Kubectl
RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl && \
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
RUN wget https://github.com/roboll/helmfile/releases/download/v0.99.0/helmfile_linux_amd64 && \
    chmod +x helmfile_linux_amd64 && \
    mv helmfile_linux_amd64 /usr/local/bin/helmfile

# Pipenv
RUN python3 -m pip install pip
RUN python3.6 -m pip install pipenv

# s3cmd
RUN wget https://github.com/s3tools/s3cmd/releases/download/v2.0.2/s3cmd-2.0.2.tar.gz && \
    tar -zxvf s3cmd-2.0.2.tar.gz && \
    pip3 install setuptools==45.2.0 && \
    cd s3cmd-2.0.2 && \
    python3 setup.py install && \
    cd ../ && \
    rm s3cmd-2.0.2.tar.gz

# yq
RUN wget https://github.com/mikefarah/yq/releases/download/3.2.1/yq_linux_amd64 && \
    chmod +x yq_linux_amd64 && \
    mv yq_linux_amd64 /usr/local/bin/yq
