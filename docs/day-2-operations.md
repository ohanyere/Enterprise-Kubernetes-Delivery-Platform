# Day-2 Operations

Day-2 operations are the ongoing practices that keep a platform reliable after the first successful deployment.

## Day 0, Day 1, and Day 2

Day 0 is design and preparation. It includes architecture, repository structure, security model, and operational assumptions.

Day 1 is initial deployment. It proves that the platform can install, reconcile, and run workloads.

Day 2 is sustained operation. It covers upgrades, incidents, scaling, policy changes, observability tuning, and ownership.

## Ongoing Maintenance

Operators should regularly validate overlays, workflow behavior, policy coverage, secret synchronization, rollout behavior, dashboards, and autoscaling assumptions.

Maintenance also includes dependency updates, container base image refreshes, manifest cleanup, and documentation updates when the platform changes.

## Upgrades

Platform upgrades should be planned, staged, and reversible. This includes Kubernetes versions, ArgoCD, Kyverno, External Secrets Operator, Argo Rollouts, Istio, Prometheus, Grafana, and node autoscaling components.

Upgrade readiness should include compatibility checks, release notes review, non-production validation, rollback plans, and post-upgrade monitoring.

## Policy Evolution

Policies should evolve as platform standards mature. New controls should start with clear documentation and, where possible, audit-style validation before strict enforcement.

Operators should watch for policies that block valid work, miss important risks, or create confusing remediation paths.

## Incident Response

Incident response should be guided by symptoms, dashboards, runbooks, and clear decision points. The first goal is service recovery. Root-cause analysis comes after user impact is contained.

Runbooks should be tested and updated after real incidents, game days, or failed validation exercises.

## Operational Ownership

Every platform layer needs an owner. Ownership includes responding to alerts, approving changes, maintaining documentation, and deciding when standards must change.

Operational ownership should be visible to application teams so they know where to go for support, escalation, and platform guidance.
