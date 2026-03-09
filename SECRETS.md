# BlackRoad Secrets Setup Guide

All integration workflows are deployed and ready.
Add these secrets to your GitHub orgs to activate them.

## GitHub CLI Commands

```bash
# Run these for each org: BlackRoad-OS-Inc, BlackRoad-OS, BlackRoad-AI, ...

ORG="BlackRoad-OS-Inc"

# HuggingFace (get token: https://huggingface.co/settings/tokens)
gh secret set HF_TOKEN --org $ORG --visibility all

# Notion (get token: https://www.notion.so/my-integrations)
gh secret set NOTION_API_KEY --org $ORG --visibility all
gh secret set NOTION_DATABASE_ID --org $ORG --visibility all

# Google Drive Service Account (https://console.cloud.google.com/iam-admin/serviceaccounts)
gh secret set GOOGLE_SERVICE_ACCOUNT_JSON --org $ORG --visibility all
gh secret set GDRIVE_FOLDER_ID --org $ORG --visibility all

# Slack Webhook (https://api.slack.com/messaging/webhooks)
gh secret set SLACK_WEBHOOK_URL --org $ORG --visibility all

# Linear (https://linear.app/settings/api)
gh secret set LINEAR_API_KEY --org $ORG --visibility all
gh secret set LINEAR_TEAM_ID --org $ORG --visibility all

# Sentry (https://sentry.io/settings/auth-tokens/)
gh secret set SENTRY_AUTH_TOKEN --org $ORG --visibility all
```

## What Each Workflow Does

| Workflow | Trigger | Needs |
|----------|---------|-------|
| `hf-sync.yml` | Push to models/, weekly | HF_TOKEN |
| `notion-sync.yml` | Push *.md, weekly Monday | NOTION_API_KEY, NOTION_DATABASE_ID |
| `gdrive-backup.yml` | Daily 3 AM | GOOGLE_SERVICE_ACCOUNT_JSON, GDRIVE_FOLDER_ID |
| `integrations.yml` | Release published | SLACK_WEBHOOK_URL, LINEAR_API_KEY, SENTRY_AUTH_TOKEN |

## Already Set (Found on Device)

| Secret | Orgs | Status |
|--------|------|--------|
| CLOUDFLARE_API_TOKEN | All 16 | ✓ Set |
| RAILWAY_TOKEN | All 16 | ✓ Set |
| GH_PAT | All 16 | ✓ Set (needs admin:org scope upgrade) |

## Get Admin Scope for GitHub Secrets

```bash
# Upgrade gh CLI scope to set org secrets
gh auth refresh -h github.com -s admin:org
# Then re-run the secret set commands above
```
