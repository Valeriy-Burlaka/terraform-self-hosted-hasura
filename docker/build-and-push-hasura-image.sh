#!/usr/bin/env sh

aws_profile="ctl-dev"
aws_region=$(aws configure get region --profile $aws_profile)
aws_account_id=$( aws sts get-caller-identity --profile $aws_profile --query "Account" --output text )

repo_name="docker-hasura"
image_tag="latest"

echo $aws_account_id

# Create ECR Repository if it does not exist
aws ecr describe-repositories --repository-names $repo_name --profile $aws_profile > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating ECR repository: $repo_name"
    aws ecr create-repository --repository-name $repo_name --profile $aws_profile
fi

# Login to ECR
aws ecr get-login-password --profile $aws_profile | docker login --username AWS --password-stdin $aws_account_id.dkr.ecr.$aws_region.amazonaws.com

# Build the Docker image
echo "Building Docker image..."
docker build . -t $repo_name -f Dockerfile-Hasura

# Tag the Docker image for ECR
docker tag $repo_name:latest $aws_account_id.dkr.ecr.$aws_region.amazonaws.com/$repo_name:$image_tag

# Push the Docker image to ECR
echo "Pushing Docker image to ECR..."
docker push $aws_account_id.dkr.ecr.$aws_region.amazonaws.com/$repo_name:$image_tag

# Output the ECR image URL
echo "Image pushed to ECR: $aws_account_id.dkr.ecr.$aws_region.amazonaws.com/$repo_name:$image_tag"
