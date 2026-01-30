# MLflow Studio for Seqera Platform

Run MLflow tracking server as a custom Seqera Studio.

## Features

- **MLflow Tracking UI**: Full experiment tracking and visualization
- **Seqera Integration**: Works with connect-client and Fusion mounts
- **Proxy Compatible**: Handles Seqera's reverse proxy correctly
- **Persistent Storage**: SQLite backend with optional data link mounting

## Quick Start

### Option 1: Build with Wave CLI (Recommended)

```bash
# Install Wave CLI
brew install seqeralabs/tap/wave-cli

# Build (creates temporary URL valid ~24 hours)
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"

# Launch studio with the returned image URL
tw studios add \
  --name "MLflow Studio" \
  -w <org>/<workspace> \
  --custom-template "<wave-image-url>" \
  --compute-env "<compute-env-name>" \
  --auto-start
```

### Option 2: Use Pre-built Image

```bash
tw studios add \
  --name "MLflow Studio" \
  -w <org>/<workspace> \
  --custom-template "docker.io/skptic/mlflow-studio:latest" \
  --compute-env "<compute-env-name>" \
  --auto-start
```

### Option 3: Via Seqera Platform UI

1. Navigate to **Studios** → **Add Studio**
2. Select **Custom image**
3. Enter image: `docker.io/skptic/mlflow-studio:latest`
4. Select compute environment
5. Click **Add** then **Start**

## Test Locally

```bash
docker-compose up --build
# Access at http://localhost:5000
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MLFLOW_BACKEND_STORE_URI` | `sqlite:////tmp/mlflow/mlflow.db` | Database connection |
| `MLFLOW_DEFAULT_ARTIFACT_ROOT` | `/tmp/mlflow/mlruns` | Artifact storage |
| `CONNECT_TOOL_PORT` | `8080` | Server port (set by platform) |

### Persistent Storage with Data Links

By default, MLflow data is stored in `/tmp` and will be lost when the studio stops. For persistent storage:

1. Create a data link pointing to an S3/GCS bucket
2. Mount the data link when creating the studio
3. The studio will auto-detect `/workspace/data` and use it for storage

### Using PostgreSQL Backend

Set environment variable when creating studio:

```
MLFLOW_BACKEND_STORE_URI=postgresql://user:pass@host:5432/mlflowdb
```

## Architecture

```
Seqera Platform
       ↓
Studio Container
  ├── connect-client (handles Fusion mounts & proxy)
  ├── gunicorn (WSGI server)
  │   └── mlflow_app.py (Host header middleware)
  │       └── mlflow.server.app (Flask app)
  └── /tmp/mlflow/ or /workspace/data/ (storage)
```

### Key Components

- **connect-client**: Seqera's tool that sets up Fusion mounts and proxies HTTP traffic
- **gunicorn**: Production WSGI server running MLflow
- **mlflow_app.py**: Middleware that fixes Host header for proxy compatibility
- **start.sh**: Initialization script that configures and starts the server

## Troubleshooting

### "Invalid Host header" Error

This is fixed in the current version using WSGI middleware. If you see this error, ensure you're using the latest image.

### Studio Won't Start

- Check compute environment is available
- Verify image URL is accessible
- Check Platform UI for detailed error logs

### Data Not Persisting

- Mount a data link when creating the studio
- Verify `/workspace/data` exists inside the container
- Check the startup logs for storage location

## Development

### Build Persistent Image

```bash
# Build with Wave (persistent)
wave -f .seqera/Dockerfile \
  --context .seqera \
  --build-repo docker.io/skptic/mlflow-studio \
  --platform linux/amd64 \
  --freeze \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

### Local Docker Build

```bash
cd .seqera
docker build --platform linux/amd64 -t skptic/mlflow-studio:latest .
docker push skptic/mlflow-studio:latest
```

## Resources

- [MLflow Documentation](https://mlflow.org/docs/latest/)
- [Seqera Studios Guide](https://docs.seqera.io/platform/latest/studios)
- [Wave CLI Documentation](https://docs.seqera.io/wave/)
