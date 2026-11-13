#!/usr/bin/env bash
set -euo pipefail

expected="${1:-}"
if [[ -n "$expected" && ! "$expected" =~ ^[a-f0-9]{12}$ ]]; then
  echo 'Usage: phase4-verify.sh [first_12_characters_of_main_commit_sha]' >&2
  exit 64
fi
for svc in docker consul nomad; do
  [[ "$(systemctl is-active "$svc")" == active ]] || { echo "FAIL: $svc not active" >&2; exit 1; }
done
nomad job status rollback-demo
service_json=$(curl -fsS --max-time 10 \
  'http://127.0.0.1:8500/v1/health/service/rollback-demo?passing=true')
mapfile -t endpoints < <(jq -r '.[] | "http://\(if .Service.Address == "" then .Node.Address else .Service.Address end):\(.Service.Port)"' <<< "$service_json")
[[ ${#endpoints[@]} -gt 0 ]] || { echo 'FAIL: no passing Consul rollback-demo services' >&2; exit 1; }
for endpoint in "${endpoints[@]}"; do
  if health=$(curl -fsS --max-time 5 "$endpoint/health" 2>/dev/null) &&
     version=$(curl -fsS --max-time 5 "$endpoint/version" 2>/dev/null); then
    h=$(jq -r '.status // ""' <<< "$health" 2>/dev/null || true)
    v=$(jq -r '.version // ""' <<< "$version" 2>/dev/null || true)
    if [[ "$h" == healthy && ( -z "$expected" || "$v" == "$expected" ) ]]; then
      printf 'PASS: %s, version=%s, health=%s\n' "$endpoint" "$v" "$h"
      exit 0
    fi
  fi
done
echo "FAIL: No matching healthy endpoint (expected=${expected:-any})" >&2
exit 1
