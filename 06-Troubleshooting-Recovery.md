# Troubleshooting & Recovery Guide
## Interview-Ready & Learning Guide

---

## Quick Summary

**Common deployment failures and recovery procedures:** Build fails → Fix → Tests fail → Fix → Swap fails → Rollback/Fix.

---

## 1. Build Stage Troubleshooting

### Build Failed: Compilation Error

```
Build.NonOfficial.Chat failed
  │
  └─ error CS0103: Name 'logger' does not exist
  
Investigation:
1. Click build → see error line
2. Run locally: dotnet build Chat/Chat.slnx
3. Find: logger not imported

Fix:
- Add: using Microsoft.Extensions.Logging;
- Commit: git commit -am "Fix: add missing using"
- Push: git push origin fix/bug-name
- Build auto-retriggers
```

### Build Failed: NuGet Restore Error

```
Error: NU1101: Unable to find package "SomePackage"
  
Investigation:
1. Check package name spelling
2. Check if in Directory.Packages.props
3. Check NuGet feed access (nuget.config)
4. Run locally: dotnet restore Chat/Chat.slnx

Fix:
- Verify package version in Directory.Packages.props exists
- Check internal feed credentials (if private package)
- Contact NuGet admin if feed access denied
```

### Build Failed: Test Failure

```
Test Failure: Tests.Chat.Unit.SendMessage_WithNullInput_ThrowsException
  Expected: ArgumentException
  Actual: NullReferenceException

Investigation:
1. Read test code → see what's expected
2. Read production code → see what's happening
3. Reproduce locally: dotnet test Chat/Chat.slnx --filter "SendMessage"

Fix:
1. Logic error in code:
   - Add null check before accessing property
   - Commit: git commit -am "Fix: add null validation"
   
2. Test too strict:
   - Update test expectation if behavior changed intentionally
   - Commit: git commit -am "Test: update expectation"
   
3. Test flaky (sometimes passes, sometimes fails):
   - Add delays/retries if timing issue
   - Mock network/DB access better
   - Make test more deterministic
```

---

## 2. Deploy Stage: Bicep Failure

### Bicep Deployment Failed: Syntax Error

```
Bicep compilation error: Expected parameter, found 'resource'

Investigation:
1. Check bicep syntax (indentation, brackets)
2. Run locally: bicep lint Notifications/Deploy/env/notifications.bicep
3. Check template file for typos

Fix:
- Correct syntax
- Verify with: bicep build notifications.bicep
- Should generate ARM template with no errors
- Deploy via pipeline
```

### Bicep Deployment Failed: Resource Quota Exceeded

```
Error: The resource quota of 800 has been reached

Investigation:
1. Count current resources: az resource list --resource-group rg-notifications-dev
2. Check quota: az provider show --namespace Microsoft.Web
3. What changed: Did we add new service or duplicate?

Fix:
1. Delete unused resources
2. Consolidate services if possible
3. Request quota increase from Azure support
4. Re-queue deployment
```

### Bicep Deployment Failed: Permission Denied

```
ERROR: The user, group or application does not have the required permission

Investigation:
1. Check service connection credentials
2. Verify RBAC role on subscription/resource group
3. Check if service connection token expired

Fix:
- Contact Azure admin for RBAC role assignment
- Service connection needs "Contributor" role
- Re-queue deployment once permissions granted
```

---

## 3. Deploy Stage: Functional Tests Failure

### Functional Tests Failed: API Returns 500

```
Test: SendNotification_ShouldStoreMessage
Status: 500 Internal Server Error

Investigation:
1. Check app logs on staging slot:
   az webapp log tail -n app-notifications-frontend-dev -g rg --slot staging
   
2. Look for exception:
   System.NullReferenceException: Object reference not set...
   
3. Check recent code change: What changed?

Fix:
1. Debug locally: Reproduce the issue
2. Fix logic error
3. Commit & push
4. Build auto-triggers
5. Re-queue deployment
```

### Functional Tests Failed: Connection Timeout

```
Test: ProcessQueueMessage_ShouldUpdate
Status: Operation timed out (30s)

Investigation:
1. App startup slow? Check memory/CPU
2. Database unreachable? Check connection string
3. Network blocked? Check firewall rules
4. Service Bus down? Check queue access

Fix:
1. Increase timeout if app is slow
2. Fix connection string (wrong Cosmos DB endpoint?)
3. Check firewall rules allow staging slot IP
4. Restart service if temporarily down
5. Re-queue deployment
```

### Functional Tests Failed: Test is Flaky

```
Test sometimes passes, sometimes fails (non-deterministic)

Investigation:
Flaky test indicators:
- Fails on retry
- Passes locally, fails in pipeline
- Timing-dependent
- External service dependent

Fix:
1. Add retry logic:
   for (int i = 0; i < 3; i++)
   {
     try { response = await client.PostAsync(...); break; }
     catch { await Task.Delay(1000); }
   }

2. Mock external service:
   _mockDb.Setup(x => x.GetAsync(...)).ReturnsAsync(item);

3. Add explicit waits:
   await Task.Delay(TimeSpan.FromSeconds(2));
   var result = await GetResult();

4. Make idempotent:
   Don't rely on exact timing
```

---

## 4. Deploy Stage: Slot Swap Failure

### Slot Swap Failed: Staging Slot Doesn't Exist

```
Error: Slot 'staging' does not exist for app 'app-notifications-frontend-dev'

Investigation:
1. Check if Bicep created slot properly
2. Verify slot name in Bicep matches pipeline config

Fix:
1. Manually create slot:
   az webapp deployment slot create \
     -n app-notifications-frontend-dev \
     -g rg-notifications-frontend-dev \
     -s staging

2. Or fix Bicep to ensure slot creation

3. Re-queue deployment
```

### Slot Swap Failed: App Not Healthy

```
Error: Cannot swap - staging slot is unhealthy

Investigation:
1. SSH into staging slot and check app logs
2. Check if app started:
   curl https://app-notifications-frontend-dev-staging.azurewebsites.net/health
   
3. Look for startup errors

Fix:
1. Wait for app to fully start (30-60 seconds)
2. Check if dependencies available (DB, Key Vault)
3. Fix configuration issues
4. Re-run functional tests
5. Retry swap
```

### Slot Swap Failed: Traffic Router Issue

```
Error: Failed to update traffic routes during swap

Investigation:
This is rare, usually transient Azure issue

Fix:
1. Wait 1 minute
2. Retry swap command
3. Or contact Azure support if persistent
```

---

## 5. Production: Post-Swap Monitoring

### Error Rate Spike Detected

```
T=0:30    Swap complete
T=1:00    On-call monitors App Insights
T=1:05    Error rate: 5% (was 0.1%)

Immediate Action: ROLLBACK
```

```powershell
# Instant rollback
az webapp deployment slot swap \
  -n app-notifications-frontend-prod \
  -g rg-notifications-frontend-prod \
  --slot staging

# Result: v1.0 back live in < 1 second

# Investigation (post-rollback)
# 1. Check what changed in v2.0
# 2. Review commit diffs
# 3. Fix issue
# 4. Re-queue deployment
```

### Performance Degradation

```
T=0:30    Swap complete
T=2:00    Performance monitoring
         Latency: 500ms (was 50ms)

Investigation:
1. Check if code change inefficient
2. Check if database queries slow
3. Check if external service timeout
4. Monitor CPU/memory

If critical:
- Rollback
- Investigate root cause
- Fix & redeploy

If acceptable:
- Monitor for stability
- Fix performance in next version
```

### Database Connection Errors

```
Error: Cannot connect to database after swap

Investigation:
1. Check connection string still valid
2. Verify app can reach Cosmos DB
3. Check firewall rules

Likely causes:
- Connection string swapped incorrectly
- Staging slot config different from prod
- Cosmos DB connection limit exceeded

Fix:
1. Verify connection strings in both slots identical
2. Check Cosmos DB throttling
3. Scale up if needed
4. Re-deploy
```

---

## 6. Complete Recovery Flowchart

```
Deployment Issue Detected
  │
  ├─ Build Stage Failed?
  │  ├─ Compilation error → Fix code → Commit & push → Build auto-retriggers
  │  ├─ Test failure → Fix logic or test → Commit & push → Auto-retry
  │  └─ NuGet error → Check config → Fix credentials → Retry
  │
  ├─ Deploy Stage: Bicep Failed?
  │  ├─ Syntax error → Fix bicep → Lint locally → Re-queue
  │  ├─ Quota exceeded → Delete unused → Request increase → Re-queue
  │  └─ Permission denied → Check RBAC → Admin grants access → Re-queue
  │
  ├─ Deploy Stage: Tests Failed?
  │  ├─ API 500 error → Check logs → Fix code → Re-queue
  │  ├─ Timeout → Increase timeout or fix config → Re-queue
  │  ├─ Flaky test → Add retry logic → Re-queue
  │  └─ External service down → Wait/fix → Re-queue
  │
  ├─ Deploy Stage: Swap Failed?
  │  ├─ Slot missing → Create slot → Re-queue
  │  ├─ App unhealthy → Wait for startup → Re-queue
  │  └─ Router issue → Retry swap
  │
  └─ Production: Error Detected?
     ├─ Error rate spike → IMMEDIATE ROLLBACK
     ├─ Performance degradation → Monitor/Rollback
     ├─ Database errors → Check config → Rollback if critical
     └─ Investigate root cause → Fix → Re-deploy
```

---

## 7. Manual Recovery Commands

```bash
# Check deployment status
az deployment group show -g rg-notifications-dev -n deployment-name

# View deployment logs
az deployment group show -g rg-notifications-dev -n deployment-name --query properties.outputs

# Check app health
curl https://app-notifications-frontend-dev.azurewebsites.net/health

# View app logs
az webapp log tail -n app-notifications-frontend-dev -g rg-notifications-frontend-dev

# Manual slot swap
az webapp deployment slot swap \
  -n app-notifications-frontend-dev \
  -g rg-notifications-frontend-dev \
  --slot staging

# Scale up if needed
az appservice plan update \
  -n plan-notifications-dev \
  -g rg-notifications-frontend-dev \
  --sku P1V2

# Restart app
az webapp restart \
  -n app-notifications-frontend-dev \
  -g rg-notifications-frontend-dev
```

---

## 8. Interview-Ready Answers

### Q: "What happens if deployment fails?"

**Answer:**
```
Depends on when it fails:

BUILD STAGE:
- Compiler error: Fix code, push, build auto-retriggers
- Test failure: Fix logic, push, auto-retry
- NuGet error: Check feed access, fix config

DEPLOY STAGE (Bicep):
- Syntax error: Fix bicep, lint locally, re-queue
- Quota exceeded: Delete unused, request increase
- Permission denied: Admin grants RBAC role

DEPLOY STAGE (Tests):
- API error: Check logs, fix code, re-queue
- Timeout: Increase timeout or fix config
- Flaky test: Add retry logic, make deterministic

DEPLOY STAGE (Swap):
- Slot missing: Create slot, re-queue
- App unhealthy: Wait for startup, check config

PRODUCTION:
- Error spike: IMMEDIATE ROLLBACK (swap back)
- Performance drop: Monitor, rollback if critical
- DB errors: Check config, rollback if needed

Key: Old version always available via slot swap.
Can rollback any production issue in < 1 second.
```

### Q: "How do you debug deployment issues?"

**Answer:**
```
Systematic approach:

1. Identify failure stage:
   - Build logs: Check compiler/test output
   - Bicep logs: Check ARM template generation
   - Deploy logs: Check deployment progress
   - Functional test logs: Check test output

2. Reproduce locally:
   - dotnet build /warnaserror
   - dotnet test
   - bicep lint

3. Check configuration:
   - Connection strings correct?
   - Environment variables set?
   - Permissions/RBAC valid?

4. Fix issue:
   - Update code, commit, push
   - Build auto-retriggers

5. Monitor fix:
   - Watch build status
   - If passes: Monitor deployment
   - If prod: Watch App Insights
```

---

## 9. Key Takeaways

1. **Systematic debugging** — Identify stage, check logs, fix, retry
2. **Multiple gates catch issues** — Build, unit tests, integration, functional, prod monitoring
3. **Instant rollback** — Swap back in < 1 second if needed
4. **Safe recovery** — Old version always 1 swap away
5. **Automated retries** — Build auto-retriggers on code push
6. **Manual commands** — Always have az CLI recovery procedures ready