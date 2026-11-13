# Security, Risk and Limitations Assessment

**Context:** Isolated personal lab; risk analysis is scoped to the observed design and screenshots, not a penetration test or production certification.

## 1. Implemented protective measures

| Control | Evidence or configured behavior | Limit |
| --- | --- | --- |
| Separate lab VM | Nomad/Consul/Docker deployed on `mariana` | Single-node host compromise can affect all components |
| Loopback management APIs | Nomad `127.0.0.1:4646`, Consul `127.0.0.1:8500` | Binding is not a substitute for full ACL/mTLS hardening |
| Private runner connectivity | Tailscale tags and TCP 22 grant to VM | Tailscale and policy administration still require protection |
| SSH host identity | Pinned known-host key, strict checking | Key rotation needs an authorized workflow |
| Scoped GitHub environment secrets | Tailscale OAuth / SSH stored as secrets | Secret configuration and rotation not independently audited |
| Manual deployment kill switch | `LAB_CD_ENABLED=false` after testing | Needs branch/environment governance to prevent abuse |
| Digest-pinned Docker artifact | SHA256 image identity passed into Nomad | No signed provenance chain independently verified |
| Reviewed source merges | Pull requests #1 and #2 in project record | Branch protections were not independently audited |
| Scheduler health gate | Consul checks, canary and auto-revert | HTTP health does not cover all failure classes |

## 2. Risk register

| ID | Risk | Likelihood / impact (qualitative) | Mitigation / ownership |
| --- | --- | --- | --- |
| R01 | Single VM failure takes down lab | Medium / High | Accept in lab; use redundant nodes before production |
| R02 | Unhealthy candidate accidentally deployed outside lab | Low / High if misused | Keep test input opt-in, restrict environments, require authorized operator |
| R03 | GitHub Actions privileged workflow exposed to untrusted PR | Medium / High | Deploy only trusted main; avoid privileged PR jobs |
| R04 | SSH private key or OAuth token leaked | Medium / High | GitHub environment secrets, minimal permissions, rotation, no commit/log exposure |
| R05 | Tailscale policy allows broader peer access | Medium / Medium | Review grant scope, remove permissive defaults, record tags |
| R06 | Nomad/Consul management interfaces exposed | Low in verified design / High if changed | Loopback binding, host firewall, never publish to internet |
| R07 | Stale `~/bin/nomad-lab-deploy` invoked by CI | Medium / Medium | Reinstall from reviewed main after changes; syntax/functional checks |
| R08 | Wrong historical job version reverted | Medium / Medium | Use job history, version review and explicit operator confirmation |
| R09 | Health endpoint returns OK despite deeper app defect | Medium / Medium | Add dependency checks, traffic tests, metrics and realistic workloads |
| R10 | Misleading report says zero downtime or quantified MTTR | Medium / Medium | Distinguish command duration, recovery segment and actual outage |
| R11 | Image digest changed between review and deployment | Low / Medium with current design | Pin digest; verify commit ancestry and published digest |
| R12 | Clean-VM instructions drift from real configuration | Medium / Medium | Perform separate clean-room bootstrap before promising reproducibility |

The likelihood/impact labels are qualitative reviewer judgments, **not measured incident probabilities or scores**.

## 3. Credential protection checklist

- Do not commit `authfile`, SSH private keys, OAuth secrets, token exports, or `.env` content.
- GitHub Actions environment should separate deployment secrets from untrusted PR contexts.
- Rotate any exposed credential through its owning service; merely deleting a chat message or file does not invalidate it.
- Prefer least-privilege deployment identities; the documented VM deployment used user `manoo` for the lab.
- Sanitize screenshots and logs before publishing evidence. The eight supplied screenshots are operational captures; review them again prior to public release.

## 4. Model of safety, not proof of production resilience

The lab provides real engineering evidence for safe canary health gating and reversion in a controlled single-node environment. It does **not** provide certified access control, encrypted Nomad RPC/API transport hardening, high-availability quorum, network fault tolerance, full image signing or formal disaster recovery. In production, these controls require independent design, validation and authorization.

## 5. Operational guardrails

The running `rollback-demo` job should remain healthy while documentation is updated. Do not run `nomad job stop`, delete all Docker containers, open public management ports, weaken SSH host checking, or rerun intentional `HEALTH_MODE=unhealthy` workflows without an explicit lab testing purpose. All future tests should use a separate evidence folder and record their exact context.

## 6. Residual decisions before broader use

1. Add tested clean-VM bootstrap/provisioning and configuration backup.
2. Add Nomad/Consul ACLs, authentication, mTLS and least-privilege operator roles.
3. Define real HTTP error-rate, latency, availability and recovery SLO measurements.
4. Validate two-node/multi-node failure modes on purpose-built infrastructure.
5. Establish image signing/provenance and artifact retention policy.
6. Document secure credential rotation and incident escalation procedures.

These are future improvement options, not delivered project capabilities.
