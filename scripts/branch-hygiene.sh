#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# Git Branch Hygiene Analyzer for BlackRoad Repositories
# Analyzes branching strategies, protection rules, and identifies cleanup opportunities

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
PINK='\033[38;5;205m'
NC='\033[0m' # No Color

OUTPUT_FILE="${HOME}/GIT_BRANCH_HYGIENE_REPORT_$(date +%Y%m%d_%H%M%S).md"

# Key repos to analyze
MAJOR_REPOS=(
    "blackroad-os-infra"
    "blackroad-os-core"
    "blackroad-os-brand"
    "blackroad-io"
    "blackroad-app-store"
    "blackroad-blackroad os"
    "blackroad-console"
    "blackroad-dashboard"
    "blackroad-api-worker"
    "blackroad-agent-network"
)

echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PINK}║   Git Branch Hygiene Analyzer - BlackRoad Repositories   ║${NC}"
echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Initialize report
cat > "$OUTPUT_FILE" << 'EOF'
# Git Branch Hygiene Report - BlackRoad Infrastructure

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Analyzer:** Erebus (BlackRoad OS)
**Scope:** BlackRoad-OS GitHub Organization

## Executive Summary

EOF

# Counters
total_repos=0
total_branches=0
stale_branches=0
main_count=0
master_count=0
other_default_count=0
protected_repos=0
unprotected_repos=0

# Arrays to store findings
declare -a stale_branch_list
declare -a long_lived_branches
declare -a unprotected_list
declare -a orphan_branches

echo -e "${BLUE}[1/6]${NC} Checking GitHub authentication..."
if ! gh auth status &>/dev/null; then
    echo -e "${RED}✗ Not authenticated with GitHub${NC}"
    echo "Run: gh auth login"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated${NC}"

echo ""
echo -e "${BLUE}[2/6]${NC} Analyzing major repositories..."

# Function to check branch protection
check_protection() {
    local repo=$1
    local branch=${2:-main}

    if gh api "/repos/BlackRoad-OS/$repo/branches/$branch/protection" &>/dev/null; then
        echo "protected"
    else
        echo "unprotected"
    fi
}

# Function to get branch age in days
get_branch_age() {
    local repo=$1
    local branch=$2

    # Get last commit date
    commit_date=$(gh api "/repos/BlackRoad-OS/$repo/commits/$branch" --jq '.commit.committer.date' 2>/dev/null || echo "")

    if [ -z "$commit_date" ]; then
        echo "unknown"
        return
    fi

    # Calculate age in days
    if date --version &>/dev/null 2>&1; then
        # GNU date
        commit_epoch=$(date -d "$commit_date" +%s 2>/dev/null || echo "0")
    else
        # BSD date (macOS)
        commit_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$commit_date" +%s 2>/dev/null || echo "0")
    fi

    current_epoch=$(date +%s)
    age_days=$(( (current_epoch - commit_epoch) / 86400 ))
    echo "$age_days"
}

# Analyze each major repo
for repo in "${MAJOR_REPOS[@]}"; do
    echo -e "\n${MAGENTA}→ Analyzing: ${repo}${NC}"

    # Check if repo exists
    if ! gh api "/repos/BlackRoad-OS/$repo" &>/dev/null; then
        echo -e "  ${YELLOW}⚠ Repository not found, skipping${NC}"
        continue
    fi

    total_repos=$((total_repos + 1))

    # Get default branch
    default_branch=$(gh api "/repos/BlackRoad-OS/$repo" --jq '.default_branch' 2>/dev/null || echo "unknown")
    echo -e "  Default branch: ${PINK}$default_branch${NC}"

    # Count default branch types
    case "$default_branch" in
        main) main_count=$((main_count + 1)) ;;
        master) master_count=$((master_count + 1)) ;;
        *) other_default_count=$((other_default_count + 1)) ;;
    esac

    # Check protection on default branch
    protection_status=$(check_protection "$repo" "$default_branch")
    if [ "$protection_status" = "protected" ]; then
        echo -e "  ${GREEN}✓ Branch protection enabled${NC}"
        protected_repos=$((protected_repos + 1))
    else
        echo -e "  ${YELLOW}⚠ No branch protection${NC}"
        unprotected_repos=$((unprotected_repos + 1))
        unprotected_list+=("$repo")
    fi

    # Get all branches
    branches=$(gh api "/repos/BlackRoad-OS/$repo/branches" --paginate --jq '.[].name' 2>/dev/null || echo "")
    branch_count=$(echo "$branches" | grep -v '^$' | wc -l | tr -d ' ')
    total_branches=$((total_branches + branch_count))
    echo -e "  Total branches: ${PINK}$branch_count${NC}"

    # Analyze each branch
    while IFS= read -r branch; do
        [ -z "$branch" ] && continue
        [ "$branch" = "$default_branch" ] && continue

        age=$(get_branch_age "$repo" "$branch")

        if [ "$age" != "unknown" ] && [ "$age" -gt 30 ]; then
            stale_branches=$((stale_branches + 1))
            stale_branch_list+=("$repo/$branch (${age}d old)")

            if [ "$age" -gt 90 ]; then
                long_lived_branches+=("$repo/$branch (${age}d old)")
            fi
        fi
    done <<< "$branches"
done

echo ""
echo -e "${BLUE}[3/6]${NC} Scanning all BlackRoad-OS repositories for patterns..."

# Get comprehensive repo list
all_repos=$(gh repo list BlackRoad-OS --limit 100 --json name --jq '.[].name' 2>/dev/null || echo "")

feature_branches=0
fix_branches=0
release_branches=0
hotfix_branches=0
develop_branches=0
staging_branches=0

while IFS= read -r repo; do
    [ -z "$repo" ] && continue

    branches=$(gh api "/repos/BlackRoad-OS/$repo/branches" --jq '.[].name' 2>/dev/null || echo "")

    echo "$branches" | while IFS= read -r branch; do
        case "$branch" in
            feature/*) feature_branches=$((feature_branches + 1)) ;;
            fix/*|bugfix/*) fix_branches=$((fix_branches + 1)) ;;
            release/*) release_branches=$((release_branches + 1)) ;;
            hotfix/*) hotfix_branches=$((hotfix_branches + 1)) ;;
            develop) develop_branches=$((develop_branches + 1)) ;;
            staging) staging_branches=$((staging_branches + 1)) ;;
        esac
    done
done <<< "$all_repos"

echo -e "${GREEN}✓ Pattern analysis complete${NC}"

echo ""
echo -e "${BLUE}[4/6]${NC} Generating recommendations..."

# Generate report content
cat >> "$OUTPUT_FILE" << EOF

### Key Metrics

| Metric | Value |
|--------|-------|
| Repositories Analyzed | $total_repos major repos |
| Total Branches | $total_branches |
| Stale Branches (>30 days) | $stale_branches |
| Long-lived Branches (>90 days) | ${#long_lived_branches[@]} |
| Protected Repositories | $protected_repos |
| Unprotected Repositories | $unprotected_repos |

### Default Branch Naming

| Branch Name | Count |
|-------------|-------|
| main | $main_count |
| master | $master_count |
| other | $other_default_count |

**Status:** $([ $main_count -gt $master_count ] && echo "✅ Majority using 'main'" || echo "⚠️ Mixed naming conventions")

---

## 1. Branch Protection Analysis

### Protected Repositories
$([ $protected_repos -gt 0 ] && echo "✅ **$protected_repos repositories** have branch protection enabled" || echo "❌ No repositories have branch protection")

### Unprotected Repositories
$(if [ ${#unprotected_list[@]} -gt 0 ]; then
    echo "⚠️ **${#unprotected_list[@]} repositories** lack branch protection:"
    echo ""
    for repo in "${unprotected_list[@]}"; do
        echo "- \`$repo\`"
    done
    echo ""
    echo "**Recommendation:** Enable branch protection on all production repositories"
else
    echo "✅ All analyzed repositories have branch protection"
fi)

---

## 2. Branch Naming Patterns

| Pattern | Count | Usage |
|---------|-------|-------|
| feature/* | $feature_branches | Feature development |
| fix/*, bugfix/* | $fix_branches | Bug fixes |
| release/* | $release_branches | Release preparation |
| hotfix/* | $hotfix_branches | Emergency fixes |
| develop | $develop_branches | Development branch |
| staging | $staging_branches | Staging environment |

**Analysis:**
$(if [ $feature_branches -gt 0 ] || [ $fix_branches -gt 0 ]; then
    echo "- ✅ Git Flow or GitHub Flow patterns detected"
else
    echo "- ℹ️ Minimal branch naming conventions in use"
fi)
$(if [ $hotfix_branches -gt 0 ]; then
    echo "- ✅ Hotfix workflow present for emergency deployments"
else
    echo "- ℹ️ No dedicated hotfix branches observed"
fi)

---

## 3. Stale Branch Analysis

### Summary
- **Total stale branches:** $stale_branches (older than 30 days)
- **Long-lived branches:** ${#long_lived_branches[@]} (older than 90 days)

### Long-lived Branches Requiring Review

$(if [ ${#long_lived_branches[@]} -gt 0 ]; then
    echo "These branches are older than 90 days and should be reviewed for merge or deletion:"
    echo ""
    for branch in "${long_lived_branches[@]}"; do
        echo "- \`$branch\`"
    done
else
    echo "✅ No branches older than 90 days detected"
fi)

**Recommendation:**
- Review all branches older than 30 days
- Merge completed work
- Delete abandoned branches
- Document long-lived feature branches

---

## 4. Git Flow Assessment

### Current State
EOF

if [ $develop_branches -gt 0 ] && [ $release_branches -gt 0 ]; then
    cat >> "$OUTPUT_FILE" << EOF
✅ **Git Flow detected** - Repositories using develop/release branches

**Workflow:**
\`\`\`
main (production) ← release/* ← develop ← feature/*
                  ← hotfix/*
\`\`\`
EOF
elif [ $staging_branches -gt 0 ]; then
    cat >> "$OUTPUT_FILE" << EOF
✅ **Environment branching detected** - Using staging branches

**Workflow:**
\`\`\`
main (production) ← staging ← feature branches
\`\`\`
EOF
else
    cat >> "$OUTPUT_FILE" << EOF
ℹ️ **GitHub Flow (simplified)** - Direct feature branch workflow

**Workflow:**
\`\`\`
main ← feature/*, fix/*
\`\`\`
EOF
fi

cat >> "$OUTPUT_FILE" << 'EOF'

### Recommended Workflow for BlackRoad

Given the multi-environment infrastructure (development → staging → production), we recommend:

```
main (production)
  ↑
staging (pre-production testing)
  ↑
develop (integration)
  ↑
feature/*, fix/*, enhancement/*
```

**Branch Lifecycle:**
1. Create feature branch from `develop`
2. Develop and test locally
3. PR to `develop` (automated tests)
4. Merge to `staging` (integration testing)
5. Deploy to production via `main`
6. Use `hotfix/*` branches for emergency production fixes

---

## 5. Cleanup Recommendations

### Immediate Actions (High Priority)

1. **Enable Branch Protection** on all production repositories:
   ```bash
   # For each unprotected repo:
   gh api -X PUT "/repos/BlackRoad-OS/{repo}/branches/main/protection" \
     -f required_status_checks='{"strict":true,"contexts":["ci/test"]}' \
     -f enforce_admins=true \
     -f required_pull_request_reviews='{"required_approving_review_count":1}' \
     -f restrictions=null
   ```

2. **Standardize Default Branch Naming** to `main`:
   ```bash
   # For repos still using 'master':
   gh api -X PATCH "/repos/BlackRoad-OS/{repo}" -f default_branch=main
   ```

3. **Review and Merge/Delete Stale Branches**:
   - Schedule weekly branch hygiene review
   - Automate stale branch detection (GitHub Actions)
   - Set branch deletion policy (auto-delete after merge)

### Medium Priority

4. **Implement Git Flow** across key repositories:
   - Create `develop` branch for integration
   - Create `staging` branch for pre-production
   - Document workflow in CONTRIBUTING.md

5. **Add Branch Naming Conventions** to templates:
   ```
   feature/ISSUE-123-description
   fix/ISSUE-456-bug-description
   hotfix/critical-production-issue
   release/v1.2.3
   ```

6. **Automate Branch Protection**:
   - Create reusable GitHub Action
   - Apply protection rules org-wide
   - Require status checks before merge

### Low Priority

7. **Set up CODEOWNERS** files for automatic review assignment

8. **Configure branch cleanup automation**:
   - Auto-delete merged branches
   - Notify on stale branches (>30 days)
   - Archive long-lived branches (>90 days)

---

## 6. Orphan Branch Detection

**Note:** Full orphan branch detection requires cloning repositories and analyzing commit graphs.

**Recommended Script:**
```bash
# Run for each major repository
for repo in blackroad-os-infra blackroad-os-core; do
  git clone https://github.com/BlackRoad-OS/$repo
  cd $repo

  # Find branches with no common ancestor to main
  git branch -r | while read branch; do
    if ! git merge-base main $branch &>/dev/null; then
      echo "Orphan: $branch"
    fi
  done

  cd ..
  rm -rf $repo
done
```

---

## 7. Implementation Roadmap

### Week 1: Critical Security
- [ ] Enable branch protection on all 10 major repositories
- [ ] Audit and document current branching strategy
- [ ] Set up required status checks

### Week 2: Standardization
- [ ] Migrate all default branches to `main`
- [ ] Create branch naming convention guide
- [ ] Update repository templates

### Week 3: Automation
- [ ] Deploy stale branch detection workflow
- [ ] Set up automated branch cleanup
- [ ] Configure CODEOWNERS

### Week 4: Documentation
- [ ] Update CONTRIBUTING.md in all repos
- [ ] Create Git Flow diagram
- [ ] Training documentation for team

---

## 8. Monitoring & Maintenance

### Automated Checks (GitHub Actions)

**Stale Branch Detector** (`.github/workflows/stale-branches.yml`):
```yaml
name: Stale Branch Detector
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:

jobs:
  detect-stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v8
        with:
          days-before-stale: 30
          days-before-close: 7
          stale-branch-message: 'This branch has been inactive for 30 days. Consider merging or closing.'
```

### Weekly Review Checklist
- [ ] Review stale branches report
- [ ] Check for unmerged long-lived branches
- [ ] Verify branch protection rules are active
- [ ] Update documentation if workflow changes

---

## Appendix A: Quick Commands

```bash
# List all branches in a repo
gh api /repos/BlackRoad-OS/{repo}/branches --jq '.[].name'

# Check branch protection
gh api /repos/BlackRoad-OS/{repo}/branches/main/protection

# Enable branch protection
gh api -X PUT /repos/BlackRoad-OS/{repo}/branches/main/protection \
  -f required_pull_request_reviews='{"required_approving_review_count":1}'

# Delete remote branch
gh api -X DELETE /repos/BlackRoad-OS/{repo}/git/refs/heads/{branch}

# Get branch last commit date
gh api /repos/BlackRoad-OS/{repo}/commits/{branch} --jq '.commit.committer.date'
```

---

## Appendix B: Branch Protection Best Practices

### Recommended Settings for `main` branch:

- ✅ Require pull request reviews (1+ approvers)
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Require conversation resolution before merging
- ✅ Include administrators in restrictions
- ✅ Restrict who can push to matching branches
- ⚠️ Allow force pushes: **NO**
- ⚠️ Allow deletions: **NO**

### For `develop` branch:
- ✅ Require pull request reviews (1+ approver)
- ✅ Require status checks to pass
- ⚠️ Allow force pushes: **NO**

### For feature branches:
- ℹ️ No protection needed (ephemeral)

---

**Report Generated by:** Erebus (BlackRoad OS)
**Next Review:** 7 days from generation date
**Automation Status:** Manual (recommend GitHub Actions integration)

EOF

echo -e "${GREEN}✓ Recommendations generated${NC}"

echo ""
echo -e "${BLUE}[5/6]${NC} Writing report to: ${PINK}$OUTPUT_FILE${NC}"

echo ""
echo -e "${BLUE}[6/6]${NC} Logging to memory system..."

# Log to memory
if [ -f ~/memory-system.sh ]; then
    ~/memory-system.sh log "analyzed" "git-branch-hygiene" "Analyzed $total_repos repos, $total_branches branches, found $stale_branches stale branches, $unprotected_repos unprotected repos" "git,branches,hygiene,audit,erebus"
fi

# Log GreenLight progress
if [ -f ~/memory-greenlight-templates.sh ]; then
    source ~/memory-greenlight-templates.sh
    gl_progress "erebus-weaver-1771093745-5f1687b4" "Analyzed $total_repos repos, identified $stale_branches stale branches" "Generating cleanup automation scripts"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ Analysis Complete                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${PINK}Report saved to:${NC} $OUTPUT_FILE"
echo ""
echo -e "${YELLOW}Key Findings:${NC}"
echo -e "  • Repositories analyzed: ${PINK}$total_repos${NC}"
echo -e "  • Total branches: ${PINK}$total_branches${NC}"
echo -e "  • Stale branches (>30d): ${YELLOW}$stale_branches${NC}"
echo -e "  • Unprotected repos: ${RED}$unprotected_repos${NC}"
echo -e "  • Default 'main' usage: ${PINK}$main_count/$total_repos${NC}"
echo ""
echo -e "${PINK}View report:${NC} cat $OUTPUT_FILE"
echo -e "${PINK}Or open in editor:${NC} code $OUTPUT_FILE"
echo ""
