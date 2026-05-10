#!/usr/bin/env bash
set -euo pipefail

cat <<'FLOW'
Observability flow:

Application emits metrics
  - The service exposes operational signals such as requests, errors, and latency.
  - This phase does not add a live metrics endpoint yet.

        |
        v

Prometheus scrapes metrics
  - Prometheus Operator can use ServiceMonitor resources to discover scrape targets.

        |
        v

PrometheusRule evaluates alerts
  - Alert rules detect symptoms such as high error rate, high latency, frequent restarts, or degraded canaries.
  - Real thresholds should map to user impact and SLOs.

        |
        v

Grafana visualizes health
  - Dashboards show request rate, errors, latency, rollouts, HPA behavior, and resource usage.

        |
        v

Argo Rollouts can use metrics for analysis
  - Prometheus-style checks can decide whether a canary continues, pauses, or aborts.

        |
        v

Engineers use runbooks to respond
  - Runbooks guide first commands, containment, rollback, escalation, and follow-up.
FLOW
