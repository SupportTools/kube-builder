FROM docker.io/ubuntu:22.04

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
    make \
    build-essential \
    gnupg \
    lsb-release \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY init-kubectl /usr/local/bin/
RUN chmod +x /usr/local/bin/init-kubectl

## Install kubectl
RUN curl -kfsSL -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kubectl && \
chmod +x kubectl && \
mv kubectl /usr/local/bin/kubectl

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

## Install Docker
RUN mkdir -p /etc/apt/keyrings && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
apt-get update && \
apt-get install -yq --no-install-recommends \
docker-ce \
docker-ce-cli \
containerd.io \
docker-compose-plugin \
docker-ce-rootless-extras \
uidmap

## Setting up rootless Docker with buildx
RUN adduser rootless --disabled-password --gecos "" && \
usermod -aG docker rootless && \
su - rootless -c "dockerd-rootless-setuptool.sh install" && \
su - rootless -c "echo 'export XDG_RUNTIME_DIR=/home/rootless/.docker/run' >> ~/.bashrc" && \
su - rootless -c "echo 'export PATH=/usr/bin:$PATH' >> ~/.bashrc" && \
su - rootless -c "echo 'export DOCKER_HOST=unix:///home/rootless/.docker/run/docker.sock' >> ~/.bashrc" && \
su - rootless -c "mkdir -p ~/.docker/cli-plugins" && \
su - rootless -c "wget -k -O ~/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v0.10.0/buildx-v0.10.0.linux-amd64" && \
su - rootless -c "chmod a+x ~/.docker/cli-plugins/docker-buildx" && \
su - rootless -c "docker buildx version"
COPY start-rootless-docker.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/init-kubectl"]
