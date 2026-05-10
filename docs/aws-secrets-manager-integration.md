# AWS Secrets Manager Integration

AWS Secrets Manager stores sensitive values centrally and exposes them through AWS APIs protected by IAM. In this platform, Secrets Manager is the intended source of truth for application secrets, while Kubernetes Secrets are generated runtime artifacts.

## Architecture

Secrets are stored in AWS Secrets Manager under environment-aware paths such as:

```text
production/sample-go-service/api-key
```

External Secrets Operator reads those values and writes a Kubernetes Secret named `sample-go-service-secret`. The pod consumes that Kubernetes Secret through `envFrom`, which keeps application deployment manifests independent from provider-specific APIs.

## IAM Access Model

Access to AWS Secrets Manager should be granted with least privilege. The External Secrets Operator identity should be allowed to read only the secret paths needed for the namespaces and applications it manages.

For EKS, future integration should use IRSA or an equivalent pod identity model so the operator receives AWS permissions through a Kubernetes service account rather than static credentials.

## Audit Logging

Secrets Manager API activity can be recorded through AWS CloudTrail. This gives platform and security teams visibility into which identity read or modified secrets and when those operations happened.

Kubernetes audit logs can separately show when generated Kubernetes Secrets are created or updated inside the cluster.

## Rotation Support

AWS Secrets Manager supports managed and custom rotation workflows. When a secret rotates, External Secrets Operator can pick up the updated value on its refresh interval and update the generated Kubernetes Secret.

Applications may still need reload behavior for rotated values. Some workloads read environment variables only on startup, so rollout or restart automation may be needed after a synchronized secret changes.

## Least Privilege

Least privilege means separating duties by environment, namespace, and application. A production workload should not be able to read staging secrets, and one service should not be able to read another service's credentials.

The placeholder manifests intentionally avoid real AWS account IDs, regions, secret values, or IAM role ARNs. Those belong in environment-specific platform configuration.

## EKS Workload Authentication Readiness

The `ClusterSecretStore` uses a service account reference placeholder so the architecture is ready for future IRSA or pod identity integration. Once configured, AWS will trust the Kubernetes service account used by External Secrets Operator, and the operator can call Secrets Manager without static AWS keys in the cluster.
