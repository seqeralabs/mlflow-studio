#!/bin/bash
set -e

echo "======================================"
echo "MLflow Studio Initialization"
echo "======================================"

# Set default port if CONNECT_TOOL_PORT is not set (Seqera Studios uses 8080)
if [ -z "$CONNECT_TOOL_PORT" ]; then
    echo "⚠ Warning: CONNECT_TOOL_PORT not set, using default port 8080"
    CONNECT_TOOL_PORT=8080
fi

# Debug: Print environment info
echo "Environment Info:"
echo "  PWD: $(pwd)"
echo "  User: $(whoami)"
echo "  Python: $(which python3 || echo 'not found')"
echo "  MLflow: $(which mlflow || echo 'not found')"
echo ""

# Wait for Fusion mounts to be ready (60 second timeout)
TIMEOUT=60
ELAPSED=0
echo "Waiting for Fusion mounts at /workspace/data/..."

while [ $ELAPSED -lt $TIMEOUT ]; do
    if [ -d /workspace/data ]; then
        # Directory exists, check if it has content or just proceed after 10 seconds
        if [ "$(ls -A /workspace/data 2>/dev/null)" ] || [ $ELAPSED -ge 10 ]; then
            if [ "$(ls -A /workspace/data 2>/dev/null)" ]; then
                echo "✓ Fusion mounts ready (found data)"
            else
                echo "✓ Proceeding without mounted data (no data links)"
            fi
            break
        fi
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "⚠ Warning: /workspace/data not found. Proceeding anyway."
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
echo "Command: mlflow server --backend-store-uri ${MLFLOW_BACKEND_STORE_URI} --default-artifact-root ${MLFLOW_DEFAULT_ARTIFACT_ROOT} --host ${MLFLOW_HOST} --port ${CONNECT_TOOL_PORT}"

# Verify mlflow is accessible
if ! command -v mlflow &> /dev/null; then
    echo "ERROR: mlflow command not found!"
    exit 1
fi

# Start the server
exec mlflow server \
    --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
    --default-artifact-root "${MLFLOW_DEFAULT_ARTIFACT_ROOT}" \
    --host "${MLFLOW_HOST}" \
    --port "${CONNECT_TOOL_PORT}"
