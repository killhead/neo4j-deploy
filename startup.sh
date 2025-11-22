#!/bin/bash
set -e

# Start Neo4j in background
echo "Starting Neo4j..."
/startup/docker-entrypoint.sh neo4j &
NEO4J_PID=$!

# Wait for Neo4j to be ready
echo "Waiting for Neo4j to start..."
for i in {1..60}; do
    if wget --quiet --tries=1 --spider http://localhost:7474/ 2>/dev/null; then
        echo "Neo4j is ready!"
        break
    fi
    sleep 2
done

# Start Nginx in foreground
echo "Starting Nginx..."
exec nginx -g "daemon off;"

