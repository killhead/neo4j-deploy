FROM neo4j:5.15-community

# Install OpenSSL and Nginx
USER root
RUN apt-get update && \
    apt-get install -y openssl nginx wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create certificates directory with proper permissions
RUN mkdir -p /var/lib/neo4j/certificates/https && \
    chown -R neo4j:neo4j /var/lib/neo4j/certificates

# Generate SSL certificates at build time
RUN openssl req -x509 -newkey rsa:4096 \
    -keyout /var/lib/neo4j/certificates/https/private.key \
    -out /var/lib/neo4j/certificates/https/public.crt \
    -days 365 \
    -nodes \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" && \
    chown -R neo4j:neo4j /var/lib/neo4j/certificates && \
    chmod 600 /var/lib/neo4j/certificates/https/private.key && \
    chmod 644 /var/lib/neo4j/certificates/https/public.crt

# Copy certificates to nginx directory
RUN mkdir -p /etc/nginx/ssl && \
    cp /var/lib/neo4j/certificates/https/private.key /etc/nginx/ssl/ && \
    cp /var/lib/neo4j/certificates/https/public.crt /etc/nginx/ssl/ && \
    chmod 600 /etc/nginx/ssl/private.key && \
    chmod 644 /etc/nginx/ssl/public.crt

# Copy Neo4j configuration
COPY neo4j.conf /var/lib/neo4j/conf/neo4j.conf
RUN chown neo4j:neo4j /var/lib/neo4j/conf/neo4j.conf && \
    chmod 644 /var/lib/neo4j/conf/neo4j.conf

# Copy Nginx configuration
COPY nginx/nginx.conf /etc/nginx/nginx.conf
RUN chmod 644 /etc/nginx/nginx.conf

# Create startup script that runs both Neo4j and Nginx
COPY <<'EOF' /startup.sh
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
EOF

RUN chmod +x /startup.sh

# Expose ports
# 80 - HTTP (redirects to HTTPS, Railway will use this as main port)
# 443 - HTTPS (Neo4j UI)
# 7687 - Bolt (database connections, proxied through nginx stream)
EXPOSE 80 443 7687

# Healthcheck - check HTTP endpoint through nginx
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

# Use custom startup script
CMD ["/startup.sh"]
