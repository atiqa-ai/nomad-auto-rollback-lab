# Nomad Automatic Rollback Lab

> **Status:** Application and container behavior demonstrated; final sandbox-VM retest and the Nomad/GitHub Actions pipeline are **not yet complete**.

## Purpose

This repository is a lab-only demonstration of safe application delivery with GitHub Actions, Docker, HashiCorp Nomad, and Consul. The target workflow is to push a change to `main`, build and publish an immutable container image, deploy it as a Nomad canary, check its health through Consul, and automatically revert a failed deployment to the last stable job version. CI must report a failed rollout as a failure even when the rollback restores service.

Only **owned sandbox VMs**, test registries, and lab credentials may be used for builds, tests, deployments, and failure injection. Source code and documentation may be authored on the Ubuntu host. Never access Glynac production servers or secrets.

## System architecture

```text
Ubuntu development host (editing only)
                 |
                 v
       GitHub repository
                 |
       GitHub Actions (planned)
          |           |
          v           v
  Tests + build    Lab image registry
                      |
                      v
            Ubuntu sandbox VM
       Nomad + Docker + Consul
                      |
               Canary update
                /         \
        Healthy            Unhealthy
           |                   |
     Auto-promote       Deployment fails
                               |
                        Nomad auto-revert
                               |
                     CI reports failure
```

The diagram illustrates the **target** architecture; it does not mean Nomad rollback has already been implemented. See [Architecture & boundaries](docs/architecture.md).

## Repository layout

```text
.
├── app/
│   ├── __init__.py
│   ├── app.py
│   └── requirements.txt
├── tests/
│   └── test_health.py
├── docs/
│   ├── architecture.md
│   └── phase2-validation.md
├── Dockerfile
├── .dockerignore
├── .gitignore
└── README.md
```

`nomad/`, `.github/workflows/`, setup automation, rollout scripts, operational runbook, and production-review checklist will be added and tested in later implementation stages. **There is not yet a verified one-command lab bootstrap**.

## Application contract

The Flask service is served by Gunicorn on container port `8080`.

| Method and path | Behavior |
| --- | --- |
| `GET /` | JSON service information and current application version, HTTP 200 |
| `GET /health` | JSON health result, HTTP 200 in healthy mode or HTTP 503 in intentionally unhealthy mode |
| `GET /version` | JSON version string, HTTP 200 |

| Environment variable | Default | Purpose |
| --- | --- | --- |
| `APP_VERSION` | `v1` | Identifies the version being served; setting this alone does not rebuild the image |
| `HEALTH_MODE` | `healthy` | Setting to `unhealthy` (case-insensitive) makes `/health` return HTTP 503 |

Expected healthy response: `{"status":"healthy","version":"v1"}` (HTTP 200).

Expected unhealthy response: `{"status":"unhealthy","version":"v2"}` (HTTP 503).

**Note:** The controlled failure is introduced through configuration; this allows unit tests to pass while the later rollout fails its live health checks. The example version value is demonstration metadata, not an immutable image identity.

## Lab prerequisites

Inside the **sandbox VM**: a functional Docker Engine, Python 3 with `venv` support, network access for dependency and base-image downloads, and sufficient disk/memory for a build plus two running containers. Nomad and Consul will be needed for subsequent deployment stages. Source code must first be copied or cloned into the sandbox VM.

Do not run official build, automated testing, or intentional failure injection on the physical Ubuntu host.

## Local validation inside the sandbox VM

From the repository root, run:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r app/requirements.txt
python -m unittest discover -s tests -p 'test_*.py' -v
```

The supplied test suite contains nine cases. Check that all tests pass, rather than assuming success from this README.

Build the image:

```bash
docker build --pull -t nomad-rollback-demo:local .
docker image inspect nomad-rollback-demo:local --format 'Image user: {{.Config.User}}'
docker image inspect nomad-rollback-demo:local --format 'Command: {{json .Config.Cmd}}'
```

The intended user is `appuser` (UID 10001). The Gunicorn command should include `--no-control-socket` after the reported correction.

Start the controlled healthy and unhealthy instances (use only if these container names are not already in use):

```bash
docker run -d --name rollback-demo-healthy \
  -p 127.0.0.1:18081:8080 \
  -e APP_VERSION=v1 -e HEALTH_MODE=healthy \
  nomad-rollback-demo:local

docker run -d --name rollback-demo-broken \
  -p 127.0.0.1:18082:8080 \
  -e APP_VERSION=v2 -e HEALTH_MODE=unhealthy \
  nomad-rollback-demo:local
```

Verify the HTTP responses:

```bash
curl -i http://127.0.0.1:18081/health
curl -i http://127.0.0.1:18082/health
curl -s http://127.0.0.1:18081/version
```

Expected HTTP statuses are `200` and `503` respectively. Docker health probes are asynchronous. Verify once probes have completed:

```bash
docker ps --filter 'name=rollback-demo-'
docker inspect rollback-demo-healthy --format '{{.State.Health.Status}}'
docker inspect rollback-demo-broken --format '{{.State.Health.Status}}'
docker exec rollback-demo-healthy id
docker logs --tail 50 rollback-demo-healthy
docker logs --tail 50 rollback-demo-broken
```

Expect `healthy` for v1 and `unhealthy` for v2. In the broken container, a health probe returning HTTP 503 is **intentional**, not a Docker build defect. However, a Gunicorn `Permission denied: '/home/appuser'` control-socket error must not recur after the fix.

Clean up only these demo containers:

```bash
docker rm -f rollback-demo-healthy rollback-demo-broken
```

If the container names already exist, inspect and carefully clean up only the previous instances that belong to this lab; do not remove unrelated containers.

## Tests and evidence

See [Phase 2 validation record](docs/phase2-validation.md) for previously observed output, an explicit list of unresolved checks, and instructions to capture accepted sandbox evidence. The previous user-provided output demonstrates all nine unit tests passing, HTTP 200/503 responses, Docker `healthy`/`unhealthy`, and a non-root UID. It does **not** prove the tests occurred in an isolated sandbox VM or that the post-fix image was rebuilt and retested.

## Security boundaries

- No production infrastructure, credentials, or secrets.
- Do not publish the lab's Nomad or Consul management APIs directly to the internet.
- For future CI, use a lab-scoped runner and minimal permissions; restrict access to trusted workflows and repositories.
- Never store tokens or private environment files in Git.
- Use immutable image references in future deployment steps, not mutable `latest` tags.
- Docker container health does not by itself trigger a Nomad rollback. Nomad must assess allocation health via its configured service checks and `update` strategy.

## Planned acceptance criteria (not yet achieved)

- [ ] Push to `main` triggers tests, image build, and lab-registry push.
- [ ] Nomad deploys a canary while preserving the stable allocation.
- [ ] Consul health checks determine canary deployment health.
- [ ] Healthy canary auto-promotes.
- [ ] Broken canary causes a failed deployment and automatic revert.
- [ ] CI marks the original failed rollout as failed.
- [ ] Automatic and manual rollback are both demonstrated and timed.
- [ ] A one-command lab bootstrap is available and verified on a clean VM.
- [ ] An engineer-facing incident runbook and job review checklist are complete.
- [ ] Pull request contains evidence and can be independently reproduced.

## References

- [Nomad update block](https://developer.hashicorp.com/nomad/docs/job-specification/update)
- [Nomad canary deployment strategy](https://developer.hashicorp.com/nomad/docs/job-declare/strategy/blue-green-canary)
- [Dockerfile HEALTHCHECK reference](https://docs.docker.com/reference/dockerfile/)
- [GitHub Actions self-hosted runner security](https://docs.github.com/en/actions/reference/security/secure-use)
- [Flask testing guidance](https://flask.palletsprojects.com/en/stable/testing/)
- [Gunicorn settings](https://docs.gunicorn.org/en/stable/settings.html)
