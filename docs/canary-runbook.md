# Canary Runbook

This runbook describes the future operating model after Argo Rollouts, Istio, and Prometheus are installed.

## Start a Canary

Promote a new immutable image through the normal Git promotion flow. The Rollout controller detects the image change, creates a canary ReplicaSet, and asks Istio to send the first traffic slice to canary.

## What to Monitor

Watch success rate, error rate, latency, saturation, pod readiness, restarts, CPU and memory usage, dependency errors, and business-critical signals. A canary that is technically healthy but breaks user behavior should still be stopped.

## When to Pause

Pause when metrics are ambiguous, error budgets are tightening, dependencies are unstable, or operators need more time to inspect logs and traces. Pausing keeps the current traffic weight in place.

## When to Abort

Abort when the canary causes elevated 5xx errors, severe latency regression, repeated restarts, failed readiness, resource exhaustion, or clear business impact. The platform should prefer protecting users over completing a release.

## Rollback Behavior

When a rollout aborts, Argo Rollouts keeps or returns traffic to the stable ReplicaSet through Istio. Git rollback is still performed by reverting the promotion commit so desired state again points to the last known-good immutable image.
