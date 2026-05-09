# Config Injection

The sample service reads runtime configuration from environment variables:

- `APP_ENV`
- `LOG_LEVEL`
- `RELEASE_CHANNEL`
- `APP_VERSION`
- `COMMIT_SHA`
- `FEATURE_FLAG_EXAMPLE`

Kubernetes injects these values from ConfigMaps and Secrets. Non-secret values live in ConfigMaps. Secret manifests in this repository are examples only and must not contain real credentials.

The `/config` endpoint returns non-secret runtime configuration only. Sensitive values should never be exposed by application endpoints or committed to Git.

Future production hardening can add an external secret manager and sealed or synced Kubernetes Secrets.
