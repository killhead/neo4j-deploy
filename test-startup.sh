#!/bin/bash
echo "=== Test startup script ==="
echo "Testing if supervisor is installed..."
which supervisord || echo "Supervisor not found!"
echo "Testing if nginx is installed..."
which nginx || echo "Nginx not found!"
echo "Testing Neo4j entrypoint..."
ls -la /startup/docker-entrypoint.sh || echo "Neo4j entrypoint not found!"
echo "=== End test ==="

