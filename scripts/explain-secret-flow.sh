#!/usr/bin/env bash
set -euo pipefail

cat <<'FLOW'
Externalized secret flow:

AWS Secrets Manager
  - Source of truth for sensitive values.
  - Owns rotation, IAM access control, and audit history.

        |
        v

External Secrets Operator
  - Runs in the Kubernetes cluster after a future installation phase.
  - Reads ExternalSecret resources and fetches only the referenced remote secrets.
  - Authenticates to AWS through future IRSA or pod identity integration.

        |
        v

Kubernetes Secret: sample-go-service-secret
  - Generated and refreshed by External Secrets Operator.
  - Exists in Kubernetes so workloads can use normal Secret consumption patterns.
  - Should not be manually edited as the long-term source of truth.

        |
        v

Pod environment variables
  - The Deployment consumes sample-go-service-secret through envFrom.secretRef.
  - The application receives keys such as API_KEY and DATABASE_PASSWORD.
  - Secret value ownership remains centralized outside the cluster.
FLOW
