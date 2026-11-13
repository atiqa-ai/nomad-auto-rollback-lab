# Nomad Deployment Review Checklist

**Purpose:** Help engineers review a Nomad service job before applying deployment changes.

**Scope:** Review guidance only. This lab does not authorize changes to company infrastructure.

## 1. Job Configuration

- [ ] Job name, datacenter and namespace are correct.
- [ ] Job specification passes `nomad job validate`.
- [ ] Task group count and resource limits are reviewed.
- [ ] Container image uses an approved immutable digest.
- [ ] Required environment variables are configured safely.
- [ ] Credentials and secrets are not hardcoded.

## 2. Update Strategy

- [ ] An `update` block is explicitly configured.
- [ ] `canary` is appropriate for the service.
- [ ] `max_parallel` limits concurrent replacements safely.
- [ ] `auto_promote` behavior is understood.
- [ ] `auto_revert` is enabled where automatic recovery is required.
- [ ] `health_check` matches the registered check mechanism.
- [ ] `min_healthy_time` allows sufficient validation.
- [ ] `healthy_deadline` is appropriate for startup time.
- [ ] `progress_deadline` allows realistic rollout completion.
- [ ] Shutdown behavior is reviewed.

## 3. Service Health

- [ ] Application exposes a meaningful health endpoint.
- [ ] Consul service registration is configured correctly.
- [ ] Health check interval and timeout are appropriate.
- [ ] Intentionally unhealthy instances fail the service check.
- [ ] Health checks represent actual service readiness.
- [ ] Candidate promotion depends on passing checks.

## 4. Deployment Safety

- [ ] Proposed deployment changes are reviewed using `nomad job plan`.
- [ ] Existing healthy allocations are identified.
- [ ] Canary deployment preserves the intended stable service.
- [ ] Deployment command monitors rollout completion.
- [ ] The CI/CD job fails when a candidate deployment fails.
- [ ] Rollback target and previous stable job version are known.
- [ ] A manual recovery procedure is available.

## 5. Failure and Recovery

- [ ] Failed deployment history can be inspected.
- [ ] Automatic revert behavior has been tested in a lab.
- [ ] Manual `nomad job revert` procedure is documented.
- [ ] Recovered service health is independently verified.
- [ ] Recovery duration and evidence are recorded accurately.
- [ ] Deployment failure is not incorrectly reported as success.

## 6. Security and Approval

- [ ] Deployment is limited to an authorized environment.
- [ ] Network access follows least-privilege requirements.
- [ ] SSH identities and host keys are verified.
- [ ] Credentials are stored using approved secret management.
- [ ] An authorized engineer approves production-specific settings.
- [ ] A recovery owner and escalation path are identified.

## 7. Post-Deployment Verification

- [ ] Nomad deployment reports the expected outcome.
- [ ] Running allocations match the desired count.
- [ ] Consul health checks are passing.
- [ ] Application version matches the intended release.
- [ ] CI/CD result matches the deployment outcome.
- [ ] Evidence and incident notes are retained.

## Review Outcome

- Job reviewed:
- Environment:
- Reviewer:
- Review date:
- Decision: Approved / Changes required / Rejected
- Findings:
- Required corrective actions:

## Lab-Verified Configuration

The demonstration job `rollback-demo` used:

| Setting | Verified Value |
|---|---|
| `canary` | `1` |
| `max_parallel` | `1` |
| `auto_promote` | `true` |
| `auto_revert` | `true` |
| `health_check` | `"checks"` |
| `min_healthy_time` | `"10s"` |
| `healthy_deadline` | `"2m"` |
| `progress_deadline` | `"4m"` |
| Consul HTTP check | `/health` |
| Check interval | `5s` |
| Check timeout | `2s` |

These are tested lab settings, not automatically approved production defaults.
