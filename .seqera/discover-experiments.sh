#!/bin/bash

echo "Scanning for MLflow experiments in /workspace/data/..."

# Track if we found any experiments
FOUND_EXPERIMENTS=false

# Look for mlruns directories
if find /workspace/data -name "mlruns" -type d 2>/dev/null | grep -q .; then
    find /workspace/data -name "mlruns" -type d 2>/dev/null | while read dir; do
        echo "✓ Found experiment directory: $dir"
        # Count experiments (directories with numeric names)
        exp_count=$(find "$dir" -maxdepth 1 -type d -regex '.*/[0-9]+' 2>/dev/null | wc -l)
        echo "  Contains $exp_count experiment(s)"
        FOUND_EXPERIMENTS=true
    done
fi

# Look for MLflow database files
if find /workspace/data -name "mlflow.db" -type f 2>/dev/null | grep -q .; then
    find /workspace/data -name "mlflow.db" -type f 2>/dev/null | while read db; do
        echo "✓ Found MLflow database: $db"
        FOUND_EXPERIMENTS=true
    done
fi

# Look for .mlflow directories (tracking metadata)
if find /workspace/data -name ".mlflow" -type d 2>/dev/null | grep -q .; then
    find /workspace/data -name ".mlflow" -type d 2>/dev/null | while read dir; do
        echo "✓ Found MLflow metadata: $dir"
        FOUND_EXPERIMENTS=true
    done
fi

if [ "$FOUND_EXPERIMENTS" = false ]; then
    echo "No existing MLflow experiments found. Starting with clean slate."
fi

echo "Experiment discovery complete."
