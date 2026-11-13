#!/usr/bin/env bash
set -euo pipefail

repo="$HOME/nomad-auto-rollback-lab"
[[ -d "$repo/.git" ]] || { echo "FAIL: missing Git clone: $repo" >&2; exit 1; }
cd "$repo"
echo "Repository: $(pwd)"
git status -sb
origin=$(git remote get-url origin)
[[ "$origin" == *github.com/atiqa-ai/nomad-auto-rollback-lab.git ]] || { echo "FAIL: unexpected origin: $origin" >&2; exit 1; }

for file in Dockerfile app/app.py app/requirements.txt tests/test_health.py \
  nomad/rollback-demo.nomad.hcl scripts/nomad-lab-deploy.sh .github/workflows/ci-cd.yml; do
  [[ -s "$file" ]] || { echo "FAIL: missing or empty file: $file" >&2; exit 1; }
done

bash -n scripts/nomad-lab-deploy.sh
git diff --check
nomad job validate nomad/rollback-demo.nomad.hcl

for service in docker consul nomad; do
  state=$(systemctl is-active "$service" || true)
  printf '%s: %s\n' "$service" "$state"
  [[ "$state" == active ]] || { echo "FAIL: $service is not active" >&2; exit 1; }
done

nomad node status
nomad job status rollback-demo
echo 'PASS: Phase 4 repository and VM preflight checks'
