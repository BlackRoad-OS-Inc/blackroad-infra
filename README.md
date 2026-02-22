# blackroad-infra

> Infrastructure-as-code, CI/CD workflows, and deployment configs for BlackRoad OS.

[![CI](https://github.com/BlackRoad-OS-Inc/blackroad-infra/actions/workflows/ci.yml/badge.svg)](https://github.com/BlackRoad-OS-Inc/blackroad-infra/actions/workflows/ci.yml)

## Overview

All IaC, container configs, CI/CD pipelines, and cloud provider deployments. One source of truth for how BlackRoad OS infrastructure is defined and deployed.

## Structure

```
blackroad-infra/
├── terraform/        # Terraform modules (DigitalOcean, Cloudflare, Railway)
├── docker/           # Dockerfiles and compose files
├── k8s/              # Kubernetes manifests
├── cloudflare/       # Cloudflare Workers & Pages configs (wrangler.toml)
├── railway/          # Railway project configs (railway.toml)
├── ci/               # Reusable CI/CD workflow templates
├── dashboard/        # Infrastructure dashboard
└── scripts/          # Deployment automation scripts
```

## Platforms

| Platform | Config Location | Purpose |
|----------|----------------|---------|
| Cloudflare | `cloudflare/` | 75+ Workers, Pages, Tunnel |
| Railway | `railway/` | 14 projects, GPU services |
| DigitalOcean | `terraform/` | Droplets, Spaces |
| Docker | `docker/` | Container definitions |
| Kubernetes | `k8s/` | Orchestration |

## Quick Deploys

```bash
# Cloudflare Worker
cd cloudflare/<worker> && wrangler deploy

# Railway
railway up

# Terraform
cd terraform && terraform plan && terraform apply
```

## Required Secrets

See `.env.example` for all required environment variables.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

---

© BlackRoad OS, Inc. — All rights reserved. Proprietary.
