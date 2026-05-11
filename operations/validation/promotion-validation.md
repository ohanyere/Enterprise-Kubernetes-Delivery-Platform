# Promotion Validation

Promotion validation confirms that the platform moves one immutable artifact through environments by changing Git deployment intent, not by rebuilding the application.

## Validate Dev Promotion

- Confirm the CI workflow built and validated the image from the expected source commit.
- Confirm the dev overlay references the immutable image tag for that commit.
- Render `deploy/overlays/dev` and verify the image resolves to the promoted tag.
- Confirm ArgoCD points dev at the dev overlay.

Expected result: dev runs the new image first, with a clear link back to the Git commit and workflow run that produced it.

## Validate Staging Promotion

- Confirm the staging promotion uses the same image tag already validated in dev.
- Review the pull request or commit that updates `deploy/overlays/staging`.
- Render the staging overlay and compare the image tag with dev.
- Confirm staging-specific config, replicas, and resources remain environment-specific.

Expected result: staging receives the dev-validated artifact without rebuilding or changing application code.

## Validate Production Promotion

- Confirm production promotion uses the image already validated in dev and staging.
- Review the production overlay change for minimal scope: image tag only unless a config change is intentional.
- Confirm prod ArgoCD sync behavior matches the platform's approval model.
- Confirm rollout, observability, and rollback paths are ready before sync.

Expected result: production promotion is auditable, intentionally approved, and tied to a known artifact.

## Immutable SHA Verification

- Use commit SHA tags or another immutable digest-based reference.
- Verify the overlay image tag matches the source commit expected for the release.
- Confirm no environment rebuild produces a different image for the same release.
- Prefer registry digest verification when live registry access is available.

Expected result: operators can prove which source revision is running in each environment.

## Rollback Validation

- Identify the Git commit that promoted the bad image.
- Confirm the previous known-good image tag is visible in Git history.
- Revert the promotion commit and allow ArgoCD to reconcile the target environment.
- Validate pods return to the previous image and service health recovers.

Expected result: rollback is a Git operation with a predictable cluster outcome.
