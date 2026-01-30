"""
MLflow WSGI app wrapper with middleware to handle proxy Host headers.
"""
import os

# Set MLflow environment before importing
os.environ.setdefault("MLFLOW_BACKEND_STORE_URI", "sqlite:////tmp/mlflow/mlflow.db")
os.environ.setdefault("MLFLOW_DEFAULT_ARTIFACT_ROOT", "/tmp/mlflow/mlruns")

from mlflow.server import app


class HostFixMiddleware:
    """
    WSGI middleware that rewrites the Host header to localhost
    to bypass Werkzeug's host validation for proxied requests.
    """
    def __init__(self, app):
        self.app = app

    def __call__(self, environ, start_response):
        # Rewrite Host header to bypass validation
        environ['HTTP_HOST'] = 'localhost:8080'
        environ['SERVER_NAME'] = 'localhost'
        environ['SERVER_PORT'] = '8080'
        return self.app(environ, start_response)


# Wrap the Flask app with our middleware
application = HostFixMiddleware(app)
