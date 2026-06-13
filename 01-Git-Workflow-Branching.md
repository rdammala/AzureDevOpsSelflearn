# Git Workflow & Branching Strategy
## Interview-Ready & Learning Guide

---

## Quick Summary

**Single master branch model** with feature branches, PR-based code review, and automated CI/CD on merge.

---

## 1. Core Concepts

### The Big Picture
```
Feature Branch → Pull Request → Code Review → Merge to master → Auto CI/CD Triggers
     ↓              ↓               ↓               ↓                    ↓
   Local         Remote        Human Review    Protected        Automated Deploy
```

### Key Principle
- **master is the source of truth** — all production deployments come from commits on master
- **No direct pushes to master** — all changes via Pull Requests (PRs)
- **Linear git history** — squash merge keeps history clean

---

## 2. Branch Organization

### Branching Model: Single Master

```
master (protected branch)
  ↑
  └─ Feature Branches (developers' work)
     ├─ fix/chat-spam-filter
     ├─ feature/notifications-ui
     ├─ refactor/search-indexing
     ├─ hotfix/urgent-auth-bug
     ├─ chore/update-dependencies
     ├─ docs/api-documentation
     └─ test/load-testing
```

### Branch Naming Conventions

**Format:** `<type>/<description>`

| Type | Use Case | Example |
|------|----------|---------|
| `fix/` | Bug fixes | `fix/null-reference-exception` |
| `feature/` | New features | `feature/user-authentication` |
| `refactor/` | Code refactoring | `refactor/optimize-queries` |
| `hotfix/` | Critical production issues | `hotfix/payment-processing-down` |
| `chore/` | Maintenance tasks | `chore/update-nuget-packages` |
| `docs/` | Documentation | `docs/api-endpoints` |
| `test/` | Testing | `test/performance-benchmark` |

**Rules:**
- Use lowercase
- Use hyphens, not underscores
- Descriptive but concise (30 chars max)
- No spaces or special characters

---

## 3. Git Workflow Step-by-Step

### Step 1: Create Feature Branch

```bash
# Update master locally
git checkout master
git pull origin master

# Create feature branch
git checkout -b fix/chat-message-encoding

# Branch created locally only
# Nothing pushed yet
```

### Step 2: Make Changes & Commit

```bash
# Edit files
<make your code changes>

# Stage changes
git add .

# Commit with semantic message
git commit -m "[Chat] fix: Handle UTF-8 message encoding in API response"

# Message format: [DOMAIN] type: description
# Example: [Chat] fix: ..., [Search] feature: ..., [Refunds] refactor: ...
```

**Commit Message Convention:**
```
[DOMAIN] type: description

Details here if needed (optional).

- Bullet point 1
- Bullet point 2
```

### Step 3: Push to Remote

```bash
# Push feature branch
git push origin fix/chat-message-encoding

# Output:
# remote: Create a pull request for 'fix/chat-message-encoding' on GitHub by visiting:
# remote:      https://dev.azure.com/organization/SupportServices/_git/...
```

### Step 4: Open Pull Request

**Via Azure DevOps UI:**
1. Go to repository
2. Click "Pull Requests"
3. Click "New Pull Request"
4. Select `fix/chat-message-encoding` → `master`
5. Fill in title & description
6. Add reviewers (auto-assigned via `owners.txt`)
7. Click "Create"

**PR Title Format:**
```
[Chat] Fix: Properly encode UTF-8 characters in message responses
```

**PR Description Template:**
```markdown
## Description
Brief explanation of what changed and why.

## Changes
- Fixed UTF-8 encoding in Chat API
- Added test case for non-ASCII characters
- Updated documentation

## Related Issues
Closes #1234

## Testing
How to test locally:
1. Send message with emoji
2. Verify response is readable in UI
```

### Step 5: Automated Checks

**PR Status Checks Trigger:**
```
✅ Build.NonOfficial.Chat started
  ├─ Restore NuGet packages
  ├─ Compile code (warnings-as-errors)
  ├─ Run unit tests
  ├─ Run integration tests
  ├─ Code formatting check
  └─ Style/lint rules
```

**If build fails:**
```
❌ Build failed: 3 compilation errors
- Fix locally
- git commit -am "Fix: address build errors"
- git push origin fix/chat-message-encoding
- Build auto-retriggers
```

**If build passes:**
```
✅ All checks passed
- PR status shows green checkmark
- Reviewers can now approve
```

### Step 6: Code Review

**Reviewers:**
- Determined by `owners.txt` file
- Typically 1-2 people familiar with the domain
- Review for:
  - Logic correctness
  - Convention compliance
  - Security issues
  - Performance implications
  - Test coverage

**Review Actions:**
```
Comment: "Can you add a test for edge case X?"
Request Changes: "This needs refactoring"
Approve: "Looks good! ✅"
```

**Developer Response:**
```
1. Address feedback in code
2. git add . && git commit -m "[Chat] fix: Add edge case test for UTF-8"
3. git push origin fix/chat-message-encoding
4. Build re-triggers, review updates
```

### Step 7: Merge to Master

**Requirements Before Merge:**
- ✅ All build/test checks pass
- ✅ Code review approved
- ✅ All comments resolved
- ✅ No conflicts with master

**Merge Strategy: Squash Merge**
```
Before merge:
  Commit 1: Fix UTF-8 encoding
  Commit 2: Add test case
  Commit 3: Update docs
  Commit 4: Fix linting errors

After squash merge to master:
  One commit: "[Chat] Fix: Properly encode UTF-8 characters..."
  
Benefit: Clean history, easy to identify "one change = one commit"
```

**Merge via Azure DevOps:**
1. Click "Complete pull request"
2. Confirm merge strategy is "Squash commit"
3. Optionally delete source branch
4. Click "Complete merge"

```
✅ PR merged successfully
✅ Feature branch auto-deleted
✅ CI/CD triggers automatically
```

### Step 8: Auto CI/CD Triggers

**On master merge:**
```
T=0:00    Commit hits master
T=0:02    NonOfficial build starts (Build.NonOfficial.Chat)
T=0:15    Build completes → Artifact created
T=0:17    NonOfficial deploy starts
T=0:40    Code in dev environment
T=0:50    Code in staging environment
T=1:00    Available for manual production deployment
```

---

## 4. PR Policies Enforced

### What Blocks Merging?

| Policy | Description | Why |
|--------|-------------|-----|
| **Build Passing** | All compilation + tests must pass | Prevent broken code |
| **Minimum Reviewers** | At least 1 approval required | Ensure peer review |
| **Code Reviewer** | Domain owners must review | Maintain consistency |
| **Comment Resolution** | All comments must be addressed | Track feedback |
| **No Conflicts** | PR must not have conflicts with master | Prevent merge issues |
| **Branch Policies** | Branch must be up-to-date with master | Latest base code |

### Viewers vs Reviewers vs Approvers

```
Viewers: Can see PR, cannot approve
Reviewers: Can comment and request changes
Approvers: Can approve (usually domain owners)
```

---

## 5. Special Cases

### Hotfix (Critical Production Issue)

```bash
# Even hotfixes follow same process
git checkout -b hotfix/urgent-payment-bug
<make fix>
git add . && git commit -m "[Refunds] hotfix: Fix payment processing"
git push origin hotfix/urgent-payment-bug

# Open PR (expedited review)
# ✅ Merged → Auto-deploys to production
```

### Handling Review Feedback

**Scenario: Reviewer wants changes**

```
Reviewer Comment:
"This function could be simpler. Consider using LINQ instead of foreach."

Developer Action:
1. Update code based on feedback
2. git commit -m "[Chat] refactor: Simplify message filtering with LINQ"
3. git push origin fix/chat-message-encoding
4. Build re-triggers automatically
5. Reviewer reviews again
6. Reviewer marks as "Approved"
```

### Conflict Resolution

**If master has changed since your branch:**

```bash
# Fetch latest master
git fetch origin

# Rebase your branch on latest master (preferred)
git rebase origin/master

# Or merge master into your branch (if rebase too complex)
git merge origin/master

# Fix conflicts in affected files
<resolve conflicts manually>

# Complete rebase/merge
git add .
git rebase --continue
# or
git merge --continue

# Force push your updated branch
git push origin fix/chat-message-encoding -f
```

---

## 6. Interview-Ready Answers

### Q: "Describe your branching strategy"

**Answer:**
```
We use a single master branch model. All work happens on feature branches
created from master. The workflow is:

1. Create feature branch: git checkout -b fix/bug-name
2. Commit changes with domain prefix: [Chat] fix: description
3. Push and open PR against master
4. Automated builds & tests run
5. Domain reviewers approve
6. Squash merge to master
7. CI/CD auto-triggers

Master is always deployable. No manual releases or release branches.
Production version is just a git tag/commit on master.

Key principle: one change = one PR = one squash commit on master
```

### Q: "What happens if someone tries to push directly to master?"

**Answer:**
```
Can't. Master is a protected branch. Azure DevOps prevents direct pushes.
You must go through PR + review + all checks passing.

This ensures:
- No broken code reaches master
- All changes are reviewed
- Build/tests always pass
- Clear audit trail
```

### Q: "How do you keep git history clean?"

**Answer:**
```
Squash merge. When a PR is merged, all commits are combined into one.
So a PR with 5 commits becomes 1 commit on master.

Benefits:
- History is linear (easy to read)
- Each commit represents one feature/fix
- Easy to revert: git revert <commit>
- Easier to bisect for debugging
```

### Q: "What if you have a merge conflict?"

**Answer:**
```
Rebase your branch on latest master:

git fetch origin
git rebase origin/master

Fix conflicts in your editor (VS Code shows them clearly)
Then: git add . && git rebase --continue

Or if rebase is complex, use merge:
git merge origin/master

Either way, resolve manually, then push to trigger build again.
```

---

## 7. Common Workflows

### Bug Fix Workflow
```bash
git checkout master && git pull
git checkout -b fix/bug-123
# ... make fix ...
git add . && git commit -m "[Domain] fix: Description"
git push origin fix/bug-123
# Open PR, wait for review, merge
```

### Feature Development Workflow
```bash
git checkout master && git pull
git checkout -b feature/new-feature
# ... develop over multiple commits ...
# Push each commit as you go
git push origin feature/new-feature  # Each time you commit
# Once ready, open PR (all commits already visible)
# Review, merge, squash happens
```

### Keeping Branch Updated
```bash
# If master has moved ahead while you're still working
git fetch origin
git rebase origin/master  # Reapply your changes on top of new master
git push origin fix/bug-name -f  # Force push (OK for feature branches)
```

---

## 8. Best Practices

### DO ✅
- ✅ Create branch for each feature/fix
- ✅ Use descriptive branch names
- ✅ Push frequently (don't let branch diverge too much)
- ✅ Keep PRs focused (1 feature = 1 PR)
- ✅ Write clear commit messages
- ✅ Respond to review feedback promptly
- ✅ Delete merged branches

### DON'T ❌
- ❌ Push directly to master
- ❌ Have multiple features in one PR
- ❌ Ignore build/test failures
- ❌ Use vague commit messages ("fix stuff", "update code")
- ❌ Let branch stay unmerged for weeks
- ❌ Rewrite public history (use rebase only on your branch before PR)

---

## 9. Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't push (access denied) | Check branch permissions, contact repo admin |
| Build failing | Run `dotnet build /warnaserror` locally, fix errors, push again |
| Conflicts after rebase | Resolve manually, `git add .`, `git rebase --continue` |
| Accidentally committed to master | Create new branch from that commit, fix on branch, revert master |
| PR won't merge (requires status checks) | Wait for build to finish, scroll down in PR to see status |
| Reviewer won't approve | Ask for clarification on feedback, address and request re-review |

---

## 10. Key Takeaways

1. **Master is sacred** — protected, tested, deployable
2. **PR first** — all changes via PR, no exceptions
3. **Automation does heavy lifting** — build/test runs automatically
4. **Humans review logic** — focus on correctness, not formatting
5. **Clean history** — squash merge keeps it readable
6. **Explicit domain tagging** — commit messages identify affected domain