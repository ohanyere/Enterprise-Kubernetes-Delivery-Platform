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
  - name: docker.io/ohanyere/sample-go-service
    newName: <registry>/<username>/<image>
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

## Later Phases

Prod is not promoted yet. A future phase can promote the same immutable SHA tag into `deploy/overlays/prod` with manual approval. The build-once-deploy-many rule remains the same: build one image, then promote that exact image by changing Git.
