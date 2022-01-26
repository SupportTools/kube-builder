#!/bin/bash -x

echo "Installing kubectl..."
if [ $1 == "amd64" ]
then
  echo "amd64"
  curl -sLf https://storage.googleapis.com/kubernetes-release/release/$(curl -ks https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl > /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl
elif [ $1 == "arm64" ]
then
  echo "arm64"
  curl -sLf https://storage.googleapis.com/kubernetes-release/release/$(curl -ks https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/arm64/kubectl > /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl
elif [ $1 == "arm" ]
then
  echo "arm"
  curl -sLf https://storage.googleapis.com/kubernetes-release/release/$(curl -ks https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/arm/kubectl > /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl
else
    echo "Unknown architecture"
    exit 3
fi
kubectl version --client || exit 2

echo "Installing helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
helm version || exit 2

echo "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update
apt-get install -yq --no-install-recommends gh
gh version || exit 2

echo "Install KubeLinter..."
if [ $1 == "amd64" ]
then
  echo "amd64"
  curl -fsSL -o kube-linter-linux.tar.gz https://github.com/stackrox/kube-linter/releases/download/0.2.5/kube-linter-linux.tar.gz
  tar -zvxf kube-linter-linux.tar.gz
  chmod +x kube-linter
  mv kube-linter /usr/local/bin/kube-linter
else
  echo "No ARM support yet"
fi

echo "Installing Go..."
curl https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash