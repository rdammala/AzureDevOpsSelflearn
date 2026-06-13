# Infrastructure as Code (IaC) - Bicep Deep Dive
## Interview-Ready & Learning Guide

---

## Quick Summary

**Bicep** is a domain-specific language (DSL) that compiles to ARM templates, providing type safety, reusability, and clean syntax for Azure infrastructure.

---

## 1. Why Bicep Over ARM Templates?

### The Problem with ARM Templates (JSON)

**ARM Template (Raw JSON):**
```json
{
  "type": "Microsoft.Web/serverfarms",
  "apiVersion": "2021-02-01",
  "name": "[concat(variables('appServicePlanName'), '-', parameters('environment'))]",
  "location": "[parameters('location')]",
  "sku": {
    "name": "B1",
    "capacity": 1
  },
  "properties": {
    "reserved": false
  }
}
```

**Issues:**
- 60+ lines for simple resource
- String concatenation nightmare: `concat()`, `replace()`, `split()`
- Weak typing (errors at deploy time)
- Hard to reuse (copy-paste)
- Difficult to review in git diffs
- No validation until deployment

### The Bicep Solution

**Bicep (Clean DSL):**
```bicep
param location string
param environment string
param appServicePlanName string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${appServicePlanName}-${environment}'
  location: location
  sku: {
    name: 'B1'
    capacity: 1
  }
  properties: {
    reserved: false
  }
}
```

**Benefits:**
- ~30 lines for same resource
- Native string interpolation: `${var}`
- Full type safety (errors at compile time)
- Nested modules (reusable)
- Clean diffs in git
- Validation before deployment

### Comparison Table

| Aspect | ARM JSON | Bicep |
|--------|----------|-------|
| **Lines of code** | 200+ | ~80 |
| **Readability** | Poor | Excellent |
| **Type safety** | None | Full |
| **String concat** | concat(), replace() | ${var} |
| **Module reuse** | linkedTemplates (complex) | Modules (simple) |
| **Error detection** | Deploy time | Compile time |
| **Diffs in git** | Hard to read | Easy to read |
| **Learning curve** | Steep | Shallow |
| **IDE support** | Limited | Excellent (VS Code) |

---

## 2. Bicep Architecture

### Core Concepts

```
User writes:     app.bicep
  ↓ (bicep compile)
Generates:       app.json (ARM template)
  ↓ (az deployment)
Azure deploys:   Resources
```

### Module Hierarchy

```
Common Reusable Modules (50+ modules)
├─ WebApp.bicep          # App Service
├─ FunctionApp.bicep     # Function App
├─ KeyVault.bicep        # Secrets store
├─ CosmosDb.bicep        # Data storage
├─ ServiceBus.bicep      # Messaging
└─ ... others

Domain-Specific Files (per domain)
├─ notifications.bicep   # Compose modules
├─ parameters
│  ├─ dev.bicepparam
│  ├─ staging.bicepparam
│  └─ prod.bicepparam
```

---

## 3. Bicep File Structure

### Basic Template

```bicep
// Parameters: inputs from bicepparam files
param location string
param environment string
param instanceCount int = 1

// Variables: computed values
var appServicePlanName = 'plan-notifications-${environment}'
var webAppName = 'app-notifications-${environment}'
var deployProduction = environment == 'prod'

// Conditions: deploy only if true
var deployProd = deployProduction ? 'Premium' : 'Standard'

// Resources: what to create
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: deployProd
    capacity: instanceCount
  }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

// Outputs: return values for other templates
output appServicePlanId string = appServicePlan.id
output webAppId string = webApp.id
```

### Parameters vs Variables

| Aspect | Parameters | Variables |
|--------|-----------|-----------|
| **Source** | `.bicepparam` file | Computed in template |
| **Mutable** | No | No |
| **Use case** | Config that changes per env | Derived values |
| **Example** | `location: 'westus'` | `var name = 'app-${env}'` |

---

## 4. Modules: Reusability

### Why Modules?

```
Without modules: Copy-paste each resource definition
  ↓
Leads to drift: Modules differ between domains
  ↓
Maintenance nightmare: Update one, forget others

With modules: Define once, use everywhere
  ↓
Consistency: All WebApps configured same way
  ↓
Easy maintenance: Update module, all consumers benefit
```

### Creating a Reusable Module

**File: Common/Bicep/WebApp/webapp.bicep**
```bicep
param name string
param location string
param appServicePlanId string
param appSettings object
param httpsOnly bool = true

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: name
  location: location
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: httpsOnly
    siteConfig: {
      appSettings: [for setting in items(appSettings): {
        name: setting.key
        value: setting.value
      }]
    }
  }
}

output id string = webApp.id
output name string = webApp.name
```

### Using a Module

**File: Chat/Deploy/env/chat.bicep**
```bicep
param location string
param environment string

module frontendApp 'Common/Bicep/WebApp/webapp.bicep' = {
  name: 'frontendDeployment'
  params: {
    name: 'app-chat-frontend-${environment}'
    location: location
    appServicePlanId: appServicePlan.id
    appSettings: {
      ASPNETCORE_ENVIRONMENT: environment
      ServiceDomain: 'chat'
    }
  }
}

module backendApp 'Common/Bicep/WebApp/webapp.bicep' = {
  name: 'backendDeployment'
  params: {
    name: 'app-chat-backend-${environment}'
    location: location
    appServicePlanId: appServicePlan.id
    appSettings: {
      ASPNETCORE_ENVIRONMENT: environment
      ServiceDomain: 'chat'
    }
  }
}

output frontendAppId string = frontendApp.outputs.id
output backendAppId string = backendApp.outputs.id
```

### Module Composition Pattern

```
Root template (notifications.bicep)
├─ Module: WebApp (frontend)
│  └─ Uses: Common/WebApp module
├─ Module: FunctionApp (backend)
│  └─ Uses: Common/FunctionApp module
├─ Module: CosmosDb (data)
│  └─ Uses: Common/CosmosDb module
└─ Module: KeyVault (secrets)
   └─ Uses: Common/KeyVault module
```

---

## 5. Two-Level Deployment Model

### Why Two Levels?

```
PROBLEM: Resource cost
- Cosmos DB instance: $500+/month
- Create one per dev, int, prod = $1500+/month
- Wasteful if shared resources same

SOLUTION: Two levels
- envType (subscription-level): Shared resources (Cosmos DB, Key Vault)
  └─ Created once per nonprod, once per prod
- env (resource-group-level): Per-environment resources (App Services)
  └─ Created for each environment (dev, staging, prod)

RESULT:
- Save cost (shared expensive resources)
- Separate concerns (infra vs per-env)
```

### Level 1: envType Deployment (Subscription-level)

```bicep
// File: Notifications/Deploy/envType/notifications-envtype.bicep
param location string

// Shared across all environments in this subscription
resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: 'cosmos-notifications-nonprod'
  location: location
  // Shared Cosmos DB instance for dev + staging
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: 'kv-notifications-nonprod'
  location: location
  // Shared secrets for dev + staging
}

output cosmosDbId string = cosmosDb.id
output keyVaultId string = keyVault.id
```

**Deployment:**
```bash
# Run once per subscription (dev=nonprod, prod=prod)
az deployment sub create \
  --location westus \
  --template-file Notifications/Deploy/envType/notifications-envtype.bicep \
  --parameters name=notifications-nonprod
```

### Level 2: env Deployment (Resource-group-level)

```bicep
// File: Notifications/Deploy/env/notifications.bicep
param location string
param environment string
param cosmosDbId string  # Input from envType level

// Per-environment resources
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: 'plan-notifications-${environment}'
  location: location
  // Different for dev, staging, prod (sizes vary)
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: 'app-notifications-${environment}'
  location: location
  // Per-env: dev has B1, staging has B2, prod has P1V2
}

output appServicePlanId string = appServicePlan.id
```

**Deployment:**
```bash
# Run for each environment (dev, staging, prod)
az deployment group create \
  --resource-group rg-notifications-dev \
  --template-file Notifications/Deploy/env/notifications.bicep \
  --parameters location=westus environment=dev
```

---

## 6. Parameter Files (.bicepparam)

### Inheritance Pattern

**Global Defaults:**
```bicep
// global.bicepparam
param location = 'westus'
param tagsEnvironment = 'nonprod'
param tagsOwner = 'notifications-team'
param instanceCount = 1
```

**envType Overrides:**
```bicep
// envType.nonprod.bicepparam
using global.bicepparam

param environment = 'nonprod'
```

**Per-Environment Overrides:**
```bicep
// dev.bicepparam
using envType.nonprod.bicepparam

param environment = 'dev'
param instanceCount = 1        # Dev: cheap
param sku = 'Standard'          # Dev: shared
```

```bicep
// staging.bicepparam
using envType.nonprod.bicepparam

param environment = 'staging'
param instanceCount = 2         # Staging: moderate
param sku = 'Premium'           # Staging: dedicated
```

```bicep
// prod.bicepparam
using global.bicepparam

param environment = 'prod'
param instanceCount = 5         # Prod: high availability
param sku = 'Premium'           # Prod: dedicated
param backupEnabled = true      # Prod: backup enabled
```

---

## 7. Interview-Ready Answers

### Q: "Why use Bicep instead of ARM templates?"

**Answer:**
```
Bicep is a DSL that compiles to ARM, so you get both benefits:

1. DEVELOPER EXPERIENCE:
   - Clean syntax vs JSON nightmare
   - String interpolation: ${var} vs concat()
   - Modules vs linkedTemplates (way simpler)
   - Type safety (errors at compile time, not deploy time)

2. MAINTAINABILITY:
   - ~30 lines vs ~60 lines for same resource
   - Easy git diffs (not JSON noise)
   - Reusable modules (50+ in Common/)
   - Consistent across all domains

3. COMPLIANCE:
   - Compiles to ARM (Azure understands it)
   - Deployment stacks track changes
   - Full audit trail
   - Version controlled in git

Example: Simple web app is 30 lines Bicep vs 60 lines JSON.
Multiply across 50+ domains × 3 environments = maintenance saving
```

### Q: "Explain the two-level deployment model"

**Answer:**
```
Two levels:

LEVEL 1 - envType (subscription-level):
- Shared expensive resources (Cosmos DB, Key Vault, VNet)
- Created once per subscription (nonprod subscription, prod subscription)
- Dev AND staging share same Cosmos DB instance
- Saves cost ($500/month saved × 2 envs = $1000 savings)

LEVEL 2 - env (resource-group-level):
- Per-environment resources (App Services, Function Apps)
- Created for each environment (dev, staging, prod)
- Dev has B1 SKU (cheap), staging B2, prod P1V2 (expensive)
- Allows right-sizing per environment needs

Why?
- Shared expensive resources reduce cost
- Per-env sizing allows tuning per workload
- Clear separation: shared infra vs per-env config

How to deploy:
1. First: envType.bicep (once per subscription)
2. Then: env.bicep per environment (dev, staging, prod)
```

### Q: "How do you manage configuration across environments?"

**Answer:**
```
Parameter files with inheritance:

global.bicepparam
  ↓ (base defaults)
envType.nonprod.bicepparam
  ↓ (shared nonprod settings)
dev.bicepparam, staging.bicepparam
  ↓ (environment-specific overrides)
prod.bicepparam (separate hierarchy)

Example:
- Base: location = westus
- envType.nonprod: environment = nonprod
- dev.bicepparam: instanceCount = 1, sku = B1 (cheap)
- staging.bicepparam: instanceCount = 2, sku = B2
- prod.bicepparam: instanceCount = 5, sku = P1V2 (expensive)

Result:
- Easy to see what differs per environment
- DRY (Don't Repeat Yourself)
- Parameters drive infrastructure (IaC)
```

---

## 8. Key Commands

```bash
# Validate Bicep syntax (no deploy)
bicep build notifications.bicep
bicep lint notifications.bicep

# Deploy envType (once per subscription)
az deployment sub create \
  --location westus \
  --template-file Notifications/Deploy/envType/notifications-envtype.bicep

# Deploy env (for each environment)
az deployment group create \
  --resource-group rg-notifications-dev \
  --template-file Notifications/Deploy/env/notifications.bicep \
  --parameters dev.bicepparam

# See what will change before deploying
az deployment group create \
  --resource-group rg-notifications-dev \
  --template-file notifications.bicep \
  --what-if
```

---

## 9. Key Takeaways

1. **Bicep is DSL** — Compiles to ARM, best of both
2. **Type safe** — Errors at compile, not deploy
3. **Modules** — Reusable, consistent infrastructure
4. **Two levels** — envType (shared) + env (per-env)
5. **Parameters** — Drive infrastructure via bicepparam files
6. **Version controlled** — All infra in git
7. **Deployment stacks** — Immutable history, instant rollback