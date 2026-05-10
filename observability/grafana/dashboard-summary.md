# Grafana Dashboard Summary

This phase does not add a live Grafana dashboard JSON. It defines the core dashboard panels the platform should provide once metrics exist.

## Panels

- Request rate: Shows total request volume and helps correlate incidents with traffic spikes.
- Error rate: Tracks 5xx and failed request ratio so operators can see user-facing failure quickly.
- Latency p95/p99: Shows tail latency, which is often where user pain appears first.
- Pod restarts: Highlights crash loops, dependency failures, memory pressure, or bad configuration.
- Rollout phase: Shows stable/canary progression and whether a rollout is paused, progressing, or aborted.
- HPA replicas: Compares desired, current, min, and max replicas during scaling events.
- CPU/memory usage: Shows resource pressure against requests and limits.
- Service availability: Summarizes whether the service is meeting its availability objective.

Dashboards should help operators answer: is the service healthy, are users affected, what changed, and should a rollout continue?
