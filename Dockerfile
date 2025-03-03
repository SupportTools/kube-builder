FROM docker.io/ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -yq --no-install-recommends \
    apt-utils \
    curl \
    wget \
    openssh-client \
    git \
    zip \
    unzip \
    rsync \
    jq \
    ca-certificates \
    make \
    build-essential \
    gnupg \
    lsb-release \
    mariadb-client \
    postgresql-client \
    sqlite3 \
    screen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

## Adding common Root CA's
COPY ./rootca/* /usr/local/share/ca-certificates/
RUN chmod 644 /usr/local/share/ca-certificates/* && \
    update-ca-certificates

COPY init-kubectl /usr/local/bin/
RUN chmod +x /usr/local/bin/init-kubectl

## Install kubectl
RUN curl -fsSL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

## Install helm
RUN curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
    chmod 700 /tmp/get_helm.sh && \
    /tmp/get_helm.sh

## Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

## Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

## Install gh cli
RUN curl -sS https://webi.sh/gh | sh

## Install GO
RUN curl -fsSL https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc

## Set Go environment variables
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="/go/bin:${PATH}"

## Install kube-linter
RUN go install golang.stackrox.io/kube-linter/cmd/kube-linter@latest

## Install rancher-projects
RUN curl -o /usr/local/bin/rancher-projects https://raw.githubusercontent.com/SupportTools/rancher-projects/main/rancher-projects.sh && \
    chmod +x /usr/local/bin/rancher-projects

## Install Docker
RUN apt-get update -y && apt-get install -yq --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update -y && apt-get install -yq --no-install-recommends docker-ce docker-ce-cli containerd.io && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## Install Docker Buildx
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

## Install Grafana sync
COPY ./bin/grafana-sync /usr/bin/grafana-sync
RUN chmod +x /usr/bin/grafana-sync

ENTRYPOINT ["/usr/local/bin/init-kubectl"]
