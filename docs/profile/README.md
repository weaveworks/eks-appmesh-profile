---
title: App Mesh Profile
---

# App Mesh Profile

The App Mesh integration with EKS is made out of the following components:

* **Kubernetes custom resources** -
    mesh, virtual nodes, services and gateways
* **CRD controller** - 
    keeps the custom resources in sync with the App Mesh control plane
* **Admission controller** - 
    injects the Envoy sidecar and assigns pods to App Mesh virtual nodes
* **Envoy Gateway** - 
    routes traffic from outside the cluster into the mesh 
* **Telemetry service** - 
    Prometheus instance that collects and stores Envoy's metrics
* **Progressive delivery operator** - 
    Flagger instance that automates canary releases on top of App Mesh 

![App Mesh Canary Release](/gitops-appmesh.png)

## Create a GitHub repository

In order to follow the guide you'll need a GitHub account and a
[personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)
that can create repositories (check all permissions under `repo`).

Fork [this repository](https://github.com/stefanprodan/gitops-appmesh) on your personal GitHub account
and export your access token, username and repo:

```sh
export GITHUB_TOKEN=YOUR_GITHUB_TOKEN
export GITHUB_USER=YOUR_GITHUB_USERNAME
export GITHUB_REPO=gitops-appmesh
```

Clone the repository on your local machine:

```sh
git clone https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git
cd ${GITHUB_REPO}
```

## Cluster bootstrap

Create an EKS cluster named `gitops-appmesh`.
Note that the region used in this lab is `us-west-2`.
This will take around 15 minutes:

```sh
cat << EOF | eksctl create cluster -f -
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: gitops-appmesh
  region: us-west-2
nodeGroups:
  - name: default
    instanceType: m5.large
    desiredCapacity: 2
    volumeSize: 120
    iam:
      withAddonPolicies:
        appMesh: true
        xRay: true
EOF
```

The above command will create a two nodes cluster with App Mesh IAM policy attached to the EKS node instance role.

Verify that your EKS cluster satisfies the prerequisites with:

```console
$ flux check --pre
► checking prerequisites
✔ kubectl 1.19.4 >=1.18.0
✔ Kubernetes 1.18.9-eks-d1db3c >=1.16.0
✔ prerequisites checks passed
```

Install Flux on your cluster with:

```sh
flux bootstrap github \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=clusters/appmesh
```

The bootstrap command commits the manifests for the Flux components in `clusters/appmesh/flux-system` dir
and creates a deploy key with read-only access on GitHub, so it can pull changes inside the cluster.

Sync your local repository:

```sh
git pull origin main
```

Wait for the cluster reconciliation to finish:

```console
$ watch flux get kustomizations 
NAME          	REVISION                                     	READY
apps          	main/582872832315ffca8cf24232b0f6bcb942131a1f	True
cluster-addons	main/582872832315ffca8cf24232b0f6bcb942131a1f	True	
flux-system   	main/582872832315ffca8cf24232b0f6bcb942131a1f	True	
mesh          	main/582872832315ffca8cf24232b0f6bcb942131a1f	True	
mesh-addons   	main/582872832315ffca8cf24232b0f6bcb942131a1f	True	
```

Verify that Flagger, Prometheus, AppMesh controller and gateway Helm releases have been installed:

```console
$ flux get helmreleases --all-namespaces 
NAMESPACE      	NAME              	REVISION	READY
appmesh-gateway	appmesh-gateway   	0.1.5   	True
appmesh-system 	appmesh-controller	1.2.0   	True
appmesh-system 	appmesh-prometheus	1.0.0   	True
appmesh-system 	flagger           	1.2.0   	True
kube-system    	metrics-server    	5.0.1   	True
```
