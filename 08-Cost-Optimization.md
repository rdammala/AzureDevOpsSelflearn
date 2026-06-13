# Cost Optimization in Cloud DevOps
## Interview-Ready & Learning Guide

---

## Quick Summary

**Cost optimization strategies:** Right-sizing, shared resources, auto-scale, cleanup automation, reserved instances, monitoring.

---

## 1. Cost Drivers

### What Costs Money in Azure?

```
App Services:
├─ Compute (VM instances): B1 ($10), B2 ($50), P1V2 ($500)
├─ SKU size (more CPU/memory = more cost)
└─ Instance count (more instances = more cost)

Databases:
├─ Cosmos DB: $500+/month (shared by envs)
├─ SQL Database: $50-500/month (shared by envs)
└─ Storage: $1-50/month per 50GB

Networking:
├─ Front Door (CDN): $0.079 per GB
├─ App Gateway: $30/month base + per rule
├─ Data transfer out: $0.087 per GB

Monitoring:
├─ Application Insights: Free tier (1GB/day)
├─ Log Analytics: $0.50 per GB ingested

Storage:
├─ Blob storage: $0.018 per GB/month
├─ Queue storage: $0.50 per million operations

Typically: 70% compute, 20% data, 10% networking/monitoring
```

---

## 2. Right-Sizing by Environment

### Dev Environment (Cheap)

```
Purpose: Developer testing, not production-like
   ↓
Size accordingly:

Web App:
  ├─ SKU: B1 (Shared compute)
  ├─ Instances: 1 (single)
  ├─ Cost: ~$10/month

Cosmos DB:
  ├─ Throughput: 400 RU/s (minimum)
  ├─ Shared with staging (same subscription)
  ├─ Cost: ~$50/month (shared)

Result: Dev environment = $10-20/month
```

### Staging Environment (Moderate)

```
Purpose: Production-like testing before go-live
   ↓
Size closer to production:

Web App:
  ├─ SKU: B2 or P1V1 (dedicated compute)
  ├─ Instances: 2-3 (moderate HA)
  ├─ Cost: ~$50-150/month

Cosmos DB:
  ├─ Shared with dev (same subscription/envType)
  ├─ Throughput: Shared
  ├─ Cost: Shared ~$50/month

Result: Staging environment = $50-150/month
```

### Production Environment (Expensive, Justified)

```
Purpose: Live user traffic, SLA requirements
   ↓
Size for reliability & performance:

Web App:
  ├─ SKU: P1V2-P3V2 (Premium, HA)
  ├─ Instances: 5-10 (high availability)
  ├─ Cost: ~$500-1000/month

Cosmos DB:
  ├─ Separate subscription (prod)
  ├─ Higher throughput: 10,000+ RU/s
  ├─ Cost: ~$500+/month

CDN/Front Door:
  ├─ $0.079/GB
  ├─ If 1TB traffic/month: $79
  └─ Cost: $79-200/month

Result: Production environment = $1000-1500/month
```

---

## 3. Two-Level Deployment Savings

### Without Two-Level Model

```
Traditional approach: Separate resources per env

Dev Environment:
├─ App Service: $10
├─ Cosmos DB: $500
└─ Total: $510

Staging Environment:
├─ App Service: $50
├─ Cosmos DB: $500 (duplicate!)
└─ Total: $550

Production Environment:
├─ App Service: $500
├─ Cosmos DB: $500 (duplicate!)
└─ Total: $1000

TOTAL MONTHLY COST: $2,060
```

### With Two-Level Model (SupportServices)

```
Two-level: Shared expensive resources

Nonprod Subscription (dev + staging):
├─ envType:
│  ├─ Cosmos DB: $50 (shared, low throughput)
│  └─ Key Vault: $1
│  └─ Subtotal: $51
├─ Dev environment:
│  └─ App Services: $10
├─ Staging environment:
│  └─ App Services: $50
└─ Nonprod Subtotal: $111

Production Subscription:
├─ envType:
│  ├─ Cosmos DB: $500 (high throughput, isolated)
│  └─ Key Vault: $1
│  └─ Subtotal: $501
├─ Production environment:
│  └─ App Services: $500
└─ Prod Subtotal: $1001

TOTAL MONTHLY COST: $1,112

SAVINGS: $2,060 - $1,112 = $948/month!
         = ~$11,400/year per domain
```

---

## 4. Resource Cleanup

### Unused Resources Cost Money

```
Example: Dev environment not used during weekend

WITHOUT AUTOMATION:
- App Service running 24/7
- Cosmos DB running 24/7
- Cost even when not used

WITH AUTOMATION:
- Schedule scale-down on Friday night
- Schedule scale-up Monday morning
- Save 3 days/week × 60% resource = $50/month
```

### Auto-Scaling Example

```bicep
// Scale down non-prod during off-hours
resource autoscaleRule 'Microsoft.Insights/autoscalesettings@2021-04-01' = {
  name: 'autoscale-${environment}'
  location: location
  
  properties: {
    targetResourceUri: appServicePlan.id
    enabled: true
    
    profiles: [
      {
        name: 'scale-down-night'
        capacity: {
          minimum: '1'      // Minimum 1 instance at night
          maximum: '1'
          default: '1'
        }
        // Schedule: 6 PM - 8 AM (off hours)
        recurrence: {
          frequency: 'Week'
          schedule: {
            timeZone: 'Pacific Standard Time'
            days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
            hours: [18]      // 6 PM
            minutes: [0]
          }
        }
      }
      {
        name: 'scale-up-day'
        capacity: {
          minimum: '3'      // 3 instances during business hours
          maximum: '5'
          default: '3'
        }
        recurrence: {
          frequency: 'Week'
          schedule: {
            timeZone: 'Pacific Standard Time'
            days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
            hours: [8]       // 8 AM
            minutes: [0]
          }
        }
      }
    ]
  }
}
```

---

## 5. Rightsizing Metrics

### Monitor These

```
CPU Utilization:
  ├─ < 20% average: Overprovisioned (scale down)
  ├─ 20-80% average: Right-sized (good)
  └─ > 80% average: Underprovisioned (scale up)

Memory Usage:
  ├─ < 50%: Likely overprovisioned
  └─ > 80%: Likely underprovisioned

Network Throughput:
  ├─ Calculate: peak throughput / instance capacity
  └─ < 50%: Likely overprovisioned

Cost per Transaction:
  ├─ Total cost / transactions per month
  ├─ If increasing without scaling: Inefficient
  └─ Should be relatively constant
```

### Rightsizing Example

```
Current setup: P1V2 (5 instances) = $500/month
  Metrics show: CPU 15%, Memory 30%, Network 10%
  Problem: Way overprovisioned

Action: Scale down to B2 (2 instances) = $100/month
  New metrics: CPU 40%, Memory 60%, Network 25%
  Result: Still has headroom, saves $400/month
```

---

## 6. Reserved Instances (1-year or 3-year commitment)

### Discount Strategy

```
On-Demand Pricing:
  ├─ Pay as you go
  ├─ No commitment
  ├─ Highest cost per hour

1-Year Reserved Instance:
  ├─ Commit to 1 year upfront
  ├─ ~33% discount vs on-demand
  ├─ Can't cancel (stuck)

3-Year Reserved Instance:
  ├─ Commit to 3 years upfront
  ├─ ~45-50% discount vs on-demand
  ├─ Substantial savings if stable workload

Example (P1V2 App Service):
  On-demand: $500/month × 12 = $6,000/year
  1-year RI:  ~$4,000/year (33% saving)
  3-year RI:  ~$3,000/year (50% saving)
```

### When to Use RIs

```
✅ USE RIs for:
   - Production infrastructure (stable, long-term)
   - Core databases (always running)

❌ AVOID RIs for:
   - Dev/test environments (may be deleted)
   - Experimental infrastructure
   - Short-lived projects
```

---

## 7. Monitoring Costs

### Azure Cost Management

```
# Check current spend per domain
az costmanagement query create \
  --scope /subscriptions/<id> \
  --timeframe LastMonth

# Set budget alert
az costmanagement budget create \
  --name "Chat-monthly-budget" \
  --amount 500 \
  --threshold 90 \
  --contact email@example.com
```

### Cost Visibility

```
Track by:
- Domain (Chat, Refunds, Search, etc.)
- Environment (dev, staging, prod)
- Resource type (App Service, Cosmos DB, etc.)
- Time (daily, weekly, monthly trends)

Budget alerts:
- Alert at 50% of budget
- Alert at 90% of budget
- Alert if actual > 110% of forecast
```

---

## 8. Interview-Ready Answers

### Q: "How do you optimize cloud costs?"

**Answer:**
```
Multiple strategies:

1. RIGHT-SIZING:
   - Dev: B1 SKU, 1 instance (~$10/month)
   - Staging: B2, 2-3 instances (~$50/month)
   - Prod: P1V2+, 5+ instances (~$500/month)
   - Match resources to actual needs

2. SHARED RESOURCES (Two-level):
   - Expensive resources (Cosmos DB, Key Vault) shared by dev+staging
   - Saves ~40% vs duplicating per env
   - Prod gets own isolated resources

3. AUTO-SCALING:
   - Scale down at night/weekends
   - Scale up during business hours
   - ~$50-100/month savings per domain

4. RESERVED INSTANCES:
   - Production: 1-3 year commitment
   - 30-50% discount vs on-demand
   - Saves thousands per year

5. MONITORING:
   - Track CPU, memory, network
   - Set budget alerts
   - Rightesize when metrics show waste

6. CLEANUP:
   - Delete unused resources
   - Stop staging slots when not deploying
   - Remove old app service plans

SupportServices example:
- Two-level deployment saves 40%
- Auto-scaling saves 10%
- Reserved instances save 40% on prod
- Total: 50%+ cost savings vs traditional
```

---

## 9. Cost Breakdown Example

### Single Domain (Chat) Monthly Cost

```
DEVELOPMENT:
├─ App Services: $10
├─ Share of Cosmos DB: $5
├─ Storage: $1
└─ Subtotal: $16/month

STAGING:
├─ App Services: $50
├─ Share of Cosmos DB: $10
├─ Storage: $2
└─ Subtotal: $62/month

PRODUCTION:
├─ App Services: $500
├─ Cosmos DB (dedicated): $500
├─ Storage: $50
├─ CDN/Front Door: $100
├─ Networking: $50
└─ Subtotal: $1,200/month

TOTAL PER DOMAIN: $1,278/month

With 14 domains:
Total Infrastructure Cost: ~$18,000/month
Per domain: ~$1,280/month
```

---

## 10. Key Takeaways

1. **Right-size per environment** — Dev cheap, Prod expensive
2. **Share expensive resources** — Two-level deployment
3. **Auto-scale off-hours** — Save 10-20%
4. **Monitor continuously** — Catch waste early
5. **Reserved instances** — 30-50% discount for prod
6. **Clean up unused** — Stop what's not needed
7. **Track by domain** — Visibility into cost drivers
8. **Budget alerts** — Catch overspend early