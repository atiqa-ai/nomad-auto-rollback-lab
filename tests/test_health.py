import os
import unittest
from unittest.mock import patch

from app.app import app


class TestDemoService(unittest.TestCase):

    def setUp(self):
        self.env_patch = patch.dict(os.environ, {}, clear=True)
        self.env_patch.start()
        self.addCleanup(self.env_patch.stop)
        self.client = app.test_client()

    def test_home_endpoint(self):
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.is_json)
        self.assertEqual(response.json["service"], "nomad-rollback-demo")
        self.assertEqual(response.json["version"], "v1")
        self.assertEqual(
            response.json["message"],
            "Nomad Automatic Rollback Demo"
        )

    def test_home_custom_version(self):
        os.environ["APP_VERSION"] = "v2"

        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["version"], "v2")

    def test_health_default(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["status"], "healthy")
        self.assertEqual(response.json["version"], "v1")

    def test_health_explicit_healthy(self):
        os.environ["HEALTH_MODE"] = "healthy"

        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["status"], "healthy")

    def test_health_unhealthy(self):
        os.environ["HEALTH_MODE"] = "unhealthy"

        response = self.client.get("/health")

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json["status"], "unhealthy")

    def test_health_case_insensitive(self):
        os.environ["HEALTH_MODE"] = "UNHEALTHY"

        response = self.client.get("/health")

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json["status"], "unhealthy")

    def test_health_custom_version(self):
        os.environ["APP_VERSION"] = "v3"

        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["version"], "v3")

    def test_version_default(self):
        response = self.client.get("/version")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["version"], "v1")

    def test_version_custom(self):
        os.environ["APP_VERSION"] = "v2"

        response = self.client.get("/version")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["version"], "v2")


if __name__ == "__main__":
    unittest.main()
