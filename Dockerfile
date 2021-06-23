FROM sinlead/drone-kubectl:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -yq --no-install-recommends \
    apt-utils \
    curl \
    wget \
    openssh-client \
    git \
    python3 \
    python3-pip \
    python3-setuptools \
    && pip3 install --upgrade pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

## Install AWS CLI
RUN pip3 --no-cache-dir install --upgrade awscli

## Install kubectl
RUN curl -sLf https://storage.googleapis.com/kubernetes-release/release/$(curl -ks https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/arm64/kubectl > /usr/local/bin/kubectl && \
chmod +x /usr/local/bin/kubectl

## Install Helm3
#RUN HVER=$(curl -sSL https://github.com/kubernetes/helm/releases | sed -n '/Latest release<\/a>/,$p' | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1) && \
#wget -k https://get.helm.sh/helm-"$HVER"-linux-arm64.tar.gz && \
#tar -zvxf helm-* && \
#cd linux-arm64 && \
#chmod +x helm && \
#mv helm /usr/local/bin/helm
RUN curl -ks https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install jq
RUN curl -sLf http://stedolan.github.io/jq/download/linux64/jq > /usr/local/bin/jq && \
chmod +x /usr/local/bin/jq
