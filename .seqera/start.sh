#!/bin/bash

echo "======================================"
echo "MLflow Studio"
echo "======================================"

PORT="${CONNECT_TOOL_PORT:-8080}"

# Use /tmp for data (simple and reliable)
DATA_DIR="/tmp/mlflow"
mkdir -p "$DATA_DIR/mlruns"

# Set MLflow environment
export MLFLOW_BACKEND_STORE_URI="sqlite:///$DATA_DIR/mlflow.db"
export MLFLOW_DEFAULT_ARTIFACT_ROOT="$DATA_DIR/mlruns"

echo "Backend: $MLFLOW_BACKEND_STORE_URI"
echo "Artifacts: $MLFLOW_DEFAULT_ARTIFACT_ROOT"
echo "Port: $PORT"
echo "======================================"

# Run MLflow with gunicorn directly (bypasses mlflow server issues)
exec gunicorn \
    --bind "0.0.0.0:$PORT" \
    --workers 1 \
    --timeout 120 \
    --forwarded-allow-ips="*" \
    "mlflow.server:app"
