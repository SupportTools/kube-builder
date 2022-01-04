FROM ubuntu:latest
ARG TARGETPLATFORM

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update --allow-unauthenticated && apt-get install -yq --no-install-recommends --allow-unauthenticated \
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
    go \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY init-kubectl /usr/local/bin/
RUN chmod +x /usr/local/bin/init-kubectl

## Install kubectl
RUN curl -sLf https://storage.googleapis.com/kubernetes-release/release/$(curl -ks https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/${TARGETPLATFORM}/kubectl > /usr/local/bin/kubectl && \
chmod +x /usr/local/bin/kubectl && \
kubectl

## Install Helm3
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
chmod +x get_helm.sh && \
./get_helm.sh && \
helm

## Install KubeLinter
RUN curl -fsSL -o kube-linter-linux.tar.gz https://github.com/stackrox/kube-linter/releases/download/0.2.5/kube-linter-linux.tar.gz && \
tar -zvxf kube-linter-linux.tar.gz && \
chmod +x kube-linter && \
mv kube-linter /usr/local/bin/kube-linter

ENTRYPOINT ["/usr/local/bin/init-kubectl"]