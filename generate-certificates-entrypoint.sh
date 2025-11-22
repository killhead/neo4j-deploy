#!/bin/bash
set -e

CERT_DIR="/var/lib/neo4j/certificates/https"
KEY_FILE="${CERT_DIR}/private.key"
CERT_FILE="${CERT_DIR}/public.crt"

# Generate certificates if they don't exist
if [ ! -f "${KEY_FILE}" ] || [ ! -f "${CERT_FILE}" ]; then
    echo "Generating SSL certificates for Neo4j HTTPS..."
    
    # Generate self-signed certificate
    openssl req -x509 -newkey rsa:4096 \
        -keyout "${KEY_FILE}" \
        -out "${CERT_FILE}" \
        -days 365 \
        -nodes \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    
    # Set proper permissions
    chmod 600 "${KEY_FILE}"
    chmod 644 "${CERT_FILE}"
    
    echo "✓ Certificates generated successfully!"
fi

# Execute original Neo4j entrypoint
exec /startup/docker-entrypoint.sh "$@"

