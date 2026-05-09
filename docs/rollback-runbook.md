# Rollback Runbook

Rollback should be boring and auditable. In this project, rollback is performed by reverting the Git commit that promoted a bad image tag or configuration change.

## Steps

1. Identify the bad promotion commit in Git.
2. Revert that commit.
3. Open and merge the rollback pull request.
4. Let ArgoCD reconcile the environment.
5. Confirm `/health`, `/ready`, and `/version`.

For dev, ArgoCD automated sync applies the revert automatically. For staging and prod, perform the manual sync or approval step according to your operational process.

Avoid rebuilding an old image during rollback. The previous immutable image tag should already exist in the registry.
