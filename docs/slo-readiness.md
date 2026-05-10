# SLO Readiness

SLOs connect engineering signals to user expectations. They help teams decide whether the system is healthy enough to release, continue a rollout, or spend time on reliability work.

## SLA vs SLO vs SLI

An SLA is an external commitment, often contractual. Missing an SLA may have business or financial consequences.

An SLO is an internal reliability target, such as 99.5% successful requests over 30 days.

An SLI is the measured signal used to evaluate the SLO, such as successful request ratio.

## Example SLI

Successful request ratio:

```text
successful HTTP requests / total HTTP requests
```

In Prometheus-style terms, this might compare non-5xx requests against total requests over a time window.

## Example SLO

The service should maintain 99.5% successful requests over 30 days.

This means up to 0.5% of requests can fail during the SLO window before the service exhausts its reliability budget.

## Error Budget

An error budget is the allowed amount of unreliability within the SLO window. If a service burns budget quickly, teams should slow down risky changes, investigate causes, and protect users.

## Why SLOs Matter for Rollouts

Canary decisions should be tied to user impact. If a new version burns error budget, raises latency, or reduces successful request ratio, Argo Rollouts should pause or abort instead of continuing automatically.

SLOs help replace subjective release confidence with measurable operational evidence.
