#!/bin/bash
set -e

echo "=== Starting Neo4j and Nginx ==="

# Start Neo4j in background using the default entrypoint
echo "Starting Neo4j..."
/startup/docker-entrypoint.sh neo4j &
NEO4J_PID=$!

# Wait for Neo4j to be ready
echo "Waiting for Neo4j to start..."
MAX_ATTEMPTS=60
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if wget --quiet --tries=1 --spider http://localhost:7474/ 2>/dev/null; then
        echo "✓ Neo4j is ready!"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "⚠ Warning: Neo4j may not be fully ready, but continuing..."
    fi
    sleep 2
done

# Test Nginx configuration
echo "Testing Nginx configuration..."
nginx -t || {
    echo "❌ Nginx configuration test failed!"
    exit 1
}

# Start Nginx in foreground
echo "Starting Nginx..."
exec nginx -g "daemon off;"

