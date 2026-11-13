# Consolidated Validation and Acceptance Matrix

**Review date:** 13 November 2026  
**Evidence policy:** A “Pass” means corresponding observed terminal or GitHub/Nomad output was supplied. “Not verified” means an expected deliverable or advanced property has no adequate observed proof. Historic identifiers are not live guarantees.

## 1. Acceptance checklist

| ID | Acceptance requirement | Evidence observed | Decision |
| --- | --- | --- | --- |
| A01 | Isolated VM tools operational | Active Docker, Nomad and Consul; ready `mariana` client | Pass |
| A02 | Python unit tests | Nine passing tests on `mariana` | Pass |
| A03 | Healthy/unhealthy app responses | Earlier local HTTP 200 and intentional HTTP 503 | Pass in recorded lab exercise |
| A04 | Non-root image | Earlier `appuser` / UID 10001 check | Observed historically |
| A05 | Source tested before publish | Full successful Actions run + expected-failure run tests green | Pass |
| A06 | Immutable registry image produced | GHCR SHA tag and published digest in CI output | Pass |
| A07 | Temporary private runner reaches VM | Tailscale/SSH deployment steps green | Pass |
| A08 | Nomad canary promoted when healthy | Job version 2; `promoted=true`, `healthy=1` | Pass |
| A09 | Unhealthy candidate rejected | Nomad versions 3, 5 and 7 failed progress deadline | Pass |
| A10 | Automatic revert to last stable | Versions 4 and 8 recovered stable configuration | Pass |
| A11 | Manual operator recovery | `nomad job revert rollback-demo 4`, exit 0 | Pass |
| A12 | CI accurately marks failed rollout | Run `43442086173`, deployment failed exit 1 | Pass |
| A13 | Final service healthy | Final `phase4-verify.sh`: `version=v2, health=healthy` | Pass |
| A14 | Evidence retained | Fourteen Phase 5 VM files listed; eight supplied screenshots | Pass for inventory only |
| A15 | Full one-command clean-VM bootstrap | No clean VM test or one-command script proof | **Not verified** |
| A16 | No user-visible downtime | No continuous outside-the-VM HTTP probing | **Not measured** |
| A17 | Full post-fix Gunicorn regression | No separate new-container log provided for socket fix | **Not verified separately** |
| A18 | Operational runbook and documentation | Complete in this package; procedures not all rerun from scratch | Documented; fresh-VM execution pending |
| A19 | Production security and high availability | Single lab VM; no ACL/mTLS audit or redundant nodes | Outside scope |

## 2. Verified run and deployment IDs

| Event | Identifier | Result |
| --- | --- | --- |
| Phase 4 all-green CI | GitHub Actions `43426413120` | Successful test/build/deploy |
| Healthy v2 | Nomad deployment `5f0c7bd0`, version 2 | Successful promotion |
| Unhealthy v3 | Nomad `752b186e`, version 3 | Failed progress deadline |
| v3 automatic recovery | Nomad `36110492`, version 4 | Successful |
| Manual failure | Nomad `4b1f2d2d`, version 5 | Failed progress deadline |
| Manual revert recovery | Nomad `76dfe0ac`, version 6 | Successful |
| CI-induced failure | GitHub Actions `43442086173` / Nomad version 7 | Expected fail, exit 1 |
| CI-induced recovery | Nomad version 8, subsequent deployment `f2b389f5` | Stable and healthy |

## 3. Final health acceptance (historical)

```text
systemctl: docker, nomad, consul active
Nomad: rollback-demo running
latest deployment: f2b389f5 successful
web: 1 desired / 1 placed / 1 healthy / 0 unhealthy
version: v2
health: healthy
LAB_CD_ENABLED: false
```

The recorded dynamic endpoint was on a libvirt NAT IP with an assigned high port. Do not write a specific port as a stable interface. Query Consul passing services or run the included verification script to get the current endpoint.

## 4. Repeatable tests and evidence collection

Inside VM `mariana`:

```bash
cd ~/nomad-auto-rollback-lab
systemctl is-active docker nomad consul
python3 -m unittest discover -s tests -v
nomad job status rollback-demo
nomad job history rollback-demo
nomad job deployments rollback-demo
bash scripts/phase4-verify.sh
gh variable list
```

The script's exit status and actual `PASS:` line are both required for health sign-off. For a current deployment event, collect specific job/evaluation IDs, failure reasons and allocated application version. Do not mark an unexpected runner failure as “successfully tested auto-revert”.

## 5. Final validation statement

Within the explicitly defined lab scope, the system implemented and demonstrated **successful and failed canary releases, automatic and manual reversion, immutable artifact deployment and truthful CI/CD failure reporting**. Remaining validation items A15–A17 must remain open until independently tested, and A19 is not claimed. See the [handover checklist](FINAL_HANDOVER_CHECKLIST.md) for closure ownership.
