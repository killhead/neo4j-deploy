#!/bin/bash
set -e

echo "=== Starting Neo4j and Nginx ===" | tee -a /var/log/startup.log

# Start Neo4j in background
echo "Starting Neo4j..." | tee -a /var/log/startup.log
cd /var/lib/neo4j
su - neo4j -c "/startup/docker-entrypoint.sh neo4j" &
NEO4J_PID=$!
echo "Neo4j started with PID: $NEO4J_PID" | tee -a /var/log/startup.log

# Wait for Neo4j to be ready
echo "Waiting for Neo4j to start..." | tee -a /var/log/startup.log
MAX_ATTEMPTS=60
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if wget --quiet --tries=1 --spider http://localhost:7474/ 2>/dev/null; then
        echo "✓ Neo4j is ready!" | tee -a /var/log/startup.log
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "⚠ Warning: Neo4j may not be fully ready, but continuing..." | tee -a /var/log/startup.log
    fi
    sleep 2
done

# Test Nginx configuration
echo "Testing Nginx configuration..." | tee -a /var/log/startup.log
nginx -t 2>&1 | tee -a /var/log/startup.log || {
    echo "❌ Nginx configuration test failed!" | tee -a /var/log/startup.log
    exit 1
}

# Start Nginx in foreground
echo "Starting Nginx..." | tee -a /var/log/startup.log
exec nginx -g "daemon off;"

