# Project Milestones and Changes Record

**Purpose:** Brief factual timeline. Dates and identifiers are tied to supplied logs; no unobserved release dates or performance claims are inferred.

| Date (2026) | Milestone | Recorded evidence |
| --- | --- | --- |
| 5 Nov | Application and initial Docker exercise documented | Flask health/version endpoints, nine tests, healthy/unhealthy containers; post-fix Gunicorn regression remained open |
| 7 Nov | Initial Nomad/Consul lab deployment history | First stable job version 0 recorded at 20:18:12 UTC |
| 13 Nov | VM and local services validated | Docker/Nomad/Consul active, Nomad client ready on `mariana` |
| 13 Nov | Phase 4 CI/CD completed | Successful full GitHub Actions run `43426413120` |
| 13 Nov | Healthy v2 canary promoted | Nomad version 2, deployment `5f0c7bd0` |
| 13 Nov | Unhealthy v3 auto-revert verified | Candidate version 3 failed; recovery version 4 succeeded |
| 13 Nov | Manual revert verified | Candidate version 5 failed; explicit revert to version 4 produced stable version 6 |
| 13 Nov | Controlled CI failure propagated | GitHub Actions `43442086173`: unhealthy candidate version 7 rejected, recovery version 8 succeeded |
| 13 Nov | Final system verified | Stable v2 response, healthy job, deployment `f2b389f5` |
| 13 Nov | Documentation handover assembled | Final report, runbook, guides, validation matrix, risks, screenshots and index |

**Current safe lab setting at last verification:** `LAB_CD_ENABLED=false`. Future status changes should receive a new dated record and fresh runtime evidence. This milestone log is not a substitute for Git history or a live audit log.
