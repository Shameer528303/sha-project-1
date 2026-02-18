## Document Service – Cloud Native Microservice on AWS EKS

This project implements a scalable, cloud-native Document Service deployed on AWS using Kubernetes (EKS) and Terraform. The system provides REST APIs for storing and retrieving documents with caching, persistent storage, and load-balanced access.

The architecture follows production-grade best practices including infrastructure as code, containerization, externalized configuration, and managed AWS services.


##  Architecture Overview

![image](https://github.com/Shameer528303/sha-project-1/blob/main/image.jpg)

### Core Components:

| Layer                   | Service                         | Purpose                                 |
| ----------------------- | ------------------------------- | --------------------------------------- |
| Load Balancing          | AWS Elastic Load Balancer (ELB) | Distributes traffic to EKS worker nodes |
| Container Orchestration | Amazon EKS                      | Runs document-service pods              |
| Networking              | Kubernetes NodePort + Service   | Routes ELB traffic to pods              |
| Cache                   | AWS ElastiCache Redis           | Fast access for frequent                |
| Object Storage          | AWS S3                          | Document file storage                   |
| IaC                     | Terraform                       | Automates infrastructure creation       |
| CI/CD                   | GitHub Actions                  | Automated build & deploy                |

---

##  Request Flow

1. User sends request to ELB DNS endpoint
2. ELB forwards traffic to EKS worker nodes (NodePort)
3. Kubernetes Service routes request to document-service pod
4. Application flow:

   * Checks Redis cache
   * If cache miss → s3 bucket 
   * Stores/retrieves document from S3 when required
   * Updates Redis cache

This ensures high performance with durable storage.

---

##  Key Design Decisions

### Why ELB + NodePort (instead of Ingress):

* Terraform-managed infrastructure control
* Simple and production realistic setup
* Explicit traffic routing visibility

### Why Redis:

* Low latency caching
* Improves API response time

### Why S3:

* Cost effective object storage
* Durable and secure
* Ideal for document content

---

##  Deployment Workflow

### Infrastructure Provisioning

```bash
terraform init
terraform apply
```

Creates:

* EKS Cluster
* ELB
* Redis (ElastiCache)
* S3 bucket
* IAM roles

---

### Application Deployment

```
kubectl apply -f kubernetes/
```

---

### Verify

```
kubectl get pods
kubectl get svc
```

---

##  Service Endpoints

### Health Check

```
http://<ELB-DNS>/health
```

### Swagger UI

```
http://<ELB-DNS>/docs
```

### Store Document

```
PUT /documents/{id}
```

### Get Document

```
GET /documents/{id}
```

---

##  Cost Awareness (Approximate – AWS)

| Resource          | Monthly Estimate |
| ----------------- | ---------------- |
| EKS Cluster       | ~$72             |
| EC2 Nodes         | ~$40–60          |
| ElastiCache Redis | ~$15–30          |
| S3                | Minimal          |
| ELB               | ~$18             |

Total (small scale): **~$150/month**

---

##  Security Practices

* IAM roles for EKS node access
* Redis SG restricted to cluster nodes
* No public database exposure
* AWS managed encryption at rest
* Kubernetes secrets for sensitive configs

---

##  Testing Strategy

* Health endpoint validation
* Swagger-based API testing
* Redis connectivity verification (PING)
* s3 read/write verification
* Load balancer routing validation


### Assumptions

* The system is designed for moderate traffic workloads
* Redis cache fits commonly accessed documents in memory
* DynamoDB is used for fast key-value metadata access
* Documents stored in S3 are not extremely large
* Single AWS region deployment
* Stateless application pods

### Known Limitations

No HTTPS termination (ELB uses HTTP only for simplicity)
No auto-scaling configured for pods or nodes
Basic logging without centralized observability stack
No rate limiting or API authentication
Cache eviction handled via TTL only

### Future Improvements

* Add HTTPS with ACM certificates
* Implement Horizontal Pod Autoscaler (HPA)
* Add monitoring with Prometheus & Grafana
* Centralized logging with CloudWatch / ELK
* Introduce API authentication and authorization
* Migrate to ALB Ingress for advanced routing*



## Conclusion

This project demonstrates a real-world cloud-native microservice deployed using:

✔ Infrastructure as Code
✔ Managed AWS services
✔ Kubernetes orchestration
✔ High availability design
✔ Performance optimization using cache

It closely follows modern DevOps and SRE production patterns.





