---
title: Canary Tests
---

# Canary Tests

Flagger comes with a testing service that can run acceptance and load tests when configured as a webhook.

## Define tests

For podinfo, we've setup:
* an acceptance test by verifying that the app can issue token
* a load test that generates traffic during the canary analysis

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: podinfo
spec:
  analysis:
    webhooks:
      - name: acceptance-test
        type: pre-rollout
        url: http://flagger-loadtester.$(NAMESPACE)/
        timeout: 30s
        metadata:
          type: bash
          cmd: "curl -sd 'test' http://podinfo-canary.$(NAMESPACE):9898/token | grep token"
      - name: load-test
        url: http://flagger-loadtester.$(NAMESPACE)/
        timeout: 5s
        metadata:
          cmd: "hey -z 1m -q 10 -c 2 http://podinfo-canary.$(NAMESPACE):9898/"
```

## Run tests

When the canary analysis starts, Flagger will call the pre-rollout webhooks before routing traffic to the canary.
If the acceptance test fails, Flagger will retry until the analysis threshold is reached and the canary is rolled back.

If the acceptance test passes, then Flagger will start the load test and begin the traffic shifting.

```console
$ kubectl -n appmesh-system logs deployment/flagger -f | jq .msg

New revision detected! Scaling up podinfo.test
Pre-rollout check acceptance-test passed
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

## Manual Gating

For manual approval of a canary deployment you can use the `confirm-rollout` and `confirm-promotion` webhooks. 
The confirmation rollout hooks are executed before the pre-rollout hooks. 
Flagger will halt the canary traffic shifting and analysis until the confirm webhook returns HTTP status 200.

For manual rollback of a canary deployment you can use the `rollback` webhook.  The rollback hook will be called 
during the analysis and confirmation states.  If a rollback webhook returns a successful HTTP status code, Flagger 
will shift all traffic back to the primary instance and fail the canary. 

Manual gating with Flagger's tester:

```yaml
  analysis:
    webhooks:
      - name: "confirm gate"
        type: confirm-rollout
        url: "http://flagger-loadtester.$(NAMESPACE)/gate/halt"
```

The `/gate/halt` returns HTTP 403 thus blocking the rollout. 

If you have notifications enabled, Flagger will post a message to Slack or MS Teams if a canary rollout is waiting for approval.

Change the URL to `/gate/approve` to start the canary analysis:

```yaml
  analysis:
    webhooks:
      - name: "confirm gate"
        type: confirm-rollout
        url: "http://flagger-loadtester.$(NAMESPACE)/gate/approve"
```

The `confirm-promotion` hook type can be used to manually approve the canary promotion.
While the promotion is paused, Flagger will continue to run the metrics checks and load tests.

```yaml
  analysis:
    webhooks:
      - name: "promotion gate"
        type: confirm-promotion
        url: "http://flagger-loadtester.$(NAMESPACE)/gate/halt"
```
