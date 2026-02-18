# Troubleshooting – Document Service (EKS + ELB + NodePort)

This guide helps debug common issues when accessing the Document Service via:
**User → AWS ELB (Terraform) → EKS NodePort Service → Pod**



## 0) Quick Checklist (Most common causes)

* Pod Running?  
* Service type NodePort correct-a?  
* NodePort value correct-a?  
* ELB TargetGroup health = healthy?  
* Worker node SG inbound NodePort allowed?  
* Redis SG allows access from EKS nodes?  
* IAM role has DynamoDB/S3 permissions?  
* ConfigMap values correct-a?  

---

## 1) ELB DNS open pannaa "Not Found" / Blank screen

### Why it happens
- Root path `/` API-la define pannirukka maattanga.
- Correct URLs are `/docs` or `/health`.

### Fix / Verify
Open these URLs:
- `http://<ELB_DNS>/docs`
- `http://<ELB_DNS>/health`

---

## 2) ELB URL works locally (port-forward) but NOT via ELB

### Symptom
- `kubectl port-forward` works (localhost:8080/docs opens)
- But ELB DNS doesn't load / times out

### Check 1: Service & NodePort
```bash
kubectl get svc -n default
kubectl describe svc document-service -n default
````

Confirm:

* `Type: NodePort`
* `Port: 80` (or your service port)
* `TargetPort: 8000`
* `NodePort: 3xxxx`

### Check 2: Are pods healthy?

```bash
kubectl get pods -n default -o wide
kubectl describe pod <pod-name> -n default
```

### Check 3: ELB Target Group Health

AWS Console → EC2 → Target Groups → Targets tab
Should be `healthy`
If unhealthy → security group / NodePort mismatch / health check path wrong.

---

## 3) Service endpoints not showing IP:PORT

### Symptom

`kubectl get endpoints document-service` empty / no endpoints

### Fix

Pods selector mismatch likely.

Check labels:

```bash
kubectl get pods --show-labels -n default
kubectl describe svc document-service -n default
```

Service selector labels must match Pod labels.

---

## 4) Swagger loads but PUT/GET returns 500 (Internal Server Error)

### Symptom

Swagger works, `/health` might return ok
But:

* `PUT /documents/{id}` → 500
* logs show boto3 errors / AccessDenied

### Debug

Get pod logs:

```bash
kubectl logs <pod-name> -n default --tail=200
```

If error shows:
`AccessDeniedException` / `no identity-based policy allows dynamodb:PutItem`

This is IAM problem (NOT Kubernetes).

---

## 5) /health shows status=unhealthy (storage down / cache down)

### Example

```json
{"status":"unhealthy","storage":"down","cache":"ok"}
```

Meaning:

* **Redis OK**
* **DynamoDB failing** (permissions / table name / region / networking)

### Debug (Storage)

Check pod env values:

```bash
kubectl describe pod <pod-name> -n default | findstr /i "AWS_REGION STORAGE TABLE BUCKET"
```

Check ConfigMap:

```bash
kubectl get configmap document-service-config -n default -o yaml
```

Ensure:

* correct region
* correct table name
* correct bucket name
* STORAGE_TYPE correct (dynamodb/s3/local)

---

## 6) DynamoDB permission / access issue (storage down)

### Common causes

* Node role / IRSA missing policy
* Wrong AWS region
* Wrong table name

### Verify which role pod is using

If IRSA configured:

```bash
kubectl describe sa <serviceaccount-name> -n default
```

If no IRSA:
Pod will use **EKS node IAM role**.

### Fix

Attach policy allowing:

* `dynamodb:GetItem`
* `dynamodb:PutItem`
* `dynamodb:UpdateItem`
* `dynamodb:Scan`

Scope should be the specific table ARN (best practice).

---

## 7) Redis configured but cache still "down"

### Symptom

`/health` shows:

```json
{"cache":"down"}
```

### Check 1: ConfigMap values

`cache-host` must be only hostname, NOT include port in host value (recommended)

Example:

* cache-host: `docsvc-redis.xxx.cache.amazonaws.com`
* cache-port: `6379`

Check:

```bash
kubectl get configmap document-service-config -n default -o yaml
```

### Check 2: Redis SG inbound

Redis SG inbound should allow port **6379** from EKS nodes.

Best practice:

* Source = **EKS worker node security group** (not CIDR)

---

## 8) Best practice: Redis SG source should be Worker Node SG

### Why

CIDR `10.0.0.0/16` is broader.
Safer is: only EKS nodes can connect.

### How

AWS Console → ElastiCache → Redis → Security groups
Edit inbound rule:

* Port: 6379
* Source: **EKS Worker Node SG**

---

## 9) /docs works inside cluster but not via ELB

### Test inside cluster

```bash
kubectl run tmp --rm -it --restart=Never --image=curlimages/curl -- sh
curl -s -I http://document-service:80/docs
curl -s http://document-service:80/health
```

If inside cluster works but ELB fails → mostly:

* ELB SG inbound missing NodePort
* Node SG inbound missing NodePort
* Target group health checks wrong port/path

---

## 10) Health checks spam logs (GET /health repeated)

### Why

Kubernetes liveness/readiness probes call `/health` repeatedly.
This is normal.

You will see logs like:
`GET /health HTTP/1.1 200 OK`

---

## 11) Useful Commands (Copy/Paste)

### Get resources

```bash
kubectl get pods -o wide -n default
kubectl get svc -n default
kubectl get endpoints -n default
```

### Describe

```bash
kubectl describe pod <pod-name> -n default
kubectl describe svc document-service -n default
```

### Logs

```bash
kubectl logs <pod-name> -n default --tail=200
```

### Port forward (local debugging)

```bash
kubectl port-forward svc/document-service 8080:80 -n default
```

Then open:

* [http://localhost:8080/docs](http://localhost:8080/docs)
* [http://localhost:8080/health](http://localhost:8080/health)

---

```


✔️ ELB not working fix
✔️ Redis down fix
✔️ DynamoDB permission issues
✔️ Pod crash fix
✔️ Health unhealthy fix