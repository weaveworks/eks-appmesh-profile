---
title: Canary Tests
---

# Helm Tests

Flagger comes with a testing service that can run acceptance and load tests when configured as a webhook.

## Create tests

Create a Kustomize patch for the podinfo canary in `overlays/canary.yaml`:

```sh{10,17}
cat <<EOF > overlays/canary.yaml
apiVersion: flagger.app/v1alpha3
kind: Canary
metadata:
  name: podinfo
  namespace: demo
spec:
  canaryAnalysis:
    webhooks:
      - name: acceptance-test
        type: pre-rollout
        url: http://flagger-loadtester.demo/
        timeout: 30s
        metadata:
          type: bash
          cmd: "curl -sd 'test' http://podinfo-canary.demo:9898/token | grep token"
      - name: load-test
        url: http://flagger-loadtester.demo/
        timeout: 5s
        metadata:
          cmd: "hey -z 1m -q 10 -c 2 http://podinfo-canary.demo:9898/"
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
          image: stefanprodan/podinfo:3.1.3
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

