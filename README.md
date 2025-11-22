# Neo4j Deployment with HTTPS Support

## Overview
This guide provides step-by-step instructions for deploying Neo4j with HTTPS support, enabling secure access to the Neo4j Browser UI.

## Prerequisites
- Docker and Docker Compose installed
- OpenSSL (for certificate generation)
- Basic knowledge of Docker and Neo4j

---

## Quick Start

### Option 1: Docker Compose (Recommended)

The easiest way to deploy Neo4j with HTTPS is using the provided `docker-compose.yml`:

```bash
cd /cases/assistant/neo4j-deploy
docker-compose up -d
```

This will:
- Generate SSL certificates automatically (if not present)
- Configure Neo4j with HTTPS enabled
- Start Neo4j on port 7473 (HTTPS) and 7687 (Bolt)

Access Neo4j Browser at: `https://localhost:7473`

---

## Detailed Setup Guide

### Step 1: Generate SSL Certificates

#### Option A: Self-Signed Certificate (Development)

```bash
# Create certificates directory
mkdir -p certificates/https

# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 \
  -keyout certificates/https/private.key \
  -out certificates/https/public.crt \
  -days 365 \
  -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

**Note:** For production, use certificates from a trusted CA (Let's Encrypt, etc.)

#### Option B: Use Existing Certificates

If you have existing certificates:
1. Place `private.key` in `certificates/https/`
2. Place `public.crt` in `certificates/https/`

---

### Step 2: Configure Neo4j

Create `neo4j.conf` with HTTPS configuration:

```properties
# Enable HTTPS connector
dbms.connector.https.enabled=true
dbms.connector.https.listen_address=0.0.0.0:7473

# Disable HTTP (optional, for security)
dbms.connector.http.enabled=false

# SSL Policy Configuration
dbms.ssl.policy.https.enabled=true
dbms.ssl.policy.https.base_directory=certificates/https
dbms.ssl.policy.https.private_key=private.key
dbms.ssl.policy.https.public_certificate=public.crt

# Bolt connector (for driver connections)
dbms.connector.bolt.enabled=true
dbms.connector.bolt.listen_address=0.0.0.0:7687

# Authentication
dbms.security.auth_enabled=true

# Memory settings (adjust based on your system)
dbms.memory.heap.initial_size=512m
dbms.memory.heap.max_size=2G
dbms.memory.pagecache.size=1G
```

---

### Step 3: Docker Compose Configuration

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  neo4j:
    image: neo4j:5.15-community
    container_name: neo4j-https
    ports:
      - "7473:7473"  # HTTPS
      - "7687:7687"  # Bolt
    environment:
      - NEO4J_AUTH=neo4j/your_password_here
      - NEO4J_PLUGINS=["apoc"]
    volumes:
      - ./neo4j.conf:/var/lib/neo4j/conf/neo4j.conf:ro
      - ./certificates:/var/lib/neo4j/certificates:ro
      - neo4j_data:/data
      - neo4j_logs:/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "https://localhost:7473"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  neo4j_data:
  neo4j_logs:
```

---

### Step 4: Deploy Neo4j

#### Using Docker Compose

```bash
# Start Neo4j
docker-compose up -d

# Check logs
docker-compose logs -f neo4j

# Check status
docker-compose ps
```

#### Using Docker directly

```bash
# Build custom image (if using Dockerfile)
docker build -t neo4j-https:custom .

# Run container
docker run -d \
  --name neo4j-https \
  -p 7473:7473 \
  -p 7687:7687 \
  -v $(pwd)/neo4j.conf:/var/lib/neo4j/conf/neo4j.conf:ro \
  -v $(pwd)/certificates:/var/lib/neo4j/certificates:ro \
  -e NEO4J_AUTH=neo4j/your_password_here \
  neo4j:5.15-community
```

---

### Step 5: Verify HTTPS Access

1. **Open Neo4j Browser:**
   - Navigate to: `https://localhost:7473`
   - If using self-signed certificate, accept the security warning

2. **Connect with credentials:**
   - Username: `neo4j`
   - Password: (the password you set in `NEO4J_AUTH`)

3. **Test connection:**
   ```cypher
   RETURN "Neo4j HTTPS is working!" as message
   ```

---

## Alternative: Nginx Reverse Proxy

For more control and production-ready setup, use Nginx as a reverse proxy:

### Nginx Configuration

Create `nginx/nginx.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/nginx/ssl/public.crt;
    ssl_certificate_key /etc/nginx/ssl/private.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://neo4j:7474;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for Neo4j Browser
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Updated docker-compose.yml with Nginx

```yaml
version: '3.8'

services:
  neo4j:
    image: neo4j:5.15-community
    container_name: neo4j
    environment:
      - NEO4J_AUTH=neo4j/your_password_here
    volumes:
      - neo4j_data:/data
      - neo4j_logs:/logs
    networks:
      - neo4j-network

  nginx:
    image: nginx:alpine
    container_name: neo4j-nginx
    ports:
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certificates:/etc/nginx/ssl:ro
    depends_on:
      - neo4j
    networks:
      - neo4j-network
    restart: unless-stopped

volumes:
  neo4j_data:
  neo4j_logs:

networks:
  neo4j-network:
    driver: bridge
```

---

## Configuration Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NEO4J_AUTH` | Authentication (format: `username/password`) | `neo4j/neo4j` |
| `NEO4J_PLUGINS` | Plugins to install | `[]` |
| `NEO4J_dbms_memory_heap_initial__size` | Initial heap size | `512m` |
| `NEO4J_dbms_memory_heap_max__size` | Max heap size | `2G` |

### Port Configuration

- **7473**: HTTPS (Neo4j Browser)
- **7474**: HTTP (if enabled)
- **7687**: Bolt protocol (driver connections)

---

## Security Recommendations

1. **Use Strong Passwords:**
   ```bash
   # Generate strong password
   openssl rand -base64 32
   ```

2. **Restrict Network Access:**
   - Use firewall rules to limit access
   - Consider binding to `127.0.0.1` instead of `0.0.0.0` for local-only access

3. **Use Production Certificates:**
   - Let's Encrypt for free SSL certificates
   - Or certificates from trusted CA

4. **Enable Authentication:**
   ```properties
   dbms.security.auth_enabled=true
   ```

5. **Regular Updates:**
   - Keep Neo4j updated to latest stable version
   - Monitor security advisories

---

## Troubleshooting

### Certificate Issues

**Problem:** Browser shows "Not Secure" warning
- **Solution:** This is normal for self-signed certificates. Accept the exception or use a trusted CA certificate.

**Problem:** Neo4j fails to start with SSL errors
- **Solution:** Check certificate permissions:
  ```bash
  chmod 600 certificates/https/private.key
  chmod 644 certificates/https/public.crt
  ```

### Connection Issues

**Problem:** Cannot connect to Neo4j Browser
- **Check:** Verify Neo4j is running:
  ```bash
  docker-compose ps
  docker-compose logs neo4j
  ```

**Problem:** Port already in use
- **Solution:** Change port mapping in `docker-compose.yml`:
  ```yaml
  ports:
    - "17473:7473"  # Use different host port
  ```

### Authentication Issues

**Problem:** Cannot login to Neo4j
- **Solution:** Reset password:
  ```bash
  docker exec -it neo4j-https neo4j-admin dbms set-initial-password new_password
  ```

---

## Useful Commands

### Docker Compose

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f neo4j

# Restart services
docker-compose restart neo4j

# Check status
docker-compose ps
```

### Neo4j Management

```bash
# Access Neo4j shell
docker exec -it neo4j-https cypher-shell -u neo4j -p your_password

# View Neo4j logs
docker logs neo4j-https

# Backup database
docker exec neo4j-https neo4j-admin database dump neo4j --to-path=/backups

# Restore database
docker exec neo4j-https neo4j-admin database load neo4j --from-path=/backups
```

### Certificate Management

```bash
# Check certificate validity
openssl x509 -in certificates/https/public.crt -text -noout

# Check certificate expiration
openssl x509 -in certificates/https/public.crt -noout -enddate

# Renew certificate (before expiration)
openssl req -x509 -newkey rsa:4096 \
  -keyout certificates/https/private.key \
  -out certificates/https/public.crt \
  -days 365 -nodes
```

---

## Production Deployment

### Using Let's Encrypt

1. **Install Certbot:**
   ```bash
   sudo apt install certbot
   ```

2. **Generate Certificate:**
   ```bash
   sudo certbot certonly --standalone -d your-domain.com
   ```

3. **Copy Certificates:**
   ```bash
   sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem certificates/https/private.key
   sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem certificates/https/public.crt
   sudo chown $USER:$USER certificates/https/*
   ```

4. **Auto-renewal:**
   ```bash
   # Add to crontab
   0 0 * * * certbot renew --quiet && docker-compose restart neo4j
   ```

### Monitoring

Consider adding monitoring:
- Prometheus + Grafana for metrics
- Health checks via HTTPS endpoint
- Log aggregation (ELK stack, etc.)

---

## Additional Resources

- [Neo4j Documentation](https://neo4j.com/docs/)
- [Neo4j SSL Configuration](https://neo4j.com/docs/operations-manual/current/configuration/connectors/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Let's Encrypt](https://letsencrypt.org/)

---

## File Structure

```
neo4j-deploy/
├── README.md                 # This file
├── docker-compose.yml        # Docker Compose configuration
├── neo4j.conf               # Neo4j configuration file
├── certificates/            # SSL certificates directory
│   └── https/
│       ├── private.key      # Private key
│       └── public.crt       # Public certificate
└── nginx/                   # Nginx configuration (optional)
    └── nginx.conf           # Nginx reverse proxy config
```

---

## Support

For issues or questions:
1. Check Neo4j logs: `docker-compose logs neo4j`
2. Verify certificate configuration
3. Check network connectivity
4. Review Neo4j documentation

