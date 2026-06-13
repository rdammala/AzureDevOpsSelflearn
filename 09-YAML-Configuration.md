# YAML Configuration for CI/CD Pipelines
## Interview-Ready & Learning Guide

---

## Quick Summary

**YAML syntax for defining pipelines:** Triggers, stages, jobs, steps, variables, conditional execution.

---

## 1. YAML Basics

### What is YAML?

```
YAML = Yet Another Markup Language
- Human-readable configuration format
- Uses indentation (NOT tabs, spaces only!)
- Key: value pairs
- Lists with hyphens

YAML Syntax:
key: value                    # String
number: 42                    # Number
boolean: true                 # Boolean
list:                         # List
  - item1
  - item2
nested:                       # Nested object
  child_key: child_value
```

### YAML Rules

```
❌ WRONG (tab indentation):
pipeline:
→   stages:        # TAB = ERROR
    - stage: Build

✅ CORRECT (space indentation):
pipeline:
  stages:          # 2 spaces = correct
    - stage: Build

❌ WRONG (inconsistent):
pipeline:
  stages:
   - stage: Build  # 1 space (was 2 above)

✅ CORRECT (consistent):
pipeline:
  stages:
    - stage: Build # 2 spaces consistently
```

---

## 2. CI/CD Pipeline Structure

### Top-Level Structure

```yaml
# Azure Pipelines YAML syntax

trigger:                      # When to run?
  branches:
    include:
      - master
  paths:
    include:
      - Chat/**

pool:                         # Where to run?
  vmImage: windows-latest

variables:                    # Reusable values
  buildConfiguration: Release
  artifactName: 'build-artifact'

stages:                       # Workflow stages
  - stage: Build
    displayName: Build Code
    jobs:
      - job: CompileAndTest
        steps:
          - step1
          - step2
```

---

## 3. Triggers

### Branch Trigger

```yaml
# Run pipeline when code pushed to master branch
trigger:
  branches:
    include:
      - master         # Include master
      - release/*      # Include release/* branches
    exclude:
      - hotfix/*       # Don't run for hotfix/*
```

### Path Trigger (Path Filtering)

```yaml
# Run only if specific paths changed
trigger:
  branches:
    include:
      - master
  paths:
    include:
      - Chat/**        # Run if Chat folder changed
      - Common/**      # Run if Common folder changed
    exclude:
      - Docs/**        # Don't run if only docs changed
      - '**/*.md'      # Don't run if only markdown changed
```

### Schedule Trigger

```yaml
# Run on a schedule (nightly build)
trigger: none  # Don't run on every commit

schedules:
  - cron: "0 2 * * *"  # 2 AM daily
    displayName: Nightly Build
    branches:
      include:
        - master
    always: false  # Only if changes since last run
```

### Pull Request Trigger

```yaml
# Run tests when PR created (not official pipelines)
pr:
  branches:
    include:
      - master
  paths:
    include:
      - Chat/**
```

---

## 4. Variables

### Variable Types

```yaml
variables:
  # Simple variable
  buildConfiguration: Release
  
  # Templated variable (reference another)
  buildOutputPath: $(Build.ArtifactStagingDirectory)
  
  # Multiline string
  scriptContent: |
    echo "Line 1"
    echo "Line 2"
  
  # Group variables (from Azure DevOps library)
  - group: NotificationsSecrets

# Access variables in steps
steps:
  - script: echo $(buildConfiguration)  # Outputs: Release
```

### Predefined Variables

```yaml
# These are automatically set by pipeline system
$(Build.BuildId)              # Build number
$(Build.SourceBranch)         # master or feature/xyz
$(Build.ArtifactStagingDirectory)  # Where artifacts go
$(Build.SourcesDirectory)     # Where source code is
$(System.DefaultWorkingDirectory)  # Current directory
$(Pipeline.Workspace)        # Workspace directory

# Example:
steps:
  - script: echo "Build: $(Build.BuildId)"
```

---

## 5. Stages

### Stage Definition

```yaml
stages:
  # STAGE 1: Build
  - stage: Build
    displayName: Build Solution   # UI label
    dependsOn: []                 # No dependencies (runs first)
    
    jobs:
      - job: BuildJob
        steps:
          - script: dotnet build Chat/Chat.slnx
  
  # STAGE 2: Test (runs after Build)
  - stage: Test
    displayName: Run Tests
    dependsOn: Build              # Depends on Build stage
    condition: succeeded()         # Only if Build succeeded
    
    jobs:
      - job: TestJob
        steps:
          - script: dotnet test Chat/Chat.slnx
  
  # STAGE 3: Deploy (runs after Test)
  - stage: Deploy
    displayName: Deploy to Dev
    dependsOn: Test               # Depends on Test stage
    condition: succeeded()
    
    jobs:
      - job: DeployJob
        steps:
          - script: echo "Deploy code"
```

---

## 6. Jobs & Steps

### Jobs

```yaml
jobs:
  # JOB 1
  - job: BuildWindows
    displayName: Build on Windows
    pool:
      vmImage: windows-latest
    
    steps:
      - script: dotnet build

  # JOB 2 (runs in parallel with Job 1)
  - job: BuildLinux
    displayName: Build on Linux
    pool:
      vmImage: ubuntu-latest
    
    steps:
      - script: dotnet build
```

### Steps

```yaml
steps:
  # Step 1: Script
  - script: dotnet build
    displayName: Build Solution
  
  # Step 2: PowerShell
  - powershell: |
      Write-Host "Running PowerShell"
      $result = 1 + 1
  
  # Step 3: Bash
  - bash: |
      echo "Running Bash"
      echo $(Build.BuildId)
  
  # Step 4: Task (built-in action)
  - task: PublishBuildArtifacts@1
    inputs:
      artifactName: drop
  
  # Step 5: Download artifact
  - task: DownloadBuildArtifacts@0
    inputs:
      artifactName: drop
```

---

## 7. Conditions & Strategy

### Conditional Execution

```yaml
steps:
  # Always run
  - script: echo "Always"
    condition: always()
  
  # Only if previous step succeeded
  - script: echo "Only on success"
    condition: succeeded()
  
  # Only if previous step failed
  - script: echo "Only on failure"
    condition: failed()
  
  # Only on specific branch
  - script: echo "Prod deploy"
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/master')
  
  # Complex condition
  - script: echo "Complex"
    condition: and(succeeded(), eq(variables['buildConfiguration'], 'Release'))
```

### Strategy: Matrix Builds

```yaml
jobs:
  - job: TestMatrix
    displayName: Test Multiple Configurations
    
    strategy:
      matrix:
        Windows_Release:
          vmImage: windows-latest
          configuration: Release
        Linux_Debug:
          vmImage: ubuntu-latest
          configuration: Debug
    
    pool:
      vmImage: $(vmImage)
    
    steps:
      - script: dotnet build --configuration $(configuration)
```

---

## 8. Real-World Pipeline Examples

### Build Pipeline YAML

```yaml
trigger:
  branches:
    include:
      - master
  paths:
    include:
      - Chat/**
      - Common/**

pool:
  vmImage: windows-latest

variables:
  buildConfiguration: Release
  artifactName: Chat-Build

stages:
  - stage: Build
    displayName: Build Chat Solution
    
    jobs:
      - job: CompileAndTest
        displayName: Compile & Test
        
        steps:
          # Step 1: Restore dependencies
          - task: DotNetCoreCLI@2
            displayName: Restore NuGet packages
            inputs:
              command: restore
              projects: Chat/Chat.slnx
          
          # Step 2: Build with warnings-as-errors
          - task: DotNetCoreCLI@2
            displayName: Build solution
            inputs:
              command: build
              projects: Chat/Chat.slnx
              arguments: '/p:TreatWarningsAsErrors=true'
          
          # Step 3: Run unit tests
          - task: DotNetCoreCLI@2
            displayName: Run unit tests
            inputs:
              command: test
              projects: Chat/Chat.slnx
              arguments: '--filter "TestCategory=Unit"'
          
          # Step 4: Run integration tests
          - task: DotNetCoreCLI@2
            displayName: Run integration tests
            inputs:
              command: test
              projects: Chat/Chat.slnx
              arguments: '--filter "TestCategory=Integration"'
          
          # Step 5: Publish artifact
          - task: DotNetCoreCLI@2
            displayName: Publish artifact
            inputs:
              command: publish
              projects: Chat/Frontend/Frontend.csproj
              arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'
          
          # Step 6: Publish build artifacts
          - task: PublishBuildArtifacts@1
            displayName: Upload artifact
            inputs:
              PathtoPublish: $(Build.ArtifactStagingDirectory)
              ArtifactName: $(artifactName)
```

### Deploy Pipeline YAML

```yaml
trigger: none  # Manual trigger only

pool:
  vmImage: windows-latest

variables:
  environment: dev
  resourceGroup: rg-chat-dev

stages:
  - stage: DeployInfrastructure
    displayName: Deploy Infrastructure
    
    jobs:
      - job: BicepDeploy
        displayName: Bicep Deployment
        
        steps:
          # Download artifact from build
          - task: DownloadBuildArtifacts@0
            displayName: Download build artifact
            inputs:
              artifactName: Chat-Build
          
          # Deploy bicep template
          - task: AzureResourceManagerTemplateDeployment@3
            displayName: Deploy Bicep template
            inputs:
              deploymentScope: ResourceGroup
              azureResourceManagerConnection: ProductionServiceConnection
              subscriptionId: $(subscriptionId)
              action: Create Or Update Resource Group
              resourceGroupName: $(resourceGroup)
              location: westus2
              templateLocation: Linked artifact
              csmFile: Chat/Deploy/env/chat.bicep
              csmParametersFile: Chat/Deploy/env/chat.dev.bicepparam
              overrideParameters: -environment $(environment)
  
  - stage: DeployCode
    displayName: Deploy Code to App Service
    dependsOn: DeployInfrastructure
    
    jobs:
      - job: SlotSwap
        displayName: Deploy to Staging & Swap
        
        steps:
          # Deploy to staging slot
          - task: AzureWebApp@1
            displayName: Deploy to staging slot
            inputs:
              azureSubscription: ProductionServiceConnection
              appType: webAppWindows
              appName: app-chat-frontend-dev
              deployToSlotOrASE: true
              resourceGroupName: $(resourceGroup)
              slotName: staging
              package: $(Pipeline.Workspace)/**/Chat.Frontend.zip
          
          # Run functional tests on staging
          - task: DotNetCoreCLI@2
            displayName: Run functional tests
            inputs:
              command: test
              projects: Chat/Frontend.Functional.Tests/Frontend.Functional.Tests.csproj
              arguments: '--filter "TestCategory=Functional"'
          
          # Swap slots (production ← staging)
          - task: AzureAppServiceManage@0
            displayName: Swap slots
            inputs:
              azureSubscription: ProductionServiceConnection
              action: Swap Slots
              appName: app-chat-frontend-dev
              resourceGroupName: $(resourceGroup)
              sourceSlot: staging
```

---

## 9. Interview-Ready Answers

### Q: "Explain YAML syntax for pipelines"

**Answer:**
```
YAML basics:
- Indentation-based (2-4 spaces, NOT tabs)
- key: value pairs
- Lists with hyphens (-)

Pipeline structure:
1. Trigger: When to run
   - Branch trigger (master, PR)
   - Path filtering (only if specific folder changed)
   - Schedule (nightly builds)

2. Variables: Reusable values
   - Simple strings
   - Predefined (Build.BuildId, etc.)
   - Groups (secrets from Azure)

3. Stages: Major phases
   - Build
   - Test
   - Deploy
   - Parallel or sequential

4. Jobs: Work within stages
   - Can run in parallel
   - Can run on different agents

5. Steps: Individual actions
   - Script, PowerShell, Bash
   - Tasks (built-in actions)
   - Conditions (if/when)

Example:
trigger:
  - master

stages:
  - stage: Build
    jobs:
      - job: Compile
        steps:
          - script: dotnet build --configuration Release
          - task: PublishBuildArtifacts
```

---

## 10. Key Takeaways

1. **Indentation matters** — 2 spaces, not tabs
2. **Trigger defines when** — Branch, path, schedule
3. **Variables for reuse** — Avoid hardcoding
4. **Stages sequence work** — Build → Test → Deploy
5. **Jobs can parallelize** — Multiple tests at once
6. **Steps execute in order** — Script, task, script...
7. **Conditions add logic** — If/when to run step
8. **Matrix builds** — Test multiple configurations