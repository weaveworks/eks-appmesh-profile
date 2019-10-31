---
title: Cleanup
---

# Cleanup

This lab takes about $7/day to run on AWS.
If you have a $30 credit, you can run your cluster for 4 days before it will start counting toward your AWS bill.

To cleanup, run the following:
```sh
# Stop flux
kubectl delete ns flux
kubectl delete ns demo

kubectl delete mesh.appmesh.k8s.aws --all
# Allow some time for the appmesh k8s controller to cleanup resources in AWS
sleep 30

eksctl delete cluster \
  --name appmesh \
  --region us-west-2
```

At this point, you may also delete your GitHub repository if you wish.
