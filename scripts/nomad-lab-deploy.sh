#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: nomad-lab-deploy COMMIT_SHA IMAGE_DIGEST" >&2
  exit 64
fi

commit="$1"
digest="$2"
mode="${3:-healthy}"
[[ "$mode" == healthy || "$mode" == unhealthy ]] || exit 64
[[ "$commit" =~ ^[a-f0-9]{40}$ ]] || { echo "Invalid 40-character commit SHA" >&2; exit 64; }
[[ "$digest" =~ ^sha256:[a-f0-9]{64}$ ]] || { echo "Invalid SHA256 image digest" >&2; exit 64; }

image="ghcr.io/atiqa-ai/nomad-auto-rollback-lab@${digest}"
version="${commit:0:12}"
repo="$HOME/nomad-lab-cd-source"

for tool in git nomad curl jq; do
  command -v "$tool" >/dev/null || { echo "Missing dependency: $tool" >&2; exit 1; }
done

if [[ ! -d "$repo/.git" ]]; then
  git clone --no-checkout https://github.com/atiqa-ai/nomad-auto-rollback-lab.git "$repo"
fi

git -C "$repo" fetch --no-tags origin "+refs/heads/main:refs/remotes/origin/main"
git -C "$repo" cat-file -e "${commit}^{commit}" || { echo "Commit not available" >&2; exit 1; }
git -C "$repo" merge-base --is-ancestor "$commit" origin/main || {
  echo "Refusing to deploy a commit outside origin/main" >&2
  exit 1
}
git -C "$repo" checkout --force --detach "$commit"
job="$repo/nomad/rollback-demo.nomad.hcl"
[[ -f "$job" ]] || { echo "Missing Nomad job in fetched commit: $job" >&2; exit 1; }

echo "Deploy commit=$commit version=$version image=$image"
nomad job validate -var="image=$image" -var="app_version=$version" -var="health_mode=$mode" "$job"

plan_file=$(mktemp)
trap 'rm -f "$plan_file"' EXIT
set +e
nomad job plan -no-color \
  -var="image=$image" -var="app_version=$version" -var="health_mode=$mode" "$job" > "$plan_file" 2>&1
plan_rc=$?
set -e
cat "$plan_file"
if [[ "$plan_rc" -ne 0 && "$plan_rc" -ne 1 ]]; then
  echo "Nomad plan failed: exit $plan_rc" >&2
  exit 1
fi

check_index=$(sed -n 's/^Job Modify Index: \([0-9][0-9]*\)$/\1/p' "$plan_file" | tail -n 1)
[[ "$check_index" =~ ^[0-9]+$ ]] || { echo "Missing Nomad Job Modify Index" >&2; exit 1; }

nomad job run -check-index "$check_index" \
  -var="image=$image" -var="app_version=$version" -var="health_mode=$mode" "$job"

for attempt in $(seq 1 30); do
  if health_json=$(curl -fsS --max-time 6 \
    'http://127.0.0.1:8500/v1/health/service/rollback-demo?passing=true'); then
    mapfile -t endpoints < <(jq -r '.[] | "http://\(if .Service.Address == "" then .Node.Address else .Service.Address end):\(.Service.Port)"' <<< "$health_json")
    for endpoint in "${endpoints[@]}"; do
      [[ -n "$endpoint" ]] || continue
      if version_json=$(curl -fsS --connect-timeout 3 --max-time 5 "$endpoint/version" 2>/dev/null) &&
         health_payload=$(curl -fsS --connect-timeout 3 --max-time 5 "$endpoint/health" 2>/dev/null); then
        actual_version=$(jq -r '.version // ""' <<< "$version_json" 2>/dev/null || true)
        actual_health=$(jq -r '.status // ""' <<< "$health_payload" 2>/dev/null || true)
        if [[ "$actual_version" == "$version" && "$actual_health" == 'healthy' ]]; then
          echo "PASS: Consul passing, version=$version at $endpoint"
          nomad job status rollback-demo
          exit 0
        fi
      fi
    done
  fi
  sleep 3
done

echo "FAIL: deployed version $version did not achieve passing Consul and HTTP health" >&2
nomad job status rollback-demo >&2 || true
exit 1
