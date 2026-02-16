# Document Service Helm Chart

## Installation

```bash
# Install the chart
helm install document-service . -f values.yaml

# Upgrade the chart
helm upgrade document-service . -f values.yaml

# Uninstall the chart
helm uninstall document-service
```

## Configuration

Edit `values.yaml` to customize:
- Image repository and tag
- Replica count
- Resource limits
- Storage and cache endpoints
- Service type

## Prerequisites

- Kubernetes cluster (EKS)
- ECR image repository
- ElastiCache Redis cluster
- Storage (S3 bucket, DynamoDB table, or RDS)

