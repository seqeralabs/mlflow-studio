#!/bin/bash

echo "======================================"
echo "MLflow Studio Initialization"
echo "======================================"

# Set default port if CONNECT_TOOL_PORT is not set (Seqera Studios uses 8080)
if [ -z "$CONNECT_TOOL_PORT" ]; then
    echo "Warning: CONNECT_TOOL_PORT not set, using default port 8080"
    CONNECT_TOOL_PORT=8080
fi

# Debug: Print environment info
echo "Environment Info:"
echo "  PWD: $(pwd)"
echo "  User: $(whoami)"
echo "  ID: $(id)"
echo "  PATH: $PATH"
PYTHON_PATH=$(which python3 2>/dev/null || echo "not found")
MLFLOW_PATH=$(which mlflow 2>/dev/null || echo "not found")
echo "  Python: $PYTHON_PATH"
echo "  MLflow: $MLFLOW_PATH"
echo ""

# Verify mlflow is available early
if [ "$MLFLOW_PATH" = "not found" ]; then
    echo "ERROR: mlflow command not found in PATH!"
    echo "Checking /usr/local/bin/:"
    ls -la /usr/local/bin/ 2>/dev/null || echo "  Cannot list /usr/local/bin/"
    exit 1
fi

# Test mlflow can actually run
echo "Testing mlflow command..."
if ! mlflow --version 2>&1; then
    echo "ERROR: mlflow command exists but cannot run!"
    exit 1
fi
echo ""

# Wait for Fusion mounts to be ready (60 second timeout)
# Note: Do NOT create /workspace/data manually - Fusion needs to mount it
TIMEOUT=60
ELAPSED=0
echo "Waiting for Fusion mounts at /workspace/data/..."

while [ $ELAPSED -lt $TIMEOUT ]; do
    if [ -d /workspace/data ]; then
        # Directory exists (Fusion created it), check if it has content or proceed after 10 seconds
        CONTENTS=$(ls -A /workspace/data 2>/dev/null || true)
        if [ -n "$CONTENTS" ] || [ $ELAPSED -ge 10 ]; then
            if [ -n "$CONTENTS" ]; then
                echo "Fusion mounts ready (found data)"
            else
                echo "Proceeding without mounted data (no data links)"
            fi
            break
        fi
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    echo "  Waited ${ELAPSED}s..."
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "Warning: Timeout waiting for /workspace/data."
fi

# Now create our data directories (after Fusion has set up /workspace)
echo "Creating MLflow data directories..."
mkdir -p /workspace/data/mlruns || echo "Warning: Could not create mlruns directory"

# Run experiment discovery
if [ -f /app/discover-experiments.sh ]; then
    echo "Running experiment discovery..."
    bash /app/discover-experiments.sh || echo "Warning: Experiment discovery had issues"
fi

# Initialize database if needed
if [[ "$MLFLOW_BACKEND_STORE_URI" == sqlite://* ]]; then
    DB_PATH="${MLFLOW_BACKEND_STORE_URI#sqlite:///}"
    DB_DIR=$(dirname "$DB_PATH")
    if [ ! -f "$DB_PATH" ]; then
        echo "Initializing new SQLite database at $DB_PATH"
        mkdir -p "$DB_DIR"
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

# Start the server (exec replaces the shell process)
exec mlflow server \
    --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
    --default-artifact-root "${MLFLOW_DEFAULT_ARTIFACT_ROOT}" \
    --host "${MLFLOW_HOST}" \
    --port "${CONNECT_TOOL_PORT}"
