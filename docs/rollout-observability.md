# Rollout Observability

Canary rollout decisions should be based on production signals, not only deployment status. A pod can be Ready while the service is still returning errors or violating latency expectations.

## What to Observe

During a canary, compare stable and canary for success rate, error rate, latency p95/p99, pod restarts, readiness, CPU, memory, dependency failures, and request volume. Also watch rollout phase and traffic weight.

## Why Argo Rollouts Needs Metrics

Argo Rollouts can pause and advance by steps, but metrics tell it whether advancing is safe. Prometheus analysis lets the rollout continue only when measured health stays inside acceptable bounds.

## Continue or Abort

Prometheus metrics can evaluate queries such as successful request ratio or canary error rate. If the canary is healthy, rollout proceeds to higher weights. If metrics fail, rollout aborts and traffic returns to stable.

## Bad Rollout Signals

Bad signals include rising 5xx rate, canary latency worse than stable, readiness flapping, repeated restarts, CPU throttling, memory pressure, dependency timeouts, or customer-impacting business metrics.

The goal is to catch these signals at 10% or 25% traffic instead of after the release reaches everyone.
