# Kyverno Operations

Kyverno runs as a Kubernetes admission controller. After installation, it registers webhooks with the API server so create and update requests can be evaluated before Kubernetes stores the requested object.

## Request Interception

When a user, CI job, GitOps controller, or automation tool submits a Kubernetes object, the API server sends an admission review to Kyverno for matching resources. Kyverno evaluates the object against installed policies and returns an allow or deny response for validation rules.

For GitOps platforms, this means unsafe manifests can be rejected even if they exist in Git. Git remains the source of desired state, and Kyverno becomes a cluster-side safety boundary.

## Policy Evaluation

Kyverno policies match resources by kind, namespace, labels, and other selectors. A `ClusterPolicy` can apply across the whole cluster. Each rule evaluates the incoming object against patterns, deny conditions, or other validation logic.

The policies in `policies/kyverno` match Pods. Kyverno can automatically generate equivalent validation for common Pod controllers such as Deployments, StatefulSets, DaemonSets, Jobs, and CronJobs, so platform standards apply to workload controllers rather than only raw Pods.

## Audit vs Enforce

In `Audit` mode, a policy reports violations but allows the request. This is useful when introducing governance to an existing cluster because teams can see what would break before enforcement begins.

In `Enforce` mode, a policy denies non-compliant requests. The policies in this repository use `validationFailureAction: Enforce` because they represent baseline safety rules: no mutable latest tags, required resources, non-root execution, and health probes.

## Risks of Weak Governance

Weak governance allows unsafe defaults to spread through the platform. Common failures include workloads without resource limits consuming shared node capacity, images changing unexpectedly under mutable tags, root containers increasing compromise impact, and missing probes causing broken pods to receive traffic.

Kyverno reduces those risks by making operational standards automatic, consistent, and visible. It does not replace review or observability, but it catches classes of errors before they reach runtime.
