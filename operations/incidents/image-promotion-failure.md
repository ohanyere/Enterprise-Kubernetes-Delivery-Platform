# Incident Runbook: Image Promotion Failure

## Symptoms

- ArgoCD cannot sync the target environment.
- Pods fail with `ImagePullBackOff` or `ErrImagePull`.
- Rendered manifests reference an unexpected image tag.
- Deployment or Rollout status shows no available replicas after promotion.
- The promoted image cannot be found in the registry.

## Invalid Image Tag

An invalid tag usually means the overlay was updated with a malformed, mutable, or mistyped value.

Check:

- The target overlay `images` block.
- The promotion commit diff.
- The CI output that produced the intended tag.

Recover by correcting the overlay to a valid immutable tag or reverting the promotion commit.

## Missing Image

A missing image means the overlay references a tag that does not exist in the registry or is not accessible from the cluster.

Check:

- Registry artifact existence.
- Image pull permissions.
- Repository name and registry hostname.
- Whether CI pushed the image after building it.

Recover by promoting an existing known-good image or fixing the registry publication path before retrying.

## SHA Mismatch

A SHA mismatch means the image tag in the overlay does not correspond to the commit operators expected to release.

Check:

- Commit SHA in the promotion request.
- Image tag in dev, staging, and prod overlays.
- Workflow run associated with the image build.
- Registry metadata when available.

Recover by stopping promotion until the intended artifact is identified. Do not promote a tag that cannot be traced to source.

## Broken Deployment References

Broken references can occur when image names, container names, Rollout templates, or Kustomize patches no longer align.

Check:

- Kustomize render output for the target overlay.
- Container names in patches and base manifests.
- Argo Rollouts pod template image references.
- Service selectors and pod labels after render.

Recover by fixing the Git manifest reference and allowing ArgoCD to reconcile from Git.
