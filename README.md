# Starter Template

This is an optional starter template to help you get started quickly. Feel free to use it as a starting point or build from scratch.

## Structure

```
starter-template/
├── app/                    # Application code
│   ├── main.py            # FastAPI application (document service)
│   ├── requirements.txt    # Python dependencies
│   ├── Dockerfile         # Container definition
│   └── docker-compose.yml # For local testing
├── infrastructure/        # Terraform code
│   ├── main.tf           # Main Terraform configuration
│   ├── variables.tf      # Variable definitions
│   └── outputs.tf       # Output values
├── kubernetes/           # Kubernetes deployment files
│   ├── deployment.yaml   # Kubernetes manifests (if using plain YAML)
│   └── helm/             # Helm charts (if using Helm)
│       └── document-service/
└── ci-cd/                # CI/CD pipeline
    ├── .github/
    │   └── workflows/
    │       └── deploy.yml # GitHub Actions workflow
    └── bitbucket-pipelines.yml # Bitbucket Pipelines
```

## Usage

1. Copy the files to your solution directory
2. Customize as needed
3. Fill in the TODOs and placeholders
4. Build upon this foundation

## Application

The starter includes a basic FastAPI application with:
- PUT /documents/{id} endpoint (to be implemented)
- GET /documents/{id} endpoint (to be implemented)
- GET /health endpoint
- Basic structure for storage and cache integration

You need to implement:
- Storage backend (S3, DynamoDB, or RDS)
- Cache client (Redis/ElastiCache)
- Cache strategy (read-through, write-through, or cache-aside)
- Error handling
- Input validation

## Infrastructure

The Terraform template includes placeholders for:
- VPC and networking
- EKS or ECS cluster
- Application Load Balancer
- Storage (S3, DynamoDB, or RDS)
- ElastiCache (Redis/Memcached)
- ECR repository
- IAM roles

You need to implement:
- Complete Terraform modules
- Resource configurations
- Security groups
- IAM policies

## Kubernetes

Choose one approach:

Option A: Kubernetes Manifests (YAML)
- Use files in `kubernetes/` directory
- Complete the deployment.yaml template
- Add service, configmap, and other manifests as needed

Option B: Helm Charts
- Use files in `kubernetes/helm/document-service/`
- Complete the Helm chart templates
- Customize values.yaml

## CI/CD

Choose one approach:

Option A: GitHub Actions
- Use `.github/workflows/deploy.yml`
- Configure secrets in GitHub repository settings
- Customize workflow steps

Option B: Bitbucket Pipelines
- Use `bitbucket-pipelines.yml`
- Configure variables in Bitbucket repository settings
- Customize pipeline steps

## Notes

- This is a minimal starting point
- You'll need to complete the implementation
- Follow the requirements in `assessment/requirements.md`
- This template uses Python/FastAPI, but you can use Node.js if preferred
- Focus on demonstrating your SRE skills: storage durability, cache correctness, and operational thinking

## Key Areas to Focus On

1. **Storage Choice**: Choose S3, DynamoDB, or RDS and justify your choice
2. **Cache Strategy**: Implement read-through, write-through, or cache-aside correctly
3. **Failure Handling**: Handle cache failures gracefully
4. **Durability**: Ensure data persists even if cache fails
5. **Observability**: Add metrics for cache hits/misses, latency, errors
6. **Security**: Follow IAM best practices, use secrets management

## Important: Tagging and Access Control

Critical: All resources you create MUST be tagged with `Candidate: <your-candidate-name>`.

- The `candidate_name` variable is already included in the Terraform template
- Extract your candidate name from your repository name: `principal-sre-assessment-<your-name>`
- Your IAM permissions only allow access to resources with your specific `Candidate` tag
- Without the correct tag, you won't be able to modify or delete resources later

The starter template automatically applies this tag via `default_tags` in the AWS provider configuration.

## Resource Cleanup

After completing your assessment, clean up all AWS resources:

```bash
cd infrastructure
terraform destroy
```

See [docs/RESOURCE-CLEANUP.md](../../docs/RESOURCE-CLEANUP.md) for detailed cleanup instructions.

