# Kubernetes Deployment Guide for Medusa

This directory contains Kubernetes manifests for deploying your Medusa application to a Kubernetes cluster.

## Overview

The Kubernetes setup includes:

- **Namespace**: `medusa` - isolates all Medusa resources
- **PostgreSQL**: Database with persistent storage
- **Redis**: Cache and session store
- **Medusa**: Backend application and admin dashboard
- **Services**: Internal service discovery
- **Ingress** (optional): External access configuration

## Prerequisites

1. A running Kubernetes cluster (minikube, kind, GKE, EKS, AKS, etc.)
2. `kubectl` configured to connect to your cluster
3. Docker image of your Medusa application built and pushed to a container registry
4. (Optional) An ingress controller installed (nginx-ingress, traefik, etc.)

## Quick Start

### 1. Build and Push Docker Image

First, build your Docker image and push it to a container registry:

**For Production (recommended):**
```bash
# Build the production image
docker build -f Dockerfile.prod -t your-registry/medusa-backend:latest .

# Push to registry (example with Docker Hub)
docker push your-registry/medusa-backend:latest
```

**For Development:**
```bash
# Build the development image
docker build -t your-registry/medusa-backend:latest .

# Push to registry
docker push your-registry/medusa-backend:latest
```

Or if using a private registry:

```bash
docker tag medusa-backend:latest your-registry/medusa-backend:latest
docker push your-registry/medusa-backend:latest
```

### 2. Update Image Reference

Edit `medusa-deployment.yaml` and update the `image` field with your actual image:

```yaml
image: your-registry/medusa-backend:latest
```

### 3. Update Secrets

**IMPORTANT**: Before deploying to production, update the secrets in `secret.yaml`:

```bash
# Generate strong passwords
openssl rand -base64 32  # For JWT_SECRET
openssl rand -base64 32  # For COOKIE_SECRET
openssl rand -base64 32  # For POSTGRES_PASSWORD
```

Then update `k8s/secret.yaml` with your secure values.

### 4. Deploy Everything

**Option A: Using the deployment script (recommended)**

```bash
# Deploy with default settings
./k8s/deploy.sh

# Or with custom namespace and image
./k8s/deploy.sh my-namespace your-registry/medusa-backend:v1.0.0
```

**Option B: Using kubectl directly**

```bash
# Apply all manifests
kubectl apply -f k8s/

# Or using kustomize
kubectl apply -k k8s/
```

### 5. Verify Deployment

Check that all pods are running:

```bash
kubectl get pods -n medusa
kubectl get services -n medusa
```

You should see:
- `postgres-xxx` - Running
- `redis-xxx` - Running  
- `medusa-xxx` - Running (may take a minute to start)

### 6. Check Logs

View Medusa logs:

```bash
kubectl logs -f deployment/medusa -n medusa
```

## Configuration

### Environment Variables

Most configuration is managed through:
- **ConfigMap** (`configmap.yaml`): Non-sensitive configuration
- **Secrets** (`secret.yaml`): Sensitive data (passwords, keys)

### Persistent Storage

PostgreSQL data is stored in a PersistentVolumeClaim (`postgres-pvc.yaml`). The default size is 10Gi. Adjust as needed:

```yaml
resources:
  requests:
    storage: 10Gi  # Change this value
```

### Resource Limits

Resource requests and limits are set for all containers. Adjust in the respective deployment files based on your cluster capacity and workload:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Scaling

To scale the Medusa deployment:

```bash
kubectl scale deployment medusa --replicas=3 -n medusa
```

**Note**: PostgreSQL and Redis are currently set to single replica. For production, consider:
- PostgreSQL: Use a managed database service or StatefulSet with replication
- Redis: Use Redis Sentinel or a managed Redis service

### Exposing the Service

#### Option 1: NodePort (for testing)

Edit `medusa-service.yaml`:

```yaml
spec:
  type: NodePort
  nodePort: 30090
```

Then access via: `http://<node-ip>:30090`

#### Option 2: LoadBalancer

Edit `medusa-service.yaml`:

```yaml
spec:
  type: LoadBalancer
```

#### Option 3: Ingress (recommended for production)

1. Make sure you have an ingress controller installed
2. Update `ingress.yaml` with your domain
3. Apply the ingress:

```bash
kubectl apply -f k8s/ingress.yaml
```

## Database Migrations

The Medusa application runs migrations automatically on startup (via `start.sh`). The init container ensures PostgreSQL is ready before the main container starts.

To manually run migrations:

```bash
kubectl exec -it deployment/medusa -n medusa -- npx medusa db:migrate
```

## Creating Admin User

Create an admin user:

```bash
kubectl exec -it deployment/medusa -n medusa -- npx medusa user -e admin@example.com -p your-secure-password
```

## Monitoring and Debugging

### View Pod Status

```bash
kubectl get pods -n medusa
kubectl describe pod <pod-name> -n medusa
```

### View Logs

```bash
# Medusa logs
kubectl logs -f deployment/medusa -n medusa

# PostgreSQL logs
kubectl logs -f deployment/postgres -n medusa

# Redis logs
kubectl logs -f deployment/redis -n medusa
```

### Execute Commands in Pods

```bash
# Enter Medusa pod
kubectl exec -it deployment/medusa -n medusa -- sh

# Enter PostgreSQL pod
kubectl exec -it deployment/postgres -n medusa -- psql -U postgres -d medusa-store
```

### Port Forwarding (for local access)

```bash
# Forward Medusa service to localhost
kubectl port-forward service/medusa 9000:9000 -n medusa

# Access at http://localhost:9000
```

## Production Recommendations

1. **Secrets Management**: Use a secrets management solution (Sealed Secrets, External Secrets Operator, Vault) instead of plain YAML files
2. **Database**: Consider using a managed PostgreSQL service (AWS RDS, Google Cloud SQL, Azure Database) instead of in-cluster PostgreSQL
3. **Redis**: Consider using a managed Redis service (AWS ElastiCache, Google Memorystore, Azure Cache) for production
4. **Backup**: Set up regular backups for PostgreSQL
5. **Monitoring**: Add monitoring (Prometheus, Grafana) and logging (ELK, Loki) solutions
6. **SSL/TLS**: Configure TLS certificates for ingress
7. **Resource Limits**: Tune resource requests/limits based on actual usage
8. **Horizontal Pod Autoscaling**: Set up HPA for Medusa based on CPU/memory metrics
9. **Network Policies**: Implement network policies for security
10. **Image Pull Secrets**: If using a private registry, create and reference image pull secrets

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n medusa

# Check logs
kubectl logs <pod-name> -n medusa
```

### Database Connection Issues

Verify that the PostgreSQL service is running and accessible:

```bash
kubectl get svc postgres -n medusa
kubectl exec -it deployment/postgres -n medusa -- pg_isready -U postgres
```

### Image Pull Errors

If you see `ImagePullBackOff`:

1. Verify the image exists in your registry
2. Check if you need to configure image pull secrets for private registries
3. Verify the image name in `medusa-deployment.yaml`

### Persistent Volume Issues

If PostgreSQL can't mount the volume:

```bash
# Check PVC status
kubectl get pvc -n medusa

# Check PV status
kubectl get pv
```

## Cleanup

To remove all resources:

```bash
kubectl delete namespace medusa
```

Or delete individual resources:

```bash
kubectl delete -f k8s/
```

## File Structure

```
k8s/
├── namespace.yaml           # Namespace definition
├── configmap.yaml           # Non-sensitive configuration
├── secret.yaml              # Sensitive data (UPDATE BEFORE PRODUCTION!)
├── postgres-pvc.yaml        # Persistent volume for PostgreSQL
├── postgres-deployment.yaml # PostgreSQL deployment
├── postgres-service.yaml    # PostgreSQL service
├── redis-deployment.yaml    # Redis deployment
├── redis-service.yaml       # Redis service
├── medusa-deployment.yaml   # Medusa deployment
├── medusa-service.yaml      # Medusa service
├── ingress.yaml             # Ingress configuration (optional)
├── kustomization.yaml       # Kustomize configuration
├── deploy.sh                # Deployment script
└── README.md                # This file

../Dockerfile.prod           # Production Dockerfile (optimized for K8s)
```

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Medusa Documentation](https://docs.medusajs.com/)
- [Kustomize Documentation](https://kustomize.io/)
