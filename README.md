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

Create a repository on GitHub and run the `enable repo` and `enable profile` commands
(replace `GHUSER` and `GHREPO` values with your own):

```sh
export GHUSER=username
export GHREPO=repo
export EKSCTL_EXPERIMENTAL=true

eksctl enable repo \
--cluster=appmesh \
--region=us-west-2 \
--git-url=git@github.com:${GHUSER}/${GHREPO} \
--git-user=${GHUSER} \
--git-email=${GHUSER}@users.noreply.github.com
```

The command `eksctl enable repo` takes an existing EKS cluster and an empty repository 
and sets up a GitOps pipeline.

After the command finishes installing [Flux](https://github.com/fluxcd/flux) and [Helm Operator](https://github.com/fluxcd/flux),
you will be asked to add Flux's deploy key to your GitHub repository.
Once that is done, Flux will be able to pick up changes in the repository and deploy them to the cluster.

```sh
eksctl enable profile appmesh \
--cluster=appmesh \
--region=us-west-2 \
--git-url=git@github.com:${GHUSER}/${GHREPO} \
--git-user=fluxcd \
--git-email=${GHUSER}@users.noreply.github.com
```

The command `eksctl enable profile appmesh` installs the App Mesh control plane on this cluster,
and adds its manifests to the configured repository.

List the installed components:

```
$ kubectl get helmreleases --all-namespaces

NAMESPACE        NAME                 RELEASE              STATUS     MESSAGE                  AGE
appmesh-system   appmesh-controller   appmesh-controller   DEPLOYED   helm install succeeded   1m
appmesh-system   appmesh-inject       appmesh-inject       DEPLOYED   helm install succeeded   1m
appmesh-system   appmesh-prometheus   appmesh-prometheus   DEPLOYED   helm install succeeded   1m
appmesh-system   appmesh-grafana      appmesh-grafana      DEPLOYED   helm install succeeded   1m
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

Access the Grafana dashboards with:

```sh
kubectl -n appmesh-system port-forward svc/appmesh-grafana 3000:3000
```

Open your browser and navigate to `localhost:3000`.

![AWS App Mesh: Control Plane](https://user-images.githubusercontent.com/3797675/68316268-da565300-00c1-11ea-96b5-20634fed2c46.png)
![AWS App Mesh: Data Plane](https://user-images.githubusercontent.com/3797675/68325902-0c23e580-00d3-11ea-8f2a-f10f972fe0ac.png)
