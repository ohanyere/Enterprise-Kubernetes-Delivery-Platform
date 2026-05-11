# Incident Runbook: Failed Canary Rollout

## Symptoms

- Argo Rollouts reports a paused, degraded, or aborted rollout.
- Canary pods show elevated restarts, failed readiness probes, or high latency.
- Error rate increases after traffic shifts to the canary.
- Prometheus analysis checks fail or remain inconclusive.
- Users report intermittent failures during a release window.

## Traffic Behavior

During a canary, only a configured percentage of traffic should reach the new version. Stable traffic should continue serving most requests until the canary proves healthy.

If the canary is unhealthy, operators should expect one of these behaviors:

- Rollout pauses before the next traffic step.
- Rollout aborts and traffic returns to stable.
- Manual intervention is needed to restore stable weighting if automation is incomplete.

## Metrics to Inspect

- Request success rate split by stable and canary version.
- HTTP 5xx and 4xx rates.
- P50, P95, and P99 latency.
- Pod restart count and readiness failures.
- CPU and memory pressure on canary pods.
- Rollout analysis metrics and Prometheus query results.
- Istio traffic weights and request distribution.

## Rollback Decisions

Abort or roll back when user-facing errors, latency, or crash behavior exceed the release threshold. Do not wait for full rollout if the canary already shows clear regression.

Recommended response:

- Pause the rollout if symptoms are ambiguous and user impact is low.
- Abort the rollout if canary metrics clearly fail.
- Revert the promotion commit if the bad image reached the environment's desired state.
- Confirm stable traffic recovery in dashboards before beginning root-cause analysis.
