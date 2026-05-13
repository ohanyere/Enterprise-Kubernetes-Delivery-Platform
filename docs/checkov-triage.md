# Checkov Kubernetes Triage

## Scope

This triage covers the current Checkov Kubernetes scan for `deploy/`.

Two scan views were used:

- Raw directory scan: `checkov --directory deploy --framework kubernetes`
- Rendered overlay scan: `kubectl kustomize deploy/overlays/{dev,staging,prod}` followed by Checkov against the rendered output

The raw directory scan reported 74 failures. Most of those failures came from Checkov evaluating Kustomize base files and strategic merge patch fragments as standalone Kubernetes resources. The rendered overlay scan reduced the real deployed findings to 12 findings across four check families.

## Decision Summary

| Category | Checks | Decision |
| --- | --- | --- |
| MUST_FIX_NOW | `CKV2_K8S_6` | Added a `NetworkPolicy` to the base manifests so all overlays deploy an associated policy. |
| ACCEPTABLE_FOR_CURRENT_PHASE | `CKV_K8S_15` | Kept `IfNotPresent` because the platform promotes immutable `sha-*` image tags and does not rely on mutable `latest` for promoted environments. |
| FUTURE_HARDENING | `CKV_K8S_35`, `CKV_K8S_43` | Documented and explicitly skipped until the secrets and release-digest phases are integrated. |
| FALSE_POSITIVE | Patch/base namespace and inherited pod-hardening findings from the raw scan | CI now scans rendered overlays, where inherited security context, probes, namespaces, and image settings are visible to Checkov. |

## MUST_FIX_NOW

### `CKV2_K8S_6` - Pods Lack Associated NetworkPolicy

- Resource affected: `Deployment.sample-go-service-{dev,staging,prod}.sample-go-service` and the resulting Pods.
- Why it failed: No `NetworkPolicy` selected the application Pods in the rendered overlays.
- Operational/security risk: Without a NetworkPolicy, clusters with a policy-enforcing CNI may allow broader lateral movement than intended if another workload in the cluster is compromised.
- Production enforcement: Commonly enforced on production platforms, especially in multi-tenant or regulated clusters.
- Recommended action: Fixed now. Added `deploy/base/networkpolicy.yaml` with an ingress policy for the service HTTP port so every overlay deploys an associated policy.

## ACCEPTABLE_FOR_CURRENT_PHASE

### `CKV_K8S_15` - Image Pull Policy Should Be Always

- Resource affected: `Deployment.sample-go-service-{dev,staging,prod}.sample-go-service`.
- Why it failed: The Deployment uses `imagePullPolicy: IfNotPresent`.
- Operational/security risk: With mutable tags, a node could reuse a stale cached image. That risk is materially reduced when images are promoted by immutable `sha-*` tags.
- Production enforcement: Some platforms enforce `Always`, especially where mutable tags are permitted. Platforms that require immutable tags or digests commonly allow `IfNotPresent` to reduce registry dependency and startup latency.
- Recommended action: Accepted for the current phase. Keep `IfNotPresent` while the platform uses immutable promotion tags. Revisit if mutable tags are introduced.
- CI handling: Explicit Checkov skip annotation added to the Deployment with the immutable-tag rationale.

## FUTURE_HARDENING

### `CKV_K8S_35` - Prefer Secrets as Files Over Environment Variables

- Resource affected: `Deployment.sample-go-service-{dev,staging,prod}.sample-go-service`.
- Why it failed: The application consumes `sample-go-service-secret` through `envFrom.secretRef`.
- Operational/security risk: Secret values exposed as environment variables can appear in process environments and may be harder to rotate without restarting Pods.
- Production enforcement: Mature platforms often prefer mounted secret files, CSI Secret Store, or sidecar-driven refresh patterns for high-sensitivity secrets.
- Recommended action: Defer to the runtime secrets integration phase. The current platform already keeps AWS Secrets Manager as the source of truth and uses External Secrets Operator to materialize Kubernetes Secrets.
- CI handling: Explicit Checkov skip annotation added to the Deployment with the later file/CSI projection rationale.

### `CKV_K8S_43` - Image Should Use Digest

- Resource affected: `Deployment.sample-go-service-{dev,staging,prod}.sample-go-service`.
- Why it failed: Images are referenced by repository plus tag, not by digest.
- Operational/security risk: Tags can be moved at the registry, while digests identify exact image content.
- Production enforcement: Strong production platforms often enforce digest pinning or signed provenance after registry publishing and promotion metadata are fully integrated.
- Recommended action: Defer until the release workflow records and promotes registry digests. The current phase preserves build-once-deploy-many by promoting immutable `sha-*` tags and forbidding `latest` for promoted overlays.
- CI handling: Explicit Checkov skip annotation added to the Deployment with the digest-promotion rationale.

## FALSE_POSITIVE

These findings are not accepted as real deployed risk. They are artifacts of scanning Kustomize source fragments directly instead of rendered manifests.

### Raw Base Namespace Findings

- Check ID: `CKV_K8S_21`
- Resources affected: `Deployment.default.sample-go-service`, `Service.default.sample-go-service`, `ConfigMap.default.sample-go-service-config`, `Secret.default.sample-go-service-secret`.
- Why it failed: The base resources do not set `metadata.namespace`.
- Operational/security risk if real: Applying resources to `default` weakens environment isolation.
- Production enforcement: Commonly enforced.
- Recommended action: Treat as false positive for this repository because overlays inject `sample-go-service-dev`, `sample-go-service-staging`, and `sample-go-service-prod`. CI now scans rendered overlays so namespaces are visible.

### Kustomize Patch Fragment Findings

- Check IDs: `CKV_K8S_8`, `CKV_K8S_9`, `CKV_K8S_14`, `CKV_K8S_15`, `CKV_K8S_20`, `CKV_K8S_21`, `CKV_K8S_22`, `CKV_K8S_23`, `CKV_K8S_28`, `CKV_K8S_29`, `CKV_K8S_30`, `CKV_K8S_31`, `CKV_K8S_37`, `CKV_K8S_38`, `CKV_K8S_40`, `CKV_K8S_43`.
- Resources affected: `deploy/overlays/{dev,staging,prod}/patch-replicas.yaml` and `deploy/overlays/{dev,staging,prod}/patch-resources.yaml` when interpreted as standalone `Deployment.default.sample-go-service` resources.
- Why it failed: The patch files intentionally contain only the fields they modify, such as replicas or resources. They inherit probes, namespace, non-root user, seccomp, service-account token settings, capability drops, read-only root filesystem, and image configuration from the base plus overlay rendering.
- Operational/security risk if real: These would be serious workload hardening gaps if the fragments were deployable manifests.
- Production enforcement: Production platforms typically enforce these controls on rendered workload manifests or through admission policy.
- Recommended action: Treat as false positive for raw source scanning. CI now renders each overlay and scans the rendered manifests, preserving strict scanning against deployable output rather than suppressing the checks globally.

## Platform Security Rationale

The platform remains strict where the rendered deployment surface shows real risk. Workload hardening continues to include non-root execution, high UID, dropped Linux capabilities, no privilege escalation, read-only root filesystem, disabled service-account token automount, seccomp `RuntimeDefault`, CPU and memory requests/limits, readiness and liveness probes, and immutable image promotion tags.

Kyverno remains the runtime governance layer for admission-time enforcement. Checkov remains a CI guardrail, now pointed at rendered manifests so it evaluates the same objects that promotion workflows deploy.

## GitHub Actions Workflow Findings

### `CKV2_GHA_1` - Ensure Top-Level Permissions Are Not Set To Write-All

- Resources affected: `on(Promote Staging)` in `.github/workflows/promote-staging.yaml` and `on(Promote Production)` in `.github/workflows/promote-prod.yaml`.
- Why it failed: The workflows granted `contents: write` at the job level, but did not declare an explicit top-level permissions baseline. Checkov expects workflow-level permissions to avoid implicit broad token defaults.
- Operational/security risk: A workflow without an explicit top-level token boundary can make future jobs inherit broader permissions than intended, increasing blast radius if a step or dependency is compromised.
- Production enforcement: Commonly enforced. Enterprise GitHub Actions baselines usually require top-level read-only permissions and job-level write permissions only where commits, releases, or deployments require them.
- Remediation: Added top-level `permissions: contents: read` to both manual promotion workflows. Kept job-level `permissions: contents: write` only on the promotion jobs because they intentionally commit the overlay image tag update.
- Final design: Manual promotion behavior is unchanged. Staging still copies the immutable `sha-*` image from dev, production still copies the immutable `sha-*` image from staging, and neither workflow rebuilds images, uses `latest`, force pushes, or changes promotion semantics.
