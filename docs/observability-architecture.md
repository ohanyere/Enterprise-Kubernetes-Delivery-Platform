# Observability Architecture

Observability helps operators detect failure, understand system behavior, and make safe decisions. A healthy platform uses metrics, logs, and traces together because each signal answers a different question.

## Metrics

Metrics are numeric time series such as request count, error count, latency, CPU, memory, restarts, and replica counts. They power alerts because they are cheap to aggregate and can be evaluated continuously against thresholds or SLO burn rates.

Prometheus is the metrics collection and alert evaluation system represented in this phase. ServiceMonitor resources define scrape targets, and PrometheusRule resources define example alerts.

## Logs

Logs explain events. They help answer what happened around a specific request, pod restart, deployment, or dependency failure. Loki can store and query logs in a Kubernetes-friendly way.

Metrics may say the error rate is high; logs often explain the error messages and code paths behind the spike.

## Traces

Traces explain request paths across services. They show where time is spent and which downstream calls contributed to latency or failure. Tempo or Jaeger can provide distributed tracing once the application emits trace data.

Traces are especially useful for latency incidents and dependency-related failures.

## How the Tools Fit Together

Prometheus collects metrics and evaluates alerts. Grafana visualizes metrics and can bring together metrics, logs, and traces. Loki stores logs. Tempo or Jaeger stores traces.

Argo Rollouts can use Prometheus metrics for analysis during canary progression. That connection turns observability into a release-safety mechanism rather than only a debugging tool.

This phase adds reference observability manifests and operational docs only. It does not install Prometheus, Grafana, Loki, Tempo, or Jaeger, and it does not add application instrumentation.
