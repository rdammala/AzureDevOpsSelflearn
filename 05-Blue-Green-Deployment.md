# Blue-Green Deployment & Zero-Downtime Strategy
## Interview-Ready & Learning Guide

---

## Quick Summary

**Slot-based blue-green deployment:** Two app slots (staging + production), test on staging, swap traffic with zero downtime, instant rollback capability.

---

## 1. The Problem: Downtime

### Traditional Deployment

```
Traditional Approach:
  Production Running (v1.0)
  ↓
  Stop Application (⏹️ 5 minutes downtime)
  ↓
  Deploy New Code (v2.0)
  ↓
  Start Application
  ↓
  ⚠️  Customers see service unavailable!
```

**Issues:**
- ❌ Service unavailable during deploy
- ❌ No rollback if issues detected
- ❌ Customers' experience interrupted
- ❌ SLA violation (99.9% uptime requirement)

---

## 2. The Solution: Slot-Based Deployment

### How Slot Swap Works

```
BEFORE SWAP:
┌─────────────────────────────┐
│ App Service: notifications  │
├─────────────────────────────┤
│ Production Slot (live)      │
│ ├─ Code: v1.0              │
│ └─ Serving: 1000+ requests/sec
├─────────────────────────────┤
│ Staging Slot (offline)      │
│ ├─ Code: [empty]            │
│ └─ Idle                     │
└─────────────────────────────┘

DEPLOYMENT STAGE 1: Deploy to Staging
┌─────────────────────────────┐
│ App Service: notifications  │
├─────────────────────────────┤
│ Production Slot (live)      │
│ ├─ Code: v1.0              │
│ └─ Serving: 1000+ requests/sec
├─────────────────────────────┤
│ Staging Slot (testing)      │
│ ├─ Code: v2.0              │
│ └─ Running functional tests │
└─────────────────────────────┘

DEPLOYMENT STAGE 2: Tests Pass, Ready to Swap
┌─────────────────────────────┐
│ App Service: notifications  │
├─────────────────────────────┤
│ Production Slot (live)      │
│ ├─ Code: v1.0              │
│ └─ Serving: 1000+ requests/sec
├─────────────────────────────┤
│ Staging Slot (ready)        │
│ ├─ Code: v2.0              │
│ └─ Tests passed ✅           │
└─────────────────────────────┘

SWAP OPERATION (instant):
Command: az webapp deployment slot swap -n app -g rg -slot staging

AFTER SWAP:
┌─────────────────────────────┐
│ App Service: notifications  │
├─────────────────────────────┤
│ Production Slot (live)      │
│ ├─ Code: v2.0    🎉         │
│ └─ Serving: 1000+ requests/sec (no interruption!)
├─────────────────────────────┤
│ Staging Slot (idle)         │
│ ├─ Code: v1.0 (backup)      │
│ └─ 1 slot swap away         │
└─────────────────────────────┘

⏱️  SWAP TIME: < 1 second (instant!)
🔄 ROLLBACK: 1 swap back = v1.0 live again (if issues)
```

### Why This Works

```
✅ Zero Downtime: Traffic never stops
   - Staging gets new code
   - Tests run against staging
   - Swap happens (instant traffic switch)
   - Production now has new code
   - Old version now on staging (backup)

✅ Instant Rollback: If issues detected in prod
   - Swap staging ← production
   - v1.0 live again in < 1 second
   - v2.0 moved to staging
   - Zero customer impact

✅ Safe Testing: Tests run before traffic
   - Functional tests on staging slot
   - Real app, real dependencies, same config as prod
   - If tests fail → swap never happens
   - Old version stays live
```

---

## 3. Complete Deployment Timeline

### Before Swap

```
T=0:00    Bicep deployment starts
T=0:05    Infrastructure provisioned
          ├─ Web app created/updated
          ├─ Staging slot created
          └─ Settings configured

T=0:10    Code deployment to staging
          ├─ Frontend.zip extracted
          ├─ Dependencies restored
          └─ App starting...

T=0:15    App started on staging
          ├─ Health check: GET /health
          ├─ Waiting for 200 OK
          └─ Retry if needed (usually 2-3 attempts)

T=0:20    Functional tests start
          ├─ Test 1: Send notification
          ├─ Test 2: Verify in database
          ├─ Test 3: Check backend processing
          └─ ...all tests in suite

T=0:25    Tests complete
          ├─ If ✅ all pass: Continue to swap
          ├─ If ❌ any fail: HALT (swap doesn't happen)
          └─ Old version stays live
```

### Swap Moment

```
T=0:26    SWAP DECISION: All tests passed ✅
          
T=0:26    Execute swap command
          az webapp deployment slot swap \
            -n app-notifications-frontend-dev \
            -g rg-notifications-frontend-dev \
            --slot staging
          
T=0:26.1  Azure redirects router
          ├─ Production route → staging
          ├─ Staging route → production (old)
          └─ Swap complete
          
T=0:26.2  NEW CODE LIVE
          ├─ Customers now on v2.0
          ├─ No interruption (traffic continues)
          └─ v1.0 now on staging (backup)

T=0:27    Post-swap verification
          ├─ Health check production
          ├─ Monitor error rates
          └─ Watch metrics
```

---

## 4. Rollback Scenario

### If Issues Detected in Production

```
T=0:30    On-call engineer monitors
          ├─ Watches App Insights
          ├─ Error rate spikes
          └─ Detects anomaly: 5% errors (was 0.1%)

T=0:35    INCIDENT: Error spike confirmed

T=0:36    INSTANT ROLLBACK INITIATED
          
          az webapp deployment slot swap \
            -n app-notifications-frontend-dev \
            -g rg-notifications-frontend-dev \
            --slot staging
            
          Result: Swap production ← staging (again)

T=0:36.1  v1.0 BACK LIVE
          ├─ Customers now on v1.0
          ├─ Error rate drops to 0.1%
          └─ v2.0 back on staging (for investigation)

T=0:37    Post-rollback
          ├─ Team investigates v2.0 issue
          ├─ Fix bug
          ├─ Commit fix
          └─ Re-queue deployment when ready

TIME SAVED BY SLOT SWAP: 20+ minutes
  Without slots: Stop app, fix, redeploy = 30+ min downtime
  With slots: Swap back in 1 second = no customer impact
```

---

## 5. Swap Configuration

### App Service Configuration

```bicep
// Bicep template for web app with slots
resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: appName
  location: location
  
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    
    // Swap-safe configuration
    siteConfig: {
      // App settings (swapped by default)
      appSettings: [
        { name: 'ASPNETCORE_ENVIRONMENT', value: environment }
        { name: 'ServiceDomain', value: 'notifications' }
      ]
      
      // Connection strings (swapped by default)
      connectionStrings: [
        { 
          name: 'CosmosDb',
          connectionString: cosmosDbConnStr,
          type: 'Custom'
        }
      ]
    }
  }
}

// Staging slot (for swap)
resource stagingSlot 'Microsoft.Web/sites/slots@2021-02-01' = {
  parent: webApp
  name: 'staging'
  
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      // Same config as production
      appSettings: webApp.properties.siteConfig.appSettings
      connectionStrings: webApp.properties.siteConfig.connectionStrings
    }
  }
}
```

### Swap-Safe vs Non-Swappable Settings

| Setting | Swaps | Reason |
|---------|-------|--------|
| **App settings** | Yes | Environment-specific |
| **Connection strings** | Yes | Both slots use same DB |
| **Deployment slot** | Yes | Core swap mechanism |
| **IP addresses** | No | Routing-level |
| **SSL certificates** | No | Domain-level |
| **DNS bindings** | No | Domain-level |

---

## 6. Cost Savings from Slot Swap

### Compared to Multiple Environments

```
WITHOUT SLOT SWAP:
Scenario: 3 separate web apps (dev, staging, prod)
├─ Dev:     B1 SKU (1 instance)  = $10/month
├─ Staging: B2 SKU (2 instances) = $50/month
└─ Prod:    P1V2 (5 instances)   = $500/month
                    Total = $560/month

WITH SLOT SWAP:
Scenario: 1 web app with 2 slots per environment
├─ Dev:     1 app B1 + staging slot = $10/month
├─ Staging: 1 app B2 + staging slot = $50/month
└─ Prod:    1 app P1V2 + staging slot = $500/month
                    Total = $560/month

SAVINGS on slot itself: Minimal (slots don't add cost)

REAL SAVINGS: Fewer environments needed
├─ No duplicate resources
├─ Shared Cosmos DB (envType level)
├─ Shared Key Vault (envType level)
└─ Total: 30-40% infrastructure savings vs traditional
```

---

## 7. Limitations & Considerations

### Stateful Apps

```
⚠️  Problem: If your app stores state IN MEMORY

Before swap:
- Session in-memory dictionary on prod

After swap:
- Staging slot (now prod) doesn't have old sessions
- Users logged out! ❌

Solution:
- Use external session store (Redis, CosmosDB)
- Stateless APIs are best
- Never rely on app-instance memory
```

### Slot Warm-up

```
Problem: After swap, app takes time to start

After swap:
- Staging slot (now prod) needs app startup
- Cold start: 5-10 seconds
- Requests queued/slow during startup

Solution:
- Health check before swap
- Warm-up slot before swap
- Azure auto warm-up on swap (if configured)
```

### Database Compatibility

```
Issue: Bicep deploys SCHEMA changes during swap

Old app (prod): Expects column A
New app (staging): Expects columns A + B

What if swap happens mid-schema-change?
- Old app can't read new column names
- New app can't work with old schema
- ❌ Errors

Solution:
- Deploy schema FIRST (backward compatible)
- Deploy code that uses new + old schema
- Remove old column AFTER all instances updated
- Database versioning strategy needed
```

---

## 8. Interview-Ready Answers

### Q: "How do you achieve zero-downtime deployments?"

**Answer:**
```
Slot-based blue-green deployment:

1. Two app slots per environment (production + staging)
2. Deploy new code to staging slot
3. Run functional tests against staging
4. If tests pass: Swap staging ← production
5. Swap happens in < 1 second (instant traffic switch)
6. New code now live, zero downtime
7. Old code on staging slot (backup)

Rollback: If issues detected, swap back to old code
in < 1 second. Zero customer impact.

Why it works:
- Tests run on real app before traffic switches
- Swap is atomic (instant)
- Old version always 1 swap away
- No customer interruption
```

### Q: "What if deployment fails?"

**Answer:**
```
Depends on when it fails:

1. Bicep deployment fails:
   - Infrastructure not updated
   - Staging slot creation failed
   - Check Azure quotas, permissions
   - Manual fix required

2. Code deployment fails:
   - App won't start on staging
   - Tests can't run
   - Swap never happens
   - Old version stays live

3. Functional tests fail:
   - Deployment halts
   - Swap BLOCKED
   - Old version stays live (safe)
   - Team investigates & fixes

4. Swap succeeds but app breaks in prod:
   - On-call engineer monitors
   - Detects anomaly in App Insights
   - Immediate rollback: swap back to staging
   - Old version live again in < 1 second
   - Zero customer impact (compared to 20+ min without slots)
```

---

## 9. Key Takeaways

1. **Blue-green** — Two slots (staging + production)
2. **Test first** — Functional tests on staging before swap
3. **Atomic swap** — < 1 second, no interruption
4. **Instant rollback** — Swap back if issues
5. **Safe testing** — Real app, real dependencies
6. **Cost savings** — Shared resources at envType level
7. **Stateless design** — External session stores only