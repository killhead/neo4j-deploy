FROM neo4j:5.15-community

# Install OpenSSL for certificate generation
USER root
RUN apt-get update && \
    apt-get install -y openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create entrypoint script for certificate generation
RUN mkdir -p /startup-scripts
COPY generate-certificates-entrypoint.sh /startup-scripts/
RUN chmod +x /startup-scripts/generate-certificates-entrypoint.sh

# Copy Neo4j configuration
COPY neo4j.conf /var/lib/neo4j/conf/neo4j.conf

# Create certificates directory
RUN mkdir -p /var/lib/neo4j/certificates/https && \
    chown -R neo4j:neo4j /var/lib/neo4j/certificates

# Switch back to neo4j user
USER neo4j

# Expose ports
EXPOSE 7473 7687

# Use custom entrypoint that generates certificates if needed
# CMD will use default from base image
ENTRYPOINT ["/startup-scripts/generate-certificates-entrypoint.sh"]
