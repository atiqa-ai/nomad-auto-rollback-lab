# Phase 4 — Verified VM-Only CI/CD Deployment Guide

**Execution:** Ubuntu VM `mariana`, user `manoo`  
**Status:** CI/CD publishing and real VM deployment verified on 13 November 2026  
**Safe default:** `LAB_CD_ENABLED=false` when no authorized release is in progress

This guide describes the **deployed** GitHub Actions → GHCR → temporary Tailscale runner → pinned SSH → Nomad workflow. It is not a one-command installer. Run commands inside the sandbox VM only.

## 1. Confirm the environment

```bash
cd ~/nomad-auto-rollback-lab
git status --short
systemctl is-active docker consul nomad
nomad node status
bash scripts/phase4-preflight.sh
```

The last command performs repository checks, shell syntax validation, job validation, and local service checks. If Git reports changes, review them before proceeding. Never stop the stable job merely to update documentation.

## 2. Required source files

| File | Purpose |
| --- | --- |
| `.github/workflows/ci-cd.yml` | Test, publish and optionally deploy from trusted main |
| `nomad/rollback-demo.nomad.hcl` | Canary strategy and Consul health check |
| `scripts/nomad-lab-deploy.sh` | Validated, monitored VM deployment |
| `scripts/phase4-preflight.sh` | Local prerequisites and source validation |
| `scripts/phase4-verify.sh` | Post-deployment health + version check |

These executable paths are part of the Git repository. The documentation archive does **not** replace their current content.

## 3. GitHub workflow behavior

The workflow runs nine unit tests on pull requests; publication and deployment skip for PR events. On `main`, tests run and Buildx publishes `ghcr.io/atiqa-ai/nomad-auto-rollback-lab:sha-<full-commit-sha>` plus a digest. Deploy runs only if the repo variable `LAB_CD_ENABLED` is `true`. A manual `workflow_dispatch` input `failure_test` defaults to `false`; `true` is reserved for an intentionally unhealthy test.

GitHub environment `nomad-lab` stores the lab-only secrets:

- `TS_OAUTH_CLIENT_ID`
- `TS_OAUTH_CLIENT_SECRET`
- `LAB_SSH_PRIVATE_KEY`
- `LAB_SSH_KNOWN_HOSTS`

The repository variables are `LAB_TAILSCALE_IP` and `LAB_CD_ENABLED`. Never print secret **values** in issue threads, reports or screenshots.

## 4. Secure runner-to-VM path

The GitHub-hosted runner joins Tailscale using `tag:ci` and reaches VM `mariana` tagged `tag:nomad-lab` over TCP 22. The VM's Nomad and Consul APIs remain bound to `127.0.0.1`. SSH on the runner verifies a pinned host key; do not bypass `StrictHostKeyChecking` if connectivity fails. The historical test used a temporary GitHub-hosted runner, not a permanently privileged public self-hosted runner.

For a replacement VM or Tailscale identity, revalidate the tags, permissions, trusted host key fingerprint, secret placement and environment branch restrictions. This may require authorized interactive configuration; the package cannot replicate authentication automatically.

## 5. Install/update the VM deployment command

After a reviewed `main` update:

```bash
cd ~/nomad-auto-rollback-lab
git status --short
git switch main
git pull --ff-only origin main
mkdir -p "$HOME/bin"
install -m 0750 scripts/nomad-lab-deploy.sh "$HOME/bin/nomad-lab-deploy"
bash -n "$HOME/bin/nomad-lab-deploy"
```

The remote workflow executes `/home/manoo/bin/nomad-lab-deploy`. **Always update this installed file when its source script changes.** The script accepts an immutable image digest, a 40-character source SHA and an optional health mode for the controlled test; its default is healthy.

## 6. Standard healthy release procedure

1. Ensure the current application is healthy (`bash scripts/phase4-verify.sh`).
2. Review `main` change and required secrets without printing them.
3. Check `LAB_CD_ENABLED`; enable only when the authorized run is intended.
4. Trigger the workflow through GitHub Actions or `gh workflow run ci-cd.yml --ref main -f failure_test=false`.
5. Inspect all three jobs: Python tests, image publishing, VM deployment.
6. Confirm the last job version, GHCR digest, canary promotion and Consul health.
7. Disable `LAB_CD_ENABLED` if continuous automatic deployment is not wanted for this lab.

The historical all-green run was **43426413120**: unit tests **6s**, publish **33s**, deploy **58s**. This is recorded as a demonstration result, not a performance guarantee.

## 7. Controlled unhealthy release test (lab only)

The failure test is deliberately disruptive to a **candidate**, not a production service. Confirm the existing stable job is healthy, restrict access to authorized maintainers and **do not run on production**.

```bash
cd ~/nomad-auto-rollback-lab
gh variable set LAB_CD_ENABLED --body "true"
gh workflow run ci-cd.yml --ref main -f failure_test=true
```

Record the selected workflow run ID. Once testing is finished, restore the guarded state:

```bash
gh variable set LAB_CD_ENABLED --body "false"
gh variable list
nomad job history rollback-demo
bash scripts/phase4-verify.sh
```

**Expected failure:** Candidate deployment fails; CI deploy job reports exit code `1`; Nomad auto-reverts to last stable job. The historical controlled run **43442086173** demonstrated precisely this, with unhealthy job version **7**, rollback to stable version **6**, and recovery version **8**. If the workflow fails earlier at Tailscale, SSH, registry pull or validation, do not falsely attribute that failure to canary health.

## 8. Handling unexpected failure

- Identify failing stage in the GitHub Actions run; collect relevant job output.
- Inspect `nomad job deployments rollback-demo` and `nomad job history rollback-demo`.
- Check Consul passing service and active application `/health`.
- If automatic revert has not recovered the service, follow the [operational runbook](OPERATIONAL_RUNBOOK.md) and deliberately choose the last confirmed stable job version.
- Record failure start, recovery confirmation and the precise time interval being measured.

## 9. Post-deployment proof

```bash
nomad job status rollback-demo
nomad job deployments rollback-demo
nomad job history rollback-demo
bash scripts/phase4-verify.sh
gh variable list
```

For the historical final state, `phase4-verify.sh` returned `version=v2, health=healthy`; the latest successful deployment ID was `f2b389f5`, stable version 8. The deployment check does **not** assert a particular commit when invoked without a SHA argument. A screenshot of a “healthy” Nomad dashboard alone is insufficient to prove HTTP response content; combine it with verification output.

Go to [Phase 5 test report](PHASE5_ROLLBACK_TEST_REPORT.md) for the execution transcript summary and [evidence index](EVIDENCE_INDEX.md) for the screenshots and saved logs.
