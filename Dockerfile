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
COPY goinstall.sh /usr/local/bin/goinstall.sh
RUN chmod +x /usr/local/bin/goinstall.sh && \
/usr/local/bin/goinstall.sh

## Install rancher-projects
COPY ./bin/rancher-projects.sh /usr/local/bin/rancher-projects
RUN chmod +x /usr/local/bin/rancher-projects

## Install Docker
COPY ./bin/gpg-ubuntu /tmp/gpg-ubuntu
RUN mkdir -p /etc/apt/keyrings && \
cat /tmp/gpg-ubuntu | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
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
COPY ./bin/rootless /usr/local/bin/rootless
RUN chmod +x /usr/local/bin/rootless && \
adduser rootless --disabled-password --gecos "" && \
usermod -aG docker rootless && \
su - rootless -c "bash /usr/local/bin/rootless" && \
su - rootless -c "echo 'export XDG_RUNTIME_DIR=/home/rootless/.docker/run' >> ~/.bashrc" && \
su - rootless -c "echo 'export PATH=/usr/bin:$PATH' >> ~/.bashrc" && \
su - rootless -c "echo 'export DOCKER_HOST=unix:///home/rootless/.docker/run/docker.sock' >> ~/.bashrc" && \
su - rootless -c "mkdir -p ~/.docker/cli-plugins" && \
su - rootless -c "wget -k -O ~/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v0.10.0/buildx-v0.10.0.linux-amd64" && \
su - rootless -c "chmod a+x ~/.docker/cli-plugins/docker-buildx" && \
su - rootless -c "docker buildx version"

ENTRYPOINT ["/usr/local/bin/init-kubectl"]