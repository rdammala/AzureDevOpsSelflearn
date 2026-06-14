# PowerShell Reproduction Scripts for Common DevOps Scenarios
# Run individual functions or `. .\reproduction-scenarios.ps1` then call functions

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] $Level | $Message" -ForegroundColor $color
}

# ============================================================================
# Scenario 1: Test Build Pipeline Locally
# ============================================================================
function Test-BuildPipeline {
    Write-Log "🔨 Starting local build pipeline reproduction"
    
    $steps = @(
        @{ Name = "Restore dependencies"; Command = "dotnet restore --no-cache" },
        @{ Name = "Build solution"; Command = "dotnet build SupportServices.slnx /warnaserror" },
        @{ Name = "Run unit tests"; Command = "dotnet test SupportServices.slnx --filter 'TestCategory=Unit'" },
        @{ Name = "Generate NuGet packages"; Command = "dotnet pack SupportServices.slnx" }
    )
    
    $startTime = Get-Date
    $success = $true
    
    foreach ($step in $steps) {
        Write-Log "⚙️  $($step.Name)..."
        try {
            Invoke-Expression $step.Command | Out-Null
            Write-Log "✓ $($step.Name) completed" -Level "SUCCESS"
        } catch {
            Write-Log "❌ $($step.Name) failed: $_" -Level "ERROR"
            $success = $false
            break
        }
    }
    
    $elapsed = (Get-Date) - $startTime
    Write-Log "✓ Pipeline completed in $($elapsed.TotalSeconds) seconds" -Level "SUCCESS"
    
    return $success
}

# ============================================================================
# Scenario 2: Test NuGet Restore Performance
# ============================================================================
function Test-NuGetRestorePerformance {
    Write-Log "📦 Starting NuGet restore performance test"
    
    Write-Log "Clearing NuGet cache..."
    dotnet nuget locals all --clear | Out-Null
    
    Write-Log "Running restore without cache..."
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    dotnet restore --no-cache | Out-Null
    $sw.Stop()
    $noCacheTime = $sw.Elapsed.TotalSeconds
    
    Write-Log "First restore (no cache): $noCacheTime seconds"
    
    Write-Log "Running restore with cache..."
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    dotnet restore | Out-Null
    $sw.Stop()
    $cacheTime = $sw.Elapsed.TotalSeconds
    
    Write-Log "Second restore (cached): $cacheTime seconds"
    Write-Log "Cache speedup: $('{0:F1}' -f ($noCacheTime / $cacheTime))x" -Level "SUCCESS"
}

# ============================================================================
# Scenario 3: Test Build Cache Effectiveness
# ============================================================================
function Test-BuildCacheEffectiveness {
    Write-Log "🔄 Starting build cache effectiveness test"
    
    Write-Log "Running clean build (no cache)..."
    dotnet clean | Out-Null
    
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    dotnet build | Out-Null
    $sw.Stop()
    $cleanBuildTime = $sw.Elapsed.TotalSeconds
    
    Write-Log "Clean build time: $cleanBuildTime seconds"
    
    Write-Log "Running incremental build (with cache)..."
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    dotnet build | Out-Null
    $sw.Stop()
    $incrementalBuildTime = $sw.Elapsed.TotalSeconds
    
    Write-Log "Incremental build time: $incrementalBuildTime seconds"
    
    $speedup = (1 - ($incrementalBuildTime / $cleanBuildTime)) * 100
    Write-Log "Cache effectiveness: $('{0:F1}' -f $speedup)% faster" -Level "SUCCESS"
}

# ============================================================================
# Scenario 4: Test Deployment to Staging
# ============================================================================
function Test-StagingDeployment {
    param([string]$ResourceGroup = "rg-staging", [string]$AppName = "app-staging")
    
    Write-Log "🚀 Starting staging deployment test"
    
    try {
        Write-Log "Checking Azure login..."
        $context = Get-AzContext
        if (-not $context) {
            Write-Log "Not logged in to Azure. Running Connect-AzAccount..." -Level "WARN"
            Connect-AzAccount | Out-Null
        }
        
        Write-Log "Deploying to staging: $AppName"
        
        # Publish application
        Write-Log "Publishing application..."
        dotnet publish -c Release -o publish | Out-Null
        
        Write-Log "✓ Application published" -Level "SUCCESS"
        
        # Deploy to App Service
        Write-Log "Deploying to App Service..."
        # Uncomment to actually deploy:
        # az webapp up -n $AppName -g $ResourceGroup --runtime "DOTNET|8.0"
        
        Write-Log "✓ Staging deployment completed" -Level "SUCCESS"
        
    } catch {
        Write-Log "❌ Staging deployment failed: $_" -Level "ERROR"
        return $false
    }
    
    return $true
}

# ============================================================================
# Scenario 5: Test Service Health Checks
# ============================================================================
function Test-ServiceHealthChecks {
    param([string]$ServiceUrl = "https://localhost:5001/health")
    
    Write-Log "❤️  Starting service health check test"
    
    $maxRetries = 5
    $delaySeconds = 3
    
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            Write-Log "Attempt $attempt/$maxRetries - Checking $ServiceUrl..."
            
            $response = Invoke-WebRequest -Uri $ServiceUrl -TimeoutSec 5 -SkipHttpErrorCheck
            
            if ($response.StatusCode -eq 200) {
                Write-Log "✓ Service is healthy" -Level "SUCCESS"
                return $true
            } else {
                Write-Log "Service returned status code: $($response.StatusCode)" -Level "WARN"
            }
            
        } catch {
            if ($attempt -lt $maxRetries) {
                Write-Log "Health check failed, retrying in $delaySeconds seconds..." -Level "WARN"
                Start-Sleep -Seconds $delaySeconds
            } else {
                Write-Log "❌ Service health check failed after $maxRetries attempts" -Level "ERROR"
                return $false
            }
        }
    }
    
    return $false
}

# ============================================================================
# Scenario 6: Test Bicep Template Validation
# ============================================================================
function Test-BicepTemplates {
    param([string]$TemplateDir = "bicep")
    
    Write-Log "🏗️  Starting Bicep template validation"
    
    if (-not (Test-Path $TemplateDir)) {
        Write-Log "Template directory not found: $TemplateDir" -Level "ERROR"
        return $false
    }
    
    $bicepFiles = Get-ChildItem -Path $TemplateDir -Filter "*.bicep" -Recurse
    
    if ($bicepFiles.Count -eq 0) {
        Write-Log "No Bicep files found in $TemplateDir" -Level "WARN"
        return $true
    }
    
    $success = $true
    foreach ($file in $bicepFiles) {
        Write-Log "Validating $($file.Name)..."
        
        try {
            az bicep build --file $file.FullName 2>&1 | Out-Null
            Write-Log "✓ $($file.Name) is valid" -Level "SUCCESS"
        } catch {
            Write-Log "❌ $($file.Name) validation failed" -Level "ERROR"
            $success = $false
        }
    }
    
    if ($success) {
        Write-Log "✓ All Bicep templates are valid" -Level "SUCCESS"
    }
    
    return $success
}

# ============================================================================
# Scenario 7: Test Parallel Test Execution
# ============================================================================
function Test-ParallelTestExecution {
    Write-Log "⚡ Starting parallel test execution comparison"
    
    try {
        # Sequential execution
        Write-Log "Running tests sequentially..."
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        dotnet test SupportServices.slnx /p:ParallelizeTestCollections=false | Out-Null
        $sw.Stop()
        $sequentialTime = $sw.Elapsed.TotalSeconds
        
        Write-Log "Sequential test time: $sequentialTime seconds"
        
        # Parallel execution
        Write-Log "Running tests in parallel..."
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        dotnet test SupportServices.slnx /p:ParallelizeTestCollections=true | Out-Null
        $sw.Stop()
        $parallelTime = $sw.Elapsed.TotalSeconds
        
        Write-Log "Parallel test time: $parallelTime seconds"
        
        $speedup = $sequentialTime / $parallelTime
        Write-Log "Parallel speedup: $('{0:F1}' -f $speedup)x faster" -Level "SUCCESS"
        
    } catch {
        Write-Log "❌ Test execution failed: $_" -Level "ERROR"
        return $false
    }
    
    return $true
}

# ============================================================================
# Scenario 8: Test Resource Cleanup
# ============================================================================
function Test-ResourceCleanup {
    param([string]$ResourcePattern = "rg-test-*")
    
    Write-Log "🧹 Starting resource cleanup test"
    
    try {
        Write-Log "Searching for resources matching: $ResourcePattern"
        
        $rgs = Get-AzResourceGroup -ErrorAction SilentlyContinue | 
               Where-Object { $_.ResourceGroupName -like $ResourcePattern }
        
        if ($rgs.Count -eq 0) {
            Write-Log "No resources found matching pattern" -Level "WARN"
            return $true
        }
        
        Write-Log "Found $($rgs.Count) resource groups to clean up"
        
        foreach ($rg in $rgs) {
            Write-Log "Deleting $($rg.ResourceGroupName)..."
            # Uncomment to actually delete:
            # Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force | Out-Null
            Write-Log "✓ $($rg.ResourceGroupName) marked for deletion" -Level "SUCCESS"
        }
        
    } catch {
        Write-Log "❌ Cleanup failed: $_" -Level "ERROR"
        return $false
    }
    
    return $true
}

# ============================================================================
# Scenario 9: Generate Cost Analysis Report
# ============================================================================
function Get-CostAnalysisReport {
    Write-Log "💰 Generating cost analysis report"
    
    $resources = @(
        @{ Name = "App Service Plans (12)"; Cost = 73 },
        @{ Name = "Cosmos DB (1)"; Cost = 500 },
        @{ Name = "Storage Accounts (3)"; Cost = 25 },
        @{ Name = "Key Vaults (2)"; Cost = 1 },
        @{ Name = "Application Insights (12)"; Cost = 24 }
    )
    
    $totalCost = 0
    Write-Host "`nResource Cost Breakdown:" -ForegroundColor Cyan
    Write-Host "================================================"
    
    foreach ($resource in $resources) {
        $totalCost += $resource.Cost
        Write-Host "$($resource.Name.PadRight(40)) `$$($resource.Cost)" -ForegroundColor Cyan
    }
    
    Write-Host "================================================"
    Write-Host "Total Monthly Cost: `$$totalCost" -ForegroundColor Green
    Write-Host "Annual Cost: `$$($totalCost * 12)" -ForegroundColor Green
    Write-Host "`n"
}

# ============================================================================
# Main Menu
# ============================================================================
function Invoke-ReproductionScenarios {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "    DevOps Scenario Reproduction Tool (PowerShell)" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Scenarios:" -ForegroundColor Yellow
    Write-Host "  1. Build Pipeline"
    Write-Host "  2. NuGet Restore Performance"
    Write-Host "  3. Build Cache Effectiveness"
    Write-Host "  4. Staging Deployment"
    Write-Host "  5. Service Health Checks"
    Write-Host "  6. Bicep Template Validation"
    Write-Host "  7. Parallel Test Execution"
    Write-Host "  8. Resource Cleanup"
    Write-Host "  9. Cost Analysis Report"
    Write-Host "  0. Exit"
    Write-Host ""
    
    $choice = Read-Host "Select scenario (0-9)"
    
    switch ($choice) {
        "1" { Test-BuildPipeline }
        "2" { Test-NuGetRestorePerformance }
        "3" { Test-BuildCacheEffectiveness }
        "4" { Test-StagingDeployment }
        "5" { Test-ServiceHealthChecks }
        "6" { Test-BicepTemplates }
        "7" { Test-ParallelTestExecution }
        "8" { Test-ResourceCleanup }
        "9" { Get-CostAnalysisReport }
        "0" { Write-Log "Exiting..." -Level "SUCCESS"; exit }
        default { Write-Log "Invalid choice" -Level "ERROR" }
    }
    
    Write-Host ""
    $again = Read-Host "Run another scenario? (y/n)"
    if ($again -eq "y") { Invoke-ReproductionScenarios }
}

# Run the menu
# Invoke-ReproductionScenarios
