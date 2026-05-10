# Istio Traffic Management

Istio separates traffic routing decisions from application code. It can route requests by host, path, headers, destination subsets, and traffic weights.

## Gateway

A `Gateway` exposes a service through the Istio ingress gateway. It defines listener ports, protocols, and hosts such as `sample.example.com`.

## VirtualService

A `VirtualService` defines how matching requests are routed. For canary delivery, it contains weighted routes that split traffic between stable and canary destinations. Argo Rollouts can update those weights as the rollout progresses.

## DestinationRule

A `DestinationRule` defines policies and subsets for a service. Subsets select pods by labels, such as `version: stable` and `version: canary`.

## Subset Routing

Subset routing lets one Kubernetes Service represent the application while Istio sends different percentages of traffic to different pod groups behind that service. This is what enables precise canary weights such as 10%, 25%, and 50%.

## Traffic Splitting

Traffic splitting is the core Istio behavior used by canary delivery. Stable receives most traffic at first. Canary receives a small percentage. As health checks pass, the canary percentage increases.

## mTLS with ISTIO_MUTUAL

`ISTIO_MUTUAL` tells Istio to use mesh-managed mutual TLS for service-to-service communication. This gives encrypted transport and workload identity within the mesh without each application managing its own certificates.
