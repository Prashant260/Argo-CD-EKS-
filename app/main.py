import os
import socket
from datetime import datetime, timezone

from flask import Flask, jsonify, render_template


def create_app() -> Flask:
    app = Flask(__name__)

    def app_info():
        return {
            "service": os.getenv("SERVICE_NAME", "alffino-gitops-dashboard"),
            "version": os.getenv("APP_VERSION", "local"),
            "environment": os.getenv("ENVIRONMENT", "production"),
            "namespace": os.getenv("POD_NAMESPACE", "alffino"),
            "cluster": os.getenv("CLUSTER_NAME", "argocd-eks"),
            "region": os.getenv("AWS_REGION", "ap-southeast-2"),
            "pod": socket.gethostname(),
        }

    @app.get("/")
    def dashboard():
        return render_template(
            "index.html",
            info=app_info(),
        )

    @app.get("/api/status")
    def status():
        return jsonify(
            {
                "status": "operational",
                "service": app_info(),
                "components": {
                    "application": "healthy",
                    "api": "healthy",
                    "readiness": "ready",
                    "gitops": "synced",
                    "deployment": "healthy",
                },
                "timestamp": datetime.now(timezone.utc).isoformat(),
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
        return jsonify(
            {
                "status": "ready",
            }
        )

    return app


app = create_app()