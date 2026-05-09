# Enterprise Kubernetes Delivery Platform

This project is a production-style Kubernetes delivery platform template. It is not a business app. The sample Go service is intentionally small so the repository can focus on deployment architecture, GitOps, promotion, rollback, and operational clarity.

## Why This Exists

Teams often start with Kubernetes manifests that work for one environment but become hard to promote, audit, and roll back. This repository provides a clean foundation for platform engineering practices:

- Build once, deploy many.
- Immutable Docker image tags.
- Dev, staging, and prod Kustomize overlays.
- GitOps reconciliation with ArgoCD.
- Runtime config injection through ConfigMaps and Secrets.
- DevSecOps validation from the first workflow.
- Promotion through Git changes.
- Rollback by Git revert.
- Readiness for policy-as-code, autoscaling, and progressive delivery.

## Operational Problem Solved

The platform separates application build artifacts from environment-specific deployment intent. CI builds and validates a single image. Git records which image and config each environment should run. ArgoCD reconciles clusters from that desired state.

That means production changes become reviewable, repeatable, and reversible.

## Build Once, Deploy Many

The same image tag should move from dev to staging to prod. Do not rebuild the service for each environment. Environment-specific behavior comes from ConfigMaps, Secrets, replicas, resources, and overlay patches.

The base image placeholder is:

```text
docker.io/ohanyere/sample-go-service:replace-me
```

Each overlay has an `images` block ready for promotion by replacing `newTag` with an immutable tag such as a Git commit SHA.

## Environment Overlays

Kustomize overlays live under `deploy/overlays`:

- `dev`: 1 replica, debug logs, `RELEASE_CHANNEL=dev`
- `staging`: 2 replicas, info logs, `RELEASE_CHANNEL=staging`
- `prod`: 3 replicas, info logs, `RELEASE_CHANNEL=stable`

The Go code does not hardcode environment-specific values.

## GitOps Promotion

ArgoCD Applications live in `argocd`:

- Dev points to `deploy/overlays/dev` and uses automated sync.
- Staging points to `deploy/overlays/staging` and does not auto-sync by default.
- Prod points to `deploy/overlays/prod` and does not auto-sync by default.

Promotion is a pull request that updates the target overlay image tag.

## Config Injection

The service reads runtime config from environment variables:

- `APP_ENV`
- `LOG_LEVEL`
- `RELEASE_CHANNEL`
- `APP_VERSION`
- `COMMIT_SHA`
- `FEATURE_FLAG_EXAMPLE`

Kubernetes injects those values from ConfigMaps. A Secret example exists only to show where secret injection belongs. Do not commit real secrets.

## Rollback By Git Revert

To roll back a bad deployment, revert the Git commit that changed the overlay image tag or config. ArgoCD will reconcile the environment back to the previous desired state.

## DevSecOps Validation

The initial CI workflow is validation-only. It checks Go formatting, vetting, and tests; builds the Docker image without pushing it; scans the Dockerfile with Hadolint; scans the built image with Trivy; renders all Kustomize overlays; and runs Checkov against Kubernetes manifests and GitHub Actions workflows.

Terraform scanning is intentionally not included because this repository does not contain Terraform yet.

## Run Locally

```bash
cd apps/sample-go-service
APP_ENV=local \
LOG_LEVEL=debug \
RELEASE_CHANNEL=local \
APP_VERSION=0.0.0-local \
COMMIT_SHA=local \
FEATURE_FLAG_EXAMPLE=true \
go run ./cmd/server
```

Then call:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/ready
curl http://localhost:8080/version
curl http://localhost:8080/config
```

## Build Docker Image

```bash
docker build -t docker.io/ohanyere/sample-go-service:local .
```

## Render Manifests

```bash
kustomize build deploy/overlays/dev
kustomize build deploy/overlays/staging
kustomize build deploy/overlays/prod
```

## Project Status

This is the clean foundation only. It intentionally does not install Istio, Argo Rollouts, Kyverno, External Secrets, HPA, or Karpenter yet.
