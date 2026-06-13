# Containers & Orchestration Platforms
## Interview-Ready & Learning Guide

---

## Quick Summary

**Container deployment approaches:** Docker (containerization), Kubernetes (orchestration), Ansible (configuration management), vs direct App Service deployment.

---

## 1. What Are Containers?

### Concept

```
Container = Lightweight VM-like package
├─ Contains: Application + dependencies + runtime
├─ Not: Full OS (shares host kernel)
├─ Benefit: Consistent across environments
├─ Technology: Docker

Traditional Deployment:
Dev Environment          Production Environment
├─ Windows 11           ├─ Windows Server 2022
├─ .NET 8               ├─ .NET 8
└─ Code                 ├─ Code
   "Works on my machine"   └─ "Why doesn't it work here?"
                           ❌ Environment mismatch

Container Deployment:
Dev Container                 Prod Container
├─ .NET 8                     ├─ .NET 8
├─ App dependencies           ├─ App dependencies
├─ Config                     ├─ Config
└─ Code                       └─ Code
   ✅ Identical               ✅ Identical
   ✅ Guaranteed consistency
```

### Docker Image vs Container

```
Docker Image = Blueprint (template)
├─ Contains: Application + runtime + dependencies
├─ Immutable (read-only)
├─ Stored in registry (Docker Hub, Azure Container Registry)
├─ Versioned (tag: v1.0, v2.0)
└─ Multiple containers run from same image

Docker Container = Running instance
├─ Instance of image
├─ Mutable (running state)
├─ Can be started/stopped
├─ Resource-limited (CPU, memory)
└─ Isolated from other containers

Analogy:
- Image = Class definition
- Container = Object instance
```

### Dockerfile Example

```dockerfile
# Base image
FROM mcr.microsoft.com/dotnet/aspnet:8.0

# Set working directory
WORKDIR /app

# Copy built application
COPY bin/Release/net8.0/publish/ .

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

# Run application
ENTRYPOINT ["dotnet", "NotificationsFrontend.dll"]
```

---

## 2. Kubernetes (Container Orchestration)

### What Is Kubernetes?

```
Kubernetes = Orchestration platform for containers
├─ Automatically manages containers
├─ Scales applications
├─ Handles failover
├─ Load balances traffic
├─ Updates rolling deployments
└─ Complex but powerful

Kubernetes Concepts:
├─ Pod: Smallest unit (usually 1 container)
├─ Deployment: Desired state (3 replicas)
├─ Service: Load balancer for pods
├─ Ingress: External traffic routing
├─ ConfigMap: Configuration data
└─ Secret: Sensitive data
```

### Kubernetes Architecture

```
KUBERNETES CLUSTER:

Master Node (Control Plane):
├─ API Server
├─ Scheduler
├─ Controller Manager
└─ etcd (state storage)

Worker Nodes (compute):
├─ Node 1 (kubelet)
│  ├─ Pod 1 (Container 1)
│  └─ Pod 2 (Container 2)
├─ Node 2 (kubelet)
│  ├─ Pod 3 (Container 1)
│  └─ Pod 4 (Container 1)
└─ Node 3 (kubelet)
   ├─ Pod 5 (Container 1)
   └─ Pod 6 (Container 1)

Service (Load Balancer):
└─ Routes traffic to pods automatically
   (if pod 1 dies, traffic routes to pod 2)
```

### Kubernetes Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notifications-frontend
spec:
  replicas: 3           # 3 pod replicas
  selector:
    matchLabels:
      app: notifications
  template:
    metadata:
      labels:
        app: notifications
    spec:
      containers:
      - name: app
        image: acr.azurecr.io/notifications:v2.0
        ports:
        - containerPort: 8080
        
        # Resource limits
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        
        # Health check
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10

---
apiVersion: v1
kind: Service
metadata:
  name: notifications-service
spec:
  selector:
    app: notifications
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

### Kubernetes Benefits

```
✅ AUTO-SCALING
   - Monitor CPU
   - If CPU > 80%: Add more pods
   - If CPU < 20%: Remove pods

✅ SELF-HEALING
   - Pod crashes? Restart it
   - Node dies? Move pods to other nodes
   - Health check failed? Restart pod

✅ ROLLING UPDATES
   - Deploy v2.0 gradually
   - Replace old pods with new
   - No downtime (like slot swap, but continuous)

✅ LOAD BALANCING
   - Distribute traffic across pods
   - Service abstracts pod IPs
   - Client sees single endpoint

✅ RESOURCE EFFICIENCY
   - Bin-pack pods on nodes
   - Share infrastructure
   - Lower cost than VMs
```

---

## 3. Docker Orchestration

### Docker Swarm (Simple Orchestration)

```
Docker Swarm = Simpler alternative to Kubernetes
├─ Built into Docker
├─ Easier to learn than Kubernetes
├─ Limited features compared to Kubernetes
├─ Works on Docker hosts directly
└─ Good for small deployments

Docker Compose (Local Development):
version: '3'
services:
  notifications-api:
    image: myregistry/notifications:v1.0
    ports:
      - "8080:8080"
    environment:
      - ConnectionString=...
  
  cosmos-db:
    image: mcr.microsoft.com/cosmosdb/linux/emulator
    ports:
      - "8081:8081"

docker-compose up -d  # Start all services
docker-compose down   # Stop all services
```

### Why Kubernetes Over Docker Swarm?

```
Kubernetes:
├─ Feature-rich (auto-scale, rolling updates)
├─ Industry standard (90%+ adoption)
├─ Larger ecosystem
├─ Better for production at scale
└─ More complex (steeper learning curve)

Docker Swarm:
├─ Simpler learning curve
├─ Easier to get started
├─ Less powerful (limited scaling)
├─ Rarely used in production (2% adoption)
└─ Limited community support

Recommendation: Use Kubernetes for production
```

---

## 4. Ansible (Configuration Management)

### What Is Ansible?

```
Ansible = Configuration management automation
├─ NOT for orchestration
├─ Used to: Configure servers, deploy code, manage configs
├─ Agentless (SSH-based)
├─ Simple YAML playbooks
├─ Works on any OS (Linux, Windows, Mac)

Typical Use Case:
├─ Deploy to 100 physical servers
├─ Configure networking, firewall
├─ Install software on each
├─ Update configuration files
└─ Restart services
```

### Ansible Playbook Example

```yaml
---
- name: Deploy Application
  hosts: all
  tasks:
    - name: Stop current application
      systemd:
        name: notifications
        state: stopped
    
    - name: Download new version
      get_url:
        url: https://releases.example.com/v2.0.zip
        dest: /opt/app/
    
    - name: Extract application
      unarchive:
        src: /opt/app/v2.0.zip
        dest: /opt/app/
    
    - name: Start application
      systemd:
        name: notifications
        state: started
    
    - name: Health check
      uri:
        url: http://localhost:8080/health
        status_code: 200
      retries: 3
      delay: 10
```

### Use Cases

```
✅ USE Ansible if:
   - Multiple physical servers
   - Need configuration management
   - Simple, agentless deployment
   - Team familiar with YAML

❌ AVOID Ansible if:
   - Using containers (use Kubernetes)
   - Using cloud-managed services (use cloud tools)
   - Need auto-scaling/orchestration
```

---

## 5. SupportServices: Why App Service Instead?

### Architecture Decision

```
SupportServices CHOSE: App Service + Slots
├─ Hosted on Azure
├─ Managed by Microsoft
├─ No container complexity
├─ Built-in scaling, health checks, deployment slots

Why NOT Kubernetes?
├─ Over-engineered for our scale
├─ 14 services × 3 environments = manageable count
├─ Would require: K8s cluster, operators, expertise
├─ Additional cost: ~$500/month per K8s cluster
├─ Operational burden: Higher complexity

Why NOT Docker?
├─ Docker alone doesn't solve orchestration
├─ Would need: Docker Swarm or Kubernetes
├─ App Service already handles: versioning, rollback
├─ No benefit without orchestration

Why NOT Ansible?
├─ Unnecessary for cloud-managed services
├─ App Service deployment is already automated
├─ Would add complexity without benefit
```

### Cost Comparison

```
SupportServices Current (App Service):
├─ 14 domains
├─ 3 environments (dev, staging, prod)
├─ 1 app per environment
├─ Cost: ~$1,200/month per domain
├─ Total: ~$16,800/month

If Changed to Kubernetes:
├─ AKS cluster: ~$500/month base
├─ Node pool: ~1,000/month
├─ Ingress controller: ~100/month
├─ Container registry: ~50/month
├─ Database (separate managed): ~500/month
├─ Additional operational cost
├─ Total: ~$3,500+/month just for infrastructure
├─ PLUS: Need Kubernetes expertise, operational overhead
└─ NET: 20%+ MORE expensive, more complex
```

### Trade-offs

```
APP SERVICE (Current Choice):
✅ Managed by Microsoft
✅ Simple deployment (zip upload)
✅ Built-in slot swap (blue-green)
✅ Auto-scaling built-in
✅ Health checks built-in
✅ Lower operational burden
✅ Cost-effective for our scale
❌ Less flexible (not for custom orchestration)
❌ Azure-only (vendor lock-in)

KUBERNETES (Alternative):
✅ Highly flexible
✅ Multi-cloud capable
✅ Industry standard (portable skills)
✅ Self-healing, auto-scaling
✅ Scales to massive deployments
❌ Operational complexity (must manage)
❌ Requires expertise
❌ Overkill for 14 services
❌ Higher cost (for this scale)
❌ Slower deployments (image building)
```

---

## 6. When to Use Each

### App Service (Current Approach)

```
USE App Service when:
- Azure-only environment
- 10-100 applications
- Want managed service
- Team prefers simplicity
- Cost-conscious at mid-scale

AVOID when:
- Multi-cloud needed
- 1000+ services
- Require custom orchestration
- Need full control over runtime
```

### Kubernetes

```
USE Kubernetes when:
- Multi-cloud or on-premises
- 1000+ containers at scale
- Need advanced auto-scaling
- Team has Kubernetes expertise
- Organization has dedicated platform team

AVOID when:
- Simple CRUD apps
- Small team without K8s experience
- Cost-conscious for small scale
- Azure-only with few services
```

### Containers (Docker)

```
USE Containers when:
- Want consistency across environments
- Need portability
- Will use with orchestration
- Need microservices at scale
- Team comfortable with container tech

AVOID when:
- App Service works fine
- No portability requirements
- Team unfamiliar with Docker
```

### Ansible

```
USE Ansible when:
- Multiple physical servers
- Configuration management needed
- Simple deployments
- Team familiar with Ansible

AVOID when:
- Using cloud-managed services
- Need orchestration (use K8s)
- Deploy to containers (use K8s)
```

---

## 7. Deployment Comparison

### App Service Deployment (SupportServices)

```
Timeline: 40 minutes
├─ T=0:00   Code commit
├─ T=0:05   Build (compile + test)
├─ T=0:25   Publish artifact
├─ T=0:30   Bicep deployment
├─ T=0:35   Code to staging slot
├─ T=0:40   Functional tests
├─ T=0:45   Swap slots (prod ← staging)
├─ T=0:45   v2.0 LIVE
└─ Zero downtime ✅

Why fast:
- No image building
- No registry push
- Zip upload is quick
- Direct App Service deployment
```

### Kubernetes Deployment

```
Timeline: 90+ minutes
├─ T=0:00   Code commit
├─ T=0:05   Build (compile + test)
├─ T=0:25   Build Docker image
├─ T=0:35   Push to registry
├─ T=0:40   Update Kubernetes manifest
├─ T=0:45   Apply to cluster
├─ T=1:00   Rolling update (old pods → new pods)
├─ T=1:20   Readiness probes pass
├─ T=1:30   v2.0 LIVE
└─ Rolling update (gradual, not instant)

Why slower:
- Image building takes 10-15 minutes
- Registry push takes 10 minutes
- Rolling update takes 10+ minutes
- More moving parts
```

---

## 8. Interview-Ready Answers

### Q: "When would you use Kubernetes vs App Service?"

**Answer:**
```
KUBERNETES:
Use when:
- Need multi-cloud portability
- 1000+ services at massive scale
- Require advanced auto-scaling/self-healing
- Have dedicated platform team
- Microservices architecture

APP SERVICE (Our Choice):
Use when:
- Azure-only environment
- 10-100 applications
- Want managed service (no ops burden)
- Cost-conscious at this scale
- Simple deployment pipeline

SupportServices uses App Service because:
- 14 domains, 3 environments = manageable count
- Azure-only infrastructure
- Want simplicity & managed service
- Slot-based deployment is sufficient
- Lower cost & operational burden
- Team focused on features, not infrastructure
```

### Q: "Explain containers and when to use them"

**Answer:**
```
Containers (Docker):
- Lightweight package: app + dependencies + runtime
- Portable: Same container runs on dev, prod, laptop
- Benefit: "Works on my machine" problem solved

Use containers when:
✅ Need consistency across environments
✅ Will use with orchestration (K8s)
✅ Need microservices at scale
✅ Portability across cloud providers

Don't use containers if:
❌ App Service is sufficient
❌ No orchestration planned (container alone doesn't scale)
❌ Team unfamiliar with Docker

SupportServices decision:
- Could use containers, but App Service simpler
- No need for portability (Azure-only)
- Direct deployment faster than docker build → push → K8s deploy
```

---

## 9. Key Takeaways

1. **Containers** = Packaging (Docker) for portability
2. **Kubernetes** = Orchestration (auto-scale, self-heal)
3. **Ansible** = Configuration management (not orchestration)
4. **App Service** = Managed service (no ops burden)
5. **Choose based on:**
   - Scale (services count, traffic)
   - Complexity (operational burden)
   - Flexibility (multi-cloud, custom)
   - Cost
   - Team expertise
6. **SupportServices** = App Service is right choice (simplicity, cost, scale)
7. **Know when each applies** (interview requirement)