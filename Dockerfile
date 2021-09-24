FROM sinlead/drone-kubectl:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get install -yq --no-install-recommends \
    curl \
    wget \
    openssh-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

## Install kubectl
RUN curl -sLf https://storage.googleapis.com/kubernetes-release/release/$(curl -ks https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/arm64/kubectl > /usr/local/bin/kubectl && \
chmod +x /usr/local/bin/kubectl

## Install Helm3
RUN HVER=$(curl -sSL https://github.com/kubernetes/helm/releases | sed -n '/Latest release<\/a>/,$p' | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1) && \
wget -k https://get.helm.sh/helm-"$HVER"-linux-arm64.tar.gz && \
tar -zvxf helm-* && \
cd linux-arm64 && \
chmod +x helm && \
mv helm /usr/local/bin/helm

# Install jq
RUN curl -sLf http://stedolan.github.io/jq/download/linux64/jq > /usr/local/bin/jq && \
chmod +x /usr/local/bin/jq

# GitHub CLI
ENV GITHUB_CLI_VERSION 2.0.0

RUN set -ex; \
    curl -L "https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_checksums.txt" -o checksums.txt; \
    curl -OL "https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.deb"; \
    shasum --ignore-missing -a 512 -c checksums.txt; \
	dpkg -i "gh_${GITHUB_CLI_VERSION}_linux_amd64.deb"; \
	rm -rf "gh_${GITHUB_CLI_VERSION}_linux_amd64.deb"; \
    # verify gh binary works
    gh --version;