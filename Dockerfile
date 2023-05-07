FROM docker.io/ubuntu:22.04

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
    make \
    build-essential \
    gnupg \
    lsb-release \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

## Adding common Root CA's
COPY ./rootca/* /usr/local/share/ca-certificates/
RUN chmod 644 /usr/local/share/ca-certificates/* && \
    update-ca-certificates

COPY init-kubectl /usr/local/bin/
RUN chmod +x /usr/local/bin/init-kubectl

## Install kubectl
COPY ./bin/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

## Install kustomize
COPY ./bin/install_kustomize.sh /usr/local/bin/install_kustomize.sh
RUN chmod +x /usr/local/bin/install_kustomize.sh && \
bash /usr/local/bin/install_kustomize.sh

## Install helm
COPY ./bin/get_helm.sh /usr/local/bin/get_helm.sh
RUN chmod +x /usr/local/bin/get_helm.sh && \
/usr/local/bin/get_helm.sh && \
helm version || exit 2

## Install gh cli
COPY ./bin/githubcli-archive-keyring.gpg /etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
apt update && \
apt-get install -yq --no-install-recommends gh && \
gh version || exit 2

## Install kube-linter
COPY ./bin/kube-linter-linux.tar.gz /tmp/kube-linter-linux.tar.gz
RUN cd /tmp && \
tar -zvxf kube-linter-linux.tar.gz && \
chmod +x kube-linter && \
mv kube-linter /usr/local/bin/kube-linter

## Install GO
COPY ./bin/goinstall.sh /usr/local/bin/goinstall.sh
RUN chmod +x /usr/local/bin/goinstall.sh && \
/usr/local/bin/goinstall.sh

## Install rancher-projects
COPY ./bin/rancher-projects.sh /usr/local/bin/rancher-projects
RUN chmod +x /usr/local/bin/rancher-projects

## Install Docker
COPY ./bin/get-docker.sh /usr/local/bin/get-docker.sh
RUN chmod +x /usr/local/bin/get-docker.sh && \
/usr/local/bin/get-docker.sh

## Install Docker Buildx
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

## Install Grafana sync
FROM ghcr.io/mpostument/grafana-sync:1.7.0 AS grafana-sync
COPY --from=grafana-sync /usr/bin/grafana-sync /usr/bin/grafana-sync
RUN chmod +x /usr/bin/grafana-sync

ENTRYPOINT ["/usr/local/bin/init-kubectl"]