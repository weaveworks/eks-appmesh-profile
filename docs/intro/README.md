---
title: Introduction
---

# Introduction

This guide walks you through setting up a progressive delivery GitOps pipeline on an Amazon EKS cluster.

## What is GitOps?

GitOps is a way to do Continuous Delivery, it works by using Git as a source of truth for
declarative infrastructure and workloads. For Kubernetes this means using `git push` instead
of `kubectl create/apply` or `helm install/upgrade`.

::: tip GitOps vs CiOps

In a traditional CI/CD pipeline, CD is an implementation extension powered by the continuous integration tooling
to promote build artifacts to production. In the GitOps pipeline model, any change to production must be committed
in source control (preferable via a pull request) prior to being applied on the cluster.
If the entire production state is under version control and described in a single Git repository,
when disaster strikes, the whole infrastructure can be quickly restored without rerunning the CI pipelines.

[Kubernetes anti-patterns: Let's do GitOps, not CIOps!](https://www.weave.works/blog/kubernetes-anti-patterns-let-s-do-gitops-not-ciops)
:::

In order to apply the GitOps model to Kubernetes you need:

* a container registry where your CI system pushes immutable images
(no *latest* tags, use *semantic versioning* or git *commit sha*)
* a Git repository with your workloads definitions in YAML format,
Helm charts and any other Kubernetes custom resource that defines your cluster desired state
* Kubernetes controller that:
    * watches for changes in the config repository
    * reconciles the cluster state as described in the repository

In this workshop you'll be using GitHub to host the config repository and
[Flux](https://github.com/fluxcd/flux2) as the GitOps delivery solution.

## What is Progressive Delivery?

Progressive delivery is an umbrella term for advanced deployment patterns like canaries, feature flags and A/B testing.
Progressive delivery techniques are used to reduce the risk of introducing a new software version in production
by giving app developers and SRE teams a fine-grained control over the blast radius.

::: tip Canary release

A benefit of using canary releases is the ability to do capacity testing of the new version in a production environment
with a safe rollback strategy if issues are found. By slowly ramping up the load, you can monitor and capture metrics
about how the new version impacts the production environment.

[Martin Fowler blog](https://martinfowler.com/bliki/CanaryRelease.html)
:::

In this workshop you'll be using
[Flagger](https://github.com/weaveworks/flagger),
[AWS App Mesh](https://aws.amazon.com/app-mesh/) and
[Prometheus](https://github.com/prometheus)
to automate canary releases for your applications.
