# MLflow Studio - Seqera Custom Studio

Run MLflow tracking server as a Seqera Studio with automatic experiment discovery.

## Features

- **Latest MLflow UI**: Full experiment tracking and visualization
- **GitHub-to-Live**: Deploy directly from repository
- **Auto-Discovery**: Automatically finds experiments in mounted data
- **Persistent Storage**: SQLite backend in mounted workspace
- **Flexible Configuration**: Environment variable overrides

## Quick Start

### Deploy to Seqera Platform

**Prerequisites:**
- Wave must be configured in your workspace
- Container repository must be set in Settings → Studios → Container repository
- Container registry credentials must be configured

1. **Create Studio**
   - Navigate to Workspace → Studios → Create Studio
   - Select "Git repository" as source

2. **Configure Repository**
   - Repository URL: `https://github.com/YOUR-ORG/mlflow-studio`
   - Branch: `main`

3. **Launch Configuration**
   - CPUs: 2
   - Memory: 4 GB (8 GB recommended for large datasets)
   - Mount data links with MLflow experiments (optional)

4. **Environment Variables** (Optional)
   - `MLFLOW_BACKEND_STORE_URI`: Database connection string
   - `MLFLOW_DEFAULT_ARTIFACT_ROOT`: Artifact storage path

5. **Launch**
   - Click "Create Studio"
   - Wait 30-60 seconds for initialization

### Test Locally

```bash
# Start with docker-compose
docker-compose up --build

# Access at http://localhost:5000
```

### Build and Push Manually

If you prefer to build and push the image yourself:

```bash
# Build the image
cd .seqera
docker build --platform linux/amd64 -t ghcr.io/seqeralabs/mlflow-studio:latest .

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Push the image
docker push ghcr.io/seqeralabs/mlflow-studio:latest

# In Seqera Platform, create Studio using "Container image"
# Image URI: ghcr.io/seqeralabs/mlflow-studio:latest
```

## Using the Studio

### Viewing Experiments

The MLflow UI automatically displays:
- All experiments from mounted data links
- Experiment metrics and parameters
- Model artifacts and outputs

### Logging New Runs

Connect from Python code:

```python
import mlflow

# Set tracking URI to your studio
mlflow.set_tracking_uri("https://<studio-url>")

# Log experiments
with mlflow.start_run():
    mlflow.log_param("alpha", 0.5)
    mlflow.log_metric("rmse", 0.7)
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MLFLOW_BACKEND_STORE_URI` | `sqlite:////workspace/data/mlflow.db` | Database connection |
| `MLFLOW_DEFAULT_ARTIFACT_ROOT` | `/workspace/data/mlruns` | Artifact storage |
| `MLFLOW_HOST` | `0.0.0.0` | Server host |
| `CONNECT_TOOL_PORT` | Set by platform | Server port |

### Using PostgreSQL Backend

Set environment variable in Studio configuration:

```
MLFLOW_BACKEND_STORE_URI=postgresql://user:pass@host:5432/mlflowdb
```

## Data Organization

### Mounting Existing Experiments

1. Create data link to S3/GCS bucket containing:
   - `mlruns/` directory (experiment data)
   - `mlflow.db` (optional SQLite database)
   - Artifact files

2. Mount data link when creating Studio

3. Override backend URI if needed:
   ```
   MLFLOW_BACKEND_STORE_URI=file:///workspace/data/<datalink>/mlruns
   ```

### Starting Fresh

Default configuration creates new experiments in `/workspace/data/`:
- Database: `/workspace/data/mlflow.db`
- Artifacts: `/workspace/data/mlruns/`

Mount a data link to persist this data across sessions.

## Architecture

```
GitHub Repository
       ↓
Seqera Platform (Wave build)
       ↓
Studio Container
  ├── connect-client (Fusion mounts)
  ├── start.sh (initialization)
  │   ├── Wait for mounts
  │   ├── Discover experiments
  │   └── Initialize database
  └── mlflow server (UI + REST API)
```

## Troubleshooting

**Build fails with "Attribute `buildRepository` must be specified"**
- This error occurs when Wave is configured in freeze mode but no container repository is set
- Solution 1: Configure container repository in workspace settings
  - Go to Settings → Studios → Container repository
  - Set repository path (e.g., `docker.io/username/mlflow-studio`)
  - Add container registry credentials in Credentials section
- Solution 2: Use a pre-built image
  - Build locally: `cd .seqera && docker build -t your-registry/mlflow-studio:latest .`
  - Push to registry: `docker push your-registry/mlflow-studio:latest`
  - Create Studio using "Container image" instead of "Git repository"

**Studio won't start**
- Check Wave build logs in Studios → Build reports
- Verify repository URL is accessible

**No experiments visible**
- Check data link is mounted correctly
- Verify `MLFLOW_BACKEND_STORE_URI` path
- Review container logs for discovery output

**Performance issues**
- Increase memory to 8 GB
- Consider PostgreSQL for backend (faster than SQLite)

## Resources

- [MLflow Documentation](https://mlflow.org/docs/latest/)
- [Seqera Studios Guide](https://docs.seqera.io/platform-cloud/studios)
- [IGV Studio Reference](https://github.com/seqera-services/igv-studio)
