# External Secrets Architecture

Kubernetes Secrets are useful as the runtime delivery mechanism for pods, but they are weak as the long-term source of truth. They are cluster-local, easy to copy between environments, often lack enterprise rotation workflows, and can drift when manually edited.

Externalized secret management keeps sensitive values in a centralized secret store and lets Kubernetes receive synchronized copies only where workloads need them.

## Centralized Secret Management

In this architecture, AWS Secrets Manager owns the secret values. Platform teams define `ExternalSecret` resources in Git to describe which remote secrets should be synchronized into Kubernetes. Application pods continue to consume ordinary Kubernetes Secrets, so application manifests stay simple and portable.

The sensitive value is not committed to Git. Git stores the reference to the secret, the target Kubernetes Secret name, and the expected key mapping.

## How External Secrets Operator Works

External Secrets Operator runs in the cluster and watches `ExternalSecret` resources. When it finds one, it uses the referenced `ClusterSecretStore` to authenticate to the external provider, reads the remote value, and creates or updates a Kubernetes Secret.

The sync path is:

```text
AWS Secrets Manager -> External Secrets Operator -> Kubernetes Secret -> Pod environment variables
```

## Sync Architecture

`ClusterSecretStore` defines how the cluster reaches AWS Secrets Manager. `ExternalSecret` defines what remote secret to fetch and what Kubernetes Secret to create. The workload only references `sample-go-service-secret` through `envFrom.secretRef`.

The current repository includes a manual example Secret only as a placeholder for local manifest rendering. In a real External Secrets installation, that manual placeholder should not be the long-term source of truth; the generated Secret owned by External Secrets Operator should provide the workload values.

This phase defines the architecture only. It does not install External Secrets Operator, configure IRSA, or create real AWS secrets.

## Operational Problems Solved

Centralized secret management reduces manual secret handling, inconsistent secret copies, and unclear ownership. It supports rotation workflows, audit trails, least-privilege access, and separation between platform configuration and sensitive values.

It also improves incident response. Teams can rotate or revoke a secret in one central system and allow clusters to converge through synchronization instead of hunting through manually managed Kubernetes Secret objects.

## Why Enterprises Prefer Central Stores

Enterprise platforms usually need consistent access control, audit logging, rotation, environment separation, and compliance evidence. A centralized store such as AWS Secrets Manager provides these controls more naturally than scattered Kubernetes Secret objects maintained by hand.
