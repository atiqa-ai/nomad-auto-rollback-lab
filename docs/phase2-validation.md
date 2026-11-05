# Phase 2 — Application and container validation record

**Record date:** 2026-11-05  
**Status:** Initial tests observed; sandbox-VM final acceptance pending  
**Evidence provenance:** User-supplied terminal output in project conversation. The log path and hostname match the earlier physical Ubuntu laptop; the execution location has **not** been confirmed as an isolated guest VM.

## Observed results

| Check | Observed evidence | Finding |
| --- | --- | --- |
| Python test suite | `Ran 9 tests in 0.027s` / `OK` | 9/9 pass, in reported environment |
| Docker image | `nomad-rollback-demo:local` image ID prefix `ef2508f4f022` | Image existed and ran |
| Reported image disk usage | `194MB` | Observed, not a target or size limit |
| Image configured user | `appuser` | Pass |
| Container runtime user | `uid=10001(appuser)` | Pass |
| Stable v1 `/health` | HTTP `200`, `{"status":"healthy","version":"v1"}` | Pass |
| Broken v2 `/health` | HTTP `503`, `{"status":"unhealthy","version":"v2"}` | Intentional pass |
| Stable Docker health | `healthy` | Pass |
| Broken Docker health | `unhealthy` | Intentional pass |
| Original Gunicorn logs | `Control server error: [Errno 13] Permission denied: '/home/appuser'` | Issue found |
| Gunicorn correction | User reported `--no-control-socket` applied | Rebuild/retest not yet evidenced |
| Isolated VM | Not shown by supplied outputs | **ubuntu 24.04LTS** |
| Nomad+Consul canary rollback | Not attempted in provided results | **Not verified** |

## Explicit limitations

- The original unit and container tests are useful development evidence, but they do **not** satisfy the lab-only execution requirement until reproduced in the sandbox VM.
- The `--no-control-socket` change was reported applied but no new container logs were supplied after rebuilding. Do not record the issue as verified fixed yet.
- No Nomad job, Consul HTTP service check, GitHub Actions rollout monitor, or automatic rollback proof exists in the submitted test output.

## Required sandbox-VM sign-off procedure

1. Record the sandbox VM identity and isolation:

   ```bash
   date -Is
   hostnamectl
   systemd-detect-virt
   free -h
   docker version
   ```

   Confirm the result corresponds to the **designated sandbox VM**. `systemd-detect-virt` can vary across isolation technologies; correlate it with VM inventory rather than depending only on a single command.

2. Re-run all nine Python tests **inside the VM** and record the actual output:

   ```bash
   python3 -m venv .venv
   . .venv/bin/activate
   python -m pip install -r app/requirements.txt
   mkdir -p evidence
   python -m unittest discover -s tests -p 'test_*.py' -v 2>&1 | tee evidence/phase2-unit-tests.txt
   ```

   Check exit status using `set -o pipefail` before piping if using the output as a pass/fail gate.

3. Rebuild the **corrected** Docker image inside the VM:

   ```bash
   docker build --pull -t nomad-rollback-demo:local .
   docker image inspect nomad-rollback-demo:local --format '{{json .Config.Cmd}}'
   ```

   Verify `--no-control-socket` is present in the image's command.

4. Execute healthy and broken container checks exactly as described in the root README, capturing `curl -i`, `docker ps`, health states, `docker exec ... id`, and relevant Gunicorn logs. Allow the health probes time to transition from `starting`.
5. Confirm the healthy container reports `healthy` and HTTP 200, and the broken container reports `unhealthy` and HTTP 503.
6. Confirm the previous Gunicorn `Permission denied: '/home/appuser'` error does not occur in the rebuilt containers.
7. Store redacted logs and timestamps under `evidence/`. Avoid saving tokens, environment secrets, or privileged API URLs.
8. Document who reran the commands and when; only then mark Phase 2 validation accepted.

## Acceptance checklist

- [x] Nine unit tests passed in original reported execution environment.
- [x] Healthy and broken HTTP behavior observed in original reported execution environment.
- [x] Docker health transitions observed in original reported execution environment.
- [x] Non-root runtime user observed in original reported execution environment.
- [ ] Corrected image rebuilt and verified in sandbox VM.
- [ ] All nine unit tests rerun in sandbox VM.
- [ ] Healthy and broken Docker scenarios rerun in sandbox VM.
- [ ] Gunicorn control-socket error confirmed absent in rebuilt image logs.
- [ ] Final sandbox VM evidence captured and reviewed.

**Phase 2 verdict:** Code and behavior demonstrated; final lab-only sign-off pending. This report does not claim automatic rollback has been implemented.
