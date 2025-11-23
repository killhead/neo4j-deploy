FROM neo4j:5.15-community

# Install OpenSSL, Nginx and Supervisor
USER root
RUN apt-get update && \
    apt-get install -y openssl nginx wget supervisor && \
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

# Create supervisor directories
RUN mkdir -p /var/log/supervisor /var/run/supervisor && \
    chmod 777 /var/log/supervisor /var/run/supervisor

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod 644 /etc/supervisor/conf.d/supervisord.conf

# Copy test script
COPY test-startup.sh /test-startup.sh
RUN chmod +x /test-startup.sh

# Expose ports
# 80 - HTTP (redirects to HTTPS, Railway will use this as main port for domain)
# 443 - HTTPS (Neo4j UI through nginx)
# 7687 - Bolt (database connections, exposed directly - Railway will handle port mapping)
EXPOSE 80 443 7687

# Healthcheck - check HTTP endpoint through nginx
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

# Override Neo4j's default entrypoint and use supervisor
# First run test script to verify everything is in place
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/test-startup.sh && /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf"]
