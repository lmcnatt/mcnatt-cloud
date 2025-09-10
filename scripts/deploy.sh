#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Get the project root directory (parent of scripts directory)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
CONFIG_FILE="$PROJECT_ROOT/deploy.config.json"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: deploy.config.json not found!"
  exit 1
fi

# Load configuration
SERVER_HOST=$(cat "$CONFIG_FILE" | jq -r '.server.host')
SERVER_USER=$(cat "$CONFIG_FILE" | jq -r '.server.user')
DEPLOY_PATH=$(cat "$CONFIG_FILE" | jq -r '.server.deployPath')
PM2_APP_NAME=$(cat "$CONFIG_FILE" | jq -r '.server.pm2AppName')

echo "🔥 Building Next.js app..."
pnpm run build

echo "📦 Creating deployment package..."
tar -czvf deployment.tar.gz .next public node_modules package.json

echo "🚀 Uploading to server..."
scp deployment.tar.gz "$SERVER_USER@$SERVER_HOST:$DEPLOY_PATH"

echo "🎉 Deploying on server..."
ssh "$SERVER_USER@$SERVER_HOST" "cd $DEPLOY_PATH && \
  # Clean up old files
  rm -rf .next node_modules && \
  # Extract new files
  tar -xzvf deployment.tar.gz && \
  # Start the app with PM2
  pm2 restart $PM2_APP_NAME && \
  # Save PM2 config to persist across reboots
  pm2 save"

echo "🧹 Cleaning up deployment packages..."
# Clean up on server
ssh "$SERVER_USER@$SERVER_HOST" "cd $DEPLOY_PATH && rm deployment.tar.gz"
# Clean up locally
rm deployment.tar.gz

echo "🔍 Checking deployment status..."
ssh "$SERVER_USER@$SERVER_HOST" "pm2 show $PM2_APP_NAME"

echo "✅ Deployment complete!"