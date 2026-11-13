# Phase 4 — VM-only execution guide

Project: `https://github.com/atiqa-ai/nomad-auto-rollback-lab`
VM: `mariana`, user: `manoo`
All terminal commands in this guide are run *inside the VM*, not the physical Ubuntu host.

## Acceptance boundary

The provided bundle implements a GitHub Actions workflow that tests, publishes to GitHub Container Registry (GHCR), and (after an explicit safety switch) connects to the VM over Tailscale and submits the published SHA256 image to Nomad. Preparing the files is **not** proof of live GitHub/VM success. Mark Phase 4 complete only after all green checks in §6 have been observed.

The source files verified for Phase 3 are in `~/nomad-rollback-import/nomad-auto-rollback-lab-main`, and the Git clone is `~/nomad-auto-rollback-lab`. Preserve the running Nomad `rollback-demo` job. Do not execute `nomad job stop`, or re-run the old HCL file accidentally.

## 1. Synchronize the Git repository in mariana

```bash
cd ~/nomad-auto-rollback-lab
git status -sb
git remote -v
```

The tree should be clean and on `main`, tracking `origin/main`. If it is not clean, **stop and review changes** before switching branches.

```bash
git switch main
git pull --ff-only origin main
if git show-ref --verify --quiet refs/heads/feat/phase4-ci-cd; then
  git switch feat/phase4-ci-cd
else
  git switch -c feat/phase4-ci-cd
fi
```

Preserve the exact working Phase-3 job before replacing its *source file*:

```bash
mkdir -p ~/nomad-phase4-backup
cp -n ~/nomad-rollback-import/nomad-auto-rollback-lab-main/nomad/rollback-demo.nomad.hcl \
  ~/nomad-phase4-backup/rollback-demo-phase3.nomad.hcl
```

Download `nomad_phase4_vm_only.zip` through the VM browser into `~/Downloads` (if Chrome saves elsewhere, use the real path). Then:

```bash
cd ~/nomad-auto-rollback-lab
ZIP=$(find "$HOME/Downloads" -maxdepth 3 -type f -name 'nomad_phase4_vm_only.zip' -print -quit)
test -n "$ZIP" || { echo 'ZIP not found; check browser downloads'; exit 1; }
unzip -t "$ZIP"
mkdir -p ~/phase4-staging
unzip -oq "$ZIP" -d ~/phase4-staging
mkdir -p .github/workflows nomad scripts docs
cp -i ~/phase4-staging/.github/workflows/ci-cd.yml .github/workflows/
cp -i ~/phase4-staging/nomad/rollback-demo.nomad.hcl nomad/
cp -i ~/phase4-staging/scripts/nomad-lab-deploy.sh scripts/
cp -i ~/phase4-staging/scripts/phase4-preflight.sh scripts/
cp -i ~/phase4-staging/scripts/phase4-verify.sh scripts/
cp -i ~/phase4-staging/docs/PHASE4_VM_GUIDE.md docs/
cp -i ~/phase4-staging/docs/VALIDATION.md docs/
chmod +x scripts/*.sh
bash scripts/phase4-preflight.sh
```

The job HCL variables default to the same local image and v1 as Phase 3; **do not run that HCL now**. The deployed running job is unchanged by copying source files.

To commit:

```bash
cd ~/nomad-auto-rollback-lab
git add .github/workflows/ci-cd.yml nomad/rollback-demo.nomad.hcl \
  scripts/nomad-lab-deploy.sh scripts/phase4-preflight.sh scripts/phase4-verify.sh \
  docs/PHASE4_VM_GUIDE.md docs/VALIDATION.md
git diff --cached --check
git status -sb
git commit -m 'feat: add lab CI GHCR and Nomad CD'
git push -u origin feat/phase4-ci-cd
```

If HTTPS authentication fails, use `gh auth login` in the VM or another secure GitHub authentication workflow. Do not paste GitHub passwords into the terminal or conversation. Open a PR from `feat/phase4-ci-cd` to `main` on GitHub. The PR triggers Python unit tests only; publish and deploy skip. Review and merge into protected `main` after CI is green. Only trusted maintainers should be able to merge into `main`, especially because it controls a deployment-capable workflow.

## 2. Publish image to GHCR

`main` push runs Python tests, Docker build and GHCR publish with a `sha-<full 40-char commit>` tag and immutable SHA256 digest. Check the actual workflow run at `https://github.com/atiqa-ai/nomad-auto-rollback-lab/actions`. `GITHUB_TOKEN` has `packages: write` permission in the publishing job. The package must allow the repository's GitHub Actions token to publish it; if a package with the same name pre-exists, adjust its package access settings rather than assuming permissions.

This lab design uses a **public demo-only container package** so Nomad can pull without private registry credentials. Newly published GHCR packages can default to private. Making a package public may be irreversible; do so only if you explicitly accept public image access. If it must remain private, pause deployment and change the registry authentication design; do not disable image verification.

After publishing, on the VM, replace the placeholder with the real full SHA:

```bash
sudo docker pull ghcr.io/atiqa-ai/nomad-auto-rollback-lab:sha-FULL_40_CHARACTER_SHA
```

Verify the digest shown matches the one in the workflow output.

## 3. Secure GitHub-hosted runner to private VM connectivity

The VM's NAT IP `192.168.122.83` is not reachable from GitHub-hosted runners. Use a tagged, temporary Tailscale GitHub runner and VM tailnet membership; don't install a permanent privileged self-hosted Actions runner on the public repo VM. This lab has no Nomad mTLS or Consul ACLs and must remain isolated and inaccessible from untrusted networks.

### 3A — VM SSH and Tailscale

On `mariana`:

```bash
sudo apt update
sudo apt install -y openssh-server curl jq git
sudo systemctl enable --now ssh
systemctl is-active ssh
curl -fsSL https://tailscale.com/install.sh -o /tmp/install-tailscale.sh
# Review the script if desired; this is the vendor's published Linux installer.
sudo sh /tmp/install-tailscale.sh
```

In the Tailscale admin console create tags `tag:ci` and `tag:nomad-lab` with suitable `tagOwners`, restrict grants and allow `tag:ci` to `tag:nomad-lab` *TCP 22 only*. A grant entry to merge into the existing tailnet policy is:

```json
{"src":["tag:ci"],"dst":["tag:nomad-lab"],"ip":["tcp:22"]}
```

The `grants` array is additive: review other existing grants (especially default allow-all), and never replace the entire tailnet policy with only this example. Once tag owner authorization is set up on the tailnet, inside the VM:

```bash
sudo tailscale up --advertise-tags=tag:nomad-lab
tailscale status
tailscale ip -4
```

Tailscale sign-in is an interactive user step. Ensure the `mariana` device shows the intended tag in the admin console. The VM host must have outbound connectivity. Do not open router inbound ports.

### 3B — Dedicated SSH key, generated on the VM (physical host not needed)

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [ ! -f ~/.ssh/nomad_lab_ci ]; then
  ssh-keygen -t ed25519 -f ~/.ssh/nomad_lab_ci -N ''
fi
cat ~/.ssh/nomad_lab_ci.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

This key is dedicated to the sandbox CI workflow; never commit it. In a hardened design use a separate low-privilege SSH user / constrained authorization, but for this isolated lab `manoo` is the same user that can run the local Nomad CLI.

Create the expected host key line using the **trusted VM console**, rather than trusting unauthenticated network discovery:

```bash
VM_TS_IP=$(tailscale ip -4)
test -n "$VM_TS_IP"
awk -v ip="$VM_TS_IP" '{print ip, $1, $2}' \
  /etc/ssh/ssh_host_ed25519_key.pub > ~/.ssh/nomad_lab_known_hosts
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -lf ~/.ssh/nomad_lab_known_hosts
ssh -i ~/.ssh/nomad_lab_ci \
  -o IdentitiesOnly=yes \
  -o UserKnownHostsFile="$HOME/.ssh/nomad_lab_known_hosts" \
  -o StrictHostKeyChecking=yes \
  "manoo@${VM_TS_IP}" 'whoami && nomad job status rollback-demo'
```

Both fingerprints must match. SSH command should show `manoo` and the running Nomad job. If it does not work, fix SSH/Tailscale before enabling CD; never disable strict host-key checking.

### 3C — Tailscale GitHub Action credentials

In the Tailscale admin console, create an OAuth client with `Auth Keys > Write` scope and capability to use `tag:ci` according to the official action guide. In GitHub repository Settings → Environments create `nomad-lab` and restrict deployment branches to `main`.

Create these **environment secrets** under the `nomad-lab` environment:

- `TS_OAUTH_CLIENT_ID` — Tailscale OAuth client ID
- `TS_OAUTH_CLIENT_SECRET` — Tailscale OAuth client secret
- `LAB_SSH_PRIVATE_KEY` — full contents of `~/.ssh/nomad_lab_ci` (private key)
- `LAB_SSH_KNOWN_HOSTS` — contents of `~/.ssh/nomad_lab_known_hosts` (trusted host key)

Under repo Settings → Secrets and variables → Actions → Variables create:

- `LAB_TAILSCALE_IP` = exact result of `tailscale ip -4` on VM
- `LAB_CD_ENABLED` = `false` until ready

Do not paste secrets into conversation or log output. Avoid mandatory deployment approval if the intent is fully automatic deployment from a reviewed `main` push; protect `main` and environment branch policy instead. Never make this VM a production target.

## 4. Install deployment script inside the VM

After the Phase 4 PR is merged into main, from the cloned repo on VM:

```bash
cd ~/nomad-auto-rollback-lab
git switch main
git pull --ff-only origin main
mkdir -p ~/bin
install -m 0750 scripts/nomad-lab-deploy.sh ~/bin/nomad-lab-deploy
bash -n ~/bin/nomad-lab-deploy
nomad job validate nomad/rollback-demo.nomad.hcl
```

The script verifies the SHA belongs to `main`, checks image digest format, validates the job, plans with a compare-and-swap modify index, monitors the Nomad deployment, and checks a version-matching Consul-passing endpoint.

## 5. First automatic deployment

Ensure the registry image can be pulled by `sudo docker pull`, SSH connectivity to the VM's Tailscale IP passes, and Tailscale GitHub Action credentials have been configured. Then set `LAB_CD_ENABLED=true` in GitHub repo variables. Trigger Actions → `Nomad Lab CI-CD` → Run workflow → `main` or push a reviewed new main commit.

Expected in sequence: `Python Unit Tests` passes 9/9; `Docker Build and GHCR Publish` publishes SHA tag and digest; `Deploy to Isolated Nomad VM` connects over Tailscale + SSH, runs the VM script, reports `PASS` with first 12 chars of the main commit SHA.

A failed Nomad rollout must fail the GitHub deploy job; do not use `|| true`, `continue-on-error`, or `nomad job run -detach` to hide failures.

## 6. Verification and completion

From the VM:

```bash
cd ~/nomad-auto-rollback-lab
bash scripts/phase4-verify.sh FIRST_12_CHARS_OF_DEPLOYED_MAIN_COMMIT
nomad job deployments rollback-demo
consul catalog services
```

Only mark Phase 4 **100% complete** after: green tests on main, GHCR image digest published, VM can pull it, secure runner-to-VM SSH/Tailscale verified, deployment successful and version-matched, Consul passing `/health`, and workflow deploy job green. Keep the actual GitHub Actions run URL, image digest, Nomad deployment ID, and test results as evidence.

## Sources

- GitHub GHCR: https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images
- Tailscale GitHub Action: https://tailscale.com/docs/integrations/github/github-action
- Nomad plan: https://developer.hashicorp.com/nomad/commands/job/plan
- Nomad run: https://developer.hashicorp.com/nomad/commands/job/run
- Nomad updates: https://developer.hashicorp.com/nomad/docs/job-specification/update
