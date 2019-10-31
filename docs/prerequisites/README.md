---
title: Prerequisites
---

# Prerequisites

You'll need the following tools installed locally:
* AWS CLI
* git
* jq
* kubectl

## aws cli

You may use an existing or new AWS account for this demo.
```sh
# configure the aws CLI
aws configure list

aws configure
# or
aws configure --profile demo
export AWS_PROFILE=demo
```
You may need to generate some access keys or create an IAM user:
- [AWS -- Credential Management](https://console.aws.amazon.com/iam/home#/security_credentials)
- [AWS CLI -- Installation / Docs](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

## aws-iam-authenticator

It's best to have this small go program for connecting to EKS clusters:
- [aws-iam-authenticator -- Install docs](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)

## GitHub

You'll need a GitHub account with `git` properly configured:
- [GitHub -- Setting your username](https://help.github.com/en/github/using-git/setting-your-username-in-git)
- [GitHub -- Configuring an SSH key](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

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
export PATH="$PATH:$HOME/.fluxcd/bin"
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
curl --silent --location --remote-name \
"https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.2.3/kustomize_kustomize.v3.2.3_linux_amd64" && \
chmod a+x kustomize_kustomize.v3.2.3_linux_amd64 && \
sudo mv kustomize_kustomize.v3.2.3_linux_amd64 /usr/local/bin/kustomize
```

Verify the install with:

```sh
kustomize version
```
