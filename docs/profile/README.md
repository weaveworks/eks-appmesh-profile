---
title: App Mesh Profile
---

# App Mesh Profile

The App Mesh integration with EKS is made out of the following components:

* **Kubernetes custom resources** -
    mesh, virtual nodes and virtual services
* **CRD controller** - 
    keeps the custom resources in sync with the App Mesh control plane
* **Admission controller** - 
    injects the Envoy sidecar and assigns pods to App Mesh virtual nodes
* **Telemetry service** - 
    Prometheus instance that collects and stores Envoy's metrics
* **Progressive delivery operator** - 
    Flagger instance that automates canary releases on top of App Mesh 

To install these components you'll be using the eksctl [App Mesh profile](https://github.com/weaveworks/eks-appmesh-profile).
With eksctl profiles you can launch a fully-configured managed Kubernetes cluster with EKS and
easily add the software required to run your production applications.
When you make changes to the configuration within git, these changes are reflected on your cluster.

## Create an EKS cluster

Create an EKS cluster named `appmesh`:

```sh
cat << EOF | eksctl create cluster -f -
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: appmesh
  region: eu-west-2
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

## Create a GitHub repository

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

## Install App Mesh

Run the eksctl profile command (replace `GHUSER` with your GitHub username):

```sh
export GHUSER=username
export EKSCTL_EXPERIMENTAL=true

eksctl enable profile appmesh \
--revision=demo \
--cluster=appmesh \
--region=eu-west-2 \
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

List the installed components:

```
$ watch kubectl get helmreleases --all-namespaces

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

## Kustomize the profile

Sync your local repository:

```sh
git pull origin master
```

Create kustomization files for `base` and `flux` manifests:

```sh
cd base && kustomize create --autodetect --recursive && cd .. \ &&
cd flux && kustomize create --autodetect --recursive && cd ..
```

Create a kustomization file in the repo root:

```sh
cat <<EOF > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - base
  - flux
EOF
```

Create `.flux.yaml` file in the repo root:

```sh
cat <<EOF > .flux.yaml
version: 1
commandUpdated:
  generators:
    - command: kustomize build .
EOF
```

Verify the kustomization by running a dry run apply:

```sh
kubectl apply --dry-run -k .
```

Apply changes:

```sh
git add -A && \
git commit -m "init kustomization" && \
git push origin master && \
fluxctl sync --k8s-fwd-ns flux
```
