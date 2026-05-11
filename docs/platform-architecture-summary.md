# Platform Architecture Summary

The Enterprise Kubernetes Delivery Platform is a GitOps-based delivery architecture. It separates build artifacts from deployment intent so teams can build once, promote safely, operate consistently, and roll back through Git.

```text
Developer
  -> GitHub Actions
  -> immutable image
  -> Docker registry
  -> dev/staging/prod overlays
  -> ArgoCD
  -> Kubernetes
  -> HPA
  -> Karpenter readiness
  -> Kyverno governance
  -> External Secrets
  -> Argo Rollouts
  -> Istio
  -> Prometheus/Grafana
```

## Developer

Developers change application code, manifests, or platform configuration through Git. Git is the collaboration, review, audit, and rollback boundary.

Operational purpose: every production-impacting change has an owner, review trail, and reversible history.

## GitHub Actions

GitHub Actions validates code, builds the application image, scans the delivery assets, and supports promotion workflows.

Operational purpose: CI catches defects before deployment intent reaches GitOps reconciliation.

## Immutable Image

The platform expects image tags to identify a specific source revision, such as a commit SHA. The same image moves through environments.

Operational purpose: operators can prove what code is running and avoid environment-specific rebuild drift.

## Docker Registry

The registry stores the immutable image artifact created by CI. Kubernetes pulls this artifact during deployment.

Operational purpose: the registry is the release artifact source of truth.

## Dev, Staging, and Prod Overlays

Kustomize overlays define environment-specific deployment intent, including image tag, replicas, config, resources, and release channel.

Operational purpose: each environment can differ where necessary while preserving a common base and auditable promotion path.

## ArgoCD

ArgoCD reconciles the cluster to the desired state stored in Git. It detects drift and applies approved environment configuration.

Operational purpose: deployment is controlled by Git state instead of manual cluster mutation.

## Kubernetes

Kubernetes runs the workloads, schedules pods, manages services, evaluates probes, and reports workload status.

Operational purpose: Kubernetes is the runtime control plane for application availability.

## HPA

Horizontal Pod Autoscaler adjusts replica counts based on resource pressure or future metrics integrations.

Operational purpose: HPA helps the service absorb demand changes without requiring manual scaling for normal traffic variation.

## Karpenter Readiness

Karpenter readiness documents the future node provisioning layer for unschedulable pods.

Operational purpose: when HPA asks for more pods than the cluster can place, node autoscaling should provide additional capacity.

## Kyverno Governance

Kyverno policies define admission guardrails for image immutability, probes, resource requirements, and non-root execution.

Operational purpose: platform standards become enforceable controls instead of optional conventions.

## External Secrets

External Secrets Operator synchronizes sensitive values from AWS Secrets Manager into Kubernetes Secrets consumed by workloads.

Operational purpose: secrets can be centrally managed, rotated, and audited without committing secret values to Git.

## Argo Rollouts

Argo Rollouts defines progressive delivery behavior such as canary steps, pauses, metric checks, and abort paths.

Operational purpose: new versions are exposed gradually so unhealthy releases can be stopped before full user impact.

## Istio

Istio provides traffic routing between stable and canary versions through gateway, virtual service, and destination rule configuration.

Operational purpose: traffic can be shifted precisely during rollout and returned to stable during failure.

## Prometheus and Grafana

Prometheus collects metrics and evaluates alerts. Grafana visualizes service health, rollout state, autoscaling behavior, and resource pressure.

Operational purpose: operators have the signals required to decide whether to promote, pause, roll back, or investigate.
