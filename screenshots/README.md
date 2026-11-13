# Screenshots — Report Figure Captions

These are the eight original screenshots supplied from the user's VM and GitHub browser session on 13 November 2026. **The images are not retouched.** View each through its direct local link below. Treat all as historical test evidence, not live system state.

| No. | Direct link | Caption (1–2 lines) |
| --- | --- | --- |
| 01 | [Infrastructure Services and Nomad Client](01-Infrastructure-Services-and-Nomad-Client.png) | Docker, Nomad and Consul were active in the Ubuntu VM, and the single Nomad client `mariana` was ready for scheduling. |
| 02 | [Flask Application Unit Tests](02-Flask-Application-Unit-Tests.png) | Python unittest executed nine application tests on the VM, and all completed with `OK`. |
| 03 | [Successful GitHub Actions CI/CD](03-Successful-GitHub-Actions-CI-CD.png) | Healthy release workflow completed unit tests, Docker/GHCR publish and Nomad VM deployment successfully. |
| 04 | [Nomad Job Deployment Overview](04-Nomad-Job-Deployment-Overview.png) | Nomad job `rollback-demo` showed a running, healthy allocation and successful version 8 deployment. |
| 05 | [Manual Rollback Recovery Output](05-Manual-Rollback-Recovery-Output.png) | The recorded manual recovery reaches successful job version 6; the full command and its 12-second duration are in the saved manual-revert log. |
| 06 | [Expected GitHub Actions Deployment Failure](06-Expected-GitHub-Actions-Deployment-Failure.png) | Controlled unhealthy candidate leaves tests/build green but the deployment job and workflow red, as intended. |
| 07 | [CI-Triggered Automatic Rollback Log](07-CI-Triggered-Automatic-Rollback-Log.png) | Progress deadline failure caused automatic revert to stable configuration; the recovery succeeded while CI retained exit code 1. |
| 08 | [Final Nomad Service Health](08-Final-Nomad-Service-Health.png) | Nomad UI confirmed successful version 8 and one healthy allocation after recovery; independent HTTP `v2` evidence is in verification logs. |

## Presentation recommendations

Screenshots 04 and 08 show overlapping dashboard information; if page count is limited, use 04 and the `phase4-verify.sh` terminal output instead of both. Screenshot 07 contains long wrapped log lines, so use the raw `ci-failure-job.log` for exact quotation or technical dispute. Screenshot 05 shows the successful portion of the manual recovery but not the `nomad job revert` command itself.

When placing a figure in an academic report, give it a descriptive label, include its date/context, crop only empty margins, and avoid claiming the image proves details it does not actually show. Secret-bearing files or credential screens must never appear in the submitted appendix.
