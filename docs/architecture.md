# Architecture

This repository is a platform engineering template for delivering Kubernetes workloads with a production-style workflow. The sample Go service is intentionally small so the deployment architecture remains the main artifact.

The core model is:

1. Build one immutable container image.
2. Promote that exact image tag through environment overlays.
3. Let ArgoCD reconcile each environment from Git.
4. Roll back by reverting the Git commit that changed an overlay.

The initial foundation includes readiness for policy-as-code, autoscaling, and progressive delivery without installing those tools yet. Future additions can introduce Kyverno or Gatekeeper policies, HorizontalPodAutoscalers, Argo Rollouts, service mesh traffic shifting, or external secret management as separate platform capabilities.

## Components

- `apps/sample-go-service`: Small HTTP service with health, readiness, version, and runtime config endpoints.
- `deploy/base`: Shared Kubernetes manifests for the service.
- `deploy/overlays`: Environment-specific Kustomize overlays for dev, staging, and prod.
- `argocd`: One ArgoCD Application per environment.
- `.github/workflows/ci.yaml`: Validation for Go, Docker, Kustomize, and initial DevSecOps checks.

## Delivery Principles

- Images are immutable and should be tagged with commit SHA or release identifiers.
- Environment configuration lives outside the application binary.
- Promotion is a Git change to an overlay, not a rebuild.
- Rollback is a Git revert, then ArgoCD reconciliation.
- Security checks start in CI with Hadolint, Trivy, and Checkov before dedicated policy engines are added.
