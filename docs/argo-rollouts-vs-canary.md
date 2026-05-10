# Argo Rollouts vs Canary

Canary deployment is a release strategy. It means exposing a new version to a small amount of traffic, checking health, then gradually increasing traffic if the new version behaves correctly.

Argo Rollouts is the Kubernetes controller that orchestrates that strategy. It manages stable and canary ReplicaSets, pauses between steps, tracks rollout state, and can abort unsafe releases.

Istio is the traffic engine. It receives desired traffic weights from Argo Rollouts and routes users between stable and canary destinations.

Prometheus is the health observer. It provides metrics such as success rate, error rate, latency, or saturation so rollout decisions can be based on production signals rather than hope.

Together:

```text
Canary strategy -> Argo Rollouts orchestration -> Istio traffic routing -> Prometheus health checks
```
