# Progressive Delivery

Progressive delivery reduces release risk by exposing a new version to a small amount of real traffic before promoting it everywhere. Instead of replacing all pods at once and hoping the new version behaves well, the platform advances through controlled traffic steps.

## Why It Exists

Production failures are often caused by changes that passed tests but behave differently with real users, real data, real latency, or real dependencies. Progressive delivery limits blast radius. If a canary version fails, only a small percentage of traffic is affected and the system can return traffic to stable.

## How Canary Rollout Works

A new image is promoted. Argo Rollouts creates a canary ReplicaSet alongside the stable ReplicaSet. Istio sends a configured percentage of traffic to the canary. Metrics are observed during pauses. If health signals remain good, traffic increases to 25%, 50%, and eventually 100%.

If the canary becomes unhealthy, the rollout aborts and traffic returns to the stable version.

## Limits of Kubernetes Deployment Alone

A standard Kubernetes Deployment can do rolling updates, but it does not natively route 10% of traffic to a new version, pause on metric checks, or automatically abort based on Prometheus-style health signals. Argo Rollouts and Istio add those release controls.

This phase adds architecture reference manifests only. It does not install Argo Rollouts, Istio, or Prometheus, and it does not replace the current Deployment.
