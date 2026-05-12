# Build Once, Deploy Many

Build once, deploy many means the same container image is promoted across dev, staging, and prod. The image should not be rebuilt per environment.

Environment differences belong in Kubernetes configuration:

- ConfigMaps for non-secret runtime config.
- Secrets for sensitive values.
- Kustomize overlays for replica counts, resources, and image tags.

The expected flow is:

1. CI tests the service.
2. CI builds `docker.io/kuperpull/sample-go-service:<commit-sha>`.
3. CI pushes that immutable tag after registry publishing is enabled.
4. A promotion pull request updates the target overlay image tag.
5. ArgoCD syncs the environment from Git.

This creates traceability: a running workload points back to a specific Git commit and image tag.
