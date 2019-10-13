---
title: Prerequisites
---

# Prerequisites

You'll need the following tools installed locally:
* AWS CLI
* git
* jq

## eksctl

Install eksctl for macOS:

```sh
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
```

Install eksctl for Windows:

```sh
chocolatey install eksctl
```

Install eksctl for Linux:

```sh
curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin
```

Verify the install with:

```sh
eksctl version
```

## fluxctl

Install fluxctl for macOS:

```sh
brew install fluxctl
```

Install fluxctl for Windows:

```sh
choco install fluxctl
```

Install fluxctl for Linux:

```sh
curl -sL https://fluxcd.io/install | sh
export PATH=$PATH:$HOME/.fluxcd/bin
```

Verify the install with:

```sh
fluxctl version
```

## kustomize

Install kustomize for macOS:

```sh
brew install kustomize
```

Install kustomize for Windows:

```sh
choco install kustomize
```

Install kustomize for Linux:

```sh
curl --silent --location \
"https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.2.3/kustomize_kustomize.v3.2.3_linux_amd64" && \
sudo mv kustomize_kustomize.v3.2.3_linux_amd64 /usr/local/bin/kustomize
```

Verify the install with:

```sh
kustomize version
```
