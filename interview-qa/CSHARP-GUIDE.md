# C# for DevOps Engineers - Step-by-Step Guide

> ⏱️ **Study Time:** 60-75 minutes | **Level:** Intermediate

## Overview

While C# is primarily for application development, DevOps engineers need C# knowledge for:
- Reading/understanding service code
- Writing custom build tools and analyzers
- Interacting with Azure SDKs programmatically
- Creating deployment utilities
- Testing infrastructure code

**What You'll Learn:**
- C# basics (console apps, async patterns)
- Azure SDK usage
- HTTP clients and API interactions
- Configuration management
- Error handling and logging

---

## Step 1: C# Project Setup & Structure

### Creating a Console Application

```bash
# Create new console app
dotnet new console -n DeploymentUtility
cd DeploymentUtility

# Restore dependencies
dotnet restore

# Build
dotnet build

# Run
dotnet run
```

### Project Structure
```
DeploymentUtility/
├── Program.cs           # Entry point
├── Services/
│   ├── AzureService.cs
│   └── DeploymentService.cs
├── Models/
│   ├── DeploymentConfig.cs
│   └── ResourceGroup.cs
├── appsettings.json
└── DeploymentUtility.csproj
```

---

## Step 2: Basic C# Syntax for DevOps

### Variables & Types

```csharp
using System;

class Program {
    static void Main() {
        // Variables
        string serviceName = "Chat";
        int port = 8080;
        bool isProduction = true;
        DateTime deployTime = DateTime.Now;
        
        // String interpolation
        Console.WriteLine($"Deploying {serviceName} on port {port}");
        
        // Constants
        const string ApiVersion = "2021-06-15";
        
        // Collections
        List<string> services = new() { "Chat", "Search", "Refunds" };
        Dictionary<string, string> config = new()
        {
            { "environment", "prod" },
            { "region", "eastus" }
        };
    }
}
```

### Control Flow

```csharp
// If-Else
if (isProduction) {
    Console.WriteLine("Using production settings");
} else if (isStaging) {
    Console.WriteLine("Using staging settings");
} else {
    Console.WriteLine("Using dev settings");
}

// Switch expression (modern C#)
string environment = environmentName switch {
    "prod" => "production",
    "dev" => "development",
    "staging" => "staging",
    _ => throw new ArgumentException("Unknown environment")
};

// Loops
foreach (var service in services) {
    Console.WriteLine($"Processing {service}");
}

// LINQ (Language Integrated Query)
var prodServices = services
    .Where(s => s.StartsWith("P"))
    .OrderBy(s => s)
    .ToList();
```

---

## Step 3: Async/Await Patterns

### Essential for DevOps Tools

```csharp
using System;
using System.Threading.Tasks;

class DeploymentTool {
    // Async method
    static async Task Main(string[] args) {
        try {
            await DeployServiceAsync("Chat", "prod");
        } catch (Exception ex) {
            Console.WriteLine($"Error: {ex.Message}");
        }
    }
    
    static async Task DeployServiceAsync(string serviceName, string environment) {
        Console.WriteLine($"Starting deployment of {serviceName}...");
        
        // Simulate async work
        await Task.Delay(2000);
        
        Console.WriteLine($"✓ {serviceName} deployed to {environment}");
    }
    
    // Running multiple tasks in parallel
    static async Task DeployMultipleServices(List<string> services) {
        var tasks = services.Select(s => DeployServiceAsync(s, "prod"));
        await Task.WhenAll(tasks);
        Console.WriteLine("All services deployed");
    }
}
```

---

## Step 4: Dependency Injection & Configuration

### Modern .NET Configuration Pattern

```csharp
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

class Program {
    static async Task Main(string[] args) {
        // Build configuration
        var config = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .AddEnvironmentVariables()
            .Build();
        
        // Setup dependency injection
        var services = new ServiceCollection();
        
        services.AddSingleton<IConfiguration>(config);
        services.AddScoped<IDeploymentService, DeploymentService>();
        services.AddScoped<IAzureService, AzureService>();
        services.AddHttpClient<IApiClient, ApiClient>();
        
        var serviceProvider = services.BuildServiceProvider();
        
        // Use registered services
        var deploymentService = serviceProvider.GetRequiredService<IDeploymentService>();
        await deploymentService.DeployAsync("prod");
    }
}

// Configuration classes
public class DeploymentConfig {
    public string Environment { get; set; }
    public string ResourceGroup { get; set; }
    public int MaxRetries { get; set; } = 3
}

// appsettings.json
/*
{
  "Deployment": {
    "Environment": "prod",
    "ResourceGroup": "rg-prod-apps",
    "MaxRetries": 3
  }
}
*/
```

---

## Step 5: Working with Azure SDK

### Azure Resources Management

```csharp
using Azure;
using Azure.Identity;
using Azure.ResourceManager;

class AzureService {
    private readonly ArmClient _client;
    
    public AzureService() {
        // Authenticate using DefaultAzureCredential (supports managed identity, CLI, etc.)
        _client = new ArmClient(new DefaultAzureCredential());
    }
    
    public async Task CreateResourceGroupAsync(string name, string location) {
        var subscription = await _client.GetDefaultSubscriptionAsync();
        var resourceGroups = subscription.GetResourceGroups();
        
        var rgData = new ResourceGroupData(new AzureLocation(location));
        await resourceGroups.CreateOrUpdateAsync(WaitUntil.Completed, name, rgData);
        
        Console.WriteLine($"✓ Resource group {name} created");
    }
    
    public async Task ListResourcesAsync(string resourceGroupName) {
        var subscription = await _client.GetDefaultSubscriptionAsync();
        var resourceGroup = await subscription.GetResourceGroupAsync(resourceGroupName);
        
        var resources = resourceGroup.Value.GetGenericResources();
        
        await foreach (var resource in resources.GetAllAsync()) {
            Console.WriteLine($"- {resource.Data.Name} ({resource.Data.Type})");
        }
    }
}
```

---

## Step 6: HTTP Clients & API Calls

### Interacting with REST APIs

```csharp
using System.Net.Http;
using System.Text.Json;

interface IApiClient {
    Task<T> GetAsync<T>(string endpoint);
    Task PostAsync<T>(string endpoint, T data);
    Task<bool> HealthCheckAsync(string serviceUrl);
}

class ApiClient : IApiClient {
    private readonly HttpClient _httpClient;
    
    public ApiClient(HttpClient httpClient) {
        _httpClient = httpClient;
    }
    
    public async Task<T> GetAsync<T>(string endpoint) {
        var response = await _httpClient.GetAsync(endpoint);
        response.EnsureSuccessStatusCode();
        
        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(content);
    }
    
    public async Task PostAsync<T>(string endpoint, T data) {
        var json = JsonSerializer.Serialize(data);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PostAsync(endpoint, content);
        response.EnsureSuccessStatusCode();
    }
    
    public async Task<bool> HealthCheckAsync(string serviceUrl) {
        try {
            var response = await _httpClient.GetAsync($"{serviceUrl}/health");
            return response.IsSuccessStatusCode;
        } catch {
            return false;
        }
    }
}

// Usage
var apiClient = serviceProvider.GetRequiredService<IApiClient>();
var healthy = await apiClient.HealthCheckAsync("https://api.example.com");
```

---

## Step 7: Error Handling & Logging

### Enterprise-Grade Error Handling

```csharp
using Microsoft.Extensions.Logging;

class DeploymentService : IDeploymentService {
    private readonly ILogger<DeploymentService> _logger;
    private readonly IConfiguration _config;
    
    public DeploymentService(
        ILogger<DeploymentService> logger,
        IConfiguration config) {
        _logger = logger;
        _config = config;
    }
    
    public async Task DeployAsync(string environment) {
        try {
            _logger.LogInformation("Starting deployment to {Environment}", environment);
            
            ValidateEnvironment(environment);
            
            await ExecuteDeploymentAsync(environment);
            
            _logger.LogInformation("Deployment to {Environment} completed successfully", environment);
        } catch (ValidationException ex) {
            _logger.LogError(ex, "Validation failed: {Message}", ex.Message);
            throw;
        } catch (Exception ex) {
            _logger.LogError(ex, "Deployment to {Environment} failed", environment);
            throw;
        }
    }
    
    private void ValidateEnvironment(string environment) {
        var validEnvironments = new[] { "dev", "staging", "prod" };
        if (!validEnvironments.Contains(environment)) {
            throw new ValidationException($"Invalid environment: {environment}");
        }
    }
    
    private async Task ExecuteDeploymentAsync(string environment) {
        // Implementation
        await Task.Delay(100);
    }
}

class ValidationException : Exception {
    public ValidationException(string message) : base(message) { }
}
```

---

## Step 8: Building a Deployment Utility

### Complete Example

```csharp
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

class Program {
    static async Task Main(string[] args) {
        var services = ConfigureServices();
        var deploymentTool = services.GetRequiredService<DeploymentTool>();
        
        try {
            await deploymentTool.RunAsync(args);
        } catch (Exception ex) {
            Console.WriteLine($"Fatal error: {ex.Message}");
            Environment.Exit(1);
        }
    }
    
    static ServiceProvider ConfigureServices() {
        var services = new ServiceCollection();
        
        services.AddLogging(logging => {
            logging.AddConsole();
            logging.SetMinimumLevel(LogLevel.Information);
        });
        
        services.AddSingleton<DeploymentTool>();
        
        return services.BuildServiceProvider();
    }
}

class DeploymentTool {
    private readonly ILogger<DeploymentTool> _logger;
    
    public DeploymentTool(ILogger<DeploymentTool> logger) {
        _logger = logger;
    }
    
    public async Task RunAsync(string[] args) {
        if (args.Length < 2) {
            Console.WriteLine("Usage: deployment-tool <environment> <version>");
            return;
        }
        
        string environment = args[0];
        string version = args[1];
        
        _logger.LogInformation("Deploying version {Version} to {Environment}", version, environment);
        
        var services = new List<string> { "Chat", "Search", "Refunds" };
        
        foreach (var service in services) {
            await DeployServiceAsync(service, environment, version);
        }
        
        _logger.LogInformation("All services deployed successfully");
    }
    
    private async Task DeployServiceAsync(string service, string environment, string version) {
        _logger.LogInformation("Deploying {Service} v{Version}...", service, version);
        await Task.Delay(500);  // Simulate work
        _logger.LogInformation("✓ {Service} deployed", service);
    }
}
```

---

## Step 9: Testing DevOps Tools

### Unit Testing with xUnit/MSTest

```csharp
using Xunit;
using Moq;

public class DeploymentServiceTests {
    [Fact]
    public async Task DeployAsync_WithValidEnvironment_Succeeds() {
        // Arrange
        var mockLogger = new Mock<ILogger<DeploymentService>>();
        var mockConfig = new Mock<IConfiguration>();
        var service = new DeploymentService(mockLogger.Object, mockConfig.Object);
        
        // Act
        await service.DeployAsync("prod");
        
        // Assert
        mockLogger.Verify(
            x => x.Log(
                It.IsAny<LogLevel>(),
                It.IsAny<EventId>(),
                It.IsAny<It.IsAnyType>(),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.AtLeastOnce);
    }
    
    [Fact]
    public async Task DeployAsync_WithInvalidEnvironment_ThrowsException() {
        // Arrange
        var mockLogger = new Mock<ILogger<DeploymentService>>();
        var mockConfig = new Mock<IConfiguration>();
        var service = new DeploymentService(mockLogger.Object, mockConfig.Object);
        
        // Act & Assert
        await Assert.ThrowsAsync<ValidationException>(() => service.DeployAsync("invalid"));
    }
}
```

---

## Step 10: Advanced - Custom Roslyn Analyzers

### Analyzing Code for DevOps Compliance

```csharp
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Diagnostics;

[DiagnosticAnalyzer(LanguageNames.CSharp)]
public class DeploymentCodeAnalyzer : DiagnosticAnalyzer {
    public const string DiagnosticId = "DEPLOY001";
    
    private static readonly DiagnosticDescriptor Rule = new(
        DiagnosticId,
        "Missing error handling",
        "Method '{0}' should include error handling for deployment operations",
        "Design",
        DiagnosticSeverity.Warning,
        isEnabledByDefault: true);
    
    public override ImmutableArray<DiagnosticDescriptor> SupportedDiagnostics =>
        ImmutableArray.Create(Rule);
    
    public override void Initialize(AnalysisContext context) {
        context.RegisterSyntaxNodeAction(AnalyzeMethodDeclaration, SyntaxKind.MethodDeclaration);
    }
    
    private void AnalyzeMethodDeclaration(SyntaxNodeAnalysisContext context) {
        var methodDeclaration = (MethodDeclarationSyntax)context.Node;
        
        if (methodDeclaration.Identifier.Text.Contains("Deploy") &&
            !HasErrorHandling(methodDeclaration)) {
            var diagnostic = Diagnostic.Create(Rule, methodDeclaration.GetLocation(), methodDeclaration.Identifier);
            context.ReportDiagnostic(diagnostic);
        }
    }
    
    private bool HasErrorHandling(MethodDeclarationSyntax method) {
        return method.Body?.DescendantNodes()
            .OfType<TryStatementSyntax>()
            .Any() ?? false;
    }
}
```

---

## Key NuGet Packages for DevOps

| Package | Purpose |
|---------|---------|
| `Azure.Identity` | Authentication |
| `Azure.ResourceManager` | Resource management |
| `Microsoft.Extensions.Logging` | Logging |
| `Microsoft.Extensions.Configuration` | Configuration management |
| `HttpClientFactory` | HTTP client management |
| `Serilog` | Structured logging |
| `xunit` | Unit testing |
| `Moq` | Mocking |

---

## Troubleshooting Tips

| Problem | Solution |
|---------|----------|
| NuGet package version conflicts | `dotnet package outdated` |
| Build fails on CI | Check .NET SDK version in global.json |
| Async deadlock | Use `.ConfigureAwait(false)` in library code |
| Memory leaks | Use `using` statements for IDisposable objects |
| Logging not working | Verify LogLevel configuration |

---

## Practice Exercises

1. **Build a health check utility** that tests multiple service endpoints in parallel
2. **Create a resource cleanup tool** that removes resources matching a pattern
3. **Write a deployment validator** that checks Bicep templates before deployment
4. **Build a cost analyzer** that queries Azure usage and generates reports

---

## Next Steps

- 🎯 Study Azure SDK deeply for your specific services
- 🎯 Learn dependency injection patterns for enterprise applications
- 🎯 Implement comprehensive logging and telemetry
- 🎯 Create custom analyzers for your organization's standards

Good luck! 🚀
