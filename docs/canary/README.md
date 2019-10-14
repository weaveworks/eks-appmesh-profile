---
title: Canary Releases
---

# Canary Releases

To experiment with progressive delivery, you'll be using a small Go application called
[podinfo](https://github.com/stefanprodan/prodinfo).
The demo app is exposed outside the cluster with an Envoy proxy (ingress) and an ELB.
The communication between the ingress and podinfo is managed by Flagger and App Mesh.

```sh
base/demo/
├── namespace.yaml
├── ingress # Envoy proxy
│   ├── config.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── virtual-node.yaml
├── podinfo # Demo app
│   ├── canary.yaml
│   ├── deployment.yaml
│   └── hpa.yaml
└── tester # Flagger test runner
    ├── deployment.yaml
    ├── service.yaml
    └── virtual-node.yaml
```

For apps running on App Mesh, you can configure Flagger with a Kubernetes custom resource
to automate the conformance testing, analysis and promotion of a canary release.

![App Mesh Canary Release](/eks-appmesh-flagger-stack.png)

## Canary custom resource

A canary release is described with a Kubernetes custom resource named **Canary**.

```yaml
apiVersion: flagger.app/v1alpha3
kind: Canary
metadata:
  name: podinfo
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: podinfo
  autoscalerRef:
    apiVersion: autoscaling/v2beta1
    kind: HorizontalPodAutoscaler
    name: podinfo
  service:
    port: 9898
    meshName: appmesh
  canaryAnalysis:
    interval: 10s
    stepWeight: 5
    maxWeight: 50
    threshold: 5
    metrics:
    - name: request-success-rate
      threshold: 99
      interval: 1m
    - name: request-duration
      threshold: 500
      interval: 1m
    webhooks:
      - name: load-test
        url: http://flagger-loadtester.demo/
        metadata:
          cmd: "hey -z 2m -q 10 -c 2 http://podinfo.demo:9898/"
```

Flagger takes a Kubernetes deployment and optionally a horizontal pod autoscaler (HPA),
then creates a series of objects (Kubernetes deployments, ClusterIP services, App Mesh virtual nodes and services).
These objects expose the application on the mesh and drive the canary analysis and promotion.

```sh
# applied 
deployment.apps/podinfo
horizontalpodautoscaler.autoscaling/podinfo
canary.flagger.app/podinfo

# generated Kubernetes objects
deployment.apps/podinfo-primary
horizontalpodautoscaler.autoscaling/podinfo-primary
service/podinfo
service/podinfo-canary
service/podinfo-primary

# generated App Mesh objects
virtualnode.appmesh.k8s.aws/podinfo
virtualnode.appmesh.k8s.aws/podinfo-canary
virtualnode.appmesh.k8s.aws/podinfo-primary
virtualservice.appmesh.k8s.aws/podinfo.test
virtualservice.appmesh.k8s.aws/podinfo-canary.test
```

## Application bootstrap

Install the demo app by setting `fluxcd.io/ignore` to `false` in `base/demo/namespace.yaml`:

```sh{7}
cat <<EOF > base/demo/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
  annotations:
    fluxcd.io/ignore: "false"
  labels:
    appmesh.k8s.aws/sidecarInjectorWebhook: enabled
EOF
```

Apply changes:

```sh
git add -A && \
git commit -m "init demo" && \
git push origin master && \
fluxctl sync --k8s-fwd-ns flux
```

Wait for Flagger to initialize the canary:

```sh
watch kubectl -n demo get canary
```

Find the ingress public address with:

```sh
export URL=$(kubectl -n demo get svc/ingress -ojson | jq -r .status.loadBalancer.ingress[].hostname)
```

Wait for the ingress DNS to propagate:

```sh
watch host $URL
``` 

Wait for the podinfo to become accessible:

```sh
watch curl -s $URL
``` 

When the ingres address becomes available, open it in a browser and you'll see the podinfo UI.

![podinfo](/podinfo.png)

## Automated canary promotion

When you deploy a new podinfo version, Flagger gradually shifts traffic to the canary,
and at the same time, measures the requests success rate as well as the average response duration.
Based on an analysis of these App Mesh provided metrics, a canary deployment is either promoted or rolled back.

Create a Kustomize patch for the podinfo deployment in `overlays/podinfo.yaml`:

```sh{13}
mkdir -p overlays && \
cat <<EOF > overlays/podinfo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: demo
spec:
  template:
    spec:
      containers:
        - name: podinfod
          image: stefanprodan/podinfo:3.1.1
          env:
            - name: PODINFO_UI_LOGO
              value: https://raw.githubusercontent.com/weaveworks/eks-appmesh-profile/website/logo/amazon-eks-wide.png
EOF
```

Add the patch to the kustomization file:

```sh
cat <<EOF > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - base
  - flux
patchesStrategicMerge:
  - overlays/podinfo.yaml
EOF
```

Apply changes:

```sh
git add -A && \
git commit -m "patch podinfo" && \
git push origin master && \
fluxctl sync --k8s-fwd-ns flux
```

When Flagger detects that the deployment revision changed it will start a new rollout.
You can monitor the traffic shifting with:

```sh
watch kubectl -n demo get canaries
```

Watch Flagger logs:

```sh
kubectl -n appmesh-system logs deployment/flagger -f | jq .msg
```

## Automated rollback

During the canary analysis you can generate HTTP 500 errors and high latency to test if Flagger pauses and
rolls back the faulted version.

Trigger another canary release:

```yaml{12}
cat <<EOF > overlays/podinfo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: demo
spec:
  template:
    spec:
      containers:
        - name: podinfod
          image: stefanprodan/podinfo:3.1.2
          env:
            - name: PODINFO_UI_LOGO
              value: https://raw.githubusercontent.com/weaveworks/eks-appmesh-profile/website/logo/amazon-eks-wide.png
EOF
```

Apply changes:

```sh
git add -A && \
git commit -m "update podinfo" && \
git push origin master && \
fluxctl sync --k8s-fwd-ns flux
```

Exec into the tester pod and generate HTTP 500 errors:

```sh
kubectl -n demo exec -it $(kubectl -n demo get pods -o name | grep -m1 flagger-loadtester | cut -d'/' -f 2) bash

$ hey -z 1m -c 5 -q 5 http://podinfo-canary.demo:9898/status/500
$ hey -z 1m -c 5 -q 5 http://podinfo-canary.demo:9898/delay/1
```

When the number of failed checks reaches the canary analysis threshold, the traffic is routed back to the primary and 
the canary is scaled to zero.

Watch Flagger logs with:

```
$ kubectl -n appmesh-system logs deployment/flagger -f | jq .msg

 Starting canary analysis for podinfo.prod
 Advance podinfo.test canary weight 5
 Advance podinfo.test canary weight 10
 Advance podinfo.test canary weight 15
 Halt podinfo.test advancement success rate 69.17% < 99%
 Halt podinfo.test advancement success rate 61.39% < 99%
 Halt podinfo.test advancement success rate 55.06% < 99%
 Halt podinfo.test advancement request duration 1.20s > 0.5s
 Halt podinfo.test advancement request duration 1.45s > 0.5s
 Rolling back podinfo.prod failed checks threshold reached 5
 Canary failed! Scaling down podinfo.test
```


