# Deployment Guide – Document Service

## 1. Prerequisites

Make sure the following are ready:

AWS CLI configured
kubectl installed
EKS cluster created and accessible
IAM permissions configured for DynamoDB, S3, and Redis access

---

## 2. Deploy Application

Apply all Kubernetes manifests:

kubectl apply -f kubernetes/

## 3. Verify Pods

Check if all pods are running:

kubectl get pods

All document-service pods should be in Running state.

## 4. Verify ELB Service

Check Kubernetes services:

kubectl get svc

Note the External ELB DNS name assigned to the service.

## 5. Test Application Endpoints

Health Check

http://one-doc-clb-1257126131.ap-south-1.elb.amazonaws.com/health

Expected response:

{
  "status": "healthy",
  "storage ": "ok",
  "cache": "ok"
}

- Swagger UI

http://one-doc-clb-1257126131.ap-south-1.elb.amazonaws.com/docs

Use this UI to test APIs easily.

- Store Document

PUT /documents/{id}

with JSON body:

{
  "content": "Sample document text"
}


- Get Document

GET /documents/{id}

Example:

GET /documents/1

## 6. Redis Configuration

- Redis is configured using AWS ElastiCache.

    Implemented steps:

    - ElastiCache endpoint added to Kubernetes ConfigMap

    - Port 6379 opened in Redis Security Group

    - Security Group restricted to EKS Worker Node Security Group for security

    - This allows only Kubernetes pods to access Redis securel


Deployment Complete

Once all checks pass:

    - ELB routes traffic to EKS NodePort service

    - Document Service is fully accessible

    - Redis cache and DynamoDB storage are operational


✔️ Terraform apply steps
✔️ kubectl apply steps
✔️ How to get ELB DNS
✔️ Health + Docs endpoint test
✔️ PUT/GET test example



