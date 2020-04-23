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

Create an EKS cluster named `appmesh`.
Note that the region used in this lab is `us-west-2`.
This will take around 15 minutes:

```sh
cat << EOF | eksctl create cluster -f -
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: appmesh
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

## Create a GitHub repository

Create a GitHub repository and clone it locally:
- https://github.com/new

Replace `GH_USER`/`GH_REPO` value with your GitHub username and new repo.
We'll use these variables to clone your repo and setup GitOps for your cluster.
```sh
export GH_USER=YOUR_GITHUB_USERNAME
export GH_REPO=appmesh-dev

git clone git@github.com:${GH_USER}/${GH_REPO}
cd ${GH_REPO}
```

Run the eksctl repo command:

```sh
export EKSCTL_EXPERIMENTAL=true

eksctl enable repo \
--cluster=appmesh \
--region=us-west-2 \
--git-user="fluxcd" \
--git-email="${GH_USER}@users.noreply.github.com" \
--git-url="git@github.com:${GH_USER}/${GH_REPO}"
```

The command `eksctl enable repo` takes an existing EKS cluster and an empty repository 
and sets up a GitOps pipeline.

After the command finishes installing [FluxCD](https://github.com/fluxcd/flux) and [Helm Operator](https://github.com/fluxcd/flux),
you will be asked to add Flux's SSH public key to your GitHub repository.

Copy the public key and create a deploy key with write access on your GitHub repository.
Go to `Settings > Deploy keys` click on `Add deploy key`, check `Allow write access`,
paste the Flux public key and click `Add key`.

Once that is done, Flux will pick up the changes in the repository and deploy them to the cluster.

## Install App Mesh

Run the eksctl profile command:
```sh
eksctl enable profile appmesh \
--revision=demo \
--cluster=appmesh \
--region=us-west-2 \
--git-user="fluxcd" \
--git-email="${GH_USER}@users.noreply.github.com" \
--git-url="git@github.com:${GH_USER}/${GH_REPO}"
```

Run the fluxctl sync command to install the App Mesh control plane on your cluster:

```sh
fluxctl sync --k8s-fwd-ns flux
```

Flux does a git-cluster reconciliation every five minutes, the above command can be used to speed up the
synchronization.

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

## Sync your local repository

`eksctl enable profile` pushed changes to our new repo.  
Let's fetch them:

```sh
git pull origin master
```

## Kustomize the profile

Kubernetes manifests can be long and complex, and our repo has a lot of them!
We can use kustomize to create more targeted patches that make our code easier to factor, understand, and reuse.

Create kustomization files for `base` and `flux` manifests:

```sh
for dir in ./flux ./base; do
  ( pushd "$dir" && kustomize create --autodetect --recursive )
done
```

Create a kustomization file in the repo root:

```sh
cat << EOF | tee kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - base
  - flux
EOF
```

Create `.flux.yaml` file in the repo root:

```sh
cat << EOF | tee .flux.yaml
version: 1
commandUpdated:
  generators:
    - command: kustomize build .
EOF
```

Verify the kustomization by running a dry run apply:

```sh
kubectl apply --dry-run -k . && echo && echo "config is ok :)"
```

Apply changes via git:

```sh
git add -A && \
git commit -m "init kustomization" && \
git push origin master && \
fluxctl sync --k8s-fwd-ns flux
```

Flux is now configured to patch our manifests before applying them to the cluster.
