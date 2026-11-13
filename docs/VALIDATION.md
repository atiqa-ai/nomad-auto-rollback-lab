# Phase 4 validation record

Prepared bundle — not yet deployed to the user's VM or GitHub.

Local static checks: shell script syntax, GitHub Actions YAML parsed, expected files and workflow jobs validated, ZIP archive CRC. The official Nomad docs confirm that `job plan` returns 0 for no change, 1 for scheduling changes, and 255 on planning error. Nomad `job run` blocks until completion by default and returns non-zero for failed deployments. This avoids reporting a rollback-triggering failed update as success.

User-side live tests required: VM `nomad job validate`, GitHub PR test job, GitHub main publish job, GHCR pull, tagged Tailscale access, pinned SSH identity verification, Nomad deployment, Consul passing health and deployed version equality. No claim is made that live Phase 4 completion has occurred.
