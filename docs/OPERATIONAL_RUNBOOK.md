# Operational Runbook — Deploy, Verify, Recover

**Applies to:** Personal Ubuntu VM `mariana`, Nomad job `rollback-demo` in datacenter `dc1`  
**Safe operating principle:** Preserve the last stable allocation; do not disable healthy-check gates to force a candidate through. This runbook is **not** for production use.

## 1. Routine preflight

```bash
cd ~/nomad-auto-rollback-lab
systemctl is-active docker consul nomad
nomad node status
nomad job status rollback-demo
nomad job history rollback-demo
bash scripts/phase4-verify.sh
gh variable list
```

Proceed only if the stable instance is running and healthy, the required services are active, the Git working tree is understood, and the deployment is explicitly approved. If the response differs, triage before deploying.

## 2. Healthy CI/CD release

1. Review the proposed change and the current version of the workflow and Nomad HCL in `main`.
2. Ensure GitHub environment `nomad-lab` is restricted to trusted `main` deployments.
3. Confirm no unexpected uncommitted files; review any `authfile` and keep it outside Git.
4. If `scripts/nomad-lab-deploy.sh` changed, synchronize `~/bin/nomad-lab-deploy` using `install -m 0750` and run `bash -n`.
5. Set `LAB_CD_ENABLED=true` for the authorized release only if intentionally deploying.
6. Trigger the normal workflow with `failure_test=false` or use a reviewed main push.
7. Verify test, publish, Tailscale/SSH and remote Nomad deployment steps.
8. Check final Consul service health and application version; record GHCR digest and Nomad deployment ID.
9. Turn `LAB_CD_ENABLED=false` after the demonstration if deployment must remain manually gated.

A passing build job is **not** a successful deployment. Require Nomad's latest deployment to be successful and the application to report healthy.

## 3. Inspect an unexpected failed deployment

Gather data first; do not immediately restart the stable allocation.

```bash
nomad job status rollback-demo
nomad job deployments rollback-demo
nomad job history rollback-demo
nomad node status
```

To inspect the most recent deployment from its real ID:

```bash
nomad deployment status DEPLOYMENT_ID
```

Replace `DEPLOYMENT_ID` with the identifier shown by Nomad. If the deployment failed, note whether the description says **progress deadline**, scheduler placement, image pull failure, SSH failure, or missing Consul checks. Only the first class with a verified unhealthy candidate supports the specific rollback test conclusion.

## 4. Query current application health through Consul

```bash
SERVICE=$(curl -fsS \
  'http://127.0.0.1:8500/v1/health/service/rollback-demo?passing=true' \
  | jq -r '.[0] | "\((if .Service.Address == "" then .Node.Address else .Service.Address end)):\(.Service.Port)"')
[ -n "$SERVICE" ] && [ "$SERVICE" != "null" ] || { echo 'No passing service'; exit 1; }
curl -fsS "http://$SERVICE/version"
curl -fsS "http://$SERVICE/health"
```

A HTTP response from the passing service is important evidence; avoid relying exclusively on a screenshot of a Nomad dashboard. The source script `scripts/phase4-verify.sh` provides a simpler aggregate check; run it with no argument for labeled demo versions such as `v2`.

## 5. Automatic revert triage

When `auto_revert=true`, a failed deployment should be marked failed and the previously stable configuration should be re-submitted as a new job version. Check **all three** signals: (1) failed candidate remains in history; (2) subsequent recovery deployment successful; (3) active application health/version is correct. A failed CI run after successful rollback is **desirable and correct** for a rejected candidate.

If recovery is not successful, collect logs and proceed to a controlled manual revert only after identifying a stable historical version.

## 6. Manual rollback (authorized operator only)

1. Record the failed version and find a previous known stable version using `nomad job history rollback-demo`.
2. Review that version's application/image variables and make sure it is expected to be healthy.
3. On the VM, execute the Nomad revert. **Example only:** the historical test targeted version `4`; do **not** hardcode `4` for a later incident.

```bash
nomad job revert rollback-demo STABLE_JOB_VERSION
```

4. Monitor the deployment, query Consul/application health, and record the new job version.
5. Check whether the reverted job restores `auto_revert=true`; avoid leaving a test-only `auto_revert=false` configuration active.
6. Save the CLI exit status and recovery timestamps. A command returning 0 does not automatically prove a healthy HTTP response; verify separately.

## 7. Intentional failure exercise (testing only)

The manual scenario temporarily submitted an HCL copy with `auto_revert=false` and `HEALTH_MODE=unhealthy`. The source repo's canonical HCL was not changed. A fresh test must be approved and isolated. **Do not run it merely to generate screenshots**, because historic log evidence already exists. The GitHub Actions `failure_test=true` mode similarly must never be enabled on a production target.

## 8. Troubleshooting decision table

| Symptom | First checks | Safe next action |
| --- | --- | --- |
| Workflow tests fail | Python trace and requirements | Fix application; do not publish/deploy candidate |
| GHCR publish fails | Token package permissions, build logs | Fix image publish without changing Nomad stable job |
| Tailscale ping fails | VM tag `tag:nomad-lab`, CI tag `tag:ci`, grant TCP 22 | Repair tagged access; do not open management APIs |
| SSH host key rejected | Trusted VM console fingerprint versus pinned secret | Correct known-hosts secret; never disable checking |
| VM `nomad` command unavailable | Service/CLI installation, PATH and local API | Fix VM agent/CLI before retry |
| Nomad cannot place canary | Node readiness, memory, CPU, Docker driver | Fix capacity; preserve current stable allocation |
| Canary never healthy | Consul registration, `/health`, environment variables | Let deployment fail/revert; inspect expected mode |
| Rollback succeeded but CI red | Original deployment rejected | Record correct expected-failure behavior |
| `phase4-verify.sh v2` fails usage | Script expects optional 12-char hex commit SHA | Run without argument and examine displayed version |
| Older deployment not listed | Nomad history/display retention | Use archived terminal and CI logs; label historical |

## 9. Closure and evidence record

For each incident or test, save: date/time in UTC, test operator, commit SHA, exact image digest, pre-test stable job version, candidate version and `HEALTH_MODE`, deployment ID, scheduler failure description, new recovery job version, verification response, GitHub run result and the timing measurement's start/end definitions.

Redact any private keys, OAuth values, registry tokens, environment secret content and personal data. Store the final incident note under a controlled project evidence folder. Re-run `gh variable list` to confirm the lab CD gate is disabled after a controlled failure exercise.
