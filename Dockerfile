FROM docker.io/ubuntu:latest

RUN sed -i 's/archive.ubuntu.com/mirror.coxedgecomputing.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirror.coxedgecomputing.com/g' /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y && apt install -yq --no-install-recommends \
    apt-utils \
    curl \
    wget \
    openssh-client \
    git \
    zip \
    unzip \
    awscli \
    rsync \
    jq \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY init-kubectl /usr/local/bin/
RUN chmod +x /usr/local/bin/init-kubectl

## Install kubectl
RUN curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
apt update && \
apt-get install -yq --no-install-recommends kubectl && \
kubectl version --client || exit 2

## Install kustomize
RUN curl -ks "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

## Install helm
RUN curl -kfsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
chmod +x get_helm.sh && \
./get_helm.sh && \
helm version || exit 2

## Install gh cli
RUN curl -kfsSL -o /etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
apt update && \
apt-get install -yq --no-install-recommends gh && \
gh version || exit 2

## Install kube-linter
RUN curl -kfsSL -o kube-linter-linux.tar.gz https://github.com/stackrox/kube-linter/releases/download/0.2.5/kube-linter-linux.tar.gz && \
tar -zvxf kube-linter-linux.tar.gz && \
chmod +x kube-linter && \
mv kube-linter /usr/local/bin/kube-linter

## Install GO
RUN curl -k https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash

## Install rancher-projects
RUN wget -k -O rancher-projects https://raw.githubusercontent.com/SupportTools/rancher-projects/main/rancher-projects.sh && \
chmod +x rancher-projects && \
mv rancher-projects /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/init-kubectl"]
