# Promotion Flow

Promotion is represented as a Git change to the desired environment overlay. Phase 2 promotes only the dev environment.

## Dev Promotion

On every push to `main`, the `Publish and Promote Dev` workflow validates the service, builds one Docker image, pushes it to Docker Hub, and updates only the dev overlay.

The immutable image tag is:

```text
sha-<git-commit-sha>
```

The workflow also pushes `latest` for convenience, but environment promotion uses the immutable SHA tag. Dev receives the exact image built from the commit. No environment-specific rebuild happens.

## GitOps Reconciliation

The workflow updates `deploy/overlays/dev/kustomization.yaml`:

```yaml
images:
  - name: docker.io/kuperpull/sample-go-service
    newName: docker.io/kuperpull/sample-go-service
    newTag: sha-<git-commit-sha>
```

ArgoCD watches `deploy/overlays/dev` through the dev Application. Because dev has automated sync enabled, ArgoCD reconciles the dev cluster to the promoted image after the promotion commit reaches `main`.

## Rollback

Rollback is done by reverting the Git commit that changed the dev overlay image tag. After the revert is merged or pushed to `main`, ArgoCD syncs dev back to the previous immutable image tag.

## Phase 3: Promote Dev to Staging

Dev receives the image automatically from CI when the `Publish and Promote Dev` workflow builds and publishes a SHA-tagged Docker image, then updates `deploy/overlays/dev/kustomization.yaml`.

Staging promotion is manual. The `Promote Staging` workflow is started with `workflow_dispatch` and copies the exact same immutable `newName` and `newTag` from the dev overlay into `deploy/overlays/staging/kustomization.yaml`.

The workflow does not rebuild the Docker image, create a new tag, or use `latest` for staging. It promotes the artifact that was already tested in dev, proving the build-once-deploy-many model: build one image, then deploy that same image through environments by changing Git.

Rollback is performed by reverting the staging promotion commit. After the revert reaches `main`, GitOps reconciliation returns staging to the previous immutable image tag.

## Production Promotion Flow

Production only promotes images that have already been promoted to staging. The `Promote Production` workflow is manual and reads the exact `newName` and `newTag` from `deploy/overlays/staging/kustomization.yaml`, validates that the tag is an immutable `sha-*` tag and not `latest`, and copies those values into `deploy/overlays/prod/kustomization.yaml`.

The workflow does not rebuild the image or create a production-specific tag. This preserves the evidence gathered in lower environments: the artifact that reached production is the same artifact that passed dev and staging.

Rollback is performed by reverting the production promotion commit. Because the desired production image is stored in Git, reverting returns prod to the previous immutable image tag and lets GitOps reconciliation apply that state.

Rebuilding per environment is dangerous because the resulting images can differ even when the source commit is the same. Dependency resolution, base image updates, build cache differences, timestamps, or build tooling changes can create a production artifact that staging never tested. Promotion should move a known artifact, not recreate one.

## Later Phases

Future phases can add progressive delivery controllers and traffic management while keeping the same build-once-deploy-many rule: build one image, then promote that exact image by changing Git.
