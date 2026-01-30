#!/bin/bash

echo "======================================"
echo "Simple HTTP Server Test"
echo "======================================"

echo "PORT: ${CONNECT_TOOL_PORT:-8080}"
echo "PWD: $(pwd)"
echo "User: $(whoami)"
echo "ID: $(id)"

# Create a simple index.html
mkdir -p /tmp/www
echo "<html><body><h1>MLflow Studio Test</h1><p>Server is working!</p></body></html>" > /tmp/www/index.html

# Start a simple Python HTTP server
cd /tmp/www
exec python3 -m http.server ${CONNECT_TOOL_PORT:-8080}
