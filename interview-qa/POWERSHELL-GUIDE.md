# PowerShell for DevOps & Build Engineering - Step-by-Step Guide

> ⏱️ **Study Time:** 45-60 minutes | **Level:** Beginner to Intermediate

## Overview

PowerShell is essential for DevOps engineers. This guide teaches you to automate Azure infrastructure, manage pipelines, and build deployment scripts.

**What You'll Learn:**
- Variables, loops, and control flow
- Azure PowerShell cmdlets
- Automating Azure deployments (Bicep)
- Build pipeline automation
- Error handling and logging

---

## Step 1: PowerShell Basics - Variables & Types

### What is PowerShell?
PowerShell is a task automation and configuration management framework built on .NET. It's particularly powerful for Azure automation.

### Variables & Types

```powershell
# Variables start with $
$name = "DevOps"
$count = 42
$enabled = $true

# Arrays
$services = @("Chat", "Search", "Refunds", "Notifications")
$services[0]  # "Chat"
$services.Count  # 4

# Hash tables (dictionaries)
$config = @{
    environment = "prod"
    region = "eastus"
    vmSize = "Standard_D2s_v3"
}
$config["environment"]  # "prod"
$config.vmSize  # "Standard_D2s_v3"

# String interpolation
$domain = "Refunds"
Write-Host "Deploying $domain service"  # Deploying Refunds service

# Strong typing (optional)
[int]$port = 8080
[string]$apiUrl = "https://api.example.com"
```

**Exercise:** Create a script that defines an array of your 3 favorite Azure services and prints each one.

---

## Step 2: Control Flow - If/Else & Loops

### If/Else Statements

```powershell
$environment = "prod"

if ($environment -eq "prod") {
    Write-Host "Using production settings"
} elseif ($environment -eq "staging") {
    Write-Host "Using staging settings"
} else {
    Write-Host "Using development settings"
}

# Comparison operators: -eq, -ne, -lt, -gt, -le, -ge
$buildTime = 45
if ($buildTime -gt 30) {
    Write-Warning "Build time is high!"
}

# Multiple conditions
$isProduction = $true
$hasBackup = $true

if ($isProduction -and $hasBackup) {
    Write-Host "Safe to deploy"
}
```

### Loops

```powershell
# For loop
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Build attempt $i"
}

# ForEach loop (iterating over collection)
$services = @("Chat", "Search", "Refunds")
foreach ($service in $services) {
    Write-Host "Deploying $service..."
    # Deploy logic here
}

# ForEach-Object pipeline
Get-ChildItem *.ps1 | ForEach-Object {
    Write-Host "Script: $_"
}

# While loop
$retries = 0
while ($retries -lt 3) {
    try {
        Invoke-RestMethod -Uri "https://api.example.com/health"
        break  # Exit loop on success
    } catch {
        $retries++
        Write-Host "Retry $retries..."
        Start-Sleep -Seconds 5
    }
}
```

**Exercise:** Write a loop that creates 5 Azure resource groups with names rg-prod-1 through rg-prod-5.

---

## Step 3: Functions & Modules

### Creating Reusable Functions

```powershell
# Basic function
function Get-ServiceStatus {
    param(
        [string]$ServiceName,
        [string]$Environment = "dev"
    )
    
    Write-Host "Checking status of $ServiceName in $Environment"
    return "Running"
}

# Call the function
Get-ServiceStatus -ServiceName "Chat" -Environment "prod"

# Function with multiple parameters
function Deploy-Service {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory=$true)]
        [string]$ImageVersion,
        
        [string]$Environment = "dev",
        [int]$Replicas = 1
    )
    
    Write-Host "Deploying $ServiceName v$ImageVersion to $Environment with $Replicas replicas"
    
    # Validation
    if ($Replicas -lt 1 -or $Replicas -gt 10) {
        throw "Invalid replica count: $Replicas (must be 1-10)"
    }
    
    # Deployment logic
    return @{
        ServiceName = $ServiceName
        Version = $ImageVersion
        Status = "Deployed"
    }
}

# Call with parameters
$result = Deploy-Service -ServiceName "Search" -ImageVersion "2.1.0" -Environment "prod" -Replicas 3
```

**Exercise:** Create a function `Test-BuildSuccess` that accepts a build ID and returns $true if successful, $false otherwise.

---

## Step 4: Error Handling & Try-Catch

### Robust Error Handling

```powershell
# Try-Catch-Finally
try {
    # Risky operation
    $resource = Get-AzResource -Name "non-existent" -ErrorAction Stop
    Write-Host "Resource found: $resource"
} catch [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceNotFoundException] {
    Write-Error "Resource not found!"
} catch {
    # Generic catch for any other error
    Write-Error "Unexpected error: $_"
} finally {
    Write-Host "Cleanup operations here..."
}

# Error action preferences
Get-AzResource -Name "test" -ErrorAction Stop        # Throw error and stop
Get-AzResource -Name "test" -ErrorAction Continue    # Log error and continue
Get-AzResource -Name "test" -ErrorAction SilentlyContinue  # Ignore error

# Retry logic with exponential backoff
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3
    )
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            & $ScriptBlock
            return
        } catch {
            if ($attempt -eq $MaxRetries) {
                throw "Failed after $MaxRetries attempts: $_"
            }
            $delaySeconds = [Math]::Pow(2, $attempt - 1)  # 1, 2, 4 seconds
            Write-Host "Attempt $attempt failed, retrying in $delaySeconds seconds..."
            Start-Sleep -Seconds $delaySeconds
        }
    }
}

# Usage
Invoke-WithRetry {
    New-AzResourceGroup -Name "test-rg" -Location "eastus"
}
```

---

## Step 5: Working with Azure - Authentication & Subscriptions

### Azure PowerShell Basics

```powershell
# Connect to Azure
Connect-AzAccount

# List subscriptions
Get-AzSubscription

# Set active subscription
Select-AzSubscription -SubscriptionId "00000000-0000-0000-0000-000000000000"

# Get current context
Get-AzContext
```

---

## Step 6: Managing Azure Resources

### Create & Manage Resources

```powershell
# Create a resource group
$resourceGroup = New-AzResourceGroup -Name "rg-demo-prod" -Location "eastus"

# Deploy Bicep template
$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateFile "main.bicep" `
    -TemplateParameterFile "main.bicepparam"

# Get resources
$resources = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName

# Delete resource
Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
```

---

## Step 7: Deployment Automation Script

### Complete Deployment Example

```powershell
param(
    [string]$Environment = "dev",
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

# Configuration
$config = @{
    dev = @{
        resourceGroup = "rg-dev-apps"
        location = "eastus"
        environment = "development"
    }
    prod = @{
        resourceGroup = "rg-prod-apps"
        location = "eastus"
        environment = "production"
    }
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

try {
    Write-Log "Starting deployment for $Environment v$Version"
    
    # Get environment config
    $envConfig = $config[$Environment]
    if (-not $envConfig) {
        throw "Unknown environment: $Environment"
    }
    
    # Connect to Azure
    Write-Log "Authenticating with Azure..."
    Connect-AzAccount -ErrorAction SilentlyContinue | Out-Null
    
    # Get or create resource group
    Write-Log "Setting up resource group: $($envConfig.resourceGroup)"
    $rg = Get-AzResourceGroup -Name $envConfig.resourceGroup -ErrorAction SilentlyContinue
    if (-not $rg) {
        $rg = New-AzResourceGroup -Name $envConfig.resourceGroup -Location $envConfig.location
    }
    
    # Deploy infrastructure
    Write-Log "Deploying Bicep template..."
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $rg.ResourceGroupName `
        -TemplateFile "bicep/main.bicep" `
        -TemplateParameterFile "bicep/$Environment.bicepparam" `
        -environment $Environment `
        -version $Version
    
    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Log "✓ Deployment successful"
        Write-Log "Outputs: $($deployment.Outputs | ConvertTo-Json)"
    } else {
        throw "Deployment failed: $($deployment.ProvisioningState)"
    }
    
} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

Write-Log "Deployment complete"
```

**Run it:**
```powershell
.\Deploy.ps1 -Environment prod -Version 2.1.0
```

---

## Step 8: Monitoring & Health Checks

### Health Check Script

```powershell
function Test-ServiceHealth {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceUrl,
        
        [int]$MaxRetries = 5,
        [int]$DelaySeconds = 10
    )
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri "$ServiceUrl/health" -TimeoutSec 10
            if ($response.status -eq "healthy") {
                Write-Host "✓ $ServiceUrl is healthy"
                return $true
            }
        } catch {
            Write-Warning "Health check failed (attempt $attempt/$MaxRetries): $_"
            if ($attempt -lt $MaxRetries) {
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }
    
    Write-Error "Service $ServiceUrl failed health checks"
    return $false
}

# Usage
if (Test-ServiceHealth -ServiceUrl "https://api.example.com") {
    Write-Host "Ready to proceed with deployment"
} else {
    exit 1
}
```

---

## Step 9: Scheduled Tasks & Automation

### Running Scripts on Schedule

```powershell
# Create scheduled task
$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-File C:\Scripts\backup-resources.ps1"
$principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "DailyBackup" `
    -Trigger $trigger `
    -Action $action `
    -Principal $principal `
    -Description "Daily Azure resource backup"
```

---

## Step 10: Advanced - Pipeline Integration

### Using PowerShell in Azure Pipelines

```yaml
# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

stages:
- stage: Deploy
  jobs:
  - job: DeployWithPowerShell
    steps:
    - checkout: self
    
    - task: AzurePowerShell@5
      inputs:
        azureSubscription: 'Azure-Connection'
        ScriptType: 'FilePath'
        ScriptPath: '$(System.DefaultWorkingDirectory)/Deploy.ps1'
        ScriptArguments: '-Environment prod -Version $(Build.BuildNumber)'
        azurePowerShellVersion: 'LatestVersion'
      displayName: 'Run deployment script'
    
    - task: AzurePowerShell@5
      inputs:
        azureSubscription: 'Azure-Connection'
        ScriptType: 'InlineScript'
        Inline: |
          $rg = Get-AzResourceGroup -Name "rg-prod-*"
          Write-Host "Resources deployed: $($rg.Count)"
      displayName: 'Verify deployment'
```

---

## Troubleshooting Tips

| Problem | Solution |
|---------|----------|
| Script won't run | `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned` |
| Module not found | `Install-Module -Name Az` |
| Authentication fails | `Clear-AzContext` then `Connect-AzAccount` |
| Timeout on long operations | Use `-AsJob` for background execution |
| Verbose output needed | Add `-Verbose` to any cmdlet |

---

## Key PowerShell Cmdlets Reference

| Cmdlet | Purpose |
|--------|---------|
| `Get-AzResourceGroup` | List resource groups |
| `New-AzResourceGroup` | Create resource group |
| `Get-AzResource` | List resources |
| `Get-AzWebApp` | Get App Service details |
| `Publish-AzWebapp` | Deploy to App Service |
| `Get-AzStorageAccount` | List storage accounts |
| `New-AzResourceGroupDeployment` | Deploy Bicep/ARM templates |

---

## Practice Exercises

1. **Create a backup script** that exports all resources in a resource group to JSON
2. **Write a scaling script** that scales App Service based on current CPU usage
3. **Build a resource cleanup script** that removes resources older than 30 days
4. **Create a cost analysis script** that calculates monthly spend by resource type

---

## Next Steps

- 🎯 Combine PowerShell with Azure Pipelines for CI/CD
- 🎯 Create reusable modules for your organization
- 🎯 Implement comprehensive logging and monitoring
- 🎯 Study infrastructure-as-code patterns (Bicep + PowerShell)

Good luck! 🚀
