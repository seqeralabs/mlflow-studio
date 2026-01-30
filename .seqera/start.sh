#!/bin/bash

echo "Starting MLflow UI..."
echo "Port: ${CONNECT_TOOL_PORT:-8080}"

# Use /tmp for data (definitely writable)
mkdir -p /tmp/mlflow/mlruns

# Run mlflow ui with minimal config
exec mlflow ui \
    --backend-store-uri "sqlite:////tmp/mlflow/mlflow.db" \
    --default-artifact-root "/tmp/mlflow/mlruns" \
    --host "0.0.0.0" \
    --port "${CONNECT_TOOL_PORT:-8080}"
