# Deployment, Canary and Job Review Checklist

**Use:** A review form for *each new lab release*. It is not evidence that every new build has already passed. Capture the release-specific results before approval.

## 1. Before deploying

- [ ] Confirm this is the isolated personal lab and the intended `mariana` VM, not production.
- [ ] Identify reviewed commit SHA, branch and the exact GHCR SHA256 digest.
- [ ] Confirm GitHub Actions test job is green for this commit.
- [ ] Check `nomad job status rollback-demo` and record last stable job version.
- [ ] Verify `docker`, `nomad`, and `consul` are active and the node is ready.
- [ ] Confirm currently deployed app returns HTTP 200 health and expected version.
- [ ] Validate Nomad job HCL; review service port, checks, resource limits, and update strategy.
- [ ] Verify `canary=1`, `auto_promote=true`, `auto_revert=true`, `health_check="checks"` unless an **approved** test intentionally modifies them.
- [ ] Check runner tags, access permissions, SSH pinned host key and main-branch environment restrictions.
- [ ] Confirm the `~/bin` deployment script matches the reviewed source revision.
- [ ] Enable `LAB_CD_ENABLED` only for a planned deployment window.

## 2. While the canary is evaluated

- [ ] Capture Nomad deployment ID and new job version.
- [ ] Check the canary is **placed** and Consul HTTP checks are attached.
- [ ] Confirm expected healthy count or observe the failure reason if unhealthy.
- [ ] Verify no unauthorized changes to stable workload or management APIs.
- [ ] Avoid forcing a promotion or bypassing checks to turn a failed test green.

## 3. Promotion criteria

- [ ] Nomad deployment reports `successful`.
- [ ] Candidate shows `promoted=true` where the update flow includes canary promotion.
- [ ] Consul has a passing `rollback-demo` service.
- [ ] HTTP `/health` says `healthy` and `/version` matches the planned app label.
- [ ] GitHub deployment job is green for a **healthy** release.
- [ ] Job history records the promoted version as stable.

## 4. Failed candidate and recovery

- [ ] Preserve the original deployment failure reason and exit code.
- [ ] Verify the broken candidate never became stable.
- [ ] Record the target stable job version used by automatic or manual recovery.
- [ ] Verify the **recovery** deployment succeeded and HTTP returns healthy.
- [ ] Ensure the original CI run stays failed if the candidate was rejected.
- [ ] Record separate intervals for detection, recovery command and total elapsed test time.

## 5. Post-release closure

- [ ] Confirm current job/version and health again after rollout completion.
- [ ] Restore `LAB_CD_ENABLED=false` when no further automatic lab deployment is planned.
- [ ] Store logs/screenshots with a date, run ID, job version and operator notes.
- [ ] Remove only temporary test resources and secret-bearing temporary files; do not delete Nomad-managed running tasks.
- [ ] Update release notes, validation matrix and evidence index only with actually observed results.
- [ ] Review remaining security and reproducibility gaps.

## 6. Review record template

| Field | Fill for next release |
| --- | --- |
| Date/time (UTC) | To be recorded |
| Reviewer/operator | To be recorded |
| Approved commit SHA | To be recorded |
| GHCR immutable digest | To be recorded |
| Prior stable Nomad job version | To be recorded |
| Candidate deployment ID | To be recorded |
| Outcome and failure reason | To be recorded |
| New stable/recovery version | To be recorded |
| Consul and app verification | To be recorded |
| CI run ID / result | To be recorded |
| CD gate restored | To be recorded |

**Do not complete blanks with fictional evidence.** The historic completed demonstration is documented in the [Phase 5 report](PHASE5_ROLLBACK_TEST_REPORT.md).
