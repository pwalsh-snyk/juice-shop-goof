#!/bin/bash

set -e  # Exit on error

# ==================== CONFIGURE HERE ====================
AWS_REGION="us-west-2"
CLUSTER_NAME="juice-shop"
ECR_REPO_NAME="juice-shop-repo"
DEPLOYMENT_YAML="k8s-src/juice-shop-deploy.yaml"
SERVICE_YAML="k8s-src/juice-shop-service.yaml"
NODEGROUP_NAME="juice-shop-arm64-group"
INSTANCE_TYPE="t4g.medium"  # ARM64 instance type
IMAGE_TAG="juice-shop-app"
# ==================== CONFIGURATION END ====================

# ✅ Ensure AWS Credentials Are Set
echo "🔹 Checking AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS credentials are invalid or expired. Let's configure them."
    aws configure
fi

# ✅ Verify AWS Credentials Again After Configuration
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ ERROR: AWS credentials are still invalid. Exiting."
    exit 1
fi
echo "✅ AWS credentials verified."

# ✅ Check if EKS Cluster exists
echo "🔹 Checking if EKS cluster $CLUSTER_NAME exists..."
if eksctl get cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo "✅ EKS cluster $CLUSTER_NAME already exists. Skipping creation."
else
    echo "🚀 Deploying EKS cluster with ARM64 nodes..."
    eksctl create cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" \
      --nodegroup-name "$NODEGROUP_NAME" --node-type "$INSTANCE_TYPE" --nodes 2 --node-ami-family AmazonLinux2
    echo "✅ EKS cluster deployed successfully."
fi

# ✅ Update kubeconfig so kubectl is authenticated
echo "🔹 Updating kubeconfig for kubectl access..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
echo "✅ kubeconfig updated. You can now use kubectl."

# ✅ Verify Nodes Are ARM64
echo "🔹 Checking node architecture..."
kubectl get nodes -o custom-columns="NAME:.metadata.name,ARCH:.status.nodeInfo.architecture"

# ✅ Get IAM Role for Worker Nodes
echo "🔹 Fetching IAM role for worker nodes..."
NODE_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NODEGROUP_NAME" \
  --query "nodegroup.nodeRole" --output text | cut -d'/' -f2 || true)

if [ -z "$NODE_ROLE_NAME" ]; then
    echo "❌ ERROR: Could not determine the IAM role for worker nodes."
    exit 1
fi

# ✅ Ensure worker nodes have ECR access
echo "🔹 Checking IAM policies for worker nodes..."
if ! aws iam list-attached-role-policies --role-name "$NODE_ROLE_NAME" --query "AttachedPolicies[*].PolicyArn" --output text | grep -q "AmazonEC2ContainerRegistryReadOnly"; then
    echo "🚀 Attaching ECR ReadOnly policy to worker node IAM role..."
    aws iam attach-role-policy --role-name "$NODE_ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
    echo "✅ ECR ReadOnly policy attached."
else
    echo "✅ Worker nodes already have ECR ReadOnly policy."
fi

# ✅ Get the Correct ECR Repository URI
echo "🔹 Checking ECR repository..."
ECR_URI=$(aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")

if [ -z "$ECR_URI" ]; then
    echo "🚀 Creating ECR repository..."
    ECR_URI=$(aws ecr create-repository --repository-name "$ECR_REPO_NAME" --region "$AWS_REGION" --query 'repository.repositoryUri' --output text)
    echo "✅ ECR repository created: $ECR_URI"
else
    echo "✅ ECR repository exists: $ECR_URI"
fi

# ✅ Authenticate Docker with ECR
echo "🔹 Logging in to Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"
echo "✅ Docker authenticated with ECR."

# ✅ Build & Push Docker Image
echo "🚀 Building and pushing Juice Shop Docker image..."
docker build -t "$ECR_URI:$IMAGE_TAG" .
docker push "$ECR_URI:$IMAGE_TAG"
echo "✅ Docker image pushed to ECR."

# ✅ Ensure Kubernetes Deployment Uses Correct Image
echo "🔹 Updating Kubernetes manifests..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|<ECR_IMAGE>|$ECR_URI:$IMAGE_TAG|g" "$DEPLOYMENT_YAML"
else
    sed -i "s|<ECR_IMAGE>|$ECR_URI:$IMAGE_TAG|g" "$DEPLOYMENT_YAML"
fi
echo "✅ Deployment YAML updated."

# ✅ Deploy Juice Shop to EKS
echo "🚀 Deploying Juice Shop to EKS..."
kubectl apply -f "$DEPLOYMENT_YAML"
kubectl apply -f "$SERVICE_YAML"
echo "✅ Juice Shop application deployed."

# ✅ Restart Deployment to Ensure Correct Image is Used
echo "🔹 Restarting deployment to ensure correct image..."
kubectl rollout restart deployment snyk-juice-shop
echo "✅ Deployment restarted."

# ✅ Verify Pods are Running
echo "🔹 Waiting for pods to start..."
kubectl wait --for=condition=ready pod -l app=snyk-juice-shop --timeout=120s || true

# ✅ Get LoadBalancer URL
echo "🔹 Fetching LoadBalancer URL..."
sleep 30  # Wait for service to get an external IP
LOAD_BALANCER_URL=$(kubectl get svc juice-shop-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not ready yet")
echo "✅ Juice Shop is available at: http://$LOAD_BALANCER_URL"

# ✅ Final Verification
echo "🚀 All done! Run the following command to check pod status:"
echo "kubectl get pods -o wide"


