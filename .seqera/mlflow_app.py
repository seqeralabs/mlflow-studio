"""
MLflow WSGI app wrapper that disables host header validation
for compatibility with Seqera Studios proxy.
"""
import os

# Set MLflow environment before importing
os.environ.setdefault("MLFLOW_BACKEND_STORE_URI", "sqlite:////tmp/mlflow/mlflow.db")
os.environ.setdefault("MLFLOW_DEFAULT_ARTIFACT_ROOT", "/tmp/mlflow/mlruns")

# Disable Werkzeug's host checking by patching before Flask loads
import werkzeug.serving
werkzeug.serving.is_running_from_reloader = lambda: True

from mlflow.server import app

# Disable host checking in Flask
app.config['SERVER_NAME'] = None

# WSGI application for gunicorn
application = app
