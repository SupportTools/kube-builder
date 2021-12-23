FROM ubuntu:20.04
ARG TARGETPLATFORM

RUN echo 'Acquire::http { Proxy "http://172.28.1.0:3142"; };' >> /etc/apt/apt.conf.d/01proxy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -yq --no-install-recommends \
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
    && apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /etc/apt/apt.conf.d/01proxy

COPY init-kubectl /usr/local/bin/

## Install kubectl
RUN curl -sLf https://storage.googleapis.com/kubernetes-release/release/$(curl -ks https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/${TARGETPLATFORM}/kubectl > /usr/local/bin/kubectl && \
chmod +x /usr/local/bin/kubectl && \
kubectl

## Install Helm3
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
chmod +x get_helm.sh && \
./get_helm.sh && \
helm