# Phase 2 — Application and Container Validation

**Original exercise:** 5 November 2026  
**Additional VM unit-test evidence:** 13 November 2026, terminal on `mariana`  
**Status:** Unit-test and application behavior demonstrated; see provenance notes before claiming full post-fix container acceptance.

## 1. Application contract

The Flask/Gunicorn demo provides `GET /`, `GET /health` and `GET /version`. `APP_VERSION` labels its response. `HEALTH_MODE=unhealthy` intentionally produces HTTP 503 at `/health`; in healthy mode the endpoint returns HTTP 200. The health switch is a controlled rollout test hook, not a naturally occurring production fault.

## 2. Observed verification

| Check | Recorded evidence | Result / precision |
| --- | --- | --- |
| Unit test suite, original lab | Nine tests, `OK`, 5 Nov | Pass in original reported environment |
| Unit test suite, VM | `Ran 9 tests in 0.032s` / `OK` in `mariana` screenshot, 13 Nov | **Pass in VM** |
| Local Docker healthy application | HTTP 200 and `healthy` Docker check in earlier test | Pass in historical exercise |
| Local Docker deliberately broken application | HTTP 503 and `unhealthy` Docker check | Intentional failing health behavior verified |
| Container user | Prior runtime `uid=10001(appuser)` | Non-root user observed in historical test |
| Gunicorn control-socket issue | An earlier `Permission denied: '/home/appuser'` log was recorded | Issue identified |
| Gunicorn correction | `--no-control-socket` was incorporated per project updates | Later independent cleaned log not supplied |
| GHCR image built and deployed | Successful Phase 4 and 5 GitHub Actions runs | Verified downstream integration |

Screenshot: [02 — Flask Application Unit Tests](../screenshots/02-Flask-Application-Unit-Tests.png). The screenshot contains all nine test names and `OK` summary.

## 3. Replay the VM unit tests

```bash
cd ~/nomad-auto-rollback-lab
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r app/requirements.txt
python -m unittest discover -s tests -p 'test_*.py' -v
```

If collecting evidence through a pipe, preserve the original exit code (for example, `set -o pipefail` before piping to `tee`). Only report a pass if the test process exits `0`.

## 4. Health behavior replay (additional test containers only)

```bash
docker build --pull -t nomad-rollback-demo:local .
docker run -d --name rollback-demo-healthy \
  -p 127.0.0.1:18081:8080 -e APP_VERSION=v1 -e HEALTH_MODE=healthy \
  nomad-rollback-demo:local
docker run -d --name rollback-demo-broken \
  -p 127.0.0.1:18082:8080 -e APP_VERSION=v2 -e HEALTH_MODE=unhealthy \
  nomad-rollback-demo:local
curl -i http://127.0.0.1:18081/health
curl -i http://127.0.0.1:18082/health
docker ps --filter 'name=rollback-demo-'
```

This procedure creates extra containers; run only after confirming the names and ports are unused. Do not touch Nomad-managed allocations. End by removing **only** the two containers created for this exercise. Inspect rebuilt Gunicorn logs explicitly to confirm the old permission error does not recur before signing off that specific correction.

## 5. Acceptance decision

- **Accepted:** Nine VM unit tests, correct historical healthy/unhealthy HTTP behavior, downstream canary health gating proven in Phase 5.
- **Needs distinct supporting evidence if claimed:** A fresh post-correction local Docker rebuild with full logs confirming absence of the earlier Gunicorn permission error.
- **Not tested here:** Performance, security scanning, resource stress, multi-node scheduling and end-user availability.

Do not confuse a passing unit test with evidence of a production-safe release. The combined proof is covered by the [Phase 5 rollback tests](PHASE5_ROLLBACK_TEST_REPORT.md) and [consolidated validation](VALIDATION.md).
