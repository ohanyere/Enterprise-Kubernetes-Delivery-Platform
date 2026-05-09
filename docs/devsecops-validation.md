# DevSecOps Validation

The first CI workflow is validation-only. It does not push Docker images, promote image tags, add Terraform, or change the build-once-deploy-many flow.

## Go

- `gofmt` check
- `go vet ./...`
- `go test ./...`

## Docker

- Build the sample service image with an immutable commit SHA tag.
- Scan the Dockerfile with Hadolint.
- Scan the locally built image with Trivy.

## Kubernetes

- `kustomize build deploy/overlays/dev`
- `kustomize build deploy/overlays/staging`
- `kustomize build deploy/overlays/prod`

## Security Scanning

- Checkov scans Kubernetes manifests under `deploy/`.
- Checkov scans GitHub Actions workflows under `.github/workflows/`.
- Terraform is intentionally excluded because this repository does not contain Terraform yet.
