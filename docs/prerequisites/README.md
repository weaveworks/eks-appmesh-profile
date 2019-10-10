---
title: Prerequisites
---

# Prerequisites

You'll need the following tools installed locally:
* AWS CLI
* kubectl
* git

## git

Create a GitHub repository and clone it locally
(replace the `GHUSER` value with your GitHub username):

```sh
export GHUSER=username
git clone https://github.com/${GHUSER}/appmesh-dev
```

Set your GitHub username and email:

```sh
cd appmesh-dev
git config user.name "${GHUSER}"
git config user.email "your@main.address"
```

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


