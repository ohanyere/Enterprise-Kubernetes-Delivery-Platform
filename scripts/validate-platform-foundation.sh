#!/usr/bin/env bash
set -euo pipefail

cat <<'FLOW'
Platform foundation validation sequence:

1. Kustomize overlays
   - Render dev, staging, and prod overlays before promotion.
   - Confirm each environment has the intended image tag, replicas, config, resources, probes, and service selectors.
   - Operational purpose: overlays are the Git source of deployment truth.

2. GitHub Actions workflows
   - Review workflow checks for tests, build validation, security scanning, manifest rendering, and promotion behavior.
   - Confirm promotion changes deployment intent through Git instead of rebuilding per environment.
   - Operational purpose: CI prevents broken code or manifests from becoming cluster drift.

3. Kyverno policies
   - Review policy manifests for immutable image tags, resource requirements, probes, and non-root execution.
   - Confirm workloads can satisfy the guardrails before enforcing them in a live cluster.
   - Operational purpose: policy-as-code keeps platform standards consistent.

4. Progressive delivery
   - Review Argo Rollouts canary steps, abort behavior, and analysis expectations.
   - Review Istio routing for stable and canary traffic weights.
   - Operational purpose: new versions are exposed gradually and can be stopped before full impact.

5. Observability
   - Review ServiceMonitor, PrometheusRule, and Grafana guidance.
   - Confirm metrics support release decisions, alerting, scaling, and incident response.
   - Operational purpose: operators need evidence before continuing, pausing, or rolling back.

6. Autoscaling
   - Review HPA targets, min and max replicas, and resource request assumptions.
   - Confirm Karpenter readiness is documented for future node capacity provisioning.
   - Operational purpose: pod scaling and node capacity must work together under load.

7. Secrets architecture
   - Review ExternalSecret, SecretStore assumptions, and workload secret references.
   - Confirm AWS Secrets Manager remains the external source of truth and Kubernetes receives generated Secrets.
   - Operational purpose: secrets stay out of Git while applications keep normal Kubernetes consumption patterns.

This script is intentionally explanatory. It does not install controllers, connect to a cluster, mutate overlays, or run live promotion flows.
FLOW
