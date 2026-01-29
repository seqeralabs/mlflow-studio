#!/bin/bash
set -e

echo "======================================"
echo "MLflow Studio Initialization"
echo "======================================"

# Wait for Fusion mounts to be ready (60 second timeout)
TIMEOUT=60
ELAPSED=0
echo "Waiting for Fusion mounts at /workspace/data/..."

while [ $ELAPSED -lt $TIMEOUT ]; do
    if [ -d /workspace/data ] && [ "$(ls -A /workspace/data 2>/dev/null)" ]; then
        echo "✓ Fusion mounts ready"
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "⚠ Warning: Fusion mount timeout. Proceeding with default configuration."
fi

# Ensure data directory exists
mkdir -p /workspace/data/mlruns

# Run experiment discovery
if [ -f /app/discover-experiments.sh ]; then
    echo "Running experiment discovery..."
    bash /app/discover-experiments.sh
fi

# Initialize database if needed
DB_PATH="${MLFLOW_BACKEND_STORE_URI#sqlite:///}"
if [[ "$MLFLOW_BACKEND_STORE_URI" == sqlite://* ]]; then
    if [ ! -f "$DB_PATH" ]; then
        echo "Initializing new SQLite database at $DB_PATH"
        mkdir -p $(dirname "$DB_PATH")
    else
        echo "Using existing database at $DB_PATH"
    fi
fi

# Display configuration
echo "======================================"
echo "MLflow Configuration:"
echo "  Backend Store: ${MLFLOW_BACKEND_STORE_URI}"
echo "  Artifact Root: ${MLFLOW_DEFAULT_ARTIFACT_ROOT}"
echo "  Host: ${MLFLOW_HOST}"
echo "  Port: ${CONNECT_TOOL_PORT}"
echo "======================================"

# Start MLflow server
echo "Starting MLflow server..."
exec mlflow server \
    --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
    --default-artifact-root "${MLFLOW_DEFAULT_ARTIFACT_ROOT}" \
    --host "${MLFLOW_HOST}" \
    --port "${CONNECT_TOOL_PORT}"
