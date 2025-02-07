<p align="center">
  <img src="assets/logo.svg" width="400">
</p>

# Kube-Builder

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FSupportTools%2Fkube-builder.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2FSupportTools%2Fkube-builder?ref=badge_shield)

kube-builder is a utility image that includes several tools useful in Drone pipelines for building Docker images and deploying them to Kubernetes.

## Requirements
- Docker
- Drone CI (for pipeline usage)

## Installation
Pull the image from Docker Hub:
```bash
docker pull supporttools/kube-builder
```

## Included Tools
- [curl](https://curl.se/) - Command line tool for transferring data
- [wget](https://www.gnu.org/software/wget/) - File retrieval utility
- [openssh-client](https://www.openssh.com/) - SSH connectivity tools
- [git](https://git-scm.com/) - Version control system
- [zip/unzip](https://en.wikipedia.org/wiki/Zip_(file_format)) - Compression utilities
- [awscli](https://aws.amazon.com/cli/) - AWS command line interface
- [rsync](https://rsync.samba.org/) - Fast file transfer utility
- [jq](https://stedolan.github.io/jq/) - JSON processor
- [ca-certificates](https://en.wikipedia.org/wiki/X.509#Certificate) - Common CA certificates
- [make](https://www.gnu.org/software/make/) - Build automation tool
- [build-essential](https://packages.ubuntu.com/bionic/build-essential) - C/C++ compiler and development tools
- [gnupg](https://gnupg.org/) - OpenPGP encryption and signing tool
- [lsb-release](https://wiki.debian.org/LSBInitScripts/LSBRelease) - Linux Standard Base version reporting
- [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/) - Kubernetes command-line tool
- [kustomize](https://kustomize.io/) - Kubernetes configuration management
- [helm](https://helm.sh/) - Kubernetes package manager
- [gh](https://cli.github.com/manual/) - GitHub CLI tool
- [kube-linter](https://kube-linter.io/) - Static analysis tool for Kubernetes
- [Go](https://golang.org/) - Programming language
- [rancher-projects](https://rancher.com/docs/cli/v2.x/en/) - Rancher CLI tool
- [Docker](https://www.docker.com/) - Container platform
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/) - Docker CLI plugin for extended build capabilities

## Usage
To use the kube-builder image in your Drone pipelines, specify `supporttools/kube-builder` as the image name in your `.drone.yml` file:

```yaml
pipeline:
  build:
    image: supporttools/kube-builder
    commands:
      - make build
      - make push
      - kubectl apply -f deployment.yaml
```

This example pipeline runs a make command to build a Docker image, then pushes the image to a Docker registry, and finally deploys the Kubernetes manifest in deployment.yaml using kubectl apply.

You can also use the included tools directly in your pipeline commands:

```yaml
pipeline:
  build:
    image: supporttools/kube-builder
    commands:
      - kubectl version --client
      - kustomize build overlays/dev | kubectl apply -f -
      - helm upgrade --install my-app chart/
```

## Local Development
You can run the container locally for testing:

```bash
docker run -it --rm supporttools/kube-builder /bin/bash
```

## Contributing
Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Create a Pull Request

## License
kube-builder is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FSupportTools%2Fkube-builder.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2FSupportTools%2Fkube-builder?ref=badge_large)
