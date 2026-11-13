# Project Completion and Results Summary

**Project:** Nomad Automatic Rollback Lab  
**Recorded technical verification:** 13 November 2026  
**Scope:** Personal, isolated Ubuntu VM; not production infrastructure

## Completed engineering work

- Developed and unit-tested the Flask/Gunicorn demo application with `/health`, `/version` and controlled healthy/unhealthy behavior.
- Containerized the application with Docker and published a commit-associated immutable image digest to GHCR.
- Configured a Nomad service job with one stable allocation, canary update, health checks through Consul, automatic promotion and automatic revert.
- Implemented GitHub Actions to test, build, publish and conditionally deploy to the VM using temporary tagged Tailscale access and pinned-key SSH.
- Verified a successful healthy v2 canary (job version 2, deployment `5f0c7bd0`) with one healthy and zero unhealthy allocations.
- Induced an unhealthy v3 canary; Nomad rejected it at the progress deadline and automatically restored the prior stable v2 configuration.
- Conducted a separate manual recovery test with `auto_revert=false` in a temporary HCL copy; `nomad job revert rollback-demo 4` succeeded in 12 seconds.
- Executed a controlled GitHub Actions failure exercise; tests and image publication passed, deployment failed as expected, and Nomad automatically recovered while CI retained a failed result.
- Verified the final application as `version=v2, health=healthy`, Nomad job version 8 stable, and `LAB_CD_ENABLED=false` after testing.

## Measurable evidence

| Measurement | Recorded result | Caution |
| --- | --- | --- |
| Automated Python tests | 9 passed | Application unit tests, not load testing |
| Normal full CI/CD pipeline | Run `43426413120`: 3 jobs passed | Historic run, not a guaranteed duration |
| Bad v3 entire command | 252 seconds | Includes failure detection and recovery |
| Automatic recovery segment | Approximately 12 seconds | Deadline event to recovery success |
| Manual revert execution | 12 seconds | Measured after failure recognition |
| CI-triggered recovery segment | Approximately 12 seconds | Rollback event to recovery success |
| CI failure propagation | Run `43442086173`: deployment exit 1 | Expected result for unhealthy candidate |
| Final application | `v2`, `healthy` | Verified at test conclusion |

## Technical delivery status

**Five of six planned project phases had passed their engineering acceptance tests before this documentation handover.** Phase 6 provides the final technical report, architecture, runbook, deployment guide, rollback evidence, acceptance matrix, security review, screenshots and handover checklist. This package does not prove a fresh-VM one-command bootstrap or independently measured zero downtime.

## Included handover material

Use the main [README](../README.md) to open each document directly. For full testing evidence and IDs see [Phase 5 report](PHASE5_ROLLBACK_TEST_REPORT.md); for unresolved and future work see [validation](VALIDATION.md) and [security/limitations](SECURITY_AND_RISKS.md).
