#!/bin/bash


# Label to identify the deployment
LABEL="app.kubernetes.io/name=dask-gateway"
NAMESPACE="eoap-dask-gateway"

# Check if the deployment is running
while true; do
    # Get the status of the deployment with the specified label
    DEPLOYMENT_STATUS=$(kubectl get deployment traefik-dask-gateway -n $NAMESPACE -o "jsonpath={.status.availableReplicas}")
    echo "Deployment replicas: $DEPLOYMENT_STATUS"
    # Check if the status is 'True'
    if [ "$DEPLOYMENT_STATUS" = "1" ]; then
        echo "Deployment with label $LABEL is running"
        break
    else
        echo "Waiting for deployment to be running..."
    fi

    # Wait for a short period before checking again
    sleep 5
done