---
title: App Mesh Profile
---

# App Mesh Profile

The App Mesh integration with EKS is made out of the following components:

* Kubernetes custom resources
    * `mesh.appmesh.k8s.aws` defines a logical boundary for network traffic between the services 
    * `virtualnode.appmesh.k8s.aws` defines a logical pointer to a Kubernetes workload
    * `virtualservice.appmesh.k8s.aws` defines the routing rules for a workload inside the mesh
* CRD controller - keeps the custom resources in sync with the App Mesh control plane
* Admission controller - injects the Envoy sidecar and assigns Kubernetes pods to App Mesh virtual nodes
* Metrics server - Prometheus instance that collects and stores Envoy's metrics

## Create an EKS cluster

Create an EKS cluster named `appmesh`:

```sh
eksctl create cluster --name=appmesh \
--region=us-west-2 \
--nodes 2 \
--node-volume-size=120 \
--appmesh-access
```

The above command will create a two nodes cluster with App Mesh IAM policy attached to the EKS node instance role.

## Install App Mesh

Run the eksctl profile command (replace `GHUSER` with your GitHub username):

```sh
export GHUSER=username
export EKSCTL_EXPERIMENTAL=true

eksctl enable profile \
--cluster appmesh \
--region=us-west-2 \
--name=https://github.com/weaveworks/eks-appmesh-profile \
--git-url=git@github.com:${GHUSER}/appmesh-dev \
--git-user=fluxcd \
--git-email=${GHUSER}@users.noreply.github.com
```

The command `eksctl enable profile` takes an existing EKS cluster and an empty repository 
and sets up a GitOps pipeline for the App Mesh control plane.

After the command finishes installing [FluxCD](https://github.com/fluxcd/flux) and [Helm Operator](https://github.com/fluxcd/flux),
you will be asked to add Flux's SSH public key to your GitHub repository.

Copy the public key and create a deploy key with write access on your GitHub repository.
Go to `Settings > Deploy keys` click on `Add deploy key`, check `Allow write access`,
paste the Flux public key and click `Add key`.

Once that is done, Flux will pick up the changes in the repository and deploy them to the cluster.

## App Mesh components

List the installed components:

```
$ kubectl get helmreleases --all-namespaces

NAMESPACE        NAME                 RELEASE              STATUS     MESSAGE                  AGE
appmesh-system   appmesh-controller   appmesh-controller   DEPLOYED   helm install succeeded   1m
appmesh-system   appmesh-inject       appmesh-inject       DEPLOYED   helm install succeeded   1m
appmesh-system   appmesh-prometheus   appmesh-prometheus   DEPLOYED   helm install succeeded   1m
appmesh-system   flagger              flagger              DEPLOYED   helm install succeeded   1m
kube-system      metrics-server       metrics-server       DEPLOYED   helm install succeeded   1m
```

Verify that the mesh has been created and it's active:

```
$ kubectl describe mesh

Name:         appmesh
API Version:  appmesh.k8s.aws/v1beta1
Kind:         Mesh
Spec:
  Service Discovery Type:  dns
Status:
  Mesh Condition:
    Status: True
    Type:   MeshActive
```

