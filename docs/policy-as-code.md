# Policy as Code

Policy as code turns platform rules into versioned, reviewable, testable files. Instead of relying on tribal knowledge or one-time manual checks, the cluster can reject unsafe workloads at admission time and continuously report existing resources that drift from the standard.

## Why Platform Teams Use Kyverno

Kyverno is designed for Kubernetes-native policy. Policies are Kubernetes resources, written in YAML, and evaluated by a controller running inside the cluster. Platform teams use it because it fits GitOps workflows: policy definitions can be reviewed, promoted, and rolled back like application manifests.

This phase defines Kyverno `ClusterPolicy` resources only. It does not install Kyverno or enable live admission enforcement yet.

## Admission Controller Architecture

When a client sends a create or update request to the Kubernetes API server, admission controllers can inspect the object before it is persisted. Kyverno registers admission webhooks with the API server. Matching policies evaluate the requested object and either allow it, deny it, mutate it, or generate related resources depending on policy type.

The policies in this repository are validation policies. They are intended to deny unsafe workloads before they enter the cluster.

## Policies Defined

`disallow-latest-tag` prevents containers from using `:latest`. Mutable tags make deployments non-reproducible, hide what code is actually running, and make rollback unreliable because the same tag can point to different images over time.

`require-resources` requires CPU and memory requests and limits. Missing resource controls create noisy-neighbor failures, poor scheduling decisions, and uncontrolled consumption during traffic spikes or application bugs.

`require-nonroot` requires `runAsNonRoot: true`. Running as root increases the blast radius of application compromise and raises the risk of privilege escalation or container breakout paths.

`require-probes` requires liveness and readiness probes. Without probes, Kubernetes cannot tell whether a container should receive traffic or be restarted after becoming unhealthy.

## Why Governance Matters

Kubernetes makes it easy for many teams to deploy quickly, but speed without guardrails creates platform risk. A single unsafe workload can exhaust node resources, break shared services, or make incident response harder. Governance gives teams clear boundaries while preserving self-service deployment.

These policies encode operational standards close to the platform. They prevent known failure modes before they become production incidents.
