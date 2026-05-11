# Rollback Validation

Rollback validation confirms that the platform can recover service health through controlled, auditable operations.

## Git Revert Rollback

The primary rollback model is to revert the Git commit that changed deployment intent. For image rollbacks, this normally means reverting the overlay image tag change.

Validation steps:

- Find the promotion commit for the unhealthy release.
- Confirm the previous commit references a known-good image.
- Revert the promotion commit through the normal review process or emergency approval path.
- Confirm ArgoCD reconciles the environment back to the previous desired state.

Expected result: the cluster returns to a known-good image without manually editing live resources.

## Rollout Abort Scenarios

For progressive delivery, a canary can be aborted before the release reaches full traffic. Abort when error rate, latency, readiness, restart, or business metrics show user risk.

Validation steps:

- Confirm the canary ReplicaSet is distinguishable from stable.
- Confirm traffic weights can return to stable.
- Confirm operators know whether to pause, abort, or continue based on metrics.
- Confirm post-abort cleanup leaves the stable service healthy.

Expected result: unhealthy canaries are contained before they become full production rollouts.

## Stable Traffic Recovery

Stable recovery means users are routed back to the last known-good version. With Istio, this depends on VirtualService routing and DestinationRule subsets matching stable pod labels.

Validation steps:

- Confirm stable pods are healthy and ready.
- Confirm service endpoints include stable pods.
- Confirm traffic weights return to stable.
- Confirm dashboards show error rate and latency recovery.

Expected result: user traffic returns to the healthy version and observable symptoms improve.

## Operational Rollback Mindset

Rollback is not failure. It is a reliability control. Operators should prefer a fast, boring rollback over extended debugging while users are impacted.

Good rollback decisions are based on:

- User impact.
- Error budget risk.
- Confidence in the current release.
- Time needed to diagnose safely.
- Availability of a known-good version.

Expected result: teams treat rollback as a normal production safety action, then investigate root cause after service health is restored.
