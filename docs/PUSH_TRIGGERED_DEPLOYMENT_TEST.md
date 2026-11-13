# Push-Triggered Deployment Verification

## Objective

Verify that merging a reviewed change into main triggers the
complete GitHub Actions CI/CD pipeline and deploys a healthy
application candidate to the isolated Nomad lab.

## Expected Pipeline

1. Push to main triggers GitHub Actions.
2. Python unit tests pass.
3. Docker image is built and published to GHCR.
4. Deployment gate is enabled explicitly for the test.
5. GitHub Actions connects to the isolated Ubuntu VM.
6. Nomad evaluates and deploys a healthy canary.
7. Consul health checks pass.
8. Nomad automatically promotes the candidate.
9. GitHub Actions reports successful deployment.

## Verification Evidence

Record the GitHub Actions run ID, commit SHA, image digest,
Nomad deployment ID, canary promotion status, and application
health response.

## Safety

Testing is restricted to the isolated lab VM.
Production servers and company credentials are not used.
Disable LAB_CD_ENABLED after completing the test.

## Status

Verified successfully on 13 November 2026. GitHub Actions run `43481759119` was triggered by a push to `main`. Python tests, Docker publishing and Nomad deployment passed. Commit `ea3ff5145bc7` deployed as Nomad job version `9`, deployment `ef6bf59a`, with automatic canary promotion and passing health checks.
