---
title: Canary Tests
---

# Canary Tests

Flagger comes with a testing service that can run acceptance and load tests when configured as a webhook.

## Create tests

Create a Kustomize patch for the podinfo canary in `overlays/canary.yaml`:

```sh{10,17}
cat << EOF | tee overlays/canary.yaml
apiVersion: flagger.app/v1alpha3
kind: Canary
metadata:
  name: podinfo
  namespace: demo
spec:
  canaryAnalysis:
    webhooks:
      - name: acceptance-test-token
        type: pre-rollout
        url: http://flagger-loadtester.demo/
        timeout: 30s
        metadata:
          type: bash
          cmd: "curl -sd 'test' http://podinfo-canary.demo:9898/token | grep token"
      - name: acceptance-test-tracing
        type: pre-rollout
        url: http://flagger-loadtester.demo/
        timeout: 30s
        metadata:
          type: bash
          cmd: "curl -s http://podinfo-canary.demo:9898/headers | grep X-Request-Id"
      - name: load-test
        url: http://flagger-loadtester.demo/
        timeout: 5s
        metadata:
          cmd: "hey -z 1m -q 10 -c 2 http://podinfo-canary.demo:9898/"
EOF
```

Add the canary patch to the kustomization:

```sh
cat << EOF | tee kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - base
  - flux
patchesStrategicMerge:
  - overlays/podinfo.yaml
  - overlays/canary.yaml
EOF
```

Apply changes:

```sh
git add -A && \
git commit -m "patch canary tests" && \
git push origin master && \
fluxctl sync --k8s-fwd-ns flux
```

## Run tests

Trigger a canary release:

```yaml{12}
cat << EOF | tee overlays/podinfo.yaml
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
          image: stefanprodan/podinfo:3.1.4
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

When the canary analysis starts, Flagger will call the pre-rollout webhooks before routing traffic to the canary.
If the acceptance test fails, Flagger will retry until the analysis threshold is reached and the canary is rolled back.

Watch Flagger logs:

```{4,5}
$ kubectl -n appmesh-system logs deployment/flagger -f | jq .msg

New revision detected! Scaling up podinfo.test
Pre-rollout check acceptance-test-token passed
Pre-rollout check acceptance-test-tracing passed
Advance podinfo.test canary weight 5
Advance podinfo.test canary weight 10
Advance podinfo.test canary weight 15
Advance podinfo.test canary weight 20
Advance podinfo.test canary weight 25
Advance podinfo.test canary weight 30
Advance podinfo.test canary weight 35
Advance podinfo.test canary weight 40
Advance podinfo.test canary weight 45
Advance podinfo.test canary weight 50
Copying podinfo.test template spec to podinfo-primary.test
Routing all traffic to primary
Promotion completed! Scaling down podinfo.test
```