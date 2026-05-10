# Alerting Runbook

Alerts should lead operators toward user impact, likely causes, and first actions. Avoid treating every metric movement as a page; page when users or SLOs are at risk.

## High Error Rate

First commands:

```bash
kubectl get pods -n sample-go-service-prod
kubectl describe rollout sample-go-service -n sample-go-service-prod
kubectl logs -n sample-go-service-prod deploy/sample-go-service --tail=100
kubectl get events -n sample-go-service-prod --sort-by=.lastTimestamp
```

Check recent promotions, canary status, dependency errors, configuration changes, and whether errors are isolated to canary or affect stable too. Escalate quickly if the error rate is user-facing or burning error budget.

## High Latency

Check p95/p99 latency, CPU throttling, memory pressure, downstream dependency latency, node saturation, and HPA behavior. Latency incidents often require both application and infrastructure context.

If latency appears during a canary, pause or abort the rollout while investigating.

## Frequent Restarts

Check container exit reasons, readiness/liveness probe failures, memory termination, recent config changes, and dependency startup failures.

Useful commands:

```bash
kubectl describe pod -n sample-go-service-prod -l app=sample-go-service
kubectl logs -n sample-go-service-prod -l app=sample-go-service --previous
```

Escalate if restarts reduce available replicas or coincide with elevated errors.

## Degraded Canary Rollout

Inspect rollout status, traffic weights, canary metrics, and pod health. If canary error rate or latency is worse than stable, abort the rollout and keep traffic on stable.

Useful command:

```bash
kubectl argo rollouts get rollout sample-go-service -n sample-go-service-prod
```

After user impact is contained, revert the promotion commit if the image should not remain desired state.

## Escalation Mindset

Contain user impact first, then diagnose. Pull in service owners, platform engineers, and dependency owners based on evidence. Record timeline, impact, decisions, and follow-up fixes.
