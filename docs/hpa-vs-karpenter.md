# HPA vs Karpenter

HPA and Karpenter solve different scaling problems. They are complementary, not interchangeable.

## Pod Scaling vs Node Scaling

Horizontal Pod Autoscaler scales Kubernetes workloads by changing replica counts. It answers: how many pods should this application run right now?

Karpenter scales cluster infrastructure by provisioning nodes for unschedulable pods. It answers: what compute capacity does the cluster need so these pods can run?

## Why HPA Alone Is Insufficient

HPA can request more pods, but it cannot create node capacity. If the cluster is full, new replicas remain Pending. The application still needs more capacity, but Kubernetes has nowhere to place the pods.

For example, a service may scale from three replicas to eight replicas during a traffic spike. If existing nodes only have room for two additional pods, the remaining pods wait until infrastructure capacity appears.

## Why Node Autoscaling Exists

Node autoscaling closes the infrastructure gap. Karpenter observes pending pods, evaluates their CPU, memory, architecture, topology, and scheduling constraints, then provisions suitable nodes.

This keeps the platform from running excessive idle capacity all the time while still allowing workloads to grow when demand appears.

## Operational Examples

If CPU utilization rises above the HPA target, HPA increases pod replicas. If those pods fit on existing nodes, no node autoscaling is needed.

If memory-heavy pods cannot be scheduled because nodes lack memory, Karpenter can add nodes with enough memory to satisfy the pending pods.

If a workload has strict topology or architecture requirements, node autoscaling must understand those constraints or pods may remain Pending.

HPA reacts to application pressure. Karpenter reacts to unschedulable workload demand.
