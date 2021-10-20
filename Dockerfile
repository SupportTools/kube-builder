FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -yq --no-install-recommends \
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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY init-kubectl /usr/local/bin/

RUN /bin/bash -c 'set -ex && \
    hardware=`uname --hardware-platform` && \
    if [ "$hardware" == "x86_64" ]; then \
       ARCH="amd64"; \
    elif [ "$hardware" == "aarch64" ]; then \
       echo "x86_64" && \
       ARCH="arm64"; \
    else \
       echo "unknown arch" && \
       exit 0 \
    fi'

## Install kubectl
RUN curl -sLf https://storage.googleapis.com/kubernetes-release/release/$(curl -ks https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/${ARCH}/kubectl > /usr/local/bin/kubectl && \
chmod +x /usr/local/bin/kubectl

## Install Helm3
RUN HVER=$(curl -sSL https://github.com/kubernetes/helm/releases | sed -n '/Latest release<\/a>/,$p' | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1) && \
wget -k https://get.helm.sh/helm-"$HVER"-linux-${ARCH}.tar.gz && \
tar -zvxf helm-* && \
cd linux-* && \
chmod +x helm && \
mv helm /usr/local/bin/helm

# # Install jq
# RUN curl -sLf http://stedolan.github.io/jq/download/linux64/jq > /usr/local/bin/jq && \
# chmod +x /usr/local/bin/jq

# Install GH CLI
ENV GITHUB_CLI_VERSION 2.0.0

RUN curl -OL "https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_${ARCH}.deb"; \
	dpkg -i "gh_${GITHUB_CLI_VERSION}_linux_*.deb"; \
	rm -rf "gh_${GITHUB_CLI_VERSION}_linux_*.deb"; \
    gh --version;