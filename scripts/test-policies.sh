#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Rendering Kustomize overlays that Kyverno would evaluate through admission:"
for overlay in dev staging prod; do
  echo
  echo "==> deploy/overlays/${overlay}"
  kubectl kustomize "${ROOT_DIR}/deploy/overlays/${overlay}" >/dev/null
  echo "Rendered successfully."
done

echo
echo "Kyverno policy definitions:"
for policy in "${ROOT_DIR}"/policies/kyverno/*.yaml; do
  echo " - ${policy#${ROOT_DIR}/}"
done

echo
echo "In a live cluster with Kyverno installed, these ClusterPolicies would evaluate"
echo "Pod-creating workload requests from ArgoCD, kubectl, CI jobs, and other clients."
echo "Future validation can add kyverno CLI checks or admission tests against a test cluster."
