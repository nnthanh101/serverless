#!/bin/bash
export PROJECT_ID=sam-app

## 1.1 Configuring AWS
## MacOS
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account' | tr -d '\n')
export AWS_REGION=${AWS_REGION:-"ap-southeast-1"}
## Cloud9
# export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
# export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

## 3.1. Configuring ECR
export CONTAINER_REGISTRY_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

export ECR_REPOSITORY=sam-app

## 3.2. Configuring DockerHub
export DOCKER_REGISTRY_NAMESPACE=nnthanh101
export HTTPS_GIT_REPO_URL=https://github.com/nnthanh101/serverless.git
export DOCKER_REGISTRY_USERNAME=nnthanh101
export DOCKER_REGISTRY_PASSWORD=__DOCKERHUB_PASSWORD__
export DOCKER_REGISTRY_EMAIL=nnthanh101@gmail.com