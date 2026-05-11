# Platform Validation Checklist

This checklist validates the operational foundation of the Enterprise Kubernetes Delivery Platform. It is intended for platform operators reviewing the repository before connecting these manifests to live clusters.

## GitHub Actions Workflows

### What to Validate

- Workflows lint, test, and build the application before deployment intent changes are promoted.
- Docker images are built from a repeatable source revision.
- Security checks cover source, container, Kubernetes manifests, and workflow configuration where applicable.
- Promotion workflows update environment overlays through reviewed Git changes.

### Why It Matters Operationally

CI is the first control point in the delivery path. If workflows do not consistently validate code and manifests, broken deployment intent can reach GitOps reconciliation and become a cluster incident.

### Expected Outcome

Operators can identify which workflow validates a change, which workflow promotes an image, and which checks must pass before a deployment reaches dev, staging, or prod.

## Kustomize Overlays

### What to Validate

- `deploy/overlays/dev`, `deploy/overlays/staging`, and `deploy/overlays/prod` render successfully.
- Each overlay references the intended namespace, replica count, config values, resource settings, and image tag.
- Environment-specific changes live in overlays, not in application code.
- The base remains reusable and does not contain environment-only behavior.

### Why It Matters Operationally

Kustomize overlays are the source of deployment intent for each environment. Rendering failures or misplaced environment settings break repeatability and make promotion difficult to audit.

### Expected Outcome

Each overlay renders into valid Kubernetes YAML and clearly communicates the differences between dev, staging, and prod.

## Promotion Workflows

### What to Validate

- Promotion updates only the target environment's immutable image tag.
- The same image SHA can move from dev to staging to prod without rebuilding.
- Promotion is performed by Git commit or pull request.
- Rollback is possible by reverting the promotion commit.

### Why It Matters Operationally

Promotion by Git creates an auditable chain of custody for releases. Rebuilding per environment weakens traceability and can hide differences between tested and production artifacts.

### Expected Outcome

Operators can trace a production image back to a source commit, CI build, registry artifact, and promotion history.

## Kyverno Policy Manifests

### What to Validate

- Policy manifests exist under `policies/kyverno`.
- Policies express guardrails for immutable images, resource requirements, health probes, and non-root execution.
- Policies align with the manifests they are expected to govern.
- Policy failures are understandable to application teams.

### Why It Matters Operationally

Policy-as-code converts platform standards into enforceable admission controls. Clear policies reduce configuration drift and prevent unsafe workloads from entering the cluster.

### Expected Outcome

Operators can explain what each policy protects, which workloads it applies to, and what a compliant workload must include.

## External Secret Architecture

### What to Validate

- External Secrets manifests describe AWS Secrets Manager as the source of truth.
- Kubernetes workloads consume generated Secrets rather than hardcoded values.
- Secret names and references match across `ExternalSecret`, generated `Secret`, and workload environment wiring.
- Future cloud identity integration is documented and least-privilege oriented.

### Why It Matters Operationally

Secrets must be rotated, audited, and recovered without committing sensitive values to Git. A clear external-secret model keeps GitOps safe while preserving normal Kubernetes Secret consumption.

### Expected Outcome

Operators can follow the path from external secret store to Kubernetes Secret to application environment variables.

## HPA Manifests

### What to Validate

- HPA manifests target the correct workload.
- CPU and memory metrics align with container resource requests.
- Minimum and maximum replica counts are appropriate for each environment.
- Autoscaling assumptions are documented alongside Karpenter readiness.

### Why It Matters Operationally

HPA cannot make good scaling decisions without resource requests and metrics. Misconfigured autoscaling creates either availability risk or unnecessary cost.

### Expected Outcome

Operators can explain how pod replica counts change under load and what cluster capacity layer must react when pods cannot be scheduled.

## Argo Rollouts Manifests

### What to Validate

- Rollout manifests define stable and canary behavior clearly.
- Canary step weights, pauses, and analysis expectations match operational risk tolerance.
- Rollout selectors and pod templates are consistent with service routing.
- Abort behavior returns traffic to the stable version.

### Why It Matters Operationally

Progressive delivery protects users by limiting exposure to a new version. The rollout plan must be explicit enough for operators to know when to continue, pause, or abort.

### Expected Outcome

Operators can describe how a release moves from canary to full rollout and how unhealthy canaries are contained.

## Istio Manifests

### What to Validate

- Gateway, VirtualService, and DestinationRule references align.
- Stable and canary subsets route to the intended pod labels.
- Traffic weights match rollout expectations.
- Failure behavior preserves access to the stable service.

### Why It Matters Operationally

Traffic management is the user-facing part of progressive delivery. Incorrect routing can send too much traffic to an unproven version or disconnect the service entirely.

### Expected Outcome

Operators can trace request flow from ingress to stable and canary destinations.

## Observability Manifests

### What to Validate

- ServiceMonitor resources select the intended services.
- PrometheusRule alerts map to meaningful service or platform symptoms.
- Grafana dashboard guidance covers service health, rollout health, autoscaling, and resource pressure.
- Metrics used for rollout decisions are available and operationally meaningful.

### Why It Matters Operationally

Operators cannot safely run progressive delivery, autoscaling, or incident response without observable signals. Metrics and dashboards turn symptoms into decisions.

### Expected Outcome

Operators can identify which metrics prove platform health, which alerts require action, and which dashboards support release and incident decisions.
