#!/bin/bash

echo "======================================"
echo "MLflow Studio"
echo "======================================"

PORT="${CONNECT_TOOL_PORT:-8080}"

# Setup data directory
DATA_DIR="/tmp/mlflow"
mkdir -p "$DATA_DIR/mlruns"

# Set MLflow environment
export MLFLOW_BACKEND_STORE_URI="sqlite:///$DATA_DIR/mlflow.db"
export MLFLOW_DEFAULT_ARTIFACT_ROOT="$DATA_DIR/mlruns"

echo "Backend: $MLFLOW_BACKEND_STORE_URI"
echo "Artifacts: $MLFLOW_DEFAULT_ARTIFACT_ROOT"
echo "Port: $PORT"
echo "======================================"

# Run with gunicorn using our custom wrapper
exec gunicorn \
    --bind "0.0.0.0:$PORT" \
    --workers 1 \
    --timeout 120 \
    --forwarded-allow-ips="*" \
    --chdir /app \
    "mlflow_app:application"
