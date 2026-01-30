ARG CONNECT_CLIENT_VERSION="0.9.0"

# Stage 1: Connect Client
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# Stage 2: Runtime with MLflow installed directly
FROM python:3.11-slim

# Install system dependencies including build tools for pip packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Install btrfs-progs from Debian backports (required for Seqera/Fusion mounting)
RUN echo "deb http://deb.debian.org/debian bookworm-backports main" > \
    /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get install -y -t bookworm-backports btrfs-progs && \
    rm -rf /var/lib/apt/lists/*

# Install MLflow and dependencies directly (not via multi-stage copy)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    mlflow \
    psycopg2-binary \
    pymysql \
    boto3

# Copy connect-client and install
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

# Create app directory
WORKDIR /app

# Copy startup scripts
COPY start.sh /app/start.sh
COPY discover-experiments.sh /app/discover-experiments.sh
RUN chmod +x /app/*.sh

# Default environment variables
ENV MLFLOW_BACKEND_STORE_URI="sqlite:////workspace/data/mlflow.db"
ENV MLFLOW_DEFAULT_ARTIFACT_ROOT="/workspace/data/mlruns"
ENV MLFLOW_HOST="0.0.0.0"
ENV CONNECT_TOOL_PORT="8080"

# Use connect-client as entrypoint
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint", "/app/start.sh"]
