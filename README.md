# Azure DevOps Self-Learning Library

> 🌐 **[Live Documentation Site](https://rdammala.github.io/AzureDevOpsSelflearn/docs/)** — Click to view interactive HTML pages!

**Complete guide to DevOps architecture, CI/CD pipelines, Infrastructure as Code, and cloud operations.**

## 📍 Where to Find Everything

| What | Where | Purpose |
|------|-------|---------|
| **START HERE** | [READY-TO-USE.md](READY-TO-USE.md) | Visual overview, next steps |
| **5-min setup** | [QUICK-START.md](QUICK-START.md) | Step-by-step instructions |
| **Technical details** | [GENERATE-AUDIO-VIDEO.md](GENERATE-AUDIO-VIDEO.md) | Full documentation |
| **Run this script** | [Run-AudioVideo-Generation.ps1](Run-AudioVideo-Generation.ps1) | Master automation |
| **Learning guide** | [README.md](README.md) | Navigate all documents |

---

## 📚 Document Overview

This folder contains **11 comprehensive guides** covering all aspects of DevOps from code commit to production deployment. Each document is **interview-ready** with real examples, code snippets, visuals, and practical Q&A.

### Quick Navigation

#### Core DevOps Concepts
- **[01-Git-Workflow-Branching.md](01-Git-Workflow-Branching.md)** — Branch strategy, PR process, commit conventions
- **[07-DevOps-Concepts.md](07-DevOps-Concepts.md)** — 10 fundamental DevOps principles (IaC, CI/CD, monitoring, etc.)

#### Pipeline & Build System
- **[02-CI-CD-Pipelines.md](02-CI-CD-Pipelines.md)** — Two-tier pipeline architecture (NonOfficial vs Official)
- **[09-YAML-Configuration.md](09-YAML-Configuration.md)** — YAML syntax for CI/CD pipelines

#### Infrastructure & Deployment
- **[03-Infrastructure-as-Code-Bicep.md](03-Infrastructure-as-Code-Bicep.md)** — Bicep templates, why not ARM, two-level deployment
- **[05-Blue-Green-Deployment.md](05-Blue-Green-Deployment.md)** — Zero-downtime deployments, slot swaps, instant rollback

#### Quality & Reliability
- **[04-Testing-Strategy.md](04-Testing-Strategy.md)** — Four-tier testing pyramid (unit, integration, functional, prod)
- **[06-Troubleshooting-Recovery.md](06-Troubleshooting-Recovery.md)** — Failure scenarios, debugging, recovery procedures

#### Operational Excellence
- **[08-Cost-Optimization.md](08-Cost-Optimization.md)** — Right-sizing, resource sharing, reserved instances
- **[10-OneBranch-vs-Other-Tools.md](10-OneBranch-vs-Other-Tools.md)** — CI/CD platforms (Jenkins, GitHub Actions, Terraform)
- **[11-Containers-Orchestration.md](11-Containers-Orchestration.md)** — Kubernetes, Docker, Ansible, when to use each

#### Reference
- **[00-DevOps-Architecture-Complete.md](00-DevOps-Architecture-Complete.md)** — Master guide with full architecture walkthrough (2,245 lines)

---

## 🎯 Learning Paths

### For Beginners (New to DevOps)

Start with foundational concepts:
1. [07-DevOps-Concepts.md](07-DevOps-Concepts.md) — Understand "what is DevOps"
2. [01-Git-Workflow-Branching.md](01-Git-Workflow-Branching.md) — Learn how developers work with code
3. [02-CI-CD-Pipelines.md](02-CI-CD-Pipelines.md) — See how code flows to production
4. [04-Testing-Strategy.md](04-Testing-Strategy.md) — Understand quality gates

**Time: 2-3 hours**

### For Developers (Building Features)

Understand CI/CD from developer perspective:
1. [01-Git-Workflow-Branching.md](01-Git-Workflow-Branching.md) — Your daily workflow
2. [02-CI-CD-Pipelines.md](02-CI-CD-Pipelines.md) — How code gets to prod
3. [04-Testing-Strategy.md](04-Testing-Strategy.md) — Test requirements
4. [06-Troubleshooting-Recovery.md](06-Troubleshooting-Recovery.md) — When things go wrong

**Time: 2-3 hours**

### For DevOps Engineers (Operators)

Complete operational mastery:
1. [07-DevOps-Concepts.md](07-DevOps-Concepts.md) — Foundational concepts
2. [02-CI-CD-Pipelines.md](02-CI-CD-Pipelines.md) — Pipeline architecture
3. [03-Infrastructure-as-Code-Bicep.md](03-Infrastructure-as-Code-Bicep.md) — IaC deep dive
4. [05-Blue-Green-Deployment.md](05-Blue-Green-Deployment.md) — Deployment strategies
5. [08-Cost-Optimization.md](08-Cost-Optimization.md) — Cost management
6. [06-Troubleshooting-Recovery.md](06-Troubleshooting-Recovery.md) — Incident response
7. [00-DevOps-Architecture-Complete.md](00-DevOps-Architecture-Complete.md) — Master reference

**Time: 6-8 hours**

### For Interview Preparation

Get interview-ready answers:
- **All 11 documents** contain "Interview-Ready Answers" sections
- Each document covers 5-10 common interview questions with complete answers
- Topics span architecture, pipeline design, deployment strategies, cost optimization

**Focus areas:**
- [07-DevOps-Concepts.md](07-DevOps-Concepts.md) — "What is DevOps?" fundamentals
- [02-CI-CD-Pipelines.md](02-CI-CD-Pipelines.md) — Pipeline architecture design
- [03-Infrastructure-as-Code-Bicep.md](03-Infrastructure-as-Code-Bicep.md) — IaC strategies
- [05-Blue-Green-Deployment.md](05-Blue-Green-Deployment.md) — Zero-downtime deployments
- [10-OneBranch-vs-Other-Tools.md](10-OneBranch-vs-Other-Tools.md) — Tool comparisons

**Time: 4-5 hours**

---

## 📖 Document Details

### 01-Git-Workflow-Branching.md
**Topics:** Branch naming, PR workflow, commit conventions, review process, merge strategies
**Duration:** 30 min read + 30 min practice
**Interview Q&A:** 4 common questions about branching strategy, PR policies, merge conflicts
**Key Takeaway:** Single master branch, feature branches via PR, squash merge strategy

### 02-CI-CD-Pipelines.md
**Topics:** Two-tier pipelines, build stages, deploy stages, NonOfficial vs Official, timing
**Duration:** 45 min read
**Interview Q&A:** 5 questions about pipeline architecture, trigger strategies, artifact handling
**Key Takeaway:** Automated CI on every master push, manual production trigger, path filtering

### 03-Infrastructure-as-Code-Bicep.md
**Topics:** Bicep vs ARM, modules, two-level deployment, parameter inheritance, deployment stacks
**Duration:** 45 min read
**Interview Q&A:** 4 questions about IaC benefits, Bicep advantages, parameter strategies
**Key Takeaway:** Bicep is superior to ARM (simpler, type-safe), two-level saves 30-40% cost

### 04-Testing-Strategy.md
**Topics:** Test pyramid, unit tests, integration tests, functional tests, test execution in CI/CD
**Duration:** 40 min read
**Interview Q&A:** 4 questions about testing strategy, when tests run, blocking criteria
**Key Takeaway:** Multiple test levels provide defense in depth, functional tests block deployment

### 05-Blue-Green-Deployment.md
**Topics:** Slot-based deployment, zero downtime, instant rollback, slot configuration, limitations
**Duration:** 40 min read
**Interview Q&A:** 3 questions about zero-downtime strategies, rollback procedures, slot management
**Key Takeaway:** Staging → Production swap is instant, old version always 1 swap away

### 06-Troubleshooting-Recovery.md
**Topics:** Build failures, deploy failures, test failures, production recovery, manual commands
**Duration:** 45 min read
**Interview Q&A:** 3 questions about failure modes, debugging, recovery strategies
**Key Takeaway:** Systematic debugging, multiple gates catch issues, instant rollback if needed

### 07-DevOps-Concepts.md
**Topics:** 10 fundamental concepts (automation, IaC, CI/CD, testing, monitoring, MTTR, lead time)
**Duration:** 50 min read
**Interview Q&A:** 5 key questions about DevOps definition, monitoring importance
**Key Takeaway:** DevOps = culture + automation + measurement + rapid feedback

### 08-Cost-Optimization.md
**Topics:** Right-sizing, resource sharing, auto-scaling, reserved instances, monitoring costs
**Duration:** 40 min read
**Interview Q&A:** 2 questions about cost optimization strategies
**Key Takeaway:** Two-level deployment saves 30-40%, right-sizing saves 10-30%

### 09-YAML-Configuration.md
**Topics:** YAML syntax, triggers, variables, stages, jobs, steps, conditions, real examples
**Duration:** 45 min read
**Interview Q&A:** 1 question explaining YAML structure
**Key Takeaway:** YAML basics → triggers → stages → jobs → steps, indentation matters

### 10-OneBranch-vs-Other-Tools.md
**Topics:** OneBranch, Jenkins, GitHub Actions, Terraform, comparison matrix, migration paths
**Duration:** 45 min read
**Interview Q&A:** 2 questions about tool comparisons and when to use each
**Key Takeaway:** Choose based on cloud provider, team size, complexity, maintenance appetite

### 11-Containers-Orchestration.md
**Topics:** Docker, Kubernetes, Docker Swarm, Ansible, App Service vs alternatives, trade-offs
**Duration:** 45 min read
**Interview Q&A:** 2 questions about containers and orchestration decisions
**Key Takeaway:** Containers for portability, Kubernetes for scale, App Service for simplicity

### 00-DevOps-Architecture-Complete.md
**Topics:** Complete architecture walkthrough, real YAML examples, troubleshooting guide, glossary (2,245 lines)
**Duration:** 90 min read (reference document)
**Interview Q&A:** 9 complete answers covering all major topics
**Key Takeaway:** Master reference for all architecture details

---

## 🔑 Key Takeaways Summary

### DevOps Philosophy
- **Automation first** — manual = error-prone
- **Fail fast** — detect issues early, recover quickly
- **Measure everything** — data-driven improvement
- **Collaborate** — blameless post-mortems, shared ownership

### Architecture
- **Single master branch** — all changes via PR
- **Two-tier pipelines** — NonOfficial (auto, nonprod) + Official (manual, prod)
- **Path filtering** — only rebuild affected domains
- **Three environments** — dev → staging → prod progression

### Deployment
- **Slot-based blue-green** — zero downtime, instant rollback
- **Bicep over ARM** — type-safe, cleaner, better modules
- **Two-level Bicep** — shared resources (envType) + per-env config (env)
- **Functional test gates** — tests block swap if they fail

### Quality
- **Multiple test levels** — unit → integration → functional → production
- **Warnings-as-errors** — catch quality issues early
- **Central package management** — consistent versions
- **Convention enforcement** — via PR reviews

### Operations
- **Monitoring from day one** — App Insights, custom metrics, alerts
- **Service connections per env** — RBAC isolation
- **Secrets in Key Vault** — never in code, managed identity access
- **Instant rollback** — production issues recovered in seconds

---

## 💡 How to Use These Documents

### Reading Strategy
1. **Quick overview** — Start with "Quick Summary" section (~1 min)
2. **Concepts** — Read core concept sections with diagrams (~20 min)
3. **Real examples** — Study code examples and configurations (~15 min)
4. **Interview prep** — Read Q&A sections (~10 min)
5. **Key takeaways** — Review bullet points at end (~2 min)

### Practice Approach
- Read about a topic
- Review real configuration files
- Try hands-on in your environment
- Practice explaining to a peer
- Answer interview questions out loud

### Interview Preparation
1. Read all 11 documents (order from quick to deep)
2. Focus on "Interview-Ready Answers" sections
3. Practice articulating answers without reading
4. Use diagrams to explain concepts visually
5. Have real examples ready (from your work)

---

## 🔍 Finding Specific Topics

### By Technology
- **Git:** [01-Git-Workflow-Branching.md](01-Git-Workflow-Branching.md)
- **Pipelines (CI/CD System):** [02-CI-CD-Pipelines.md](02-CI-CD-Pipelines.md), [09-YAML-Configuration.md](09-YAML-Configuration.md)
- **Bicep (IaC):** [03-Infrastructure-as-Code-Bicep.md](03-Infrastructure-as-Code-Bicep.md)
- **Testing:** [04-Testing-Strategy.md](04-Testing-Strategy.md)
- **Deployment:** [05-Blue-Green-Deployment.md](05-Blue-Green-Deployment.md)
- **Troubleshooting:** [06-Troubleshooting-Recovery.md](06-Troubleshooting-Recovery.md)
- **Containers:** [11-Containers-Orchestration.md](11-Containers-Orchestration.md)
- **Cost:** [08-Cost-Optimization.md](08-Cost-Optimization.md)

### By Role
- **Developer:** 01, 02, 04, 06, 07
- **DevOps Engineer:** 02, 03, 05, 06, 07, 08, 09
- **Architect:** 03, 05, 07, 08, 10, 11
- **Operations:** 05, 06, 08, 11
- **Interviewer:** All documents (each has Q&A section)

### By Topic
- **Architecture:** 02, 03, 05, 07, 10, 11, 00
- **Code Quality:** 01, 04, 07
- **Reliability:** 05, 06, 07
- **Cost:** 08, 11
- **Tools:** 09, 10, 11
- **Monitoring:** 06, 07, 08

---

## 📊 Learning Time Estimates

| Audience | Path | Time |
|----------|------|------|
| **Beginner** | 07 → 01 → 02 → 04 | 2-3 hours |
| **Developer** | 01 → 02 → 04 → 06 | 2-3 hours |
| **DevOps** | All (full library) | 6-8 hours |
| **Architect** | 02, 03, 05, 07, 08, 10 | 4-5 hours |
| **Interview Prep** | All (focus Q&A) | 4-5 hours |

---

## ✅ Compliance & Sanitization

All documents have been **sanitized for compliance**:
- ✅ No Microsoft-specific terminology (Microsoft → Company)
- ✅ No Xbox branding (Xbox → Company)
- ✅ No internal environment names (pmedev/pmeint/pmeprod → dev/staging/prod)
- ✅ No internal service names (OneBranch → CI/CD System)
- ✅ Generic cloud terminology (applicable to any organization)
- ✅ Focus on concepts and practices (transferable knowledge)

---

## 📝 Notes for Further Learning

### Topics to Explore Deeper
- **Kubernetes orchestration** at scale (beyond basics in 11)
- **Multi-cloud strategies** (Terraform, cloud-agnostic patterns)
- **GitOps** (declarative infrastructure, automated reconciliation)
- **Observability at scale** (distributed tracing, log aggregation)
- **Security in CI/CD** (secrets rotation, SBOM, compliance automation)

### Related Resources
- Azure Bicep documentation: https://learn.microsoft.com/azure/azure-resource-manager/bicep/
- CI/CD System documentation: Internal organizational resources
- DevOps best practices: The Phoenix Project, Accelerate (research papers)
- Cloud architecture: Well-Architected Framework

---

## 🎓 Document Versioning

These documents reflect current best practices as of 2026:
- **Version:** 1.0 (Initial comprehensive library)
- **Target audience:** Intermediate to advanced practitioners
- **Maintenance:** Update when major architectural changes occur

---

## 💬 Questions or Feedback?

Each document contains:
- ✅ Interview-Ready Q&A sections
- ✅ Key Takeaways bullets
- ✅ Real code examples
- ✅ Troubleshooting guides
- ✅ Comparison matrices

**Use these to check your understanding and prepare for discussions.**

---

## 📋 Quick Reference Checklist

- [ ] Read "Quick Summary" in relevant document
- [ ] Study diagrams and visual explanations
- [ ] Review code examples with annotations
- [ ] Answer "Interview-Ready Questions" aloud
- [ ] Explain concept to a peer
- [ ] Apply knowledge in your work
- [ ] Document what you learned

---

**Happy learning! These documents are designed to be both **comprehensive reference** and **interview preparation** guides. Start with your learning path above and work through documents at your own pace.**