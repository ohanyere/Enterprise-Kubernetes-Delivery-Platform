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

## Later Phases

Staging and prod are not promoted yet. Future phases can promote the same immutable SHA tag into `deploy/overlays/staging` and `deploy/overlays/prod` with manual approvals. The build-once-deploy-many rule remains the same: build one image, then promote that exact image by changing Git.
