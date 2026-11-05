# Architecture and execution boundaries

## Status

**Design document, not an implemented Nomad topology.** Ubuntu, Docker, Nomad, and Consul were reported available, but the provided Docker runtime output matched the known physical-host hostname. The final build/test environment must still be independently identified as a sandbox VM.

## Roles

| Component | Responsibility | Current state |
| --- | --- | --- |
| Physical Ubuntu host | Author and review code, HCL, workflows, docs; no official build/test | Project source authored |
| GitHub repository | Versioned source, pull request, Actions workflows | Not yet integrated |
| CI runner | Executes tests, builds image, publishes to lab registry, submits monitored Nomad deployment | Not configured/verified |
| Lab registry | Stores commit-addressed container images | Not configured/verified |
| Ubuntu sandbox VM | Docker image builds and all tests; Nomad/Consul deployment and failure injection | User reports services ready; VM-specific validation pending |
| Nomad | Schedules stable and canary allocations, monitors deployment, reverts on failure | Job spec not yet authored |
| Consul | Checks `/health` on Nomad-registered service | Integration pending |

## Release design

1. On a trusted push to `main`, run unit tests.
2. Build and publish an image using a commit-specific tag and preferably deploy by immutable image digest.
3. Submit a Nomad job update, ensuring an existing stable version is recorded.
4. Keep the stable allocation running while `canary = 1` starts the candidate allocation.
5. Use Nomad `health_check = "checks"` and a registered HTTP `/health` check so unsuccessful application health prevents promotion.
6. Use `auto_promote = true` for healthy canaries and `auto_revert = true` for failed deployments.
7. Wait for the deployment's terminal success/failure status, not just successful job submission. A revert restoring service does not turn the attempted rollout into a CI success.
8. Collect timestamps and logs for automatic versus manual rollback in separate trials.

**Important:** `auto_revert` reverts to the **last stable job version**; a first-ever broken deployment has no prior stable version to restore. Canary and stable allocations require enough resources to coexist. A Docker HEALTHCHECK alone does not guarantee Nomad will fail the deployment; the Nomad/Consul service-check configuration is essential.

## Planned update policy (subject to live validation)

```hcl
update {
  max_parallel      = 1
  canary            = 1
  auto_revert       = true
  auto_promote      = true
  health_check      = "checks"
  min_healthy_time  = "10s"
  healthy_deadline  = "2m"
  progress_deadline = "3m"
}
```

These deadlines are initial lab candidates, not measured or approved production defaults.

## Network and security decisions to verify

- Determine runner placement only after confirming VM access and isolation; prefer private, dedicated, trusted access to Nomad.
- Restrict Nomad and Consul API reachability to the sandbox network.
- Give the CI runner only the permissions necessary to push lab images and update the specific lab job.
- Avoid PR execution of untrusted code on a privileged self-hosted runner.
- Never place production tokens, organization secrets, or live service credentials in this project.

## Exit criteria

- Corrected image validated with healthy/unhealthy probes inside the VM.
- VM-specific host identity, test results, and logs recorded.
- Subsequent CI, canary, Consul check, and rollback evidence demonstrate the system end-to-end.

## Documentation sources

- https://developer.hashicorp.com/nomad/docs/job-specification/update
- https://docs.docker.com/reference/dockerfile/
- https://docs.github.com/en/actions/reference/security/secure-use
