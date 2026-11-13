# Evidence Index — Screenshots, Logs and Provenance

**Evidence date:** 13 November 2026. All images in this ZIP were supplied from the user's VM/browser session and preserved without altering their contents. They demonstrate the **historical** system state and must not be represented as live monitoring data.

## 1. Screenshot register

| Figure | Direct image | What it actually shows | Suggested placement |
| --- | --- | --- | --- |
| 01 | [Infrastructure services / Nomad client](../screenshots/01-Infrastructure-Services-and-Nomad-Client.png) | Docker/Nomad/Consul active; ready Nomad node | Environment setup |
| 02 | [Flask unit tests](../screenshots/02-Flask-Application-Unit-Tests.png) | 9 Python tests passed on `mariana` | Application validation |
| 03 | [Successful GitHub Actions](../screenshots/03-Successful-GitHub-Actions-CI-CD.png) | All three normal CI/CD stages green | CI/CD implementation |
| 04 | [Current Nomad deployment overview](../screenshots/04-Nomad-Job-Deployment-Overview.png) | Version 8, healthy allocation, successful deployment | Orchestration |
| 05 | [Manual rollback recovery output](../screenshots/05-Manual-Rollback-Recovery-Output.png) | Recovering job version 6 reaches successful state | Recovery validation |
| 06 | [Expected GitHub Actions failure](../screenshots/06-Expected-GitHub-Actions-Deployment-Failure.png) | Unit tests/build green; deploy red | Failure propagation |
| 07 | [CI-triggered rollback log](../screenshots/07-CI-Triggered-Automatic-Rollback-Log.png) | Failure deadline, rolling back, recovery success, exit 1 | Automatic rollback |
| 08 | [Final Nomad service health](../screenshots/08-Final-Nomad-Service-Health.png) | Healthy version 8 Nomad dashboard | Final system status |

### Interpretation caveats

- **04 and 08 overlap:** both are useful views of the same version 8 Nomad state. The terminal's `PASS: version=v2, health=healthy` line provides stronger independent application proof than these UI images alone.
- **05 is a log excerpt:** the screenshot does not display the initiating `nomad job revert rollback-demo 4` command, but the saved VM file `manual-revert.log` and supplied terminal transcript do.
- **07 wraps long lines:** core failure/recovery messages remain visible. The full unwrapped CI log file on the VM should be used if exact log interpretation is disputed.

## 2. Archived VM evidence files

The following 14 files were listed inside `~/nomad-phase5-evidence` on the VM. They are **not all embedded as raw files** in this archive; the evidence directory remained on the VM. Do not imply the ZIP contains the 30 KB CI job log or other full logs.

| File | Purpose |
| --- | --- |
| `baseline-history.txt` | Stable pre-test job versions |
| `baseline-status.txt` | Baseline job and allocation status |
| `v3-failure.log` | Unhealthy candidate and automatic rollback transcript |
| `manual-test.nomad.hcl` | Temporary `auto_revert=false` test configuration |
| `manual-failure.log` | Failed manual-candidate job output |
| `manual-revert.log` | Manual revert command result / timing |
| `final-deployments.txt` | Post-manual deployment listing |
| `final-history.txt` | Post-manual job history |
| `final-health.txt` | Post-manual application health |
| `ci-failure-job.log` | Full GitHub Actions deployment-job log from run `43442086173` |
| `ci-rollback-deployments.txt` | Recovery deployment listing |
| `ci-rollback-history.txt` | Unstable version 7, stable version 8 |
| `ci-final-health.txt` | Final Nomad/Consul/HTTP verification |
| `ci-final-result.txt` | GitHub Actions run status summary |

**If distributing raw logs:** Remove private keys, OAuth tokens, SSH configuration and unexpected environment secrets before archiving. Keep originals only in an access-controlled location.

## 3. Evidence chain

| Claim | Primary backing record |
| --- | --- |
| Python tests passed | Screenshot 02 and terminal `Ran 9 tests ... OK` |
| Normal CI/CD can deploy | Screenshot 03; GitHub run `43426413120` |
| Healthy Nomad deployment | Screenshots 04/08; `phase4-verify.sh` output |
| Failed standalone v3 | VM `v3-failure.log`, Nomad `752b186e` |
| Automatic rollback | VM `v3-failure.log` plus screenshot 07 |
| Manual recovery | VM `manual-revert.log`, job version 6; screenshot 05 is partial visual evidence |
| CI failure accurately reported | Screenshots 06/07, GitHub run `43442086173` |
| Final `v2` application healthy | `ci-final-health.txt`, terminal `PASS: version=v2, health=healthy` |

## 4. Figure use instructions

In Markdown, open images using the direct paths above, or embed using a relative path to the relevant PNG file. In Word, the images are embedded into the formal report appendix. Every figure caption should state the exercise and time context; do not caption an unhealthy canary as an accidental production outage.

See [screenshot guide](../screenshots/README.md) for short ready-to-paste captions.
