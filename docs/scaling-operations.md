# Scaling Operations

Autoscaling is a control system. It improves reliability when metrics, resource requests, scheduling, and application behavior are aligned. When those signals are wrong, autoscaling can amplify problems.

## Common Failure Modes

Pending pods usually mean the scheduler cannot place replicas. Causes include insufficient CPU or memory, missing node capacity, strict affinity rules, taints without tolerations, or unavailable storage.

Resource exhaustion appears when workloads request too little, consume too much, or hit limits under load. HPA uses requests as the baseline for utilization, so incorrect requests produce poor scaling decisions.

Incorrect requests and limits can cause two opposite problems. Requests that are too low make utilization look high and trigger unnecessary scaling. Requests that are too high can prevent scheduling and waste capacity. Limits that are too low can throttle CPU or cause memory termination.

Scaling lag happens because metrics collection, HPA reconciliation, node provisioning, image pulls, pod startup, and readiness checks all take time. Autoscaling is reactive, so services still need sensible baseline capacity.

Runaway scaling can happen when downstream dependencies fail, requests retry aggressively, or metrics reflect symptoms rather than useful capacity signals. `maxReplicas` limits the blast radius while operators investigate.

## Debugging Mindset

Start by asking which layer is blocked. If HPA did not change replicas, check metrics availability and targets. If replicas increased but pods are Pending, check scheduler events and node capacity. If pods are Running but not Ready, check probes, application startup, and dependency health.

Useful commands in a live cluster would include `kubectl describe hpa`, `kubectl describe pod`, `kubectl get events`, and node capacity checks. This repository does not install live autoscaling controllers yet.

## Operational Signals

Watch desired replicas, current replicas, pending pods, node capacity, pod readiness, CPU and memory usage, request latency, error rates, and dependency saturation. Autoscaling should protect users, not hide application or dependency failures.
