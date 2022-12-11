FROM docker.io/ubuntu:22.04
ARG TARGETARCH
ARG TARGETPLATFORM

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

RUN curl -sLf https://storage.googleapis.com/kubernetes-release/release/$(curl -ks https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl > /usr/local/bin/kubectl && \
chmod +x /usr/local/bin/kubectl && \
kubectl version --client || exit 2

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
chmod +x get_helm.sh && \
./get_helm.sh && \
helm version || exit 2

RUN curl -fsSL -o /etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
apt update && \
apt-get install -yq --no-install-recommends gh && \
gh version || exit 2

RUN curl -fsSL -o kube-linter-linux.tar.gz https://github.com/stackrox/kube-linter/releases/download/0.2.5/kube-linter-linux.tar.gz && \
tar -zvxf kube-linter-linux.tar.gz && \
chmod +x kube-linter && \
mv kube-linter /usr/local/bin/kube-linter

RUN curl https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash

RUN wget -O rancher-projects https://raw.githubusercontent.com/SupportTools/rancher-projects/main/rancher-projects.sh && \
chmod +x rancher-projects && \
mv rancher-projects /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/init-kubectl"]
