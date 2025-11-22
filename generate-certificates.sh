#!/bin/bash

# Script to generate SSL certificates for Neo4j HTTPS deployment

set -e

CERT_DIR="certificates/https"
KEY_FILE="${CERT_DIR}/private.key"
CERT_FILE="${CERT_DIR}/public.crt"

echo "Generating SSL certificates for Neo4j HTTPS..."

# Create certificates directory if it doesn't exist
mkdir -p "${CERT_DIR}"

# Check if certificates already exist
if [ -f "${KEY_FILE}" ] && [ -f "${CERT_FILE}" ]; then
    echo "Certificates already exist at ${CERT_DIR}"
    read -p "Do you want to regenerate them? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing certificates."
        exit 0
    fi
    echo "Backing up existing certificates..."
    mv "${KEY_FILE}" "${KEY_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    mv "${CERT_FILE}" "${CERT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Generate self-signed certificate
echo "Generating self-signed certificate..."
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
echo "  Private key: ${KEY_FILE}"
echo "  Certificate: ${CERT_FILE}"
echo ""
echo "Note: This is a self-signed certificate. For production, use certificates from a trusted CA."

