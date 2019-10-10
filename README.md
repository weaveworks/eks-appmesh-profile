# eks-appmesh-profile

This repository is an [eksctl profile](https://eksctl.io/usage/experimental/gitops-flux/)
for deploying the App Mesh Kubernetes [components](https://github.com/aws/eks-charts)
along with monitoring and [progressive delivery](https://flagger.app) tooling on an EKS cluster. 

## Install

Create an EKS cluster named `appmesh`:

```sh
eksctl create cluster --name=appmesh \
--region=us-west-2 \
--nodes 2 \
--node-volume-size=120 \
--appmesh-access
```

The above command will create a two nodes cluster with App Mesh IAM policy attached to the EKS node instance role.

Create a repository on GitHub and run the profile command
(replace `GHUSER` and `GHREPO` values with your own):

```sh
export GHUSER=username
export GHREPO=repo
export EKSCTL_EXPERIMENTAL=true

eksctl enable profile \
--cluster appmesh \
--region=us-west-2 \
--name=https://github.com/weaveworks/eks-appmesh-profile \
--git-url=git@github.com:${GHUSER}/${GHREPO} \
--git-user=fluxcd \
--git-email=${GHUSER}@users.noreply.github.com
```

The command `eksctl enable profile` takes an existing EKS cluster and an empty repository 
and sets up a GitOps pipeline for the App Mesh control plane.

After the command finishes installing [FluxCD](https://github.com/fluxcd/flux) and [Helm Operator](https://github.com/fluxcd/flux),
you will be asked to add Flux's deploy key to your GitHub repository. 
Once that is done, Flux will pick up the changes in the repository and deploy them to the cluster.

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
