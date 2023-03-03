# Kube-Builder

[![Build Status](https://drone.support.tools/api/badges/SupportTools/kube-builder/status.svg)](https://drone.support.tools/SupportTools/kube-builder)

kube-builder is a utility image that includes several tools useful in Drone pipelines for building Docker images and deploying them to Kubernetes.

## Included Tools
- [curl](https://curl.se/)
- [wget](https://www.gnu.org/software/wget/)
- [openssh-client](https://www.openssh.com/)
- [git](https://git-scm.com/)
- [zip](https://en.wikipedia.org/wiki/Zip_(file_format))
- [unzip](https://en.wikipedia.org/wiki/Zip_(file_format))
- [awscli](https://aws.amazon.com/cli/)
- [rsync](https://rsync.samba.org/)
- [jq](https://stedolan.github.io/jq/)
- [ca-certificates](https://en.wikipedia.org/wiki/X.509#Certificate)
- [make](https://www.gnu.org/software/make/)
- [build-essential](https://packages.ubuntu.com/bionic/build-essential)
- [gnupg](https://gnupg.org/)
- [lsb-release](https://wiki.debian.org/LSBInitScripts/LSBRelease)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/)
- [kustomize](https://kustomize.io/)
- [helm](https://helm.sh/)
- [gh](https://cli.github.com/manual/)
- [kube-linter](https://kube-linter.io/)
- [Go](https://golang.org/)
- [rancher-projects](https://rancher.com/docs/cli/v2.x/en/)
- [Docker](https://www.docker.com/)
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)

## Usage
To use the kube-builder image in your Drone pipelines, simply specify `supporttools/kube-builder` as the image name in your `.drone.yml` file:

```yaml
Copy code
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
Copy code
pipeline:
  build:
    image: supporttools/kube-builder
    commands:
      - kubectl version --client
      - kustomize build overlays/dev | kubectl apply -f -
      - helm upgrade --install my-app chart/
```

This example pipeline uses kubectl to check the client version, kustomize to build a Kubernetes manifest from an overlay, and helm to upgrade or install a Helm chart.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request if you would like to contribute to kube-builder.

## License
kube-builder is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.