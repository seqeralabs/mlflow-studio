#!/bin/bash

echo "======================================"
echo "MLflow Studio Initialization"
echo "======================================"

# Set default port
CONNECT_TOOL_PORT="${CONNECT_TOOL_PORT:-8080}"
echo "Port: $CONNECT_TOOL_PORT"

# Debug info
echo "Environment Info:"
echo "  PWD: $(pwd)"
echo "  User: $(whoami)"
echo "  PATH: $PATH"

# Check mlflow
echo ""
echo "Checking MLflow installation..."
MLFLOW_PATH=$(which mlflow 2>/dev/null)
if [ -z "$MLFLOW_PATH" ]; then
    echo "ERROR: mlflow not found in PATH"
    exit 1
fi
echo "  MLflow binary: $MLFLOW_PATH"

echo "  Testing mlflow --version..."
mlflow --version 2>&1 || { echo "ERROR: mlflow --version failed"; exit 1; }

echo ""
echo "Testing mlflow module import..."
python3 -c "import mlflow; print(f'MLflow version: {mlflow.__version__}')" 2>&1 || { echo "ERROR: Cannot import mlflow"; exit 1; }

# Create data directory (simple approach - create under /tmp if /workspace fails)
echo ""
echo "Setting up data directories..."
DATA_DIR="/workspace/data"
if mkdir -p "$DATA_DIR" 2>/dev/null; then
    echo "  Using $DATA_DIR"
else
    echo "  /workspace/data not writable, using /tmp/mlflow-data"
    DATA_DIR="/tmp/mlflow-data"
    mkdir -p "$DATA_DIR"
fi

mkdir -p "$DATA_DIR/mlruns"

# Set MLflow paths
export MLFLOW_BACKEND_STORE_URI="sqlite:///$DATA_DIR/mlflow.db"
export MLFLOW_DEFAULT_ARTIFACT_ROOT="$DATA_DIR/mlruns"

echo ""
echo "======================================"
echo "MLflow Configuration:"
echo "  Backend Store: ${MLFLOW_BACKEND_STORE_URI}"
echo "  Artifact Root: ${MLFLOW_DEFAULT_ARTIFACT_ROOT}"
echo "  Host: 0.0.0.0"
echo "  Port: ${CONNECT_TOOL_PORT}"
echo "======================================"

echo ""
echo "Starting MLflow server..."

# Run mlflow server with dev settings (single worker, no gunicorn timeout issues)
exec mlflow server \
    --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
    --default-artifact-root "${MLFLOW_DEFAULT_ARTIFACT_ROOT}" \
    --host "0.0.0.0" \
    --port "${CONNECT_TOOL_PORT}" \
    --workers 1 \
    --gunicorn-opts "--timeout 120"
