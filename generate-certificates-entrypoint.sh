#!/bin/bash
set -e

CERT_DIR="/var/lib/neo4j/certificates/https"
KEY_FILE="${CERT_DIR}/private.key"
CERT_FILE="${CERT_DIR}/public.crt"

# Generate certificates if they don't exist
if [ ! -f "${KEY_FILE}" ] || [ ! -f "${CERT_FILE}" ]; then
    echo "Generating SSL certificates for Neo4j HTTPS..."
    
    # Ensure directory exists and has correct permissions
    mkdir -p "${CERT_DIR}"
    
    # Generate self-signed certificate
    openssl req -x509 -newkey rsa:4096 \
        -keyout "${KEY_FILE}" \
        -out "${CERT_FILE}" \
        -days 365 \
        -nodes \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" 2>/dev/null || {
        echo "Warning: Failed to generate certificates, continuing anyway..."
    }
    
    # Set proper permissions if certificates were created
    if [ -f "${KEY_FILE}" ] && [ -f "${CERT_FILE}" ]; then
        chmod 600 "${KEY_FILE}"
        chmod 644 "${CERT_FILE}"
        echo "✓ Certificates generated successfully!"
    fi
fi

# Execute original Neo4j entrypoint with all arguments
# Neo4j entrypoint handles empty arguments correctly, so we can pass them as-is
exec /startup/docker-entrypoint.sh "$@"

