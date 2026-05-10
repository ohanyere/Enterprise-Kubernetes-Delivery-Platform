#!/usr/bin/env bash
set -euo pipefail

cat <<'FLOW'
Progressive delivery flow:

New image promoted
  - Git points the environment at a new immutable image tag.

        |
        v

Argo Rollouts creates canary ReplicaSet
  - Stable pods keep serving.
  - Canary pods run the new image beside the stable version.

        |
        v

Istio sends 10% traffic to canary
  - VirtualService weights route a small slice of real traffic to canary.
  - Most users continue to hit stable.

        |
        v

Metrics are checked
  - Prometheus-style metrics such as success rate, error rate, and latency decide whether the rollout should continue.

        |
        v

Rollout progresses to 25%, 50%, 100%
  - Argo Rollouts advances the canary in controlled steps when health remains good.

        |
        v

Unhealthy rollout aborts and traffic returns to stable
  - If metrics fail, Argo Rollouts aborts the release.
  - Istio sends traffic back to the stable version to protect users.
FLOW
