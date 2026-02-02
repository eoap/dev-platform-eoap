# ZOO-Project OGC API Processes Deployment

This directory contains the deployment configuration for ZOO-Project with OGC API Processes using Skaffold and Helm.

## Prerequisites

Before deploying, ensure you have the following tools installed:
- **kubectl** - Kubernetes command-line tool
- **helm** (v3+) - Kubernetes package manager
- **skaffold** - Kubernetes development tool

Add the required Helm repositories:

```bash
helm repo add zoo-project https://zoo-project.github.io/charts/
helm repo add localstack https://helm.localstack.cloud
helm repo update
```

## Deployment Profiles

### Standard Installation

Deploy ZOO-Project with Calrissian workflow engine:

```bash
skaffold dev
```

This profile includes:
- ZOO-Project DRU (v0.8.2)
- Calrissian CWL runner
- LocalStack S3 for storage
- Code-server development environment
- RabbitMQ message queue
- PostgreSQL database
- Redis cache

**Access points:**
- Code-server: http://localhost:8000
- ZOO-Project API: http://localhost:8080
- WebSocket: http://localhost:8888

### KEDA Autoscaling Profile

Deploy with Kubernetes Event-Driven Autoscaling (KEDA) and Kyverno policy enforcement:

```bash
skaffold dev -p keda
```

Additional features:
- **KEDA autoscaling** based on PostgreSQL and RabbitMQ metrics
- **Kyverno** policy engine for pod protection
- **Eviction controller** to protect active workers from termination
- Automatic scaling of ZOO-FPM workers based on queue depth

This profile is ideal for production environments requiring dynamic scaling.

### Argo Workflows Profile

Deploy with Argo Workflows for advanced workflow orchestration:

```bash
# Create S3 credentials secret first
kubectl create secret generic s3-service -n eoap-zoo-project \
  --from-literal=rootUser=test \
  --from-literal=rootPassword=test \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy with Argo profile
skaffold dev -p argo
```

Additional features:
- **Argo Workflows** (v3.7.1) for workflow orchestration
- Workflow artifact storage in LocalStack S3
- Namespaced deployment with instance isolation
- Workflow TTL and pod garbage collection
- Argo Workflows UI for workflow visualization

**Additional access points:**
- Argo Workflows UI: http://localhost:2746
- LocalStack S3: http://localhost:9000

### macOS / ARM Processor Support

For Apple Silicon (M1/M2) or other ARM-based systems:

```bash
skaffold dev -p macos
```

This profile configures `hostpath` storage class compatible with Docker Desktop on macOS.

## Cleanup

When switching between profiles or redeploying, use the cleanup script to ensure all resources are properly removed:

```bash
./cleanup.sh
```

The cleanup script will:
- Stop running Skaffold processes
- Remove Helm releases (ZOO-Project, Kyverno, LocalStack)
- Clean up KEDA and Argo Workflows resources
- Remove Custom Resource Definitions (CRDs)
- Force removal of stuck namespaces and persistent volumes
- Validate complete cleanup

**Note:** This script is particularly important when switching between KEDA and Argo profiles to avoid resource conflicts.

## Combining Profiles

Profiles can be combined for specific deployment scenarios:

```bash
# KEDA + macOS
skaffold dev -p keda,macos

# Argo + macOS
skaffold dev -p argo,macos
```

## Troubleshooting

### Namespace stuck in Terminating state
Run the cleanup script which handles finalizer removal:
```bash
./cleanup.sh
```

### Port conflicts
Ensure no other services are using the default ports (8000, 8080, 8888, 2746, 9000).

### Persistent Volume issues
The cleanup script removes all PVs. If issues persist, manually check:
```bash
kubectl get pv
kubectl delete pv <pv-name> --grace-period=0 --force
```

## Configuration Files

- **skaffold.yaml** - Main deployment configuration with all profiles
- **values.yaml** - Default Helm values for standard/KEDA deployments
- **values_argo.yaml** - Helm values for Argo Workflows deployment
- **cleanup.sh** - Resource cleanup script

## More Information

For detailed information about ZOO-Project, visit:
- [ZOO-Project Documentation](https://zoo-project.github.io/docs/)
- [ZOO-Project Helm Charts](https://github.com/ZOO-Project/charts)

