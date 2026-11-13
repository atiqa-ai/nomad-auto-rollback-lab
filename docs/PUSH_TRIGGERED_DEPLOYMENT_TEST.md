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

Pending live push-triggered deployment verification.
