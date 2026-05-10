# Progressive Delivery Foundation

Progressive delivery reduces production release risk by moving from one large, irreversible deployment event to smaller, observable rollout steps. This repository still uses standard Kubernetes Deployments today, but the base manifests are shaped so future Argo Rollouts and Istio integration can be added without changing the build and promotion model.

## Rolling Updates

A Kubernetes rolling update replaces old pods with new pods gradually. The Deployment strategy uses `maxUnavailable: 0` so Kubernetes keeps the existing serving capacity available while new pods become ready, and `maxSurge: 1` so one extra pod can start during the update.

`minReadySeconds` requires a pod to remain ready for a short period before it counts as available. `revisionHistoryLimit` keeps recent ReplicaSets so a bad rollout can be reverted quickly. `terminationGracePeriodSeconds` gives the application time to stop accepting work and finish in-flight requests before the container is killed.

## Canary Deployments

A canary deployment sends a small amount of production traffic to a new version before sending all users to it. The new version is watched for errors, latency, saturation, and business-level signals. If the canary is healthy, traffic increases. If it fails, traffic returns to the previous version.

The base labels include stable application identity labels and explicit version labels so future canary tooling can distinguish stable and candidate pods without changing the Service identity.

## What Argo Rollouts Solves

Argo Rollouts replaces basic Deployment rollout behavior with progressive delivery controls. It can pause between rollout steps, run analysis checks, automate promotion, abort unsafe releases, and keep richer rollout status than a plain Deployment.

This phase does not add Argo Rollouts CRDs or Rollout resources. It prepares the Deployment shape, labels, rollout strategy, and rollback history so that future conversion is straightforward.

## What Istio Traffic Management Solves

Istio can shift traffic by weight, route specific users or headers to a canary, mirror traffic, enforce retries and timeouts, and provide service-to-service telemetry. Those capabilities are useful when a release needs more control than Kubernetes pod replacement alone can provide.

This phase does not add Istio resources or traffic splitting. The Service selector remains stable and avoids version-specific selection so future Istio routing can decide traffic policy without fighting Kubernetes Service membership.

## Build Once, Deploy Many

Progressive delivery depends on artifact consistency. Dev, staging, and prod must evaluate the same image, not different images built from similar source. Rebuilding per environment can introduce differences in dependencies, base images, build cache, timestamps, or build tools, which makes staging evidence less trustworthy.

This project promotes immutable `sha-*` image tags through Git. Dev receives the image from CI, staging promotes from dev, and production promotes from staging. The same artifact moves forward, so failures are easier to diagnose and rollbacks can return to a known image by reverting the promotion commit.

## Failures This Foundation Helps Prevent

- Capacity drops during rolling updates when too many old pods are removed early.
- Releases that pass staging but fail production because production used a rebuilt image.
- Services accidentally selecting only one version because selectors include changing version labels.
- Slow or broken pods being treated as available before they have stayed ready.
- Abrupt pod termination that interrupts in-flight requests.
- Rollbacks that are slow or impossible because rollout history was discarded too aggressively.
