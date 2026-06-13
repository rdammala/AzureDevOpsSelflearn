# CI/CD Pipelines: Complete Overview
## Interview-Ready & Learning Guide

---

## Quick Summary

**Two-tier pipeline system:** NonOfficial (auto CI on every master commit) + Official (manual production deployment).

---

## 1. Pipeline Architecture Overview

### The Two-Tier System

```
NONOFFICIAL PIPELINE                    OFFICIAL PIPELINE
├─ Build.NonOfficial.Chat               ├─ Build.Official.Chat
└─ Deploy.NonOfficial.Chat              └─ Deploy.Official.Chat

When triggered: Auto on master commit   When triggered: Manual, any time
Environment access: Dev + Staging       Environment access: Dev + Staging + Prod
Signing: Optional                       Signing: Required (code signing)
TSA Signing: No                         TSA Signing: Yes (Trust Services Automation)
```

### Pipeline Flow Comparison

| Stage | NonOfficial | Official |
|-------|-------------|----------|
| **Trigger** | Auto on master push | Manual queue by team |
| **Build** | Compile, test, publish | Same + code signing |
| **Deploy Dev** | Yes | Yes |
| **Deploy Staging** | Yes | Yes |
| **Deploy Prod** | No (blocked) | Yes (after approval) |
| **Speed** | ~40 min to staging | ~3 hours (with approvals) |

---

## 2. NonOfficial Pipeline (Auto CI/CD)

### When It Triggers

```
Developer pushes to master
  ↓ (2 seconds)
Azure DevOps detects commit
  ↓ (if path matches Chat/**, Common/**)
Build.NonOfficial.Chat triggered
  ↓
Runs on build agent
```

### Path Filtering Example

```yaml
# Build.NonOfficial.Chat.yml
trigger:
  branches:
    include:
      - master
  paths:
    include:
      - Common/**          # Any Common changes
      - Chat/**            # Any Chat changes
    exclude:
      - Docs/**            # Docs changes don't trigger
      - README.md          # README changes don't trigger
```

**Result:**
- Commit only changes Docs/ → Pipeline skips (saves time)
- Commit changes Chat/ or Common/ → Pipeline runs

### Build Stage

```
Step 1: Restore NuGet packages
   └─ Downloads all dependencies from nuget.org + internal feeds

Step 2: Build solution
   └─ dotnet build Chat/Chat.slnx /warnaserror
   └─ Warnings = errors (fail build if any warnings)

Step 3: Run tests
   └─ Unit tests (fast, isolated)
   └─ Integration tests (slower, use emulators)
   └─ Tests must pass to continue

Step 4: Publish artifacts
   └─ dotnet publish Chat/Frontend → Frontend.zip
   └─ dotnet publish Chat/Backend → Backend.zip
   └─ Copy Bicep templates → bicep/

Step 5: Sign binaries (NonOfficial skips this)
   └─ Official: Add certificate chain proving code is authorized

Step 6: Upload artifact
   └─ Azure Artifacts: drop_build_main
   └─ Available for deployment stage
```

**Timeline:**
```
T=0:00    Commit detected
T=0:02    Build starts
T=0:10    Compile complete
T=0:15    Tests complete
T=0:18    Publish complete
T=0:20    Signing complete (if Official)
T=0:22    Artifact uploaded
```

### Deploy Stage

```
Artifact ready (Frontend.zip, Backend.zip, notifications.bicep)
  ↓ (auto-triggers)
Deploy to dev
  ├─ Run Bicep deployment
  ├─ Deploy Frontend code
  ├─ Deploy Backend code
  ├─ Run functional tests
  └─ Swap staging ← production
  ↓ (waits if tests fail)
Deploy to staging
  ├─ [Same as dev]
  ├─ [Waits for dev success]
  └─ Result: ✅ Staging ready for production
  ↓
NonOfficial complete
(Prod blocked for safety)
```

---

## 3. Official Pipeline (Production Deployment)

### When It Triggers

**Manual trigger by Release Manager:**

```
Release Manager in Azure DevOps:
  1. Go to Build.Official.Chat
  2. Click "Queue new build"
  3. Select revision (usually latest from master)
  4. Click "Queue"

Pipeline starts
  ↓
Same build as NonOfficial + code signing
  ↓
Deploy starts (dev → staging → prod gate)
```

### Code Signing (Official Only)

```
Why sign?
  ├─ Proves Microsoft authorized this build
  ├─ Protects against tampering
  ├─ Required by security/compliance
  └─ Signature chain verifiable

How?
  1. Build completes
  2. Binaries sent to signing service
  3. Certificate chain attached
  4. Signed binaries returned
  5. Artifact includes signature verification info
```

### Production Deployment Gate

```
After staging deploys successfully:
  ↓
APPROVAL GATE
  ├─ Release Manager reviews
  ├─ Checks monitoring/alerts
  ├─ Verifies staging tests passed
  └─ Decides: Approve or Reject

If Approved:
  └─ Deploy to prod

If Rejected:
  └─ Deployment stops, old version stays live
```

---

## 4. Build Pipeline Detailed Breakdown

### Azure DevOps Pipeline Structure

```yaml
name: $(Build.DefinitionName)_$(SourceBranchName)_$(Date:yyyyMMdd)$(Rev:.r)

# When to trigger
trigger:
  branches:
    include:
      - master
  paths:
    include:
      - Common/**
      - Chat/**

# What agents to use
pool:
  vmImage: 'windows-latest'

# Shared variables
variables:
  buildConfiguration: 'Release'
  dotnetVersion: '10.0.x'

stages:
  # Stage 1: Build code
  - stage: Build
    displayName: 'Build and Test'
    jobs:
      - job: BuildJob
        displayName: 'Compile & Test'
        steps:
          # Step 1: Setup .NET
          - task: UseDotNet@2
            displayName: 'Install .NET 10'
            inputs:
              version: $(dotnetVersion)
          
          # Step 2: Restore dependencies
          - task: DotNetCoreCLI@2
            displayName: 'Restore NuGet Packages'
            inputs:
              command: 'restore'
              projects: 'Chat/Chat.slnx'
          
          # Step 3: Build
          - task: DotNetCoreCLI@2
            displayName: 'Build Solution'
            inputs:
              command: 'build'
              projects: 'Chat/Chat.slnx'
              arguments: '--configuration $(buildConfiguration) /warnaserror'
          
          # Step 4: Run tests
          - task: DotNetCoreCLI@2
            displayName: 'Run Unit Tests'
            inputs:
              command: 'test'
              projects: 'Chat/Chat.slnx'
              arguments: '--configuration $(buildConfiguration) --filter "TestCategory=Unit"'
          
          # Step 5: Publish
          - task: DotNetCoreCLI@2
            displayName: 'Publish Frontend'
            inputs:
              command: 'publish'
              projects: 'Chat/Frontend/Frontend.csproj'
              publishWebProjects: false
              zipAfterPublish: true
              modifyOutputPath: false
              arguments: '--output $(Build.ArtifactStagingDirectory)/Frontend'
          
          # Step 6: Code Sign (Official only)
          - task: EsrpCodeSigning@1
            displayName: 'Sign Binaries'
            inputs:
              ConnectedServiceName: 'CodeSigningService'
              FolderPath: '$(Build.ArtifactStagingDirectory)'
          
          # Step 7: Upload artifact
          - task: PublishBuildArtifacts@1
            displayName: 'Publish Artifacts'
            inputs:
              PathtoPublish: '$(Build.ArtifactStagingDirectory)'
              ArtifactName: 'drop_build_main'
```

### What Each Step Does

| Step | Purpose | Failure Handling |
|------|---------|------------------|
| Setup .NET | Download & install dotnet 10 | Re-run (usually network) |
| Restore | Download NuGet packages | Check nuget.config, feed access |
| Build | Compile to IL | Fix code errors, commit fix |
| Test | Run unit/integration tests | Fix logic, add missing tests |
| Publish | Create deployment packages | Check output paths |
| Sign | Add certificate chain | Contact security team |
| Upload | Store in Azure Artifacts | Check storage quotas |

---

## 5. Deploy Pipeline Detailed Breakdown

### Deployment Stages

```
Stage 1: Deploy to Dev
├─ Bicep deployment (infra)
├─ Code deployment (Frontend + Backend)
├─ Functional tests (must pass)
└─ Slot swap (new code goes live on dev)

Stage 2: Deploy to Staging
├─ [Same as dev]
├─ Depends on Stage 1 success
└─ Result: Code ready for production review

Stage 3: Deploy to Prod (Official Only)
├─ APPROVAL GATE (Release Manager reviews)
├─ If approved:
│  ├─ Bicep deployment
│  ├─ Code deployment
│  ├─ Functional tests
│  └─ Slot swap
└─ If rejected:
   └─ Deployment stops (old version stays live)
```

### Bicep Deployment Example

```bash
# Deploy infrastructure via Bicep
az deployment group create \
  --resource-group rg-notifications-dev \
  --name rg-notifications-dev \
  --template-file Notifications/Deploy/env/notifications.bicep \
  --parameters Notifications/Deploy/params/dev.bicepparam
```

**What Happens:**
```
1. Validate Bicep syntax
2. Compile to ARM template
3. Generate resource change list
4. Create/update resources in Azure:
   ├─ Web App (app-notifications-frontend-dev)
   ├─ Function App (func-notifications-backend-dev)
   ├─ Key Vault (for secrets)
   ├─ Cosmos DB (data storage)
   └─ Service Bus (messaging)
5. Wait for all resources healthy
```

### Code Deployment Example

```bash
# Deploy Frontend code to staging slot
az webapp deployment source config-zip \
  --resource-group rg-notifications-frontend-dev \
  --name app-notifications-frontend-dev \
  --slot staging \
  --src-path Frontend.zip
```

**What Happens:**
```
1. Download Frontend.zip from artifact
2. Extract to staging slot
3. Start app on staging slot
4. Health check (wait for 200 OK)
5. Proceed to functional tests
```

### Functional Tests

```csharp
// Test runs against staging slot (not production)
// Verifies app works end-to-end

[TestMethod]
public async Task SendNotification_ShouldReachCustomer()
{
    // Arrange
    var client = new HttpClient { 
        BaseAddress = new Uri("https://notifications-dev.example.com/staging")
    };
    var message = new SendNotificationRequest { Text = "Hello" };
    
    // Act
    var response = await client.PostAsJsonAsync("/api/notifications", message);
    
    // Assert
    Assert.AreEqual(200, (int)response.StatusCode);
    
    // Verify in database
    var notification = await _cosmosDb.GetNotificationAsync(id);
    Assert.AreEqual("Hello", notification.Text);
}
```

**If test fails:**
```
❌ Functional test failed
  ↓
Pipeline halts (slot swap doesn't happen)
  ↓
Old version stays live (safe)
  ↓
Team investigates & fixes
  ↓
Re-queue deploy when ready
```

### Slot Swap

```
BEFORE:
  Production Slot: v1.0 (live, serving customers)
  Staging Slot: v2.0 (tested, ready)

SWAP COMMAND:
  az webapp deployment slot swap \
    -n app-notifications-frontend-dev \
    -g rg-notifications-frontend-dev

AFTER:
  Production Slot: v2.0 (live, serving customers)
  Staging Slot: v1.0 (stopped, idle)

BENEFIT:
  ✅ Zero downtime (traffic never stops)
  ✅ Instant rollback (swap back if issues)
  ✅ Safe testing (old version always 1 swap away)
```

---

## 6. Timeline: From Commit to Production

```
T=0:00    Developer commits to master
T=0:02    Azure DevOps detects commit
T=0:05    Build agent picks up job
T=0:06    Setup .NET runtime

T=0:10    Restore NuGet packages
T=0:15    Build complete (or ❌ fail)
T=0:18    Tests complete (or ❌ fail)
T=0:22    Artifact uploaded

T=0:23    Deploy stage starts (auto-trigger)
T=0:30    Bicep deployment to dev
T=0:35    Frontend code deployed to staging slot
T=0:36    Backend code deployed to staging slot
T=0:40    Functional tests start
T=0:50    Functional tests complete (or ❌ fail)
T=0:52    Slot swap (code goes live on dev)

T=1:00    Staging deployment starts (waits for dev)
T=1:15    Bicep, code, tests on staging
T=1:30    Staging slot swap
T=1:40    ✅ Staging ready

T=1:45    FOR OFFICIAL ONLY:
          Release Manager triggered manual official pipeline
T=1:50    Official build starts (same as NonOfficial + signing)
T=2:05    Signing complete
T=2:10    Official deploy starts
T=2:40    Deploy to dev again (for consistency)
T=3:00    Deploy to staging again
T=3:10    🏁 APPROVAL GATE - Release Manager decides
T=3:15    Approved → Deploy to prod
T=3:30    Prod swap
T=3:35    🌍 PRODUCTION LIVE

Total time: NonOfficial ~1h40min, Official ~3h30min
(Includes approval gates & safety checks)
```

---

## 7. Failure Scenarios

### Build Fails (Compiler Error)

```
Build.NonOfficial.Chat started
  ↓
Compile: error CS1234: Syntax error
  ↓
❌ BUILD FAILED
  ↓
PR shows ❌ status
  ↓
Developer receives notification
  ↓
Developer fixes code:
  git commit -am "Fix: compiler error"
  git push origin fix/bug-name
  ↓
Build re-triggers automatically
  ↓
✅ Passes (or ❌ fails again)
```

### Tests Fail

```
Tests running...
  ↓
Unit test: Assert.AreEqual(5, result) - expected 5, got 4
  ↓
❌ TEST FAILED
  ↓
Pipeline halts (doesn't proceed to deploy)
  ↓
Developer investigates:
  - Logic error in code? → Fix & commit
  - Test too strict? → Update test
  - Environment issue? → Configure properly
  ↓
git push fix → Build auto-retriggers
  ↓
✅ Tests pass → Deploy proceeds
```

### Functional Tests Block Deployment

```
Staging slot ready, functional tests run
  ↓
Test: POST /api/notifications → 500 Internal Server Error
  ↓
❌ FUNCTIONAL TEST FAILED
  ↓
Slot swap BLOCKED (app not working, can't go live)
  ↓
Team options:
  Option 1: Find bug, push fix, re-queue deploy
  Option 2: Skip Bicep (reuse old infra), just redeploy code
  Option 3: Revert entire deploy, rollback to previous version
```

### Slot Swap Fails

```
Ready to swap production ← staging
  ↓
Swap command executes
  ↓
❌ ERROR: Cannot swap slots
  ↓
Reason: Staging slot doesn't exist (wasn't created)
  ↓
Investigation:
  - Check if Bicep created slot
  - Check if slot naming correct
  - Check Azure quotas
  ↓
Fix & re-queue deploy
```

---

## 8. Interview-Ready Answers

### Q: "Explain your CI/CD pipeline"

**Answer:**
```
We have two pipelines:

NONOFFICIAL (auto, dev/test):
- Triggers on every master commit (path-filtered)
- Builds code, runs tests, publishes artifacts
- Deploys to dev, then staging (if tests pass)
- ~1h40min end-to-end

OFFICIAL (manual, production):
- Manually queued when team is ready to ship
- Same build as NonOfficial + code signing
- Deploys to dev/staging again (for consistency)
- Then hits approval gate → Release Manager reviews
- If approved, deploys to prod
- If rejected, deployment stops
- ~3h total (includes approval time)

Each environment progression (dev → staging → prod) has tests
that must pass before swap. If any test fails, deployment halts
and old version stays live (safe).

Deployment uses slot swap for zero downtime:
- New code on staging slot
- Tests run
- Swap production ← staging (instant)
- Rollback is 1 swap back if needed
```

### Q: "What happens if tests fail?"

**Answer:**
```
Depends on which tests:

1. Build fails (compiler error):
   - PR shows ❌
   - Developer fixes & pushes
   - Build auto-retriggers

2. Unit tests fail:
   - Build halts
   - Dev fixes logic or test
   - Retry

3. Functional tests fail (on staging):
   - Deployment halts
   - Old version stays live
   - Team investigates & fixes
   - Re-queue deploy

Multiple test gates ensure bad code never reaches customers.
```

### Q: "Why deploy to dev/staging even if it's not production?"

**Answer:**
```
Safety & validation:

1. Dev (cheap, fast): Team can test before officially shipping
2. Staging (prod-like): Production test with same config, resources
3. Prod (actual customers): Only after staging validation

Tests run at each stage. If staging tests pass but prod tests
might fail differently (network, scale, etc.), we catch it.

Also enables quick rollback: if prod has issue, we swap back
to staging slot (was running prod before, now sits idle).
```

---

## 9. Key Takeaways

1. **Two-tier pipeline** — NonOfficial auto, Official manual
2. **Path filtering** — Only affected domains rebuild
3. **Automated testing gates** — Build, unit, integration, functional
4. **Deployment safety** — Multiple approval gates + functional tests
5. **Zero downtime** — Slot swap mechanism
6. **Audit trail** — All deploys logged, traceable to commit
7. **Rollback ready** — 1 slot swap back to previous version