# Final Project Handover and Documentation Checklist

**Handover review:** 13 November 2026  
**Delivery type:** Documentation package + preserved screenshot evidence; **not** a replacement of executable project source files

## 1. Completed technical demonstrations

- [x] Flask application with configurable health/version.
- [x] Nine Python unit tests passed on VM.
- [x] Docker image and GHCR published immutable digest.
- [x] Nomad/Consul service and stable deployment on isolated VM.
- [x] Secure Tailscale/SSH-based GitHub runner-to-VM deployment path exercised.
- [x] Healthy canary automatically promoted.
- [x] Unhealthy candidate rejected on progress deadline.
- [x] Nomad automatic revert demonstrated.
- [x] Manual revert demonstrated.
- [x] GitHub Actions reports rejected deployment as failed even after recovery.
- [x] Final state verified healthy v2, stable Nomad job version 8.
- [x] Deployment gate set `LAB_CD_ENABLED=false` after tests.

## 2. Documents provided in this archive

- [x] Root navigation README with direct links.
- [x] Final report (Markdown and editable Word).
- [x] Implemented architecture and component boundaries.
- [x] Installation/prerequisite/reproducibility guide.
- [x] Phase 2 application/container validation record.
- [x] Phase 4 VM CI/CD release guide.
- [x] Phase 5 automatic/manual rollback test report.
- [x] Consolidated validation/acceptance matrix.
- [x] Operational runbook and troubleshooting table.
- [x] Security/risk assessment.
- [x] Deployment job review checklist.
- [x] Screenshot/evidence index and eight image files.
- [x] Milestone/change log.



## 4. Instructions for incorporating documentation into Git

1. Extract the ZIP without flattening its directory structure.
2. Review all Markdown and screenshot files; ensure there are no screenshots of private data or environment secret values.
3. Copy the selected `README.md`, `docs/`, `reports/` and `screenshots/` into the project Git working tree. Existing source in `app/`, `nomad/`, `scripts/` and `.github/` must remain untouched.
4. Review the file diff (`git status --short`, `git diff --check`); ensure README relative links resolve.
5. Commit to a documentation-only branch and open a pull request. Since raw logs are not included, do not write that they have been archived into the Git repository.
6. Keep the stable job running and `LAB_CD_ENABLED=false` while documenting.

## 5. Transfer acceptance record

| Item | Final observed state |
| --- | --- |
| CI healthy run | `43426413120` — passed all jobs |
| CI intentionally failed run | `43442086173` — deployment job failed as intended |
| Final job | `rollback-demo` version 8 stable |
| Final deployment | `f2b389f5` successful |
| Final application | `v2`, `healthy` |
| Evidence | 8 images in archive; 14 raw evidence files inventoried on VM |
| Automatic deployment control | `LAB_CD_ENABLED=false` |

