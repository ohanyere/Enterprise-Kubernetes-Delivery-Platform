# Promotion Flow

Promotion is represented as a Git change to the desired environment overlay.

Example promotion path:

1. A commit builds image tag `docker.io/ohanyere/sample-go-service:<sha>`.
2. Dev overlay is updated first.
3. ArgoCD automatically syncs dev.
4. After validation, staging overlay is updated by pull request.
5. Staging is manually synced or approved in ArgoCD.
6. After validation, prod overlay is updated by pull request.
7. Prod is manually synced or approved in ArgoCD.

The important rule is that staging and prod receive the same immutable image that was validated earlier. No environment-specific rebuild should happen.

In this foundation, image promotion is prepared through the `images` block in each overlay. A later workflow can automate pull requests that update `newTag`.
