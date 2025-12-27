#!/bin/bash

# Deployment script for Medusa on Kubernetes
# Usage: ./deploy.sh [namespace] [image]

set -e

NAMESPACE="${1:-medusa}"
IMAGE="${2:-medusa-backend:latest}"

echo "🚀 Deploying Medusa to Kubernetes"
echo "Namespace: $NAMESPACE"
echo "Image: $IMAGE"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✅ Cluster connection verified"
echo ""

# Create namespace if it doesn't exist
echo "📦 Creating namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Apply all manifests
echo "📝 Applying Kubernetes manifests..."
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml

# Update image in medusa deployment if custom image provided
if [ "$IMAGE" != "medusa-backend:latest" ]; then
    echo "🔄 Updating Medusa image to: $IMAGE"
    kubectl set image deployment/medusa medusa="$IMAGE" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
fi

kubectl apply -f medusa-deployment.yaml
kubectl apply -f medusa-service.yaml

echo ""
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n "$NAMESPACE" || true
kubectl wait --for=condition=available --timeout=300s deployment/redis -n "$NAMESPACE" || true
kubectl wait --for=condition=available --timeout=300s deployment/medusa -n "$NAMESPACE" || true

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "   kubectl get pods -n $NAMESPACE"
echo ""
echo "📋 View logs:"
echo "   kubectl logs -f deployment/medusa -n $NAMESPACE"
echo ""
echo "🌐 Port forward (optional):"
echo "   kubectl port-forward service/medusa 9000:9000 -n $NAMESPACE"
echo ""
