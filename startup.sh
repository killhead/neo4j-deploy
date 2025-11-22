#!/bin/bash
set -e

# Redirect all output to stdout/stderr so Railway can see it
exec > >(tee -a /proc/1/fd/1)
exec 2> >(tee -a /proc/1/fd/2)

echo "=== Starting Neo4j and Nginx ==="

# Start Neo4j in background using the original entrypoint
echo "Starting Neo4j..."
/startup/docker-entrypoint.sh neo4j &
NEO4J_PID=$!
echo "Neo4j started with PID: $NEO4J_PID"

# Wait for Neo4j to be ready
echo "Waiting for Neo4j to start..."
MAX_ATTEMPTS=60
ATTEMPT=0
NEO4J_READY=false

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if wget --quiet --tries=1 --spider http://localhost:7474/ 2>/dev/null; then
        echo "✓ Neo4j is ready!"
        NEO4J_READY=true
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Neo4j not ready yet..."
    sleep 2
done

if [ "$NEO4J_READY" = false ]; then
    echo "⚠ Warning: Neo4j may not be fully ready, but continuing..."
fi

# Test Nginx configuration
echo "Testing Nginx configuration..."
if ! nginx -t; then
    echo "❌ Nginx configuration test failed!"
    echo "Nginx config test output:"
    nginx -t 2>&1 || true
    exit 1
fi

echo "✓ Nginx configuration is valid"

# Start Nginx in foreground (this keeps container running)
echo "Starting Nginx..."
exec nginx -g "daemon off;"

