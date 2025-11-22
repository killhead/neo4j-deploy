#!/bin/bash
# Script to deploy Neo4j HTTPS to Railway
# Usage: ./deploy-to-railway.sh

set -e

PROJECT_ID="7c687313-0a78-4cee-872f-1d9a8e6d8653"
ENVIRONMENT_ID="7d70c033-ba86-432d-8fba-e31b756be2ed"
SERVICE_NAME="neo4j-https"

echo "🚀 Deploying Neo4j HTTPS to Railway..."
echo "Project ID: ${PROJECT_ID}"
echo "Environment: test (${ENVIRONMENT_ID})"
echo "Service: ${SERVICE_NAME}"
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI is not installed"
    echo "Install it from: https://docs.railway.app/develop/cli"
    exit 1
fi

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo "⚠️  Not logged in to Railway. Please run: railway login"
    exit 1
fi

echo "✅ Railway CLI is ready"
echo ""

# Link to project
echo "📌 Linking to project..."
railway link --project "${PROJECT_ID}" || {
    echo "⚠️  Project already linked or link failed. Continuing..."
}

# Switch to test environment
echo "🌍 Switching to test environment..."
railway environment use "${ENVIRONMENT_ID}" || {
    echo "⚠️  Could not switch environment. You may need to do this manually."
}

# Create service if it doesn't exist
echo "🔧 Creating service ${SERVICE_NAME}..."
railway service create "${SERVICE_NAME}" 2>/dev/null || {
    echo "ℹ️  Service may already exist. Continuing..."
}

# Set environment variables
echo "⚙️  Setting environment variables..."
read -sp "Enter Neo4j password (or press Enter to use default): " NEO4J_PASSWORD
echo ""

if [ -z "$NEO4J_PASSWORD" ]; then
    NEO4J_PASSWORD="change_this_password"
    echo "⚠️  Using default password. Please change it!"
fi

railway variables set "NEO4J_AUTH=neo4j/${NEO4J_PASSWORD}" --service "${SERVICE_NAME}"
railway variables set 'NEO4J_PLUGINS=["apoc"]' --service "${SERVICE_NAME}"

echo ""
echo "📦 Deploying service..."
railway up --service "${SERVICE_NAME}"

echo ""
echo "✅ Deployment initiated!"
echo ""
echo "📊 Check status with:"
echo "   railway status --service ${SERVICE_NAME}"
echo ""
echo "📋 View logs with:"
echo "   railway logs --service ${SERVICE_NAME}"
echo ""
echo "🌐 Get domain with:"
echo "   railway domain --service ${SERVICE_NAME}"
echo ""
echo "🔗 Access Neo4j Browser at: https://your-domain.up.railway.app:7473"
echo "   Username: neo4j"
echo "   Password: ${NEO4J_PASSWORD}"

