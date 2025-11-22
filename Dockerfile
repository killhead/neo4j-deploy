FROM neo4j:5.15-community

# Install OpenSSL for certificate generation
USER root
RUN apt-get update && \
    apt-get install -y openssl && \
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

# Copy Neo4j configuration
COPY neo4j.conf /var/lib/neo4j/conf/neo4j.conf
RUN chown neo4j:neo4j /var/lib/neo4j/conf/neo4j.conf && \
    chmod 644 /var/lib/neo4j/conf/neo4j.conf

# Switch back to neo4j user
USER neo4j

# Expose ports
EXPOSE 7473 7687

# Use default Neo4j entrypoint - no need to override it
