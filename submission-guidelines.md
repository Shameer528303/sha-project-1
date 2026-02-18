# Submission Guidelines

This document outlines how to submit your completed assessment.

## Submission Deadline

Submit your solution within 7 days of receiving the assessment, unless otherwise specified.

## What to Submit

### 1. Code Repository

Your solution should be in your assigned repository: `principal-sre-assessment-<YourName>`

**Repository Structure**:
```
your-solution/
├── app/                    # Application code
│   ├── main.py (or equivalent)
│   ├── Dockerfile
│   ├── requirements.txt (or package.json)
│   └── docker-compose.yml
├── infrastructure/         # Terraform code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/ (if applicable)
├── kubernetes/            # Kubernetes manifests or Helm charts
│   ├── deployment.yaml    # (if using plain YAML)
│   ├── service.yaml
│   └── [other manifests]
│   OR
│   └── helm/              # (if using Helm)
│       └── document-service/
├── ci-cd/                  # CI/CD pipeline files
│   └── .github/workflows/  # GitHub Actions
│   OR
│   └── bitbucket-pipelines.yml  # Bitbucket Pipelines
└── docs/                   # Documentation
    ├── architecture.md
    ├── deployment.md
    └── troubleshooting.md
```

### 2. Access Information

Ensure the following is accessible:

- Repository: Your repository should be accessible to reviewers
- AWS Resources: 
  - ALB DNS name or endpoint URL
  - Any other relevant endpoints
- Access Instructions: How to access and test your deployment

### 3. Summary Document

Create a `SUMMARY.md` or update the main `README.md` with:

#### a) Architecture Overview
- High-level architecture description
- Component diagram (ASCII art, Mermaid, or image)
- Data flow explanation (write path, read path)
- Storage and cache architecture

#### b) Key Design Decisions
Document your choices and rationale for:
- Storage choice (S3, DynamoDB, or RDS) and why
- Caching strategy (read-through, write-through, cache-aside) and why
- EKS vs ECS selection
- Kubernetes vs Helm choice
- Infrastructure design patterns
- Security decisions
- How you handle cache failures
- How you ensure data durability
- Any trade-offs made

#### c) Deployment Instructions
- Prerequisites
- Step-by-step deployment guide
- How to access the service
- How to verify it's working
- How to test the service (PUT/GET operations)

#### d) Cost Estimate
- Estimated monthly AWS costs
- Breakdown by service
- Cost optimization considerations

#### e) Assumptions & Limitations
- Any assumptions you made
- Known limitations
- What you would improve with more time

#### f) Testing
- How to test the service
- Example API calls:
  ```bash
  # Store a document
  curl -X PUT http://your-alb-endpoint/documents/doc1 \
    -H "Content-Type: application/json" \
    -d '{"content": "This is a test document"}'
  
  # Retrieve a document
  curl http://your-alb-endpoint/documents/doc1
  
  # Health check
  curl http://your-alb-endpoint/health
  ```
- Expected responses

## How to Submit

### Step 1: Complete Your Implementation

1. Ensure all code is committed and pushed to your repository
2. Verify your repository is accessible
3. Check that all required files are present
4. Review your documentation for clarity

### Step 2: Verify Deployment

- [ ] Service is deployed and accessible
- [ ] Health check endpoint works
- [ ] PUT /documents/{id} works
- [ ] GET /documents/{id} works
- [ ] Cache is functioning (verify cache hits/misses)
- [ ] Storage is durable (test by restarting cache)

### Step 3: Notify Completion

Send an email or message to your point of contact:

Subject: Principal SRE Engineer Assessment Submission - [Your Name]

Body:
```
Repository: https://github.com/ORG/principal-sre-assessment-<YourName>
ALB Endpoint: [URL or DNS name]
AWS Region: [region]

Summary:
[Brief summary of your solution, key design decisions]

Ready for review.
```

### Step 4: Resource Management

See the [Resource Management](../README.md#resource-management) section in README.md for complete resource lifecycle guidance.

## Repository Requirements

### Code Quality

- Clean, readable code
- Appropriate comments
- No hardcoded secrets or credentials
- Follow best practices for your chosen stack

### Documentation

- Clear, comprehensive documentation
- Architecture diagrams
- Deployment instructions
- Troubleshooting guide
- Critical: Document your cache strategy and storage choice

### Git History

- Meaningful commit messages
- Logical commit history (shows your process)
- No need to squash commits - we appreciate seeing your workflow

## What NOT to Include

- AWS Credentials: Never commit access keys, secret keys, or session tokens
- Personal Information: Avoid including sensitive personal data
- Large Files: Use .gitignore appropriately
- Unnecessary Dependencies: Keep dependencies minimal and justified

## Testing Your Submission

Before submitting, verify:

- [ ] Application builds and runs locally
- [ ] Docker image builds successfully
- [ ] Terraform plan/apply works
- [ ] Kubernetes manifests/Helm charts are valid
- [ ] CI/CD pipeline runs (if applicable)
- [ ] Service is accessible via ALB
- [ ] Health check endpoint works
- [ ] PUT endpoint stores documents correctly
- [ ] GET endpoint retrieves documents correctly
- [ ] Cache is working (test cache hits)
- [ ] Cache failure handling works (test with cache down)
- [ ] Data persists after cache restart
- [ ] Documentation is complete and clear
- [ ] No hardcoded credentials
- [ ] Resources are properly tagged

## Example Submission Checklist

```
Code:
[ ] Application code complete (PUT/GET endpoints)
[ ] Dockerfile follows best practices
[ ] Terraform code is modular and well-organized
[ ] Kubernetes manifests or Helm charts complete
[ ] CI/CD pipeline is functional
[ ] All code is committed and pushed

Infrastructure:
[ ] VPC and networking configured
[ ] EKS/ECS cluster deployed
[ ] ALB configured and accessible
[ ] Storage configured (S3/DynamoDB/RDS)
[ ] ElastiCache configured
[ ] Security groups properly configured
[ ] IAM roles follow least privilege

Kubernetes:
[ ] Deployment manifest complete
[ ] Service manifest complete
[ ] Health checks configured
[ ] Resource limits set
[ ] OR Helm chart complete and tested

Observability:
[ ] CloudWatch logs configured
[ ] Metrics and dashboards created
[ ] Alarms configured
[ ] Cache metrics included

Security:
[ ] Secrets in AWS Secrets Manager
[ ] No hardcoded credentials
[ ] IAM follows best practices
[ ] Network security configured

Documentation:
[ ] Architecture document (with storage/cache explanation)
[ ] Deployment runbook
[ ] Troubleshooting guide
[ ] Summary document with design decisions
[ ] Cache strategy documented
[ ] Storage choice rationale documented

Testing:
[ ] Service is accessible
[ ] Endpoints work correctly
[ ] Cache functionality verified
[ ] Durability verified
```

## Questions?

If you have questions about submission:

1. Technical Issues: Contact your assessment coordinator
2. Clarifications: Reach out via the provided communication channel
3. Extensions: Request in advance if needed (with justification)

## After Submission

1. **Resource Management**: Follow the resource lifecycle in README.md (destroy after development, redeploy before discussion)
2. **Be Prepared**: Your setup should allow for quick deployment and changes
3. **Follow-up Discussion**: You may be invited to discuss your solution and make modifications

## Tips for Success

1. Start Early: Don't wait until the last minute
2. Test Thoroughly: Verify everything works before submitting
3. Document Well: Good documentation demonstrates communication skills
4. Show Your Work: Commit history and comments show your thought process
5. Ask Questions: If something is unclear, ask rather than guess
6. Focus on Quality: Better to have fewer, well-done components than many incomplete ones
7. Cache Strategy: Clearly document and implement your caching approach
8. Durability: Ensure data persists even if cache fails

Focus on demonstrating your engineering judgment, practical skills, and ability to make thoughtful trade-offs, especially around storage, caching, and reliability.

If you encounter any issues during submission, contact your assessment coordinator immediately.
