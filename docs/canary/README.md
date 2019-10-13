---
title: Canary Releases
---

# Canary Releases

A canary release is described with a Kubernetes custom resource named **Canary**.

## Application bootstrap

Enable the demo by setting `fluxcd.io/ignore` to `false` in `base/demo/namespace.yaml`:

```yaml{5}
apiVersion: v1
kind: Namespace
metadata:
  name: demo
  annotations:
    fluxcd.io/ignore: "false"
  labels:
    appmesh.k8s.aws/sidecarInjectorWebhook: enabled
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
kubectl -n demo get canary
```

Find the ingress public address with:

```sh
export URL=$(kubectl -n demo get svc/ingress -ojson | jq -r .status.loadBalancer.ingress[].hostname)
```

Wait for the ingress DNS to propagate:

```sh
watch host $URL
``` 

When the ingres address becomes available, open it in a browser and you'll see the podinfo UI.

## Automated canary promotion

![App Mesh Canary Release](/eks-appmesh-flagger-stack.png)

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

## Automated rollback

During the canary analysis you can generate HTTP 500 errors and high latency to test if Flagger pauses and
rolls back the faulted version.

Trigger another canary release:

```yaml{7}
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


