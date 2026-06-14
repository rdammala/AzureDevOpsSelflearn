# Step-by-Step Guide: Creating Infrastructure with Bicep

**Difficulty: Intermediate** | **Time: 45-60 minutes**

This guide teaches you Bicep Infrastructure as Code from zero to production deployment.

---

## Prerequisites

- [ ] Azure CLI installed (`az --version`)
- [ ] Bicep CLI (`az bicep version`)
- [ ] Azure subscription with permissions
- [ ] Text editor (VS Code recommended)
- [ ] Understanding of Azure resources (App Service, Storage, etc.)

---

## Step 1: Install Bicep

**Windows:**
```powershell
az bicep install
az bicep version
```

**Verify:**
```
Output: Bicep CLI version 0.x.xxx
```

---

## Step 2: Create Your First Bicep File

**Goal:** Create a simple resource (Storage Account)

**Create file: `storage.bicep`**

```bicep
param location string = 'eastus'
param storageAccountName string = 'stg${uniqueString(resourceGroup().id)}'
param storageSku string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageSku
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
```

**Explanation:**
- `param`: Input variables (customizable)
- `resource`: Azure resource being created
- `output`: Values returned after deployment

---

## Step 3: Validate Your Bicep

**Goal:** Check syntax before deploying

**Command:**
```bash
az bicep validate --file storage.bicep
```

**Expected output:**
```
Deployment template validation succeeded.
```

**Build to ARM template (for inspection):**
```bash
az bicep build --file storage.bicep
```

**Output file:** `storage.json` (compiled ARM template, ~300 lines)

---

## Step 4: Deploy to Azure

**Create Resource Group:**
```bash
az group create \
  --name rg-demo \
  --location eastus
```

**Deploy Bicep:**
```bash
az deployment group create \
  --resource-group rg-demo \
  --template-file storage.bicep
```

**Expected output:**
```
{
  "properties": {
    "outputs": {
      "storageAccountId": {
        "value": "/subscriptions/.../storageAccounts/stg12345"
      },
      "storageAccountName": {
        "value": "stg12345"
      }
    },
    "provisioningState": "Succeeded"
  }
}
```

**Verify in Azure:**
```bash
az storage account list --resource-group rg-demo --output table
```

---

## Step 5: Add Parameters File

**Goal:** Externalize configuration for different environments

**Create file: `storage.bicepparam`**

```bicep
using './storage.bicep'

param location = 'eastus'
param storageAccountName = 'stgprod12345'
param storageSku = 'Standard_GRS'  # Geo-redundant for production
```

**Deploy with parameters:**
```bash
az deployment group create \
  --resource-group rg-demo \
  --template-file storage.bicep \
  --parameters storage.bicepparam
```

---

## Step 6: Create Environment-Specific Deployments

**Create multiple parameter files:**

**dev.bicepparam:**
```bicep
using './storage.bicep'

param location = 'eastus'
param storageSku = 'Standard_LRS'  # Cheap for dev
```

**prod.bicepparam:**
```bicep
using './storage.bicep'

param location = 'eastus'
param storageSku = 'Standard_RAGRS'  # Read-access geo-redundant
```

**Deploy:**
```bash
# Dev
az deployment group create \
  --resource-group rg-dev \
  --template-file storage.bicep \
  --parameters dev.bicepparam

# Prod
az deployment group create \
  --resource-group rg-prod \
  --template-file storage.bicep \
  --parameters prod.bicepparam
```

---

## Step 7: Create Reusable Modules

**Goal:** Build reusable components for multiple resources

**Create folder structure:**
```
bicep/
├── modules/
│   ├── storage.bicep
│   ├── appservice.bicep
│   └── keyvault.bicep
├── main.bicep
└── main.bicepparam
```

**Create: `modules/appservice.bicep`**

```bicep
param appServiceName string
param location string = 'eastus'
param appServicePlanSku object = {
  name: 'B1'
  capacity: 1
}
param environmentName string = 'dev'

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${appServiceName}-plan'
  location: location
  sku: appServicePlanSku
  kind: 'windows'
}

resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

resource appSettings 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: appService
  name: 'appsettings'
  properties: {
    ASPNETCORE_ENVIRONMENT: environmentName
  }
}

output appServiceId string = appService.id
output appServiceUri string = 'https://${appService.properties.defaultHostName}'
output appServicePlanId string = appServicePlan.id
```

---

## Step 8: Compose Modules into Main Template

**Create: `main.bicep`**

```bicep
param environment string = 'dev'  // 'dev' or 'prod'
param location string = 'eastus'

// Define SKUs based on environment
var appServiceSku = environment == 'prod' ? {
  name: 'P1V2'
  capacity: 2
} : {
  name: 'B1'
  capacity: 1
}

var storageSku = environment == 'prod' ? 'Standard_RAGRS' : 'Standard_LRS'

// Module 1: Storage
module storage 'modules/storage.bicep' = {
  name: 'storageModule'
  params: {
    location: location
    storageSku: storageSku
  }
}

// Module 2: App Service
module appService 'modules/appservice.bicep' = {
  name: 'appServiceModule'
  params: {
    appServiceName: 'app-${environment}-${uniqueString(resourceGroup().id)}'
    location: location
    appServicePlanSku: appServiceSku
    environmentName: environment
  }
}

// Outputs
output storageAccountId string = storage.outputs.storageAccountId
output appServiceUri string = appService.outputs.appServiceUri
output appServiceId string = appService.outputs.appServiceId
```

**Create: `main.bicepparam`**

```bicep
using './main.bicep'

param environment = 'dev'
param location = 'eastus'
```

---

## Step 9: Deploy from Azure Pipeline

**Create: `azure-pipelines.yml`**

```yaml
trigger:
  paths:
    include:
    - bicep/
    - azure-pipelines.yml

pool:
  vmImage: windows-latest

variables:
  resourceGroup: rg-$(environment)
  deploymentName: deploy-$(Build.BuildId)

stages:
- stage: Validate
  jobs:
  - job: ValidateBicep
    steps:
    - script: |
        az bicep build --file bicep/main.bicep
        Write-Host "Bicep validation passed"
      displayName: Validate Bicep syntax

- stage: DeployDev
  condition: succeeded()
  jobs:
  - deployment: DeployToDev
    displayName: Deploy to Dev
    environment: 'development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureResourceManagerTemplateDeployment@3
            inputs:
              deploymentScope: ResourceGroup
              azureResourceManagerConnection: $(serviceConnection)
              subscriptionId: $(devSubscriptionId)
              location: eastus
              resourceGroupName: $(resourceGroup)
              csmFile: bicep/main.bicep
              csmParametersFile: bicep/main.bicepparam
              overrideParameters: |
                -environment dev
              deploymentName: $(deploymentName)

- stage: DeployProd
  condition: succeeded()
  jobs:
  - deployment: DeployToProd
    displayName: Deploy to Production
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureResourceManagerTemplateDeployment@3
            inputs:
              deploymentScope: ResourceGroup
              azureResourceManagerConnection: $(serviceConnection)
              subscriptionId: $(prodSubscriptionId)
              location: eastus
              resourceGroupName: $(resourceGroup)
              csmFile: bicep/main.bicep
              csmParametersFile: bicep/prod.bicepparam
              overrideParameters: |
                -environment prod
              deploymentName: $(deploymentName)
```

---

## Step 10: Advanced Patterns

### Conditional Resources

```bicep
param deployDatabase bool = false
param location string = 'eastus'

resource sqlServer 'Microsoft.Sql/servers@2019-06-01-preview' = if (deployDatabase) {
  name: 'sqlserver-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    administratorLogin: 'adminuser'
    administratorLoginPassword: '@Passw0rd1234'
  }
}

output databaseId string = deployDatabase ? sqlServer.id : ''
```

### Using Reference to Link Resources

```bicep
param keyVaultName string

resource existingKeyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource appServiceWithKeyVault 'Microsoft.Web/sites@2021-02-01' = {
  name: 'app-with-keyvault'
  location: 'eastus'
  properties: {
    serverFarmId: appServicePlan.id
  }
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  parent: existingKeyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: appServiceWithKeyVault.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}
```

---

## PowerShell Script for Deployment Automation

**Create: `Deploy.ps1`**

```powershell
param(
    [string]$Environment = 'dev',
    [string]$ResourceGroupName,
    [string]$TemplateFile = 'bicep/main.bicep',
    [string]$ParametersFile
)

# Validate inputs
if (-not $ResourceGroupName) {
    $ResourceGroupName = "rg-$Environment"
}

if (-not $ParametersFile) {
    $ParametersFile = "bicep/$Environment.bicepparam"
}

Write-Host "=== Bicep Deployment ===" -ForegroundColor Cyan
Write-Host "Environment: $Environment"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Template: $TemplateFile"
Write-Host "Parameters: $ParametersFile"

# Step 1: Validate Bicep
Write-Host "`nStep 1: Validating Bicep syntax..."
$validateResult = az bicep validate --file $TemplateFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "Bicep validation failed"
    exit 1
}
Write-Host "✓ Validation passed" -ForegroundColor Green

# Step 2: Check if resource group exists
Write-Host "`nStep 2: Checking resource group..."
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq 'false') {
    Write-Host "Creating resource group: $ResourceGroupName..."
    az group create `
        --name $ResourceGroupName `
        --location eastus
}
Write-Host "✓ Resource group exists" -ForegroundColor Green

# Step 3: Deploy
Write-Host "`nStep 3: Deploying Bicep template..."
$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file $TemplateFile `
    --parameters $ParametersFile `
    --output json | ConvertFrom-Json

$provisioningState = $deployment.properties.provisioningState
Write-Host "✓ Deployment: $provisioningState" -ForegroundColor Green

# Step 4: Display outputs
Write-Host "`nDeployment Outputs:"
$outputs = $deployment.properties.outputs
foreach ($output in $outputs.PSObject.Properties) {
    Write-Host "  $($output.Name): $($output.Value.value)"
}

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
```

**Run:**
```bash
./Deploy.ps1 -Environment dev
./Deploy.ps1 -Environment prod
```

---

## Troubleshooting

### Error: "Module not found"
**Solution:** Ensure correct path in `using` statement
```bicep
using './modules/storage.bicep'  # Correct relative path
```

### Error: "Parameter validation failed"
**Solution:** Check parameter types match
```bicep
param storageSku string  // Must be string, not object
```

### Bicep not installed
**Solution:**
```bash
az bicep install
az bicep version
```

### Deployment takes too long
**Solution:** Check resource availability in region
```bash
az provider list --query "[?namespace=='Microsoft.Storage']" --output table
```

---

## Next Steps

1. ✅ Deploy your first Bicep template
2. 📚 Learn Bicep syntax: [docs.microsoft.com/azure/azure-resource-manager/bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep)
3. 🔐 Add Key Vault integration
4. 📊 Add monitoring and logging
5. 🚀 Integrate with Azure DevOps

---

**Estimated Time to Production: 2-4 hours**
