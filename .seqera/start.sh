#!/bin/bash

echo "======================================"
echo "MLflow Studio"
echo "======================================"

PORT="${CONNECT_TOOL_PORT:-8080}"

# Determine data directory - prefer /workspace/data if it exists
if [ -d "/workspace/data" ]; then
    DATA_DIR="/workspace/data"
    echo "Using Fusion mount: $DATA_DIR"
else
    DATA_DIR="/tmp/mlflow"
    echo "Using local storage: $DATA_DIR"
fi

mkdir -p "$DATA_DIR/mlruns"

# Configure MLflow
BACKEND_URI="sqlite:///$DATA_DIR/mlflow.db"
ARTIFACT_ROOT="$DATA_DIR/mlruns"

echo "Backend: $BACKEND_URI"
echo "Artifacts: $ARTIFACT_ROOT"
echo "Port: $PORT"
echo "======================================"

# Start MLflow server (gunicorn handles proxy headers correctly)
exec mlflow server \
    --backend-store-uri "$BACKEND_URI" \
    --default-artifact-root "$ARTIFACT_ROOT" \
    --host "0.0.0.0" \
    --port "$PORT"
