# Incident Runbook: HPA Scaling Failure

## Symptoms

- HPA does not increase replicas during load.
- HPA status shows unknown metrics.
- New replicas remain Pending.
- Pods are throttled, evicted, or repeatedly restarted.
- Service latency increases during traffic spikes.

## Pending Pods

Pending pods indicate the scheduler cannot place requested replicas.

Check:

- Pod events for scheduling failures.
- Node CPU, memory, taints, and topology constraints.
- Resource requests compared with available capacity.
- Whether Karpenter or another node autoscaler is installed and healthy.

Recover by adding capacity, reducing impossible scheduling constraints, or adjusting resource requests after validating workload needs.

## Missing Requests

HPA requires meaningful CPU and memory requests for utilization-based scaling.

Check:

- Container `resources.requests.cpu`.
- Container `resources.requests.memory`.
- Kyverno policy compliance for required requests and limits.
- Whether a recent manifest change removed resource fields.

Recover by restoring requests and limits through Git and allowing ArgoCD to reconcile.

## Insufficient Cluster Capacity

HPA can request more replicas than the cluster can run. Pod autoscaling and node autoscaling must work together.

Check:

- Node autoscaler events and provisioning status.
- Instance type or node pool constraints.
- Quotas and cloud provider capacity errors.
- Pending pods by workload and namespace.

Recover by restoring cluster capacity, widening allowed capacity choices, or temporarily reducing load.

## Metrics Issues

If metrics are unavailable, HPA cannot make scaling decisions.

Check:

- Metrics Server availability.
- HPA status conditions.
- Prometheus or adapter health if custom metrics are used.
- Target metric names and selectors.

Recover by restoring metrics collection first. Avoid tuning HPA thresholds until the metrics path is healthy.
