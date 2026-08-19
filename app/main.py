import os
from datetime import datetime, timezone

from flask import Flask, jsonify


def create_app() -> Flask:
    app = Flask(__name__)

    @app.get("/")
    def hello():
        return jsonify(
            {
                "message": "Hello World from EKS GitOps",
                "service": os.getenv("SERVICE_NAME", "alffino-python-hello"),
                "version": os.getenv("APP_VERSION", "local"),
            }
        )

    @app.get("/healthz")
    def healthz():
        return jsonify(
            {
                "status": "ok",
                "time": datetime.now(timezone.utc).isoformat(),
            }
        )

    @app.get("/readyz")
    def readyz():
        return jsonify({"status": "ready"})

    return app


app = create_app()
