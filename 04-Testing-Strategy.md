# Testing Strategy - Comprehensive Guide
## Interview-Ready & Learning Guide

---

## Quick Summary

**Four-tier testing strategy:** Unit (fast, isolated) → Integration → Functional (per-env) → Production monitoring.

---

## 1. Test Categories & Pyramid

### Testing Pyramid

```
        🔺
       /  \         Manual Testing & Monitoring (Production)
      /    \
     /______\
    /        \      Functional Tests (1-2 hours, per environment)
   /          \
  /____________\
 /              \    Integration Tests (10-15 min, emulators)
/                \
/__________________\
                     Unit Tests (1-2 min, isolated, mocked)
```

**Why this shape?**
- **Unit tests** (bottom, widest): Fast, isolated, lots of them
- **Integration tests** (middle): Fewer, slower, test components together
- **Functional tests** (narrow): Deployed app, full flow, prod-like
- **Production** (top, minimal): Real users, real data, real impact

---

## 2. Unit Tests (Category: Unit)

### Purpose
Test individual methods in isolation, fast feedback.

### Tools
- **MSTest** — Microsoft's test framework
- **Moq** — Mocking library
- **FluentAssertions** — Readable assertions

### Example

```csharp
[TestClass]
[TestCategory("Unit")]
public class NotificationServiceTests
{
    // Arrange (setup)
    private Mock<ICosmosDb> _mockDb;
    private NotificationService _service;
    
    [TestInitialize]
    public void Setup()
    {
        _mockDb = new Mock<ICosmosDb>();
        _service = new NotificationService(_mockDb.Object);
    }
    
    // Test 1: Happy path
    [TestMethod]
    public async Task SendNotification_WithValidMessage_ReturnsSuccess()
    {
        // Arrange
        var notification = new Notification { Text = "Hello" };
        _mockDb.Setup(x => x.InsertAsync(notification))
            .ReturnsAsync(true);
        
        // Act
        var result = await _service.SendNotificationAsync(notification);
        
        // Assert
        result.Should().BeTrue();
        _mockDb.Verify(x => x.InsertAsync(notification), Times.Once);
    }
    
    // Test 2: Error case
    [TestMethod]
    public async Task SendNotification_WithNullMessage_ThrowsArgumentException()
    {
        // Act & Assert
        await _service.SendNotificationAsync(null)
            .Should()
            .ThrowAsync<ArgumentException>();
    }
}
```

### Characteristics

| Aspect | Unit Tests |
|--------|------------|
| **Speed** | <100ms per test |
| **Dependencies** | Mocked |
| **Database** | No real DB |
| **Network** | No real calls |
| **Runs in** | CI build stage |
| **Failure impact** | Just this unit needs fix |
| **Count** | 100+ per domain |

### Best Practices

```csharp
✅ DO:
- Test one behavior per test
- Name: TestName_Condition_ExpectedResult
- Use arrange-act-assert pattern
- Mock external dependencies
- Test edge cases (null, empty, max)

❌ DON'T:
- Test implementation details
- Depend on other tests
- Create real DB connections
- Test library code (assume it works)
- Have multiple assertions per test (usually)
```

---

## 3. Integration Tests (Category: Integration)

### Purpose
Test components working together (but not full app).

### Setup

```csharp
[TestClass]
[TestCategory("Integration")]
public class ChatServiceIntegrationTests
{
    private TestCosmosDbEmulator _cosmosDb;
    private TestServiceBusEmulator _serviceBus;
    private ChatService _service;
    
    [ClassInitialize]
    public static void ClassSetup(TestContext context)
    {
        // Start emulators once per test class
        DockerCompose.Up("docker-compose.yml");
    }
    
    [TestInitialize]
    public async Task TestSetup()
    {
        // Reset for each test
        _cosmosDb = new TestCosmosDbEmulator();
        _serviceBus = new TestServiceBusEmulator();
        _service = new ChatService(_cosmosDb, _serviceBus);
        
        await _cosmosDb.ClearAllAsync();
        await _serviceBus.ClearAllAsync();
    }
    
    [ClassCleanup]
    public static void ClassCleanup()
    {
        DockerCompose.Down();
    }
}
```

### Example Test

```csharp
[TestMethod]
public async Task ProcessChatMessage_PublishesToServiceBus()
{
    // Arrange
    var message = new ChatMessage 
    { 
        FromUser = "user1",
        Text = "Hello world",
        CreatedAt = DateTime.UtcNow
    };
    
    // Act
    await _service.ProcessMessageAsync(message);
    
    // Assert
    // Verify in Cosmos DB
    var stored = await _cosmosDb.GetMessageAsync(message.Id);
    stored.Should().NotBeNull();
    
    // Verify published to Service Bus
    var published = await _serviceBus.GetPublishedMessageAsync("chat-messages");
    published.Should().HaveCount(1);
}
```

### Characteristics

| Aspect | Integration Tests |
|--------|------------------|
| **Speed** | 1-10 seconds per test |
| **Dependencies** | Emulators or test instances |
| **Database** | Real emulator (in-memory) |
| **Network** | Real messaging (emulator) |
| **Runs in** | CI build stage |
| **Failure impact** | Multiple units need investigation |
| **Count** | 20-50 per domain |

---

## 4. Functional Tests (Category: Functional, runs at deploy stage)

### Purpose
Test full deployed application end-to-end.

### When Runs
```
After code deployed to staging slot
  ↓
Tests run against staging slot URL
  ↓
If tests pass:
  ├─ Slot swap (code goes live)
  └─ Move to next environment
  
If tests fail:
  ├─ Swap BLOCKED
  └─ Old version stays live (safe)
```

### Example

```csharp
[TestClass]
[TestCategory("Functional")]
public class NotificationApiFunctionalTests
{
    private HttpClient _client;
    
    [ClassInitialize]
    public static void ClassSetup(TestContext context)
    {
        // Run once: Setup client to point to deployed app
        // This URL changes per environment:
        // - Dev:  https://notifications-dev.example.com/staging
        // - Staging: https://notifications-staging.example.com/staging
        // - Prod: https://notifications-prod.example.com/staging
    }
    
    [TestInitialize]
    public void TestSetup()
    {
        _client = new HttpClient 
        { 
            BaseAddress = TestConfiguration.ApiUrl,
            DefaultRequestHeaders = { Authorization = TestAuth.GetBearerToken() }
        };
    }
}
```

### Test Cases

```csharp
// Test 1: Send notification, verify in database
[TestMethod]
public async Task SendNotification_ShouldStoreInDatabase()
{
    // Arrange
    var request = new SendNotificationRequest 
    { 
        UserId = "user123",
        Text = "Test notification"
    };
    
    // Act
    var response = await _client.PostAsJsonAsync("/api/notifications", request);
    
    // Assert
    response.StatusCode.Should().Be(HttpStatusCode.OK);
    
    // Verify in database (reads from deployed app's DB)
    var stored = await _cosmosDb.FindNotificationAsync(request.UserId);
    stored.Text.Should().Be("Test notification");
}

// Test 2: Endpoint returns 401 without auth
[TestMethod]
public async Task SendNotification_WithoutAuth_Returns401()
{
    var client = new HttpClient { BaseAddress = TestConfiguration.ApiUrl };
    // No auth header
    
    var response = await client.GetAsync("/api/notifications");
    response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
}

// Test 3: Backend processes message from queue
[TestMethod]
public async Task ProcessQueuedNotifications_ShouldPublishToCustomers()
{
    // Publish test message to Service Bus queue
    await _serviceBus.SendMessageAsync("notifications-input", testMessage);
    
    // Wait for backend to process (5 second timeout)
    await Task.Delay(TimeSpan.FromSeconds(5));
    
    // Verify result in database
    var processed = await _cosmosDb.GetNotificationStatusAsync(testMessage.Id);
    processed.Status.Should().Be("Sent");
}
```

### Characteristics

| Aspect | Functional Tests |
|--------|-----------------|
| **Speed** | 30 seconds to 10 minutes |
| **Dependencies** | Deployed app, real DB, real queue |
| **Database** | Real (staging environment) |
| **Network** | Real (staging environment) |
| **Runs in** | Deploy stage (after code deployed) |
| **Failure impact** | Blocks deployment (safe) |
| **Count** | 5-20 per domain |

---

## 5. Developer/Manual Tests (Category: Developer)

### Purpose
Long-running or environment-specific tests that hit live services.

### Example

```csharp
[TestClass]
[TestCategory("Developer")]
public class ChatLoadTests
{
    // These hit REAL production data
    // Only run manually: dotnet test --filter "TestCategory=Developer"
    
    [TestMethod]
    [Timeout(300000)] // 5 minutes
    public async Task LoadTest_Send1000Notifications()
    {
        var client = CreateClientWithRealAuth();
        
        var stopwatch = Stopwatch.StartNew();
        for (int i = 0; i < 1000; i++)
        {
            var response = await client.PostAsJsonAsync(
                "/api/notifications",
                new { Text = $"Message {i}" }
            );
            response.StatusCode.Should().Be(HttpStatusCode.OK);
        }
        stopwatch.Stop();
        
        TestContext.WriteLine($"Sent 1000 messages in {stopwatch.ElapsedMilliseconds}ms");
    }
}
```

---

## 6. Test Execution in CI/CD

### During Build (All Stages)

```
Build.NonOfficial.Chat started
  ↓
Step 1: Restore
Step 2: Build
Step 3: Run Unit Tests
  ├─ TestCategory=Unit
  ├─ ~100 tests
  ├─ ~2 minutes
  └─ If ❌ fail: Build halts

Step 4: Run Integration Tests
  ├─ TestCategory=Integration
  ├─ ~30 tests
  ├─ ~5 minutes (with Docker setup)
  └─ If ❌ fail: Build halts

Step 5: Publish
Step 6: Upload Artifact
```

### During Deploy (Functional Tests Only)

```
Deploy to Staging Slot
  ↓
Health Check (wait for 200 OK)
  ↓
Run Functional Tests
  ├─ TestCategory=Functional
  ├─ ~15 tests
  ├─ ~2 minutes (tests deployed app)
  └─ If ❌ fail: SWAP BLOCKED (old version stays live)
  
If ✅ pass:
  └─ Slot Swap (new code goes live)
```

### Manual Developer Tests

```
# Run only unit tests (fast)
dotnet test Chat/Chat.slnx --filter "TestCategory=Unit"

# Run unit + integration (complete suite)
dotnet test Chat/Chat.slnx --filter "TestCategory!=Developer"

# Run only load tests (against real environment)
dotnet test Chat/Chat.slnx --filter "TestCategory=Developer"

# Run specific test
dotnet test Chat/Chat.slnx --filter "FullyQualifiedName~SendNotification"
```

---

## 7. Test Naming Convention

### Pattern

```
TestMethod_Condition_ExpectedResult

Example:
- SendNotification_WithValidMessage_ReturnsSuccess
- SendNotification_WithNullMessage_ThrowsArgumentException
- ProcessQueue_WithEmptyQueue_Returns0Processed
- AuthValidation_WithExpiredToken_Returns401
```

### Inside Test Class

```csharp
[TestClass]
[TestCategory("Unit")]
public class NotificationServiceTests
{
    // Arrange: Setup
    // Act: Execute
    // Assert: Verify
    
    [TestMethod]
    public async Task MethodUnderTest_Condition_ExpectedResult()
    {
        // Arrange
        
        // Act
        
        // Assert
    }
}
```

---

## 8. Interview-Ready Answers

### Q: "Describe your testing strategy"

**Answer:**
```
Four-tier pyramid:

UNIT TESTS (fast, isolated):
- 100+ tests per domain
- Run in ~2 minutes
- Test individual methods with mocked dependencies
- Part of every build

INTEGRATION TESTS (slower, emulated):
- 20-50 tests per domain
- Run in ~5 minutes
- Test components together (Cosmos DB emulator, Service Bus emulator)
- Part of every build

FUNCTIONAL TESTS (deployed app):
- 5-20 tests per domain
- Run against staging slot after deployment
- Test end-to-end (API, database, messaging)
- Must pass before slot swap (blocks deployment if fail)

PRODUCTION MONITORING (real users):
- App Insights tracking
- Alert on anomalies
- On-call team monitors first hour
- Instant rollback if critical issue

Multiple gates ensure bad code never reaches customers.
```

### Q: "What if functional tests fail?"

**Answer:**
```
Deployment halts. Old version stays live (safe).

Options:
1. Fix bug, commit, re-queue deploy (if quick fix)
2. Investigate root cause (could be environment issue)
3. Re-run tests (could be flaky test)
4. Skip Bicep deployment (reuse old infrastructure)
5. Rollback entirely (if broken in prod)

Key: Customers never get broken code because tests
validate before swap happens.
```

---

## 9. Key Takeaways

1. **Pyramid shape** — Unit (many, fast) → Integration → Functional (few)
2. **Unit tests** — Fast, isolated, mocked dependencies
3. **Integration tests** — Components together, emulators
4. **Functional tests** — Deployed app, blocks swap if fail
5. **Multiple gates** — Build, unit, integration, then functional
6. **Naming** — TestMethod_Condition_ExpectedResult
7. **Production ready** — Only after all tests pass at all stages