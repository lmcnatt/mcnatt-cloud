#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Get the project root directory (parent of scripts directory)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
CONFIG_FILE="$PROJECT_ROOT/deploy.config.json"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: deploy.config.json not found!"
  echo "Please copy deploy.config.template.json to deploy.config.json and update it with your settings."
  exit 1
fi

# Load configuration
SERVER_HOST=$(cat "$CONFIG_FILE" | jq -r '.server.host')
SERVER_USER=$(cat "$CONFIG_FILE" | jq -r '.server.user')
DEPLOY_PATH=$(cat "$CONFIG_FILE" | jq -r '.server.deployPath')
PM2_APP_NAME=$(cat "$CONFIG_FILE" | jq -r '.server.pm2AppName')

echo "📋 Using deployment configuration for $SERVER_USER@$SERVER_HOST"
echo "🔥 Building Next.js app..."
npm run build

echo "🧹 Pruning dev dependencies..."
npm prune --omit=dev

echo "📦 Creating deployment package..."
tar -czvf deployment.tar.gz .next public node_modules package.json next.config.ts

echo "🚀 Uploading to server..."
scp deployment.tar.gz "$SERVER_USER@$SERVER_HOST:$DEPLOY_PATH"

echo "🎉 Deploying on server..."
ssh "$SERVER_USER@$SERVER_HOST" "cd $DEPLOY_PATH && \
  tar -xzvf deployment.tar.gz && \
  npm install --omit=dev && \
  npm run build && \
  pm2 delete $PM2_APP_NAME 2>/dev/null || true && \
  PORT=3000 pm2 start npm --name $PM2_APP_NAME -- start"

echo "🧹 Cleaning up deployment packages..."
# Clean up on server
ssh "$SERVER_USER@$SERVER_HOST" "cd $DEPLOY_PATH && rm deployment.tar.gz"
# Clean up locally
rm deployment.tar.gz

echo "🔍 Checking deployment status..."
ssh "$SERVER_USER@$SERVER_HOST" "pm2 show $PM2_APP_NAME"

echo "✅ Deployment complete!"