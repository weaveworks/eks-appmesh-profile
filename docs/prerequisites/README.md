---
title: Prerequisites
---

# Prerequisites

You'll need the following tools installed locally:
* AWS CLI
* git
* jq
* yq
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

You'll need a GitHub account and a personal access token, and `git` properly configured:
- [GitHub -- Personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)
- [GitHub -- Setting your username](https://help.github.com/en/github/using-git/setting-your-username-in-git)
- [GitHub -- Configuring an SSH key](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

## eksctl

Install eksctl for macOS:

```sh
brew install weaveworks/tap/eksctl
```

Install eksctl for Linux:

```sh
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

Verify the install with:

```sh
eksctl version
```

## flux

Install flux for macOS and Linux:

```sh
brew install fluxcd/tap/flux jq yq
```

Verify the install with:

```sh
flux -v
```
