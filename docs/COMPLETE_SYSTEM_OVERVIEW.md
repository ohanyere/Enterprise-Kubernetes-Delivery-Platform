# Complete System Overview

Project: Enterprise Kubernetes Delivery Platform

Purpose: This document is the master architecture handbook, operational reference, runtime integration guide, and interview preparation guide for the platform. It explains what exists in the repository, why each layer exists, how the layers connect, what problems each layer prevents, and which runtime components must still be installed before the repository becomes a live production platform.

This repository is intentionally architecture-first. The sample service is small so the project can focus on enterprise delivery mechanics: immutable builds, environment promotion, GitOps reconciliation, policy-as-code, externalized secrets, autoscaling, progressive delivery, service mesh routing, observability, rollback, and Day-2 operational response.

## 1. Project Overview

The Enterprise Kubernetes Delivery Platform is a production-style Kubernetes delivery platform template. It demonstrates how an organization can move application code from source control to a Kubernetes runtime through a controlled, auditable, repeatable delivery system.

The platform is not primarily a business application. The application under `apps/sample-go-service/` exists as a realistic workload that can be built, tested, packaged, configured, deployed, observed, scaled, governed, and rolled back. The project is about the delivery architecture around that workload.

At a high level, the platform solves these operational problems:

- How to build an application once and promote the same artifact through multiple environments.
- How to keep deployment state in Git instead of relying on manual cluster edits.
- How to make environment differences explicit through Kustomize overlays.
- How to prevent unsafe workloads from entering the cluster.
- How to keep secrets out of Git while still letting pods consume Kubernetes Secrets.
- How to scale pods when application pressure increases.
- How to prepare node scaling when scheduled capacity is exhausted.
- How to release gradually through canary traffic shifting.
- How to observe service health, rollout health, autoscaling behavior, and incident symptoms.
- How to make rollback a deliberate operational path instead of an emergency improvisation.

Enterprise delivery systems need this architecture because production change is risky. A deployment platform must do more than run containers. It must answer operational questions:

- What exact artifact is running in each environment?
- Who changed deployment intent, when, and through what review path?
- Can we prove the production image passed earlier stages?
- Can Kubernetes restart or stop sending traffic to unhealthy pods?
- Can the platform reject unsafe manifests before they run?
- Can secrets rotate without changing application manifests?
- Can the platform add pod capacity during traffic spikes?
- Can the platform add node capacity when the scheduler cannot place pods?
- Can a release be exposed to a small percentage of traffic before full promotion?
- Can alerts and dashboards show whether a release is healthy?
- Can the team roll back quickly by reverting Git?

This project exists to model those answers in a repository that is understandable, extensible, and production-oriented.

The core repository areas are:

- `apps/sample-go-service/`: a small Go HTTP service with health, readiness, version, and config endpoints.
- `Dockerfile`: a multi-stage build that packages the Go service into a distroless non-root image.
- `.github/workflows/`: CI, image publishing, and environment promotion workflows.
- `deploy/base/`: shared Kubernetes Deployment, Service, ConfigMap, and example Secret.
- `deploy/overlays/`: dev, staging, and prod Kustomize overlays.
- `argocd/`: ArgoCD Application desired-state definitions.
- `policies/kyverno/`: Kyverno ClusterPolicies for governance.
- `external-secrets/base/`: External Secrets Operator reference manifests for AWS Secrets Manager.
- `autoscaling/hpa/`: HorizontalPodAutoscaler reference manifest.
- `progressive-delivery/`: Argo Rollouts and Istio canary delivery reference manifests.
- `observability/`: Prometheus Operator and Grafana observability reference material.
- `operations/`: validation guides and incident runbooks.
- `docs/`: focused architecture and operational documents.
- `scripts/`: explanatory scripts that teach and validate platform flows.

## 2. High-Level Platform Architecture

The platform delivery flow is:

```text
Developer
  -> GitHub Actions
  -> immutable image build
  -> Docker registry
  -> environment overlays
  -> ArgoCD GitOps reconciliation
  -> Kubernetes
  -> Kyverno governance
  -> External Secrets
  -> HPA
  -> Karpenter readiness
  -> Argo Rollouts
  -> Istio traffic routing
  -> observability stack
  -> operational validation
```

### Developer

Operational purpose: The developer changes application code, manifests, policy, scripts, or documentation in Git.

Problem solved: Git becomes the system of record for both application code and platform intent. Engineers can review, diff, audit, revert, and reason about changes before they affect runtime.

What would fail without it: If changes bypass Git, the platform loses traceability. Production state becomes a mix of manual commands, undocumented cluster drift, and unrepeatable tribal knowledge.

Repository references:

- `apps/sample-go-service/`
- `deploy/`
- `.github/workflows/`
- `argocd/`
- `policies/`
- `external-secrets/`
- `autoscaling/`
- `progressive-delivery/`
- `observability/`
- `operations/`

### GitHub Actions

Operational purpose: GitHub Actions validates code, validates container packaging, renders Kubernetes manifests, performs security checks, publishes immutable images, and updates overlay image tags during promotion.

Problem solved: CI prevents broken application code, broken Kubernetes manifests, unsafe Dockerfiles, or vulnerable images from progressing silently. Promotion workflows encode the rule that environments advance by changing Git deployment intent, not by rebuilding a new image for each environment.

What would fail without it: Developers could merge code that does not compile, manifests that do not render, or image tags that cannot be traced back to a commit. Promotions would become manual and inconsistent.

Repository references:

- `.github/workflows/ci.yaml`
- `.github/workflows/publish-and-promote-dev.yaml`
- `.github/workflows/promote-staging.yaml`
- `.github/workflows/promote-prod.yaml`
- `docs/devsecops-validation.md`
- `docs/promotion-flow.md`

### Immutable Image Build

Operational purpose: The platform builds a container image from the repository and tags it with the Git commit SHA, using the pattern `sha-${GITHUB_SHA}` in the publishing workflow.

Problem solved: An immutable tag ties a runtime artifact to source code. This makes debugging, promotion, compliance evidence, and rollback more reliable.

What would fail without it: Mutable image tags such as `latest` can change behind the same name. A rollback to `latest` may not return to the old code. Incident responders cannot prove what binary was running.

Repository references:

- `Dockerfile`
- `.github/workflows/publish-and-promote-dev.yaml`
- `deploy/overlays/dev/kustomization.yaml`
- `deploy/overlays/staging/kustomization.yaml`
- `deploy/overlays/prod/kustomization.yaml`
- `policies/kyverno/disallow-latest-tag.yaml`

### Docker Registry

Operational purpose: The registry stores the built image so Kubernetes can pull the exact artifact referenced by deployment overlays.

Problem solved: Runtime clusters do not build application code. They pull an already-built artifact. This separates build concerns from deployment concerns.

What would fail without it: Environments would need to rebuild locally or depend on non-repeatable artifacts. Runtime deployments would lose a stable artifact source.

Repository references:

- `.github/workflows/publish-and-promote-dev.yaml`
- `Dockerfile`
- `deploy/overlays/*/kustomization.yaml`

### Environment Overlays

Operational purpose: Kustomize overlays represent environment-specific deployment intent. Dev, staging, and prod can differ in namespace, replicas, resources, config, and image tag while sharing a common base.

Problem solved: The platform avoids copy-pasted manifests while still allowing controlled environment differences.

What would fail without it: Teams would either duplicate entire manifests per environment or mutate shared manifests manually. Both patterns increase drift and promotion risk.

Repository references:

- `deploy/base/`
- `deploy/overlays/dev/`
- `deploy/overlays/staging/`
- `deploy/overlays/prod/`
- `docs/build-once-deploy-many.md`
- `docs/config-injection.md`

### ArgoCD GitOps Reconciliation

Operational purpose: ArgoCD watches Git and reconciles the cluster toward the desired state stored in the environment overlays.

Problem solved: Git becomes the source of truth. If live cluster state drifts from Git, ArgoCD detects the difference and can either report it or automatically correct it depending on sync policy.

What would fail without it: The platform would rely on manual `kubectl apply` or CI pushing manifests directly into the cluster. Drift would be harder to detect, and rollback would be less predictable.

Repository references:

- `argocd/dev-application.yaml`
- `argocd/staging-application.yaml`
- `argocd/prod-application.yaml`
- `deploy/overlays/*`
- `docs/architecture.md`

### Kubernetes

Operational purpose: Kubernetes runs the workload, schedules pods, maintains desired replica counts, performs rolling updates, routes Service traffic, checks health probes, and restarts unhealthy containers.

Problem solved: Kubernetes provides the runtime control plane for desired-state application operation.

What would fail without it: The platform would have image builds and manifests but no orchestration layer to run, heal, expose, or scale workloads.

Repository references:

- `deploy/base/deployment.yaml`
- `deploy/base/service.yaml`
- `deploy/base/configmap.yaml`
- `deploy/base/secret-example.yaml`

### Kyverno Governance

Operational purpose: Kyverno acts as a Kubernetes admission controller that evaluates incoming resources against cluster policies.

Problem solved: Governance becomes automatic and consistent. Unsafe pods can be denied before they run.

What would fail without it: Standards such as immutable tags, resource requests, health probes, and non-root execution would depend on human memory and code review alone.

Repository references:

- `policies/kyverno/disallow-latest-tag.yaml`
- `policies/kyverno/require-probes.yaml`
- `policies/kyverno/require-resources.yaml`
- `policies/kyverno/require-nonroot.yaml`
- `docs/policy-as-code.md`
- `docs/kyverno-operations.md`

### External Secrets

Operational purpose: External Secrets Operator synchronizes secret values from AWS Secrets Manager into Kubernetes Secrets that workloads can consume.

Problem solved: Secrets stay out of Git while applications continue using native Kubernetes Secret consumption.

What would fail without it: Teams might commit secrets, manually create Secrets in clusters, or lose centralized rotation and auditability.

Repository references:

- `external-secrets/base/cluster-secret-store.yaml`
- `external-secrets/base/external-secret.yaml`
- `deploy/base/deployment.yaml`
- `docs/external-secrets-architecture.md`
- `docs/aws-secrets-manager-integration.md`

### HPA

Operational purpose: Horizontal Pod Autoscaler changes pod replica counts based on metrics such as CPU and memory utilization.

Problem solved: The service can add pods during load and reduce pods when load drops.

What would fail without it: Traffic spikes require manual intervention. Over-provisioning becomes the default safety mechanism.

Repository references:

- `autoscaling/hpa/sample-go-service-hpa.yaml`
- `deploy/overlays/*/patch-resources.yaml`
- `docs/autoscaling-architecture.md`
- `docs/scaling-operations.md`

### Karpenter Readiness

Operational purpose: Karpenter is the future node provisioning layer that reacts when pods cannot be scheduled because the cluster lacks suitable capacity.

Problem solved: HPA can create more pods, but pods still need nodes. Karpenter closes the capacity gap by provisioning nodes that match pending workload requirements.

What would fail without it: HPA may increase replicas, but new pods can remain Pending when existing nodes are full.

Repository references:

- `docs/hpa-vs-karpenter.md`
- `docs/autoscaling-architecture.md`
- `scripts/explain-autoscaling-flow.sh`

### Argo Rollouts

Operational purpose: Argo Rollouts replaces the basic Deployment rollout behavior with progressive delivery strategies such as canary.

Problem solved: A release can be exposed gradually and evaluated before all users receive it.

What would fail without it: Kubernetes rolling updates can replace pods safely, but they do not provide advanced traffic-weighted canary analysis and automated promotion gates.

Repository references:

- `progressive-delivery/argo-rollouts/rollout.yaml`
- `progressive-delivery/argo-rollouts/analysis-template.yaml`
- `docs/progressive-delivery.md`
- `docs/argo-rollouts-vs-canary.md`
- `docs/canary-runbook.md`

### Istio Traffic Routing

Operational purpose: Istio provides Gateway, VirtualService, DestinationRule, subsets, and weighted traffic routing between stable and canary versions.

Problem solved: Canary delivery needs traffic control. Istio lets Argo Rollouts adjust weights without requiring separate Services or manual ingress changes for every release step.

What would fail without it: Argo Rollouts could still manage ReplicaSets, but traffic shifting would be limited or would need another routing provider.

Repository references:

- `progressive-delivery/istio/gateway.yaml`
- `progressive-delivery/istio/virtual-service.yaml`
- `progressive-delivery/istio/destination-rule.yaml`
- `docs/istio-traffic-management.md`

### Observability Stack

Operational purpose: Observability provides metrics, alerts, dashboards, and eventually logs and traces to understand service and platform behavior.

Problem solved: Operators need evidence to continue rollouts, abort canaries, scale capacity, debug failures, and improve SLOs.

What would fail without it: The platform would deploy changes but lack reliable feedback. Rollout decisions would become guesswork.

Repository references:

- `observability/prometheus/service-monitor.yaml`
- `observability/prometheus/prometheus-rules.yaml`
- `observability/grafana/dashboard-summary.md`
- `docs/observability-architecture.md`
- `docs/rollout-observability.md`
- `docs/slo-readiness.md`
- `docs/alerting-runbook.md`

### Operational Validation

Operational purpose: Validation docs and scripts turn architecture into repeatable operator behavior.

Problem solved: The platform documents how to verify deployments, promotions, rollback, policies, scaling, secrets, progressive delivery, and observability.

What would fail without it: Operational knowledge would be scattered. Incidents would depend on whoever happens to remember the right commands and mental model.

Repository references:

- `operations/validation/platform-validation-checklist.md`
- `operations/validation/deployment-validation.md`
- `operations/validation/promotion-validation.md`
- `operations/validation/rollback-validation.md`
- `operations/incidents/`
- `scripts/validate-platform-foundation.sh`

## 3. Build Once Deploy Many

Build once deploy many means that the platform builds one artifact and promotes that artifact through environments without rebuilding it for each stage.

In this repository, the intended artifact is the sample service container image. The publishing workflow tags it with an immutable Git SHA:

```text
docker.io/kuberpull/sample-go-service:sha-${GITHUB_SHA}
```

That image is then promoted by updating Kustomize overlay image fields:

- Dev: `deploy/overlays/dev/kustomization.yaml`
- Staging: `deploy/overlays/staging/kustomization.yaml`
- Prod: `deploy/overlays/prod/kustomization.yaml`

### Immutable Artifacts

An immutable artifact is a build output that never changes after creation. A `sha-*` image tag should point to exactly one image digest. Promotion changes which environment points to the artifact; it does not rebuild the artifact.

Operational value:

- Reproducibility: the same bits move through the pipeline.
- Traceability: a runtime image maps back to a Git commit.
- Rollback: reverting an overlay returns the environment to a previous artifact.
- Incident response: engineers can identify exactly what code was running.
- Compliance: audit trails show build, scan, promotion, and deployment intent.

### Promotion Flow

The intended promotion path is:

```text
main branch merge
  -> publish image as sha-${GITHUB_SHA}
  -> update dev overlay image tag
  -> ArgoCD syncs dev
  -> manually promote dev image to staging
  -> ArgoCD syncs staging after operator approval/sync
  -> manually promote staging image to prod
  -> ArgoCD syncs prod after operator approval/sync
```

The workflows encode this model:

- `.github/workflows/publish-and-promote-dev.yaml` builds, pushes, and updates dev.
- `.github/workflows/promote-staging.yaml` copies the immutable image from dev to staging.
- `.github/workflows/promote-prod.yaml` copies the immutable image from staging to prod.

### Why Rebuilding Per Environment Is Dangerous

Rebuilding per environment creates false confidence. The artifact tested in dev may not be the artifact deployed to staging or prod. Even when source code is unchanged, dependencies, base images, build cache behavior, toolchain changes, timestamps, and registry state can produce different images.

Operational risks of rebuilding per environment:

- Dev tested one artifact, but production runs another.
- Security scans may not match the production image.
- Rollback may rebuild a new artifact instead of restoring the old one.
- Incident timelines become harder to reconstruct.
- A dependency change between builds can alter behavior outside code review.

### Image Tag Promotion

The promotion workflows update the `images` block in overlay kustomizations.

Dev overlay:

```yaml
images:
  - name: docker.io/kuberpull/sample-go-service
    newName: docker.io/kuberpull/sample-go-service
    newTag: replace-me
```

Staging and prod currently contain the image name and a `newTag` placeholder. During promotion, the workflows set the target environment to the immutable image that already exists in the source environment.

### Kustomize Overlays

Kustomize overlays let the platform share a base manifest while changing environment-specific values:

- Namespace
- Replica count
- Resource requests and limits
- ConfigMap values
- Image tag

The base is under `deploy/base/`. The overlays are under:

- `deploy/overlays/dev/`
- `deploy/overlays/staging/`
- `deploy/overlays/prod/`

### Deployment Safety

The base Deployment includes several production-oriented safeguards:

- `revisionHistoryLimit: 5` keeps recent ReplicaSets available.
- `minReadySeconds: 10` avoids declaring pods ready instantly.
- `maxUnavailable: 0` keeps existing capacity available during rolling updates.
- Readiness probe gates traffic.
- Liveness probe restarts unhealthy containers.
- Resource requests support scheduling and HPA calculations.
- Resource limits reduce runaway consumption.
- Non-root and restricted container security settings reduce privilege risk.

Without these settings, a deployment can become unavailable during rollout, route traffic to unready pods, fail to autoscale correctly, or run with unnecessary privileges.

## 4. GitHub Actions CI/CD Architecture

GitHub Actions is the platform's CI/CD automation layer. It validates code and manifests, builds images, pushes artifacts, and performs Git-based promotion.

### Why CI Exists

CI exists to protect the delivery platform before runtime:

- Build failures are caught before merge or release.
- Unit tests validate application behavior.
- `gofmt` and `go vet` catch code quality and correctness issues.
- Dockerfile scanning catches container build anti-patterns.
- Image scanning catches high and critical vulnerabilities.
- Kustomize rendering catches broken manifests.
- Checkov scanning catches Kubernetes and workflow security risks.

CI is not a substitute for runtime admission control or observability. It is the first quality gate.

### Workflow Responsibilities

#### `.github/workflows/ci.yaml`

Purpose: Validation-only CI for pushes to `main` and pull requests.

What it does:

- Checks out code.
- Sets up Go using `apps/sample-go-service/go.mod`.
- Runs `gofmt` check.
- Runs `go vet`.
- Runs Go tests.
- Scans `Dockerfile` with Hadolint.
- Builds a Docker image locally using the commit SHA.
- Scans the image with Trivy for high and critical vulnerabilities.
- Installs Kustomize.
- Renders dev, staging, and prod overlays.
- Scans Kubernetes manifests with Checkov.
- Scans GitHub Actions workflows with Checkov.

Operational role: This workflow prevents known-bad code, build definitions, manifests, and workflow definitions from entering the main platform path.

#### `.github/workflows/publish-and-promote-dev.yaml`

Purpose: Build and publish the immutable image after a push to `main`, then promote that image to dev by committing an overlay change.

What it does:

- Verifies required registry secrets exist.
- Runs Go formatting, vetting, and tests.
- Builds a validation Docker image.
- Renders the dev overlay.
- Logs in to the configured registry.
- Builds and pushes:
  - `docker.io/kuberpull/sample-go-service:sha-${GITHUB_SHA}`
  - `docker.io/kuberpull/sample-go-service:latest`
- Updates `deploy/overlays/dev/kustomization.yaml` to point at `sha-${GITHUB_SHA}`.
- Commits the dev promotion back to `main`.

Operational role: This workflow introduces the immutable artifact and sets dev deployment intent in Git.

Important note: The workflow currently also pushes `latest`. The Kyverno policy rejects runtime use of `latest`; the immutable `sha-*` tag is the promotion tag that environments should consume.

#### `.github/workflows/promote-staging.yaml`

Purpose: Manually promote the immutable image currently declared in dev to staging.

What it does:

- Reads image name and tag from `deploy/overlays/dev/kustomization.yaml`.
- Verifies the dev tag is non-empty, not `latest`, and starts with `sha-`.
- Updates `deploy/overlays/staging/kustomization.yaml`.
- Renders the staging overlay.
- Commits the staging promotion to `main`.

Operational role: Staging receives the exact artifact that dev ran. The workflow protects the promotion path from mutable tags.

#### `.github/workflows/promote-prod.yaml`

Purpose: Manually promote the immutable image currently declared in staging to production.

What it does:

- Reads image name and tag from `deploy/overlays/staging/kustomization.yaml`.
- Verifies the staging tag is non-empty, not `latest`, and starts with `sha-`.
- Updates `deploy/overlays/prod/kustomization.yaml`.
- Renders the prod overlay.
- Commits the production promotion to `main`.

Operational role: Production receives the exact artifact that staging validated. The workflow ensures production promotion is explicit and Git-auditable.

### DevSecOps Validation

The platform uses DevSecOps as a delivery property, not as a separate phase after deployment. Validation is distributed:

- GitHub Actions: code, image, manifest, and workflow scanning.
- Kyverno: runtime admission governance.
- External Secrets: secret ownership and synchronization.
- Observability: runtime health and SLO signals.
- Operations runbooks: response and recovery.

Security and reliability checks are most valuable when they happen before users are affected.

## 5. ArgoCD GitOps Architecture

ArgoCD is the GitOps reconciliation controller planned for this platform. It continuously compares desired state in Git with actual state in Kubernetes.

### What ArgoCD Is

ArgoCD is a Kubernetes controller and API/UI system that manages Kubernetes resources from Git repositories. An ArgoCD `Application` tells ArgoCD:

- Which Git repository to read.
- Which revision to use.
- Which path contains manifests.
- Which cluster and namespace to deploy to.
- Which sync behavior to apply.

### Desired State vs Actual State

Desired state is what Git says should exist. In this repository, desired state for the sample service is represented by Kustomize overlays:

- `deploy/overlays/dev`
- `deploy/overlays/staging`
- `deploy/overlays/prod`

Actual state is what the Kubernetes API reports is currently running in the cluster.

ArgoCD detects differences between these two states:

- Missing resource: Git declares it, cluster does not have it.
- Modified resource: cluster differs from Git.
- Extra resource: cluster has something no longer declared in Git.
- Failed resource: cluster accepted the manifest but the workload is not healthy.

### Reconciliation Loop

The ArgoCD reconciliation loop is:

```text
Watch Git repository
  -> render the configured path
  -> compare rendered manifests with live cluster objects
  -> mark application Synced or OutOfSync
  -> apply changes if sync is manual or automated
  -> report health from Kubernetes resource status
```

This loop is the core of GitOps. The cluster is not the source of truth; it is the execution target.

### Drift Detection

Drift occurs when actual state differs from desired state. Examples:

- Someone manually changes replicas with `kubectl scale`.
- Someone edits a ConfigMap directly in the cluster.
- A resource is deleted manually.
- A Service selector is changed outside Git.

With ArgoCD, drift is visible. With `selfHeal: true`, ArgoCD can also correct drift automatically.

### Sync Flow

For this project:

- Dev points to `deploy/overlays/dev`.
- Staging points to `deploy/overlays/staging`.
- Prod points to `deploy/overlays/prod`.

When an overlay image tag changes, ArgoCD sees a Git change and reconciles the cluster.

### Why GitOps Matters

GitOps matters because it creates operational discipline:

- Git history becomes deployment history.
- Pull requests become environment change review.
- Rollback is a Git revert.
- ArgoCD provides visibility into sync and health.
- Manual cluster edits become detectable drift.

### Application Resources

`argocd/dev-application.yaml` defines:

- Application name: `sample-go-service-dev`
- Source path: `deploy/overlays/dev`
- Destination namespace: `sample-go-service-dev`
- Automated sync enabled.
- `prune: true`
- `selfHeal: true`
- `CreateNamespace=true`

Operational meaning: dev is optimized for fast feedback and automatic convergence.

`argocd/staging-application.yaml` defines:

- Application name: `sample-go-service-staging`
- Source path: `deploy/overlays/staging`
- Destination namespace: `sample-go-service-staging`
- `CreateNamespace=true`
- No automated sync block.

Operational meaning: staging is intended to be more controlled than dev. Operators can review and sync intentionally.

`argocd/prod-application.yaml` defines:

- Application name: `sample-go-service-prod`
- Source path: `deploy/overlays/prod`
- Destination namespace: `sample-go-service-prod`
- `CreateNamespace=true`
- No automated sync block.

Operational meaning: production promotion should be deliberate and auditable.

### AppProject Resources

The current Application files use `project: default`. There are no custom `AppProject` resources currently defined in `argocd/`.

Future production hardening should add AppProjects to restrict:

- Allowed Git repositories.
- Allowed destination clusters and namespaces.
- Allowed Kubernetes resource kinds.
- Environment-specific permissions.

Without AppProjects, ArgoCD can still deploy the Applications, but governance boundaries are weaker.

### Automated Sync, Self-Heal, and Prune

`automated` means ArgoCD can apply Git changes without a human clicking sync.

`selfHeal` means ArgoCD can correct live drift back to Git.

`prune` means ArgoCD can delete live resources that are no longer declared in Git.

Operational tradeoff:

- Dev benefits from full automation.
- Staging and prod often require manual approval or progressive delivery gates.
- Prune is powerful and must be paired with review discipline.

### Runtime Components Still Missing

The repository defines ArgoCD Applications, but it does not install:

- ArgoCD controller.
- ArgoCD repo server.
- ArgoCD application controller.
- ArgoCD API server/UI.
- ArgoCD CRDs.
- ArgoCD RBAC.
- AppProject governance resources.
- Cluster credentials or repository credentials.

Until those runtime components exist, the `argocd/` files are architecture-ready desired-state definitions, not active reconcilers.

## 6. Kyverno Policy Architecture

Kyverno is the policy-as-code and admission governance layer for this platform.

### Admission Controllers

Kubernetes admission controllers intercept API requests after authentication and authorization but before objects are persisted. A validating admission webhook can accept or reject a request. A mutating admission webhook can modify a request before storage.

Kyverno installs admission webhooks and evaluates resources against Kyverno policies.

### Webhook Interception

The intended flow is:

```text
Client submits workload
  -> Kubernetes API server authenticates and authorizes request
  -> Admission webhooks receive the object
  -> Kyverno evaluates matching policies
  -> Request is allowed or denied
  -> Object is persisted only if admission succeeds
```

Clients include:

- ArgoCD.
- `kubectl`.
- CI jobs with cluster credentials.
- Operators.
- Other controllers creating pods or pod templates.

### Policy Evaluation Flow

Kyverno policies match resources by kind and other criteria. This repository uses `ClusterPolicy` resources that match Pods. Because Deployments create ReplicaSets and ReplicaSets create Pods, Pod policies evaluate the final workload that would run.

Evaluation considers:

- The incoming object.
- Policy match rules.
- Validation patterns or deny conditions.
- `validationFailureAction`.

### Enforce vs Audit

`validationFailureAction: Enforce` rejects non-compliant resources.

`Audit` would report violations but allow resources.

This repository sets the policies to `Enforce` because they represent baseline safety requirements. In a real adoption path, teams often start with Audit to discover violations, fix manifests, then switch to Enforce.

### Governance Architecture

Governance is layered:

- CI validates manifests before merge.
- Kyverno blocks unsafe runtime admission.
- ArgoCD keeps desired state aligned with Git.
- Observability detects runtime symptoms not visible at admission time.

Policy-as-code prevents entire classes of failures before pods run.

### Implemented Policies

#### `policies/kyverno/disallow-latest-tag.yaml`

Policy: `disallow-latest-tag`

What it enforces: Containers must not use image tags ending in `:latest`.

Operational failure prevented:

- Mutable images in production.
- Unreliable rollback.
- Inability to reconstruct which artifact ran during an incident.
- Accidental deployment of a newly-pushed `latest` image without Git promotion.

Connection to manifests:

- `deploy/base/deployment.yaml` uses `replace-me`.
- Overlays should promote immutable `sha-*` tags.
- Promotion workflows verify `sha-*` before staging and prod.

#### `policies/kyverno/require-probes.yaml`

Policy: `require-probes`

What it enforces: Containers must define both liveness and readiness probes.

Operational failure prevented:

- Traffic routed to unready pods.
- Failed processes remaining in service without restart.
- Rollouts completing before the application is actually usable.
- Lack of health gating during progressive delivery.

Connection to manifests:

- `deploy/base/deployment.yaml` defines `/ready` and `/health`.
- `apps/sample-go-service/internal/handlers/handlers.go` implements `/ready` and `/health`.

#### `policies/kyverno/require-resources.yaml`

Policy: `require-resources`

What it enforces: Containers must define CPU and memory requests and limits.

Operational failure prevented:

- Unpredictable scheduling.
- Noisy-neighbor resource consumption.
- HPA utilization calculations based on missing or misleading requests.
- Capacity planning blind spots.

Connection to manifests:

- `deploy/base/deployment.yaml` defines default requests and limits.
- `deploy/overlays/*/patch-resources.yaml` adjusts per environment.
- `autoscaling/hpa/sample-go-service-hpa.yaml` depends on meaningful requests.

#### `policies/kyverno/require-nonroot.yaml`

Policy: `require-nonroot`

What it enforces: Pods must set `spec.securityContext.runAsNonRoot: true`.

Operational failure prevented:

- Avoidable privilege escalation risk.
- Containers running as root by default.
- Weaker security posture during a container breakout scenario.

Connection to manifests:

- `deploy/base/deployment.yaml` sets `runAsNonRoot`, user/group `65532`, `RuntimeDefault` seccomp, no privilege escalation, read-only root filesystem, and drops Linux capabilities.
- `Dockerfile` uses a distroless non-root runtime image and `USER nonroot:nonroot`.

### Runtime Kyverno Controller Still Needed

The repository defines Kyverno policies but does not install:

- Kyverno CRDs.
- Kyverno admission controller.
- Kyverno background controller.
- Kyverno reports controller.
- Kyverno cleanup controller.
- Kyverno RBAC and service accounts.
- PolicyReporter or equivalent reporting stack, if desired.

Until Kyverno is installed, the policy YAML files are reference governance definitions. They do not actively block Kubernetes resources.

## 7. External Secrets Architecture

The platform prepares for centralized secret management through AWS Secrets Manager and External Secrets Operator.

### AWS Secrets Manager as Source of Truth

AWS Secrets Manager is intended to own sensitive values such as API keys, database passwords, tokens, and credentials. Kubernetes should receive generated Secrets, but it should not become the long-term secret source of truth.

Operational benefits:

- Secrets stay out of Git.
- AWS IAM controls who can read or write secrets.
- AWS audit logs can record access patterns.
- Rotation can happen centrally.
- Kubernetes workloads consume secrets through a familiar native interface.

### External Secrets Operator Reconciliation

External Secrets Operator watches `ExternalSecret` resources. It reads a referenced secret provider through a `SecretStore` or `ClusterSecretStore`, fetches remote values, and creates or updates Kubernetes Secret objects.

Reconciliation flow:

```text
AWS Secrets Manager
  -> External Secrets Operator authenticates to AWS
  -> ExternalSecret declares remote keys/properties
  -> Operator creates Kubernetes Secret
  -> Pod consumes generated Secret through envFrom.secretRef
  -> Operator refreshes the Secret on interval
```

### Generated Kubernetes Secrets

`external-secrets/base/external-secret.yaml` creates the target Kubernetes Secret:

```text
sample-go-service-secret
```

The Deployment consumes that Secret in `deploy/base/deployment.yaml`:

```yaml
envFrom:
  - secretRef:
      name: sample-go-service-secret
      optional: true
```

The Secret is marked optional in the current base so the repository can render and run in early phases without a live External Secrets installation.

### Pod Secret Consumption Flow

The pod does not talk directly to AWS Secrets Manager. The application reads environment variables. Kubernetes injects those environment variables from a Kubernetes Secret. External Secrets Operator is responsible for keeping that Kubernetes Secret synchronized with AWS.

This separation is important:

- Application code stays cloud-provider neutral.
- Kubernetes manifests stay simple.
- Secret ownership remains centralized.
- Rotation does not require rebuilding the application image.

### Operational Risks Solved

Externalized secret management helps prevent:

- Committed secrets in Git.
- Manual secret drift between environments.
- Long-lived unrotated credentials.
- Unclear secret ownership.
- Inconsistent secret names across clusters.
- Emergency redeploys just to change a secret value.

### ClusterSecretStore

`external-secrets/base/cluster-secret-store.yaml` defines:

- Kind: `ClusterSecretStore`
- Name: `aws-secrets-manager`
- Provider: AWS Secrets Manager
- Region placeholder: `<aws-region>`
- Authentication placeholder using a service account named `external-secrets` in namespace `external-secrets`

A `ClusterSecretStore` is cluster-scoped. It can be referenced by ExternalSecrets across namespaces, subject to operator configuration and RBAC.

Production hardening should define:

- Real AWS region.
- IRSA or EKS Pod Identity.
- Least-privilege IAM policy for specific secret paths.
- Separate stores per environment if needed.
- Namespace access boundaries.

### ExternalSecret

`external-secrets/base/external-secret.yaml` defines:

- Kind: `ExternalSecret`
- Name: `sample-go-service-secret`
- Namespace: `sample-go-service-prod`
- Refresh interval: `1h`
- Store reference: `ClusterSecretStore/aws-secrets-manager`
- Target Secret: `sample-go-service-secret`
- Remote keys:
  - `production/sample-go-service/api-key` property `API_KEY`
  - `production/sample-go-service/api-key` property `DATABASE_PASSWORD`

The remote path is a placeholder. Real production values should use organization-approved naming, ownership, rotation, and access rules.

### Synchronization Model

External Secrets Operator uses a pull reconciliation model:

- Git declares which remote secret values a workload needs.
- The operator periodically reads the external provider.
- The operator writes a Kubernetes Secret.
- Pods consume that Secret.
- Depending on how the workload consumes the Secret, changes may require pod restart to become visible as environment variables.

### Runtime Pieces Still Needed

The repository does not install:

- External Secrets Operator.
- External Secrets CRDs.
- AWS IAM role for service account or EKS Pod Identity.
- Service account annotations for AWS authentication.
- SecretStore/ClusterSecretStore with real region and auth.
- Real AWS Secrets Manager entries.
- Namespace-specific ExternalSecrets for every environment.
- Secret rotation policy.

Until these exist, `external-secrets/` is architecture-ready but not active.

## 8. Autoscaling Architecture

Autoscaling has two related but different concerns:

- Pod scaling: add or remove replicas of a workload.
- Node scaling: add or remove Kubernetes node capacity.

This repository implements a reference HPA manifest and documents readiness for future Karpenter integration.

### HPA Pod Scaling

Horizontal Pod Autoscaler watches metrics and updates the target workload's replica count.

`autoscaling/hpa/sample-go-service-hpa.yaml` targets:

- API version: `apps/v1`
- Kind: `Deployment`
- Name: `sample-go-service`
- Min replicas: `2`
- Max replicas: `10`
- CPU target: `70%`
- Memory target: `75%`

HPA does not create nodes. It only changes desired pod replicas.

### Metrics-Driven Scaling

HPA requires metrics. For CPU and memory resource metrics, the cluster typically needs `metrics-server`. HPA reads metrics through Kubernetes metrics APIs.

Flow:

```text
Pods consume CPU/memory
  -> metrics-server exposes resource metrics
  -> HPA controller compares usage to targets
  -> HPA updates Deployment replicas
  -> Deployment creates or removes pods
```

If metrics-server is missing, HPA cannot make reliable scaling decisions.

### Requests and Limits Importance

HPA utilization is calculated against resource requests. For example, if CPU request is `250m` and the pod uses `175m`, CPU utilization is 70%.

This is why resource requests matter operationally:

- Scheduler uses requests to place pods.
- HPA uses requests to calculate utilization.
- Karpenter uses pending pod requirements to provision appropriate nodes.
- Platform teams use requests to plan capacity.

The overlays define environment-specific resource profiles:

- Dev: `50m` CPU, `64Mi` memory request.
- Staging: `100m` CPU, `128Mi` memory request.
- Prod: `250m` CPU, `256Mi` memory request.

### Karpenter Node Provisioning

Karpenter is the planned node autoscaling layer. It watches for unschedulable pods and provisions nodes that satisfy their requirements.

Flow:

```text
HPA increases replicas
  -> Deployment creates pods
  -> scheduler attempts placement
  -> pods remain Pending if capacity is insufficient
  -> Karpenter observes unschedulable pods
  -> Karpenter provisions suitable nodes
  -> scheduler places pods
  -> readiness probes pass
  -> Service sends traffic
```

### Scheduler Interaction

The Kubernetes scheduler places pods based on:

- CPU and memory requests.
- Node capacity.
- Taints and tolerations.
- Affinity and anti-affinity.
- Topology constraints.
- Volume and networking requirements.

If no existing node can satisfy a pod, the pod remains Pending. That Pending state is the signal node autoscalers respond to.

### Unschedulable Workloads

An unschedulable workload can happen when:

- HPA creates more replicas than nodes can fit.
- Pod requests are too large.
- Nodes are unavailable in the required zone.
- Taints prevent scheduling.
- Required labels or affinity cannot be satisfied.

Karpenter readiness exists because pod autoscaling alone does not guarantee capacity.

### Runtime Metrics Systems Still Needed

The repository does not install:

- metrics-server.
- Karpenter.
- Karpenter CRDs such as NodePool and EC2NodeClass.
- IAM roles and permissions for node provisioning.
- Cluster Autoscaler, if choosing that instead of Karpenter.
- Load testing or live autoscaling validation tooling.

The HPA manifest is ready for future integration, but it is not wired into overlays yet as an active production deployment resource.

## 9. Progressive Delivery Architecture

Progressive delivery reduces release risk by exposing a new version gradually and using health signals to continue, pause, or abort.

### Canary Deployment Strategy

A canary release runs a new version beside the stable version. A small percentage of traffic goes to canary first. If metrics remain healthy, more traffic shifts to canary until it reaches 100%.

This repository models the canary sequence:

- 10% traffic to canary.
- Pause for 2 minutes.
- 25% traffic.
- Pause for 2 minutes.
- 50% traffic.
- Pause for 2 minutes.
- 100% traffic.

Reference:

- `progressive-delivery/argo-rollouts/rollout.yaml`

### Argo Rollouts Controller Responsibilities

Argo Rollouts is responsible for:

- Managing stable and canary ReplicaSets.
- Executing canary steps.
- Updating traffic weights through the configured traffic provider.
- Pausing between steps.
- Running metric analysis when configured.
- Promoting successful canaries.
- Aborting unhealthy rollouts.
- Preserving rollout history for rollback.

The Rollout resource in this repository is a future replacement or supplement for the current Kubernetes Deployment model.

### Istio Traffic Routing

Istio provides the traffic routing primitives:

- `Gateway`: external entry point.
- `VirtualService`: HTTP routing rules and weights.
- `DestinationRule`: subsets and traffic policy.

Argo Rollouts integrates with Istio by modifying the VirtualService route weights between stable and canary destinations.

### VirtualService

`progressive-delivery/istio/virtual-service.yaml` defines:

- Host: `sample.example.com`
- Gateway: `sample-go-service`
- HTTP route name: `primary`
- Stable destination weight: `100`
- Canary destination weight: `0`

During a live rollout, Argo Rollouts changes these weights.

### DestinationRule

`progressive-delivery/istio/destination-rule.yaml` defines:

- Host: `sample-go-service`
- TLS mode: `ISTIO_MUTUAL`
- Subset `stable` matching label `version: stable`
- Subset `canary` matching label `version: canary`

Subsets let Istio route to different pod groups behind the same Kubernetes Service host.

### Gateway

`progressive-delivery/istio/gateway.yaml` defines:

- Selector: `istio: ingressgateway`
- Port: `80`
- Protocol: `HTTP`
- Host: `sample.example.com`

The host is a placeholder for future environment-specific ingress configuration.

### AnalysisTemplate

`progressive-delivery/argo-rollouts/analysis-template.yaml` defines a Prometheus-based success-rate metric:

- Metric name: `success-rate`
- Interval: `1m`
- Count: `3`
- Success condition: `result[0] >= 0.99`
- Failure limit: `1`
- Prometheus address placeholder: `http://prometheus.example.com`

Operational meaning: the rollout should continue only when measured success rate meets the threshold.

### Rollback Behavior

Rollback can happen through multiple mechanisms:

- Argo Rollouts aborts canary and returns traffic to stable.
- Operators manually abort a rollout.
- Git promotion commit is reverted.
- ArgoCD reconciles the environment back to the previous desired state.
- Kubernetes/Argo Rollouts uses retained history to restore previous ReplicaSets.

The platform intentionally makes rollback a normal control path.

### Traffic Shifting

Traffic shifting protects users by limiting exposure:

- At 10%, only a small slice of users sees the new version.
- At 25% and 50%, the platform gathers stronger production signals.
- At 100%, the canary becomes the new stable version.

Without traffic shifting, all users receive the new version as soon as it rolls out.

### Runtime Controllers Still Needed

The repository does not install:

- Argo Rollouts controller.
- Argo Rollouts CRDs.
- Argo Rollouts kubectl plugin.
- Istio control plane.
- Istio ingress gateway.
- Istio sidecar injection or ambient mesh configuration.
- Istio CRDs.
- Prometheus integration for AnalysisTemplates.
- Stable and canary Services required by the Rollout strategy.
- Overlay integration that replaces or coordinates with the current Deployment.

The progressive delivery manifests are reference architecture until those runtime pieces are installed and integrated.

## 10. Observability Architecture

Observability turns runtime behavior into evidence. The platform models metrics, alerts, dashboards, SLO readiness, and rollout health signals.

### Metrics

Metrics are numeric time-series signals such as:

- Request rate.
- Error rate.
- Request duration.
- Pod restarts.
- CPU usage.
- Memory usage.
- HPA desired/current replicas.
- Rollout phase and canary weight.

The sample service currently implements health, readiness, version, and config endpoints. It does not yet implement a live `/metrics` endpoint.

### Logs

Logs provide event context. The Go service logs startup and shutdown using structured JSON logs through `slog`.

Future production logging should add:

- Centralized log collection.
- Correlation IDs.
- Request logs.
- Error logs with service, environment, version, and commit metadata.
- Retention policy.

Potential stack components:

- Fluent Bit or OpenTelemetry Collector.
- Loki or another log backend.
- Grafana log dashboards.

### Traces

Traces show request paths across services. This repository does not yet implement tracing.

Future tracing should add:

- OpenTelemetry instrumentation.
- Trace propagation.
- Collector deployment.
- Tempo, Jaeger, or another trace backend.

Traces become more important when the platform hosts multiple services.

### Alerts

`observability/prometheus/prometheus-rules.yaml` defines reference alerts:

- `HighErrorRate`
- `HighLatency`
- `PodRestartingFrequently`
- `RolloutCanaryDegraded`

These alerts map technical symptoms to operational decisions:

- Page when user impact is likely.
- Create tickets for lower urgency symptoms.
- Abort canaries when canary-specific errors rise.
- Investigate restarts before they become outages.

### Dashboards

`observability/grafana/dashboard-summary.md` describes dashboard expectations. Useful dashboards should show:

- Service RED metrics: rate, errors, duration.
- Kubernetes pod health.
- HPA current vs desired replicas.
- CPU and memory usage against requests/limits.
- Rollout progress.
- Canary vs stable error rate and latency.
- Alert state.

Dashboards should support fast diagnosis, not decorative reporting.

### SLOs

SLOs connect technical metrics to user expectations. A production platform should define:

- Availability target.
- Latency target.
- Error budget.
- Alert thresholds based on burn rate.
- Rollout gates that protect the SLO.

Repository references:

- `docs/slo-readiness.md`
- `docs/observability-architecture.md`
- `docs/rollout-observability.md`

### Prometheus Scraping

`observability/prometheus/service-monitor.yaml` defines a Prometheus Operator `ServiceMonitor`:

- Selects the sample service by labels.
- Targets namespace `sample-go-service-prod`.
- Scrapes port `http`.
- Scrapes path `/metrics`.
- Uses `30s` interval and `10s` timeout.

Runtime requirement: Prometheus Operator must be installed, and the application must expose `/metrics`.

### Grafana Dashboards

Grafana is the visualization layer. The repository currently provides dashboard planning rather than JSON dashboard definitions.

Future production work should add:

- Dashboard JSON as code.
- Environment variables for data source names.
- Folder and dashboard provisioning.
- Links to runbooks.
- Panels for rollouts, HPA, resource pressure, and SLO burn.

### Rollout Observability

Progressive delivery depends on observability. The canary strategy needs enough signal to decide whether to continue.

Important rollout signals:

- Canary error rate.
- Canary latency.
- Stable vs canary comparison.
- Pod restart count.
- Readiness failures.
- Saturation metrics.
- Business or synthetic transaction success.

Without rollout observability, canary steps become timed pauses with no objective safety check.

### Observability Stack Components Still Needed

The repository does not install:

- Prometheus Operator.
- Prometheus.
- Alertmanager.
- Grafana.
- Loki or another logging stack.
- Tempo or Jaeger for tracing.
- OpenTelemetry Collector.
- Application `/metrics` instrumentation.
- ServiceMonitor CRDs.
- PrometheusRule CRDs.
- Dashboard provisioning.
- Alert routing integrations such as Slack, PagerDuty, or email.

The observability files define the architecture and initial Prometheus resources, but the runtime stack is not active yet.

## 11. Operational Validation and Incident Response

Operational maturity is the difference between having manifests and running a platform. This repository includes validation documents, runbooks, and scripts to make operations repeatable.

### Validation Runbooks

The validation docs under `operations/validation/` describe how to verify platform behavior:

- `operations/validation/platform-validation-checklist.md`: full platform readiness checklist.
- `operations/validation/deployment-validation.md`: deployment validation.
- `operations/validation/promotion-validation.md`: image promotion validation.
- `operations/validation/rollback-validation.md`: rollback validation.

Validation areas include:

- Kustomize overlay rendering.
- Image tag correctness.
- Namespace and config correctness.
- Resource requests and limits.
- Probe existence.
- CI workflow behavior.
- Promotion commit behavior.
- Policy readiness.
- External Secrets readiness.
- HPA readiness.
- Progressive delivery readiness.
- Observability readiness.

### Day-2 Operations

Day-2 operations are the practices required after initial deployment:

- Monitoring service health.
- Responding to alerts.
- Rotating secrets.
- Managing upgrades.
- Tuning resources.
- Reviewing policies.
- Investigating drift.
- Performing rollback.
- Validating autoscaling.
- Improving SLOs after incidents.

Repository references:

- `docs/day-2-operations.md`
- `docs/operational-readiness.md`
- `docs/scaling-operations.md`
- `docs/kyverno-operations.md`

### Rollback Procedures

Rollback is primarily Git-driven:

```text
Identify bad promotion commit
  -> revert overlay image/config change
  -> push revert
  -> ArgoCD reconciles previous desired state
  -> validate pods, traffic, alerts, and user symptoms
```

Additional rollback paths:

- Abort Argo Rollouts canary.
- Manually sync previous ArgoCD revision.
- Use retained ReplicaSet history for emergency recovery.
- Revert configuration changes separately from image changes when needed.

Repository references:

- `docs/rollback-runbook.md`
- `operations/validation/rollback-validation.md`
- `operations/incidents/failed-canary-rollout.md`
- `operations/incidents/image-promotion-failure.md`

### Incident Response Mindset

Incident response should focus on:

- Protecting users first.
- Stopping the bleeding before deep root-cause analysis.
- Using evidence from metrics, logs, traces, events, and deployment history.
- Rolling back quickly when a release is likely responsible.
- Communicating clearly.
- Recording follow-up actions.

Useful first questions:

- What changed?
- Which environment is affected?
- Which image tag is running?
- Did ArgoCD sync recently?
- Are pods Ready?
- Are probes failing?
- Are error rates or latency elevated?
- Did HPA scale?
- Are pods Pending?
- Did secrets sync?
- Is the issue isolated to canary?

### Operational Maturity

The project demonstrates maturity by encoding:

- Build validation.
- Security scanning.
- Immutable promotion.
- GitOps desired state.
- Runtime governance.
- External secrets.
- Autoscaling readiness.
- Progressive delivery readiness.
- Observability readiness.
- Runbooks and validation guides.

This is how platform engineering moves from ad hoc deployment to an operational system.

## 12. Runtime Integration Status

This section separates architecture implemented in the repository from runtime components that still need live installation and configuration.

### Implemented Architecturally

The repository currently implements or models:

- Go sample service with `/health`, `/ready`, `/version`, and `/config`.
- Multi-stage Dockerfile using a distroless non-root runtime image.
- CI workflow for Go validation, Docker build validation, image scanning, Kustomize rendering, and Checkov scans.
- Publish and dev promotion workflow.
- Staging promotion workflow.
- Production promotion workflow.
- Kubernetes base Deployment, Service, ConfigMap, and example Secret.
- Dev, staging, and prod Kustomize overlays.
- ArgoCD Application resources for dev, staging, and prod.
- Kyverno ClusterPolicies for immutable tags, probes, resources, and non-root execution.
- External Secrets reference ClusterSecretStore and ExternalSecret.
- HPA reference manifest.
- Argo Rollouts reference Rollout and AnalysisTemplate.
- Istio reference Gateway, VirtualService, and DestinationRule.
- Prometheus Operator reference ServiceMonitor and PrometheusRule.
- Grafana dashboard planning.
- Operational validation docs.
- Incident response runbooks.
- Educational and validation scripts.

### Not Yet Installed Runtime Components

The following still require live installation/configuration:

- Kubernetes cluster, if not already available.
- Container registry secrets in GitHub Actions.
- ArgoCD CRDs.
- ArgoCD controller components.
- ArgoCD repository access.
- ArgoCD AppProjects.
- ArgoCD RBAC.
- Kyverno CRDs.
- Kyverno admission controller.
- Kyverno background/reports/cleanup controllers.
- External Secrets Operator CRDs.
- External Secrets Operator controller.
- AWS Secrets Manager real secret entries.
- AWS IAM role for service account or EKS Pod Identity.
- External Secrets service account and auth wiring.
- Environment-specific ExternalSecret resources.
- metrics-server.
- HPA deployment integration into overlays.
- Karpenter controller.
- Karpenter NodePools and cloud provider node classes.
- Karpenter IAM permissions.
- Argo Rollouts CRDs.
- Argo Rollouts controller.
- Argo Rollouts CLI plugin.
- Istio CRDs.
- Istio control plane.
- Istio ingress gateway.
- Sidecar injection or ambient mesh mode.
- Stable and canary Services for Argo Rollouts.
- Prometheus Operator CRDs.
- Prometheus.
- Alertmanager.
- Grafana.
- Loki or equivalent logging backend.
- Tempo, Jaeger, or equivalent tracing backend.
- OpenTelemetry Collector.
- Application metrics endpoint.
- Dashboard provisioning.
- Alert notification routing.
- Live load testing tooling.
- Live canary validation.
- Live autoscaling validation.

### Readiness Interpretation

The platform is repository-ready and architecture-ready. It is not yet runtime-complete.

That distinction matters. The repository contains the desired-state blueprints, workflow logic, and operational mental model. A live cluster still needs the controllers and operators that make those blueprints active.

## 13. Runtime Integration Roadmap

The runtime roadmap should install and validate one capability at a time. Each phase should have a clear success condition and rollback plan.

### Phase 1: Cluster and Registry Foundation

Install or identify the target Kubernetes cluster.

Configure:

- Container registry.
- GitHub repository secrets:
  - `CONTAINER_REGISTRY`
  - `CONTAINER_REGISTRY_USERNAME`
  - `CONTAINER_REGISTRY_TOKEN`
- Kubernetes access model for operators.

Validate:

- CI passes.
- Image publishing works.
- Dev overlay updates to `sha-*`.

### Phase 2: ArgoCD Installation

Install:

- ArgoCD CRDs and controllers.
- ArgoCD namespace.
- Repository credentials.
- RBAC.
- AppProject boundaries.

Apply:

- `argocd/dev-application.yaml`
- `argocd/staging-application.yaml`
- `argocd/prod-application.yaml`

Validate:

- Dev syncs automatically.
- Staging and prod appear as Applications.
- Drift detection works.
- Namespace creation works.

### Phase 3: Kyverno Installation

Install:

- Kyverno CRDs.
- Kyverno controllers.
- Policy reporting, if desired.

Apply:

- `policies/kyverno/*.yaml`

Recommended sequence:

- Start in Audit mode in a test cluster.
- Validate current manifests are compliant.
- Move to Enforce for baseline policies.

Validate:

- A pod using `:latest` is rejected.
- A pod missing probes is rejected.
- A pod missing resources is rejected.
- A pod missing non-root security context is rejected.

### Phase 4: External Secrets Operator Installation

Install:

- External Secrets Operator.
- CRDs.
- Service account and AWS authentication.
- IAM access to required AWS Secrets Manager paths.

Configure:

- Real AWS region in `ClusterSecretStore`.
- Real remote secret keys.
- Environment-specific ExternalSecrets.

Validate:

- Operator syncs `sample-go-service-secret`.
- Pods consume generated secret.
- Secret rotation is reflected on refresh.
- Failure modes are observable.

### Phase 5: Metrics Server and HPA

Install:

- metrics-server.

Apply or integrate:

- `autoscaling/hpa/sample-go-service-hpa.yaml`

Validate:

- `kubectl top pods` works.
- HPA reports CPU/memory metrics.
- Load causes desired replicas to increase.
- Low load allows scale-down.

### Phase 6: Prometheus Stack

Install:

- Prometheus Operator.
- Prometheus.
- Alertmanager.
- Grafana.

Apply:

- `observability/prometheus/service-monitor.yaml`
- `observability/prometheus/prometheus-rules.yaml`

Add:

- Application `/metrics` endpoint.
- Dashboard JSON/provisioning.
- Alert routing.

Validate:

- Prometheus scrapes service metrics.
- Alerts evaluate.
- Grafana dashboards show service health.
- Alert routing reaches the intended channel.

### Phase 7: Karpenter

Install:

- Karpenter controller.
- IAM permissions.
- NodePool and cloud provider node class resources.

Validate:

- Pending pods trigger node provisioning.
- Nodes match workload requirements.
- Scale-down/consolidation behavior is understood.
- HPA and Karpenter work together under load.

### Phase 8: Argo Rollouts

Install:

- Argo Rollouts CRDs.
- Argo Rollouts controller.
- CLI plugin for operators.

Integrate:

- Replace or coordinate Deployment with Rollout.
- Add required stable and canary Services.
- Connect AnalysisTemplate to real Prometheus.

Validate:

- Rollout creates stable/canary ReplicaSets.
- Rollout pauses at configured steps.
- Manual promote and abort work.
- Bad canary can be stopped.

### Phase 9: Istio

Install:

- Istio control plane.
- Ingress gateway.
- Sidecar injection or ambient mesh mode.

Apply:

- `progressive-delivery/istio/gateway.yaml`
- `progressive-delivery/istio/virtual-service.yaml`
- `progressive-delivery/istio/destination-rule.yaml`

Validate:

- External traffic reaches the service.
- VirtualService routes traffic.
- DestinationRule subsets map to stable/canary pods.
- mTLS policy works as intended.

### Phase 10: Live Canary Validation

Run:

- A known-good canary.
- A deliberately bad canary in a non-prod environment.

Validate:

- Traffic shifts according to weights.
- Prometheus analysis gates progression.
- Alerts detect canary degradation.
- Abort returns traffic to stable.
- Git revert restores desired state.

### Phase 11: Live Autoscaling Validation

Run load tests.

Validate:

- HPA scales pods up.
- Scheduler places pods when capacity exists.
- Karpenter provisions nodes when capacity does not exist.
- Service remains available.
- Dashboards and alerts show scaling behavior.
- Scale-down does not remove capacity too aggressively.

## 14. Operational Lessons Learned

### Platform Engineering Is About Operational Systems

Platform engineering is not just writing YAML. It is designing a system where code, artifacts, policies, controllers, runtime signals, and human operations work together.

This repository demonstrates that a delivery platform must answer:

- How do changes enter the system?
- How are artifacts built?
- How are artifacts promoted?
- How is desired state stored?
- How is desired state reconciled?
- How are unsafe changes blocked?
- How are secrets supplied?
- How does the system scale?
- How does the system release safely?
- How does the team know whether production is healthy?
- How does the team recover?

### Architecture Reasoning Matters

Architecture reasoning matters because Kubernetes platforms contain many controllers. Each controller has a job:

- GitHub Actions validates and promotes.
- ArgoCD reconciles Git to Kubernetes.
- Kubernetes controllers maintain Deployments and Services.
- Kyverno admits or rejects resources.
- External Secrets synchronizes secrets.
- HPA changes replica counts.
- Karpenter provisions nodes.
- Argo Rollouts manages canary progression.
- Istio routes traffic.
- Prometheus observes metrics and evaluates alerts.

When something fails, engineers need to know which controller owns which behavior.

### Governance Matters

Governance turns standards into automatic enforcement. Without governance, best practices become suggestions.

The Kyverno policies in this repository protect reliability and security:

- Immutable tags protect rollback and auditability.
- Probes protect availability.
- Resources protect scheduling and autoscaling.
- Non-root execution protects runtime security.

### Progressive Delivery Matters

Progressive delivery accepts that not every defect is caught before production. The platform reduces blast radius by exposing changes gradually and using metrics to decide whether to continue.

This is operationally more mature than treating deploy success as release success. A deployment can be technically complete while the release is harming users. Canary delivery gives the platform time and evidence to stop.

### Observability Matters

Observability is the feedback system. Without metrics, logs, traces, alerts, and dashboards, operators cannot confidently decide whether to promote, pause, rollback, scale, or investigate.

Observability should be connected to:

- SLOs.
- Rollout gates.
- Incident runbooks.
- Autoscaling validation.
- Capacity planning.
- Post-incident learning.

### Rollback Matters

Rollback is not failure. Rollback is a core safety mechanism.

The platform makes rollback practical by:

- Using immutable image tags.
- Storing environment intent in Git.
- Keeping rollout history.
- Separating config from image builds.
- Using ArgoCD reconciliation.
- Documenting validation steps.

Fast rollback reduces user impact and gives engineers room to investigate calmly.

## 15. Repository Folder and File Map

This section maps the repository so future engineers, AI systems, maintainers, interview preparation sessions, and runtime integration work can quickly understand where each platform concern lives.

### `apps/`

What lives here: Application source code.

Current app:

- `apps/sample-go-service/`

The sample app exists to provide a deployable workload for the platform. It is intentionally small because the repository is focused on delivery architecture rather than business logic.

Important files:

- `apps/sample-go-service/cmd/server/main.go`: starts the HTTP server, configures JSON logging, registers handlers, and performs graceful shutdown.
- `apps/sample-go-service/internal/config/config.go`: reads runtime config from environment variables.
- `apps/sample-go-service/internal/handlers/handlers.go`: implements `/health`, `/ready`, `/version`, and `/config`.
- `apps/sample-go-service/internal/handlers/handlers_test.go`: tests handler behavior.
- `apps/sample-go-service/go.mod`: Go module definition used by CI.

How it connects:

- `Dockerfile` builds this application.
- GitHub Actions tests this application.
- Kubernetes manifests deploy the resulting image.
- ConfigMaps inject environment-specific runtime config.
- Probes call `/health` and `/ready`.
- Version/config endpoints help validate runtime state.

### `Dockerfile`

What lives here: Container build definition.

The Dockerfile:

- Uses `golang:1.22-alpine` as build stage.
- Downloads Go dependencies.
- Builds a static Linux binary.
- Uses `gcr.io/distroless/static-debian12:nonroot` for runtime.
- Runs as non-root.
- Exposes port `8080`.

Operational importance:

- Supports immutable image builds.
- Reduces runtime image surface area.
- Aligns with Kyverno non-root policy.
- Produces the artifact promoted through overlays.

### `deploy/`

What lives here: Kubernetes workload desired state.

#### `deploy/base/`

Base exists to define shared Kubernetes resources that should be common across environments:

- `deployment.yaml`: workload, probes, resources, security context, rolling update strategy, config/secret injection.
- `service.yaml`: stable ClusterIP Service on port 80 targeting container port `http`.
- `configmap.yaml`: default config values.
- `secret-example.yaml`: placeholder Secret showing expected secret name and shape.
- `kustomization.yaml`: includes base resources.

Why base exists:

- Avoids duplicating common manifests.
- Centralizes defaults.
- Makes environment overlays small and auditable.

#### `deploy/overlays/`

Overlays define environment-specific deployment intent.

`deploy/overlays/dev/`:

- Namespace: `sample-go-service-dev`
- Replicas: `1`
- Lower resource requests/limits.
- Debug logging.
- Release channel: `dev`
- Feature flag enabled.
- Image tag placeholder updated by dev promotion.

`deploy/overlays/staging/`:

- Namespace: `sample-go-service-staging`
- Replicas: `2`
- Medium resource requests/limits.
- Info logging.
- Release channel: `staging`
- Image tag promoted from dev.

`deploy/overlays/prod/`:

- Namespace: `sample-go-service-prod`
- Replicas: `3`
- Higher resource requests/limits.
- Info logging.
- Release channel: `stable`
- Image tag promoted from staging.

How image promotion changes overlays:

- Promotion workflows edit `kustomization.yaml` image fields.
- The application code and Docker image do not change during staging/prod promotion.
- Git records exactly when an environment changed image intent.

How ArgoCD consumes overlays:

- ArgoCD Applications point to overlay paths.
- ArgoCD renders those paths.
- ArgoCD applies the rendered manifests to the destination namespace.

### `argocd/`

What lives here: ArgoCD Application resources.

Files:

- `argocd/dev-application.yaml`: syncs `deploy/overlays/dev` into `sample-go-service-dev`; automated sync, prune, and self-heal enabled.
- `argocd/staging-application.yaml`: syncs `deploy/overlays/staging` into `sample-go-service-staging`; manual sync posture.
- `argocd/prod-application.yaml`: syncs `deploy/overlays/prod` into `sample-go-service-prod`; manual sync posture.

How ArgoCD connects Git to Kubernetes:

- Application source points at the Git repository and overlay path.
- Destination points at the in-cluster Kubernetes API and namespace.
- Sync policy determines how reconciliation happens.

Runtime note: These files require ArgoCD CRDs/controllers to be installed before they become active.

### `.github/workflows/`

What lives here: CI/CD automation.

Files:

- `.github/workflows/ci.yaml`: validates code, Dockerfile, image, manifests, and workflows.
- `.github/workflows/publish-and-promote-dev.yaml`: builds/pushes immutable image and updates dev overlay.
- `.github/workflows/promote-staging.yaml`: promotes dev image tag to staging.
- `.github/workflows/promote-prod.yaml`: promotes staging image tag to prod.

Which workflows validate:

- `ci.yaml`
- `publish-and-promote-dev.yaml` validation job
- Overlay render steps in promotion workflows

Which workflows publish:

- `publish-and-promote-dev.yaml`

Which workflows promote:

- `publish-and-promote-dev.yaml` promotes dev.
- `promote-staging.yaml` promotes staging.
- `promote-prod.yaml` promotes production.

How promotion commits update overlays:

- Workflows read source environment image fields with `yq`.
- Workflows verify immutable `sha-*` tags for staging/prod.
- Workflows edit target environment `kustomization.yaml`.
- Workflows commit and push the change to `main`.
- ArgoCD later reconciles the changed overlay.

### `policies/`

What lives here: Policy-as-code definitions.

#### `policies/kyverno/`

Policies:

- `disallow-latest-tag.yaml`: prevents mutable `latest` image tags.
- `require-probes.yaml`: requires readiness and liveness probes.
- `require-resources.yaml`: requires CPU/memory requests and limits.
- `require-nonroot.yaml`: requires pod-level non-root execution.

Operational failures prevented:

- Mutable artifacts.
- Unhealthy pods serving traffic.
- Unbounded resource usage.
- Broken HPA calculations.
- Root containers by default.

How policies connect to `deploy/`:

- `deploy/base/deployment.yaml` is written to satisfy the policies.
- Overlay resource patches preserve requests and limits.
- Promotion workflows support immutable tags.
- The Dockerfile and pod security context support non-root execution.

Runtime note: Policies require Kyverno to be installed.

### `external-secrets/`

What lives here: External Secrets Operator reference manifests.

#### `external-secrets/base/cluster-secret-store.yaml`

Defines how External Secrets Operator should connect to AWS Secrets Manager.

Purpose:

- Treat AWS Secrets Manager as the source of truth.
- Use Kubernetes service account based authentication in a future EKS integration.
- Provide a cluster-scoped store that ExternalSecrets can reference.

#### `external-secrets/base/external-secret.yaml`

Defines which remote AWS secret properties should become a Kubernetes Secret.

Purpose:

- Create `sample-go-service-secret`.
- Map remote properties such as `API_KEY` and `DATABASE_PASSWORD`.
- Refresh values every hour.

How AWS Secrets Manager becomes source of truth:

- AWS owns the secret value.
- External Secrets Operator reads it.
- Kubernetes receives a generated Secret.
- Pods consume the generated Secret.

How `deploy/base` consumes generated Kubernetes Secret:

- `deploy/base/deployment.yaml` uses `envFrom.secretRef` for `sample-go-service-secret`.

Runtime note: The current base also includes `secret-example.yaml` as a placeholder. In production, generated secrets should replace manual secret management.

### `autoscaling/`

What lives here: Autoscaling reference resources.

#### `autoscaling/hpa/sample-go-service-hpa.yaml`

Defines:

- HPA target: `Deployment/sample-go-service`
- Min replicas: `2`
- Max replicas: `10`
- CPU target: `70%`
- Memory target: `75%`

How it depends on resource requests:

- HPA calculates utilization against requests.
- The base and overlays must define realistic CPU/memory requests.

How it connects to Karpenter readiness:

- HPA increases pod count.
- Scheduler tries to place pods.
- If nodes lack capacity, pods become Pending.
- Karpenter can later provision nodes for those Pending pods.

Runtime note: HPA requires metrics-server and must be applied/integrated into the environment manifests.

### `progressive-delivery/`

What lives here: Progressive delivery and service mesh reference resources.

#### `progressive-delivery/argo-rollouts/`

Files:

- `rollout.yaml`: Argo Rollouts canary workload definition.
- `analysis-template.yaml`: Prometheus success-rate analysis definition.

What Argo Rollouts files do:

- Define canary steps.
- Define stable/canary services.
- Connect rollout to Istio traffic routing.
- Provide a metric gate for rollout health.

#### `progressive-delivery/istio/`

Files:

- `gateway.yaml`: external HTTP entry point.
- `virtual-service.yaml`: weighted route between stable and canary subsets.
- `destination-rule.yaml`: stable/canary subsets and mTLS policy.

How these connect:

- Gateway receives traffic for `sample.example.com`.
- VirtualService routes traffic to `sample-go-service` stable/canary subsets.
- DestinationRule maps subsets to pod labels.
- Rollout tells Istio which weights to use during canary progression.
- AnalysisTemplate checks Prometheus metrics to decide health.

Runtime note: Requires Argo Rollouts, Istio, Prometheus, stable/canary Services, and overlay integration.

### `observability/`

What lives here: Metrics, alerts, and dashboard planning.

#### `observability/prometheus/service-monitor.yaml`

Defines:

- Prometheus Operator scrape configuration.
- Service selector for `sample-go-service`.
- Namespace selector for `sample-go-service-prod`.
- `/metrics` scrape path.

What it does:

- Tells Prometheus how to discover and scrape the service.

Runtime note: Requires Prometheus Operator CRDs and an application metrics endpoint.

#### `observability/prometheus/prometheus-rules.yaml`

Defines alerts for:

- High error rate.
- High latency.
- Frequent pod restarts.
- Degraded canary.

How metrics/alerts connect to rollout decisions and runbooks:

- Rollout analysis can use Prometheus success/error metrics.
- Alerts tell operators when to investigate or rollback.
- Runbooks define the response steps.

#### `observability/grafana/dashboard-summary.md`

Describes the dashboards operators should have for:

- Service health.
- Rollouts.
- Autoscaling.
- Resource usage.
- SLOs.

### `operations/`

What lives here: Operational validation and incident response material.

#### `operations/validation/`

Files:

- `deployment-validation.md`
- `platform-validation-checklist.md`
- `promotion-validation.md`
- `rollback-validation.md`

What validation docs do:

- Explain what to check before and after deployment.
- Turn architecture into repeatable operator action.
- Provide readiness criteria for runtime integration.

#### `operations/incidents/`

Files:

- `failed-canary-rollout.md`
- `hpa-scaling-failure.md`
- `image-promotion-failure.md`
- `secrets-sync-failure.md`

What incident runbooks do:

- Guide triage.
- Identify likely failure domains.
- Provide containment and rollback paths.
- Preserve learning for follow-up improvements.

Why Day-2 operations matter:

- Platforms fail in real ways after installation.
- Runbooks reduce panic and inconsistency.
- Operators need known paths for diagnosis, containment, rollback, and validation.

How operators use this folder during production issues:

- Start with the incident-specific runbook.
- Check the validation docs after containment.
- Confirm the system has returned to desired state.
- Record follow-up improvements in platform docs or manifests.

### `docs/`

What lives here: Focused architecture and operations documents.

Major docs:

- `architecture.md`: baseline architecture.
- `platform-architecture-summary.md`: concise platform summary.
- `build-once-deploy-many.md`: immutable artifact and promotion model.
- `promotion-flow.md`: environment promotion details.
- `devsecops-validation.md`: validation and security checks.
- `config-injection.md`: ConfigMap and runtime config model.
- `policy-as-code.md`: governance model.
- `kyverno-operations.md`: Kyverno operational guidance.
- `external-secrets-architecture.md`: External Secrets architecture.
- `aws-secrets-manager-integration.md`: AWS Secrets Manager integration.
- `autoscaling-architecture.md`: autoscaling design.
- `hpa-vs-karpenter.md`: pod vs node scaling.
- `scaling-operations.md`: scaling operations.
- `progressive-delivery-foundation.md`: progressive delivery foundation.
- `progressive-delivery.md`: progressive delivery details.
- `argo-rollouts-vs-canary.md`: Rollouts and canary concepts.
- `istio-traffic-management.md`: Istio routing model.
- `canary-runbook.md`: canary operations.
- `rollback-runbook.md`: rollback operations.
- `observability-architecture.md`: observability system design.
- `rollout-observability.md`: rollout metrics and decision signals.
- `alerting-runbook.md`: alert response guidance.
- `slo-readiness.md`: SLO preparation.
- `operational-readiness.md`: readiness criteria.
- `day-2-operations.md`: ongoing operations.
- `COMPLETE_SYSTEM_OVERVIEW.md`: this master handbook.

How docs support runtime integration and interview explanation:

- They explain not just what files exist, but why the architecture exists.
- They provide language for explaining platform engineering decisions.
- They map operational problems to controller responsibilities.
- They preserve the distinction between repository-ready and runtime-installed.

### `scripts/`

What lives here: Lightweight explanatory and validation scripts.

Files:

- `scripts/validate-platform-foundation.sh`: prints the platform validation sequence.
- `scripts/test-policies.sh`: renders overlays and lists Kyverno policies that would evaluate workloads.
- `scripts/explain-secret-flow.sh`: explains AWS Secrets Manager to pod secret flow.
- `scripts/explain-autoscaling-flow.sh`: explains traffic spike to HPA/Karpenter flow.
- `scripts/explain-progressive-delivery-flow.sh`: explains canary release flow.
- `scripts/explain-observability-flow.sh`: explains metrics, alerts, dashboards, rollout analysis, and runbooks.

What each script explains or validates:

- They are educational and operational aids.
- They do not install controllers.
- They do not mutate live clusters.
- They help future maintainers rehearse the platform mental model.

How scripts support learning and operations:

- New engineers can run them to understand flows.
- AI systems can read them as compact operational explanations.
- Operators can use them as preflight mental checklists before deeper validation.

## Return Summary

### Sections Created

This master handbook includes:

1. Project Overview
2. High-Level Platform Architecture
3. Build Once Deploy Many
4. GitHub Actions CI/CD Architecture
5. ArgoCD GitOps Architecture
6. Kyverno Policy Architecture
7. External Secrets Architecture
8. Autoscaling Architecture
9. Progressive Delivery Architecture
10. Observability Architecture
11. Operational Validation and Incident Response
12. Runtime Integration Status
13. Runtime Integration Roadmap
14. Operational Lessons Learned
15. Repository Folder and File Map

### Architecture Coverage Summary

The document covers the complete platform flow from developer change through CI, immutable image creation, registry storage, Kustomize overlay promotion, ArgoCD reconciliation, Kubernetes runtime behavior, Kyverno admission governance, External Secrets synchronization, HPA pod scaling, Karpenter node scaling readiness, Argo Rollouts canary delivery, Istio traffic routing, Prometheus/Grafana observability, and operational validation.

### Operational Systems Covered

Operational systems covered include:

- CI validation.
- Artifact immutability.
- GitOps reconciliation.
- Drift detection.
- Runtime admission policy.
- Secret synchronization.
- Pod autoscaling.
- Node provisioning readiness.
- Progressive delivery.
- Traffic routing.
- Metrics and alerting.
- Dashboarding.
- SLO readiness.
- Rollback.
- Incident response.
- Day-2 operations.

### Runtime Integration Readiness Summary

The repository is ready as a platform architecture foundation. It contains desired-state manifests, workflows, policies, and operational guidance. It still requires live installation and configuration of ArgoCD, Kyverno, External Secrets Operator, metrics-server, Prometheus/Grafana, Karpenter, Argo Rollouts, Istio, logging/tracing systems, runtime credentials, CRDs, RBAC, and live validation before it becomes a fully active production delivery platform.
