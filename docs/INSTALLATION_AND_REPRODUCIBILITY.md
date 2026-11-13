# Installation, Environment and Reproducibility Guide

**Scope:** Reproduce or verify the *personal, isolated* Nomad Automatic Rollback Lab on an Ubuntu VM. This is an engineering guide; a completely fresh VM has **not** been independently validated using a one-command installer.

## 1. Verified execution environment

| Item | Recorded details |
| --- | --- |
| VM |  Ubuntu 24.04 guest under KVM/virt-manager |
| Services | Docker `29.9.3`, Nomad `2.1.1`, Consul `2.1.0` (recorded environment) |
| Nomad | Single server/client lab, datacenter `dc1`, node `5917225a` ready |
| Job | `rollback-demo` / `web` |
| Management APIs | Nomad `127.0.0.1:4646`, Consul `127.0.0.1:8500` |
| Git working tree | `~/nomad-auto-rollback-lab` |
| Installed deploy command | `~/bin/nomad-lab-deploy` |
| VM deploy source checkout | `~/nomad-lab-cd-source` |
| Evidence | `~/nomad-phase5-evidence` (VM-local, not part of git) |

VM IP addresses and dynamic app ports are ephemeral and must not be copied into permanent operational assumptions. The documented value `192.168.122.83` was observed on the libvirt NAT, and the Tailscale VM IP was `100.111.209.56` on the test date; inspect the current VM before use.

## 2. Prerequisites

- Personal isolated Ubuntu VM with internet access for initial installation, image pull and GHCR/Tailscale activities.
- Working Docker Engine, HashiCorp Nomad server/client, and Consul agent; configurations appropriate for a **single-node test**, not public production.
- Git, Python 3, `venv`, `curl`, `jq`, `unzip`, SSH, GitHub CLI (`gh`) and Tailscale as appropriate to the task.
- Access to the specific source repository, GHCR package, and GitHub Actions environment.
- A dedicated lab SSH key, pinned SSH host key, Tailscale OAuth client scoped to the CI tag, and protected GitHub environment secrets.
- Sufficient local resources to schedule an existing stable allocation plus a canary (two simultaneously during the update).

**Prerequisites are not proof of installation.** Actual package provisioning and Nomad/Consul agent configuration must be validated for each new VM. The package does not ship scripts claiming a tested fresh-machine bootstrap.

## 3. Prepare or inspect an existing VM

Inside the VM:

```bash
hostnamectl
systemd-detect-virt
systemctl is-active docker nomad consul
nomad node status
nomad server members
consul members
```

Expect all three services active, a ready client and a server leader in this single-node lab. Do not run these commands on an employer or production environment. If this is a fresh VM, follow organization-approved package installation procedures and secure the Nomad and Consul agent configurations before exposing any service; the original full provisioning transcript is **not** available in this documentation package.

## 4. Source and application validation

```bash
cd ~/nomad-auto-rollback-lab
git status --short
git branch --show-current
python3 -m unittest discover -s tests -v
bash -n scripts/nomad-lab-deploy.sh
nomad job validate nomad/rollback-demo.nomad.hcl
```

The supplied VM screenshot documents nine passing tests on 13 November 2026. On a new VM, install dependencies in a Python virtual environment first:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r app/requirements.txt
python -m unittest discover -s tests -v
```

A shell displaying a Python venv does not prove Docker, Nomad or Consul are configured; each layer must be checked independently.

## 5. Build and test local Docker behavior (optional lab-only exercise)

```bash
docker build --pull -t nomad-rollback-demo:local .
docker run -d --name rollback-demo-healthy \
  -p 127.0.0.1:18081:8080 \
  -e APP_VERSION=v1 -e HEALTH_MODE=healthy \
  nomad-rollback-demo:local
docker run -d --name rollback-demo-broken \
  -p 127.0.0.1:18082:8080 \
  -e APP_VERSION=v2 -e HEALTH_MODE=unhealthy \
  nomad-rollback-demo:local
curl -i http://127.0.0.1:18081/health
curl -i http://127.0.0.1:18082/health
```

The healthy request should return HTTP 200; the broken request should return HTTP 503. This test deliberately starts **extra lab containers**. Check name/port availability first, and clean up **only** those test containers afterward (`docker rm -f rollback-demo-healthy rollback-demo-broken`). Do not stop or delete Nomad-managed application containers. If Docker requires `sudo`, use it only according to the guest's configuration.

## 6. GitHub Actions and protected access

Confirm that the repository defines `LAB_CD_ENABLED` and `LAB_TAILSCALE_IP`. The environment named `nomad-lab` needs secrets `TS_OAUTH_CLIENT_ID`, `TS_OAUTH_CLIENT_SECRET`, `LAB_SSH_PRIVATE_KEY`, and `LAB_SSH_KNOWN_HOSTS`. Record only *names*, never values. Tailscale policy should allow the temporary `tag:ci` runner to reach the `tag:nomad-lab` VM on SSH/TCP 22. The GitHub environment should be restricted to the trusted main branch.

The historical lab uses public demo-only GHCR image access for simple pulls. Do not change an image package's visibility without an explicit security review. If a registry package is private, configure registry authentication instead of assuming public access.

Review and install the current deployment script from trusted `main`:

```bash
cd ~/nomad-auto-rollback-lab
git status --short
# Continue only if any reported changes are understood.
git switch main
git pull --ff-only origin main
install -m 0750 scripts/nomad-lab-deploy.sh "$HOME/bin/nomad-lab-deploy"
bash -n "$HOME/bin/nomad-lab-deploy"
```

**Warning:** The remote GitHub workflow calls `~/bin/nomad-lab-deploy`, not merely the source file. After changes to that script, reinstall it to avoid running an outdated version.

## 7. Non-disruptive verification of an existing deployment

```bash
nomad job status rollback-demo
nomad job history rollback-demo
nomad job deployments rollback-demo
bash scripts/phase4-verify.sh
gh variable list
```

`phase4-verify.sh` without arguments requires a healthy Consul endpoint and prints the version. With an argument it accepts only a 12-character lowercase hex commit prefix, so do **not** pass `v2` as that argument. To confirm demo `v2`, examine the printed response or query the endpoint via Consul as described in the [runbook](OPERATIONAL_RUNBOOK.md).

## 8. Reproduction boundary and honest acceptance

**Validated in existing VM:** tests, Nomad/Consul job, healthy canary, bad canary rejection, automatic/manual revert, full CI publish/deploy and failure propagation. **Not validated from empty VM:** turnkey installation, repeatable provisioning without manual configuration, first-time Tailscale OAuth onboarding, OS reinstallation/host replacement and long-duration availability. Do not label a fresh environment “ready” until it passes its own acceptance matrix and supplies time-stamped evidence.

Next reading: [Phase 4 VM guide](PHASE4_VM_GUIDE.md) → [operational runbook](OPERATIONAL_RUNBOOK.md) → [final validation](VALIDATION.md).
