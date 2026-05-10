#!/usr/bin/env bash
set -euo pipefail

cat <<'FLOW'
Autoscaling flow:

Traffic spike
  - Requests increase and the running pods consume more CPU or memory.
  - Application pressure shows up in metrics.

        |
        v

HPA increases pod replicas
  - Horizontal Pod Autoscaler reacts to application pressure.
  - It changes the Deployment replica count, based on CPU and memory targets.
  - HPA needs accurate container requests because utilization is calculated from them.

        |
        v

Cluster capacity shortage
  - If existing nodes have spare CPU and memory, pods can start immediately.
  - If capacity is exhausted, new pods remain Pending.

        |
        v

Karpenter provisions nodes
  - In a future installation, Karpenter reacts to unschedulable pods.
  - It creates node capacity that matches pod resource and scheduling needs.

        |
        v

Scheduler places pods
  - Kubernetes schedules the pending replicas onto available nodes.
  - Pods must pass readiness checks before they receive traffic.

        |
        v

Workload stabilizes
  - More ready replicas share traffic.
  - When pressure drops, HPA can reduce replicas and node autoscaling can remove unused capacity.
FLOW
