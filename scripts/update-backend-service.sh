#!/bin/bash

set -e

# ==============================================================================
# ECS Backend Service Update Script
# ==============================================================================
# Redeploys the ECS service using the latest ECR image
#
# Usage:
#   ./scripts/update-backend-service.sh <aws-profile>
#
# Example:
#   ./scripts/update-backend-service.sh dev-profile
# ==============================================================================

# Argument check
if [ $# -ne 1 ]; then
    echo "Usage: $0 <aws-profile>"
    echo "Example: $0 dev-profile"
    exit 1
fi

AWS_PROFILE=$1

# Variable settings
REGION="ap-northeast-1"
CLUSTER_NAME="todo-app-cluster"
SERVICE_NAME="todo-app-backend-service"

echo "=========================================="
echo "ECS Service Update"
echo "=========================================="
echo "Environment: ${ENVIRONMENT}"
echo "AWS Profile: ${AWS_PROFILE}"
echo "Region: ${REGION}"
echo "Cluster: ${CLUSTER_NAME}"
echo "Service: ${SERVICE_NAME}"
echo "=========================================="

# Check AWS credentials
echo "🔍 Checking AWS credentials..."
aws sts get-caller-identity --profile ${AWS_PROFILE} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ AWS authentication failed. Please check the profile: ${AWS_PROFILE}"
    exit 1
fi
echo "✅ AWS authentication successful"

# Check cluster existence
echo ""
echo "🔍 Checking ECS cluster..."
aws ecs describe-clusters \
    --clusters ${CLUSTER_NAME} \
    --profile ${AWS_PROFILE} \
    --region ${REGION} \
    --query 'clusters[0].status' \
    --output text > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "❌ ECS cluster not found: ${CLUSTER_NAME}"
    exit 1
fi
echo "✅ Cluster check completed"

# Check service existence
echo ""
echo "🔍 Checking ECS service..."
aws ecs describe-services \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --profile ${AWS_PROFILE} \
    --region ${REGION} \
    --query 'services[0].serviceName' \
    --output text > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "❌ ECS service not found: ${SERVICE_NAME}"
    exit 1
fi
echo "✅ Service check completed"

# Get current task definition
echo ""
echo "📋 Getting current task definition..."
TASK_DEFINITION=$(aws ecs describe-services \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --profile ${AWS_PROFILE} \
    --region ${REGION} \
    --query 'services[0].taskDefinition' \
    --output text)

echo "Current task definition: ${TASK_DEFINITION}"

# Update service (force new deployment)
echo ""
echo "🚀 Updating ECS service with the latest image..."
aws ecs update-service \
    --cluster ${CLUSTER_NAME} \
    --service ${SERVICE_NAME} \
    --force-new-deployment \
    --profile ${AWS_PROFILE} \
    --region ${REGION} \
    --no-cli-pager

if [ $? -ne 0 ]; then
    echo "❌ Failed to update the service"
    exit 1
fi

echo ""
echo "✅ Service update request sent"
echo ""
echo "=========================================="
echo "Deployment Status Check"
echo "=========================================="
echo ""
echo "Monitoring deployment progress..."
echo "※ Press Ctrl+C to stop monitoring (deployment will continue)"
echo ""

# Wait for deployment completion
aws ecs wait services-stable \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --profile ${AWS_PROFILE} \
    --region ${REGION}

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment completed!"
    echo ""

    # Check service status after deployment
    echo "=========================================="
    echo "Service Status"
    echo "=========================================="
    aws ecs describe-services \
        --cluster ${CLUSTER_NAME} \
        --services ${SERVICE_NAME} \
        --profile ${AWS_PROFILE} \
        --region ${REGION} \
        --query 'services[0].{
            ServiceName: serviceName,
            Status: status,
            DesiredCount: desiredCount,
            RunningCount: runningCount,
            TaskDefinition: taskDefinition
        }' \
        --output table

    echo ""
    echo "🎉 Backend service update completed successfully!"
else
    echo ""
    echo "⚠️  Timeout or error occurred while waiting for deployment completion"
    echo "   Please check the status in the AWS Console"
    exit 1
fi
