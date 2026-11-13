#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "ERROR: Setup failed at line $LINENO. Existing lab services/jobs have not been intentionally stopped." >&2' ERR

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo"
mode="${1:---bootstrap}"
[[ "$mode" == '--check' || "$mode" == '--bootstrap' ]] || { echo "Usage: $0 [--check|--bootstrap]" >&2; exit 2; }
[[ -f app/app.py && -f Dockerfile && -f nomad/rollback-demo.nomad.hcl ]] || {
  echo 'ERROR: Run from the complete lab repository (app/, Dockerfile, nomad/ required).' >&2; exit 1;
}
[[ -r /etc/os-release ]] || { echo 'ERROR: OS not recognized' >&2; exit 1; }
. /etc/os-release
[[ "${ID:-}" == ubuntu ]] || { echo 'ERROR: Ubuntu required' >&2; exit 1; }
[[ "${VERSION_ID:-}" == 24.04 || "${VERSION_ID:-}" == 26.04 ]] || {
  echo "ERROR: Ubuntu ${VERSION_ID:-unknown} not validated by this lab script." >&2; exit 1;
}

check_existing() {
  for app in docker nomad consul python3 git curl; do
    command -v "$app" >/dev/null || { echo "MISSING: $app"; return 1; }
  done
  [[ $(systemctl is-active docker 2>/dev/null || true) == active ]] || { echo "NOT ACTIVE: docker"; return 1; }
  for svc in nomad consul; do
    [[ $(systemctl is-active "$svc" 2>/dev/null || true) == active || $(systemctl is-active "${svc}-rollback-lab" 2>/dev/null || true) == active ]] || {
      echo "NOT ACTIVE: $svc (or ${svc}-rollback-lab)"; return 1;
    }
  done
  nomad node status
  nomad job status rollback-demo
  bash "$repo/scripts/phase4-verify.sh"
  echo 'PASS: Existing lab environment and service verified; no changes made.'
}

if [[ "$mode" == '--check' ]]; then
  check_existing
  exit $?
fi

# Never replace a running job, a pre-existing agent, or custom host configuration.
if command -v nomad >/dev/null 2>&1 && nomad job status rollback-demo >/dev/null 2>&1; then
  echo 'Existing rollback-demo job detected. Skipping installation and deployment.'
  check_existing
  exit $?
fi
for svc in nomad consul nomad-rollback-lab consul-rollback-lab; do
  if [[ $(systemctl is-active "$svc" 2>/dev/null || true) == active ]]; then
    echo "ERROR: $svc is already active. Bootstrap refused to avoid disrupting existing services." >&2
    exit 3
  fi
done
if command -v nomad >/dev/null 2>&1 || command -v consul >/dev/null 2>&1; then
  echo 'ERROR: Nomad or Consul already installed. Use this bootstrap only on a clean lab VM.' >&2
  exit 3
fi
if [[ -e /etc/systemd/system/nomad-rollback-lab.service || -e /etc/systemd/system/consul-rollback-lab.service ]]; then
  echo 'ERROR: A previous lab systemd unit already exists. Review it manually.' >&2
  exit 3
fi

command -v sudo >/dev/null || { echo 'ERROR: sudo required' >&2; exit 1; }
sudo -v
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git jq python3 python3-venv

if ! command -v docker >/dev/null; then
  sudo install -d -m 0755 /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
fi
sudo systemctl enable --now docker

# Official signed HashiCorp packages. These install new binaries, not custom credentials.
sudo install -d -m 0755 /usr/share/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${UBUNTU_CODENAME:-$VERSION_CODENAME} main" |
  sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
sudo apt-get update
sudo apt-get install -y nomad consul

# Package-provided agents are not used by this isolated local-only lab.
# On a clean VM only: stop newly installed default units before lab units start.
sudo systemctl disable --now nomad consul 2>/dev/null || true
sudo install -d -m 0755 /etc/nomad-rollback-lab /etc/consul-rollback-lab /var/lib/nomad-rollback-lab
sudo install -d -m 0750 -o consul -g consul /var/lib/consul-rollback-lab

sudo tee /etc/consul-rollback-lab/consul.hcl >/dev/null <<'EOF'
datacenter = "dc1"
data_dir = "/var/lib/consul-rollback-lab"
server = true
bootstrap_expect = 1
bind_addr = "127.0.0.1"
client_addr = "127.0.0.1"
ui_config { enabled = true }
EOF

sudo tee /etc/nomad-rollback-lab/nomad.hcl >/dev/null <<'EOF'
data_dir = "/var/lib/nomad-rollback-lab"
datacenter = "dc1"
bind_addr = "127.0.0.1"
addresses { http = "127.0.0.1" }
server {
  enabled = true
  bootstrap_expect = 1
}
client {
  enabled = true
  servers = ["127.0.0.1:4647"]
}
consul { address = "127.0.0.1:8500" }
EOF

sudo tee /etc/systemd/system/consul-rollback-lab.service >/dev/null <<'EOF'
[Unit]
Description=Isolated Consul lab agent
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-file=/etc/consul-rollback-lab/consul.hcl
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
sudo tee /etc/systemd/system/nomad-rollback-lab.service >/dev/null <<'EOF'
[Unit]
Description=Isolated single-node Nomad lab agent
After=network-online.target docker.service consul-rollback-lab.service
Requires=docker.service
Wants=network-online.target consul-rollback-lab.service
[Service]
Type=simple
User=root
ExecStart=/usr/bin/nomad agent -config=/etc/nomad-rollback-lab/nomad.hcl
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

sudo consul validate /etc/consul-rollback-lab/consul.hcl
sudo systemctl daemon-reload
sudo systemctl enable --now consul-rollback-lab nomad-rollback-lab

ready=0
for _ in $(seq 1 30); do
  if nomad node status 2>/dev/null | grep -q 'ready'; then ready=1; break; fi
  sleep 2
done
[[ "$ready" == 1 ]] || { echo 'ERROR: Nomad client not ready; inspect journalctl -u nomad-rollback-lab' >&2; exit 1; }

python3 -m venv .venv
.venv/bin/python -m pip install -r app/requirements.txt
.venv/bin/python -m unittest discover -s tests -v
sudo docker build -t nomad-rollback-demo:local .
nomad job validate -var='image=nomad-rollback-demo:local' -var='app_version=v1' -var='health_mode=healthy' nomad/rollback-demo.nomad.hcl
nomad job run -var='image=nomad-rollback-demo:local' -var='app_version=v1' -var='health_mode=healthy' nomad/rollback-demo.nomad.hcl
nomad job status rollback-demo
echo 'BOOTSTRAP COMPLETE: Verify Consul-passing /health and /version before sign-off.'
echo 'This local setup does not configure GitHub/Tailscale credentials or prove clean-VM CI/CD connectivity.'
