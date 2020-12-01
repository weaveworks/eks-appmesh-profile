---
title: Cleanup
---

# Cleanup

This lab takes about $7/day to run on AWS.
If you have a $30 credit, you can run your cluster for 4 days before it will start counting toward your AWS bill.

Suspend the cluster reconciliation:

```sh
flux suspend kustomization cluster-addons
```

Delete the demo app and mesh addons:

```sh
flux delete kustomization apps -s
flux delete kustomization mesh-addons -s
```

Delete the AppMesh mesh:

```sh
kubectl delete mesh --all
```

Delete the EKS cluster:

```sh
eksctl delete cluster \
  --name appmesh \
  --region us-west-2
```

At this point, you may also delete your GitHub repository if you wish.
