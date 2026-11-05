import os
from flask import Flask, jsonify

app = Flask(__name__)

SERVICE_NAME = "nomad-rollback-demo"


@app.get("/")
def home():
    return jsonify({
        "service": SERVICE_NAME,
        "version": os.getenv("APP_VERSION", "v1"),
        "message": "Nomad Automatic Rollback Demo"
    }), 200


@app.get("/health")
def health():
    version = os.getenv("APP_VERSION", "v1")
    mode = os.getenv("HEALTH_MODE", "healthy").lower()

    if mode == "unhealthy":
        return jsonify({
            "status": "unhealthy",
            "version": version
        }), 503

    return jsonify({
        "status": "healthy",
        "version": version
    }), 200


@app.get("/version")
def version():
    return jsonify({
        "version": os.getenv("APP_VERSION", "v1")
    }), 200
