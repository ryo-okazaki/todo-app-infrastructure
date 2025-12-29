#!/bin/bash

set -euo pipefail

echo "Starting initial nginx image push to ECR..."

# Check required environment variable
if [ -z "${ECR_REPOSITORY_URL:-}" ]; then
  echo "ERROR: ECR_REPOSITORY_URL is not set"
  exit 1
fi

echo "Target ECR repository URL: ${ECR_REPOSITORY_URL}"

AWS_ACCOUNT_ID=$(echo "${ECR_REPOSITORY_URL}" | cut -d'.' -f1)
AWS_REGION=$(echo "${ECR_REPOSITORY_URL}" | cut -d'.' -f4)

echo "Detected AWS Account ID: ${AWS_ACCOUNT_ID}"
echo "Detected AWS Region: ${AWS_REGION}"

echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo "Successfully logged in to ECR."

WORKDIR=$(mktemp -d)
echo "Using temp build directory: ${WORKDIR}"

cd "${WORKDIR}"

echo "Creating nginx default.conf..."

cat << 'EOF' > default.conf
server {
    listen 3000;
    server_name _;

    root  /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Health check endpoints (ALB)
    location ~ ^/(health|login)$ {
        access_log off;
        default_type text/plain;
        return 200 "healthy\n";
    }
}
EOF

echo "Creating Dockerfile..."

cat << 'EOF' > Dockerfile
FROM nginx:latest

# Copy custom nginx configuration
COPY default.conf /etc/nginx/conf.d/default.conf

# Expose port 3000
EXPOSE 3000
EOF

echo "Building custom nginx image..."
docker build -t custom-nginx:latest .
echo "Image build completed."

echo "Tagging image for ECR..."
docker tag custom-nginx:latest "${ECR_REPOSITORY_URL}:latest"

echo "Pushing image to ECR..."
docker push "${ECR_REPOSITORY_URL}:latest"

echo "Cleaning up temp directory..."
rm -rf "${WORKDIR}"

echo "Initial ECR image push completed successfully."
