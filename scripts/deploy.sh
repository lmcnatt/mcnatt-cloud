#!/bin/bash

# Check if config file exists
if [ ! -f "../deploy.config.json" ]; then
    echo "❌ Error: deploy.config.json not found!"
    echo "Please copy deploy.config.template.json to deploy.config.json and update it with your settings."
    exit 1
fi

# Load configuration
SERVER_HOST=$(cat ../deploy.config.json | jq -r '.server.host')
SERVER_USER=$(cat ../deploy.config.json | jq -r '.server.user')
DEPLOY_PATH=$(cat ../deploy.config.json | jq -r '.server.deployPath')
PM2_APP_NAME=$(cat ../deploy.config.json | jq -r '.server.pm2AppName')

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
ssh "$SERVER_USER@$SERVER_HOST" "cd $DEPLOY_PATH && tar -xzvf deployment.tar.gz && npm install --omit=dev && pm2 restart $PM2_APP_NAME || pm2 start npm --name $PM2_APP_NAME -- start"

echo "🧹 Cleaning up deployment package..."
ssh "$SERVER_USER@$SERVER_HOST" "cd $DEPLOY_PATH && rm deployment.tar.gz"

echo "✅ Deployment complete!"