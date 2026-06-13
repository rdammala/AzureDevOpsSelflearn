# CI/CD Systems Comparison: OneBranch vs Alternatives
## Interview-Ready & Learning Guide

---

## Quick Summary

**Comparison of CI/CD platforms:** OneBranch (enterprise Microsoft), Terraform (IaC), Jenkins (self-hosted), GitHub Actions (git-native).

---

## 1. OneBranch (CI/CD System) - Microsoft Enterprise Platform

### Characteristics

```
OneBranch = Microsoft's enterprise CI/CD platform
├─ Built into Azure DevOps
├─ Heavily used by Microsoft engineering
├─ Enterprise focus (security, compliance)
├─ Integrates with Azure
└─ Specialized for large teams

Key features:
✅ Native Azure integration
✅ Enterprise security (signed binaries, compliance)
✅ Code signing & trusted sources
✅ Multi-platform support
✅ Large-scale parallelization
✅ Official/NonOfficial tier system
```

### Strengths

```
✅ INTEGRATED with Azure
   - Native service connections
   - App Service deployment built-in
   - Resource Manager templates supported
   - No extra config needed

✅ ENTERPRISE COMPLIANCE
   - Code signing mandatory
   - Audit trails
   - RBAC integrated
   - SOX/PCI compliant

✅ SECURITY FOCUS
   - Signed artifacts
   - Trusted only Microsoft-controlled agents
   - Secret management built-in
   - No unsigned code in production

✅ SCALE
   - Built for large monorepos (100+ projects)
   - Path filtering reduces unnecessary builds
   - Supports complex staged pipelines
   - Optimized for enterprise throughput

✅ INTERNAL TOOL
   - No vendor lock-in to external SaaS
   - Data stays on Microsoft infrastructure
   - Full control over configuration
```

### Limitations

```
❌ LEARNING CURVE
   - Steep for new users
   - Complex concepts (slots, artifacts, etc.)
   - Lots of configuration options

❌ VENDOR LOCK-IN (to Microsoft)
   - Only works with Azure DevOps
   - YAML syntax specific to Azure Pipelines
   - Moving away is difficult

❌ LIMITED COMMUNITY
   - Enterprise-focused (not open source)
   - Smaller community than GitHub Actions
   - Fewer templates/examples

❌ COST AT SCALE
   - Build agents require maintenance
   - Storage for artifacts costs money
   - Licensing for large teams
```

### Real Examples from SupportServices

```
trigger:
  branches:
    include:
      - master
  paths:
    include:
      - Chat/**      # Path filtering

stages:
  - stage: Build
    jobs:
      - job: CompileAndTest
        steps:
          - task: DotNetCoreCLI@2  # Native .NET task
          - task: PublishBuildArtifacts@1
  
  - stage: Deploy
    dependsOn: Build
    jobs:
      - job: DeployToAzure
        steps:
          - task: AzureWebApp@1  # Native Azure task
            inputs:
              azureSubscription: ProductionConnection
```

---

## 2. Terraform (Infrastructure as Code)

### What It Is

```
Terraform = IaC tool for provisioning cloud resources
├─ NOT a CI/CD tool
├─ Manages infrastructure (VMs, databases, networks)
├─ Works with Azure, AWS, Google Cloud
├─ Declarative configuration language (HCL)
└─ State-based provisioning

Relationship to CI/CD:
- CI/CD runs Terraform
- Terraform doesn't run CI/CD
- Terraform is a TOOL within CD pipeline
```

### Terraform vs Bicep

```
TERRAFORM:
├─ Language: HCL (HashiCorp Configuration Language)
├─ Provider: Multi-cloud (Azure, AWS, GCP)
├─ State: External state file (tracks current infrastructure)
├─ Syntax: Declarative but complex
└─ Learning: Steeper (state management, providers)

BICEP:
├─ Language: Domain-specific (simpler than ARM JSON)
├─ Provider: Azure-only
├─ State: Deployment stacks (built into Azure)
├─ Syntax: Similar to JSON but cleaner
└─ Learning: Easier (Azure-focused, less state management)

Why SupportServices chose Bicep:
- Azure-only environment
- Simpler syntax than ARM JSON
- Built-in deployment stacks for history/rollback
- Fewer moving parts (no external state files)
```

### Terraform Workflow

```
terraform init         # Initialize (download providers)
terraform plan         # Preview changes
terraform apply        # Apply changes
terraform destroy      # Destroy infrastructure

In CI/CD:
1. Code commit
2. Build: terraform plan → review
3. Deploy: terraform apply → provisioned
```

### Use Cases

```
✅ USE Terraform if:
   - Multi-cloud environment (AWS + Azure + GCP)
   - Need IaC tool (not CI/CD)
   - Team familiar with HCL
   - Complex infrastructure orchestration

❌ AVOID Terraform if:
   - Azure-only (use Bicep instead)
   - Simpler IaC language preferred
   - State file management burden
   - Team unfamiliar with Terraform
```

---

## 3. Jenkins (Self-Hosted CI/CD)

### Characteristics

```
Jenkins = Open-source, self-hosted CI/CD platform
├─ Runs on your own servers
├─ No SaaS dependency
├─ Highly customizable
├─ Huge plugin ecosystem
└─ Community-driven

Architecture:
├─ Controller: Manages jobs and configuration
├─ Agents: Execute jobs (on VMs, containers, etc.)
├─ Plugins: Extend functionality
└─ Webhooks: Trigger from git push
```

### Jenkins vs OneBranch

```
JENKINS:
├─ Hosting: Self-hosted (your infrastructure)
├─ Cost: Free software, expensive to maintain
├─ Plugins: 2000+ community plugins
├─ Languages: Any language/tool via plugins
├─ Customization: Unlimited
└─ Support: Community-driven

ONEBRANCH:
├─ Hosting: Microsoft-hosted
├─ Cost: Included with Azure DevOps
├─ Plugins: Limited (Azure DevOps tasks)
├─ Languages: .NET, Java, Python, Node, Go, etc.
├─ Customization: Limited to YAML
└─ Support: Microsoft enterprise support

Comparison table:
├─ Setup complexity: Jenkins HIGH, OneBranch MEDIUM
├─ Maintenance burden: Jenkins HIGH, OneBranch LOW
├─ Scalability: Jenkins MEDIUM, OneBranch HIGH
├─ Enterprise support: Jenkins COMMUNITY, OneBranch MICROSOFT
└─ Total cost of ownership: Jenkins HIGH, OneBranch LOW
```

### Jenkins Workflow

```
# Define job in Jenkinsfile
pipeline {
  agent any
  
  stages {
    stage('Build') {
      steps {
        sh 'dotnet build Chat/Chat.slnx'
      }
    }
    stage('Test') {
      steps {
        sh 'dotnet test Chat/Chat.slnx'
      }
    }
    stage('Deploy') {
      steps {
        sh 'az webapp deployment slot swap ...'
      }
    }
  }
}
```

### Use Cases

```
✅ USE Jenkins if:
   - No cloud provider lock-in desired
   - Need on-premises CI/CD
   - Highly customizable workflows required
   - Large plugin ecosystem valued
   - Team already familiar with Jenkins

❌ AVOID Jenkins if:
   - Prefer managed service (no maintenance)
   - Infrastructure team unavailable
   - Prefer cloud-native solution
   - Don't want to manage servers
```

---

## 4. GitHub Actions (Git-Native CI/CD)

### Characteristics

```
GitHub Actions = CI/CD integrated into GitHub
├─ Runs on GitHub infrastructure
├─ Triggered by git events (push, PR, release)
├─ Workflow files in .github/workflows/
├─ Free for public repos, charged for private
└─ Tight git integration

Key concepts:
├─ Workflows: Automation files
├─ Jobs: Steps within workflow
├─ Runners: Execution agents
└─ Actions: Reusable job components
```

### GitHub Actions vs OneBranch

```
GITHUB ACTIONS:
├─ Repository: GitHub only
├─ Triggers: Git events (push, PR, tag)
├─ Configuration: YAML in .github/workflows/
├─ Community: Large (many public actions)
├─ Cost: Free for public, metered for private
└─ Scalability: Good (GitHub-hosted runners)

ONEBRANCH:
├─ Repository: Azure DevOps only
├─ Triggers: Git events + scheduled
├─ Configuration: YAML in root
├─ Community: Smaller (Azure DevOps tasks)
├─ Cost: Included with Azure DevOps
└─ Scalability: Excellent (enterprise-grade)

Use case differences:
├─ GitHub Actions: Perfect for GitHub repositories
├─ OneBranch: Better for Azure DevOps + Enterprise
```

### GitHub Actions Workflow

```yaml
# .github/workflows/build.yml
name: Build and Test

on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - '.github/workflows/build.yml'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: 8.x
      
      - name: Restore dependencies
        run: dotnet restore
      
      - name: Build
        run: dotnet build --no-restore
      
      - name: Test
        run: dotnet test --no-build
      
      - name: Deploy
        run: |
          az webapp deployment slot swap ...
```

### Use Cases

```
✅ USE GitHub Actions if:
   - Repository hosted on GitHub
   - Want git-native CI/CD
   - Prefer free solution for public projects
   - Team comfortable with GitHub workflows

❌ AVOID GitHub Actions if:
   - Using Azure DevOps (use OneBranch instead)
   - Need enterprise compliance features
   - Require on-premises execution
```

---

## 5. Quick Comparison Matrix

```
COMPARISON MATRIX:

                  OneBranch    Jenkins      Terraform    GitHub Actions
────────────────────────────────────────────────────────────────────────
Purpose           CI/CD        CI/CD        IaC          CI/CD
Hosting           Microsoft    Self-hosted  Cloud-agnostic  GitHub
Learning Curve    Medium       High         High         Low
Setup Time        Low          High         High         Very Low
Cost              Medium       Low(+infra)  Free         Low-Free
Enterprise        Excellent    Limited      N/A          Limited
Support
Customization     Medium       High         High         Medium
Community Plugins Low          Very High    High         High
Scalability       Excellent    Medium       Excellent    Good
On-Premises       No           Yes          N/A          No(can use runners)
────────────────────────────────────────────────────────────────────────
```

---

## 6. Migration Scenarios

### OneBranch → GitHub Actions

```
If moving repository from Azure DevOps to GitHub:

1. Rewrite pipelines in GitHub Actions syntax
   OneBranch:  stages → jobs → steps
   GitHub:     jobs → steps

2. Migrate secrets to GitHub Secrets
3. Migrate artifacts to GitHub Releases
4. Update deployment authentication
5. Test thoroughly before migration

Example mapping:
OneBranch trigger → GitHub on event
OneBranch stages → GitHub job matrix
OneBranch task → GitHub action or run command
```

### Jenkins → OneBranch

```
If moving from on-premises Jenkins to Azure DevOps:

1. Port Jenkinsfile to Azure Pipelines YAML
   Jenkins declarative → Azure YAML

2. Migrate secrets to Azure Key Vault
3. Migrate build agents → Microsoft-hosted agents
4. Migrate artifact storage → Azure Artifacts
5. Migrate webhook configuration

Benefits:
- No more server maintenance
- Better Azure integration
- Enterprise support
- Better scaling
```

### Terraform → Bicep

```
If moving from Terraform to Bicep (Azure-only):

1. Convert HCL to Bicep syntax
2. Remove Terraform state management
3. Use Azure deployment stacks for history
4. Migrate to Bicep modules

Bicep advantages:
- Azure-native (better integration)
- Simpler than Terraform HCL
- No external state files
- Deployment stacks built-in
```

---

## 7. Interview-Ready Answers

### Q: "Compare OneBranch, Jenkins, and GitHub Actions"

**Answer:**
```
Three different CI/CD solutions:

ONEBRANCH (Microsoft Enterprise):
- Hosted by Microsoft
- Tightly integrated with Azure
- Enterprise security & compliance
- Best for: Azure DevOps repos, enterprise teams
- Setup: Moderate complexity (learn YAML)

JENKINS (Self-Hosted Open Source):
- Runs on your infrastructure
- Highly customizable with 2000+ plugins
- High maintenance burden
- Best for: On-premises, highly custom workflows
- Setup: Complex (servers, agents, plugins)

GITHUB ACTIONS (Git-Native):
- Built into GitHub
- Free for public repos, metered for private
- Simple YAML workflows
- Best for: GitHub repositories, OSS projects
- Setup: Very easy (YAML in repo)

SupportServices uses OneBranch because:
- Azure DevOps repository
- Enterprise compliance required
- Integrated with Azure infrastructure
- Better scalability for monorepo
- Microsoft support available
```

### Q: "When would you use Terraform vs Bicep?"

**Answer:**
```
TERRAFORM:
- When: Multi-cloud (AWS + Azure + GCP)
- When: Need IaC tool (not CI/CD)
- Pros: Provider-agnostic, large community
- Cons: State file complexity, HCL learning curve

BICEP:
- When: Azure-only infrastructure
- When: Simpler IaC language preferred
- Pros: Azure-native, deployment stacks, simple
- Cons: Azure-only, smaller community

SupportServices uses Bicep because:
- 100% Azure infrastructure
- Don't need multi-cloud
- Simpler than Terraform/ARM JSON
- Native Azure deployment stacks
- Better integration with OneBranch
```

---

## 8. Key Takeaways

1. **OneBranch** = Microsoft enterprise CI/CD (best for Azure DevOps)
2. **Jenkins** = Self-hosted, customizable (maintenance intensive)
3. **GitHub Actions** = Git-native CI/CD (easiest for GitHub repos)
4. **Terraform** = IaC for multi-cloud (not CI/CD itself)
5. **Bicep** = IaC for Azure-only (simpler than Terraform)
6. **Choose platform based on:**
   - Repository location (Azure DevOps → OneBranch)
   - Cloud provider (multi-cloud → Terraform)
   - Maintenance appetite (low → GitHub/OneBranch)
7. **Migration path** exists between all platforms