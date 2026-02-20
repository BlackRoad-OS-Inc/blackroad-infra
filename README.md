# blackroad-infra

Infrastructure-as-Code, Docker configs, CI templates, and operational scripts for BlackRoad OS.

## Structure

```
terraform/
  environments/        # Production and staging configs
  modules/             # Reusable Terraform modules
docker/                # Dockerfiles and docker-compose
ci/
  templates/           # Reusable GitHub Actions workflows
  actions/             # Composite GitHub Actions
scripts/               # Operational shell scripts
```

## Prerequisites

- Terraform >= 1.7
- Docker & Docker Compose
- Node.js >= 22

## Quick Start

```bash
./scripts/bootstrap.sh              # Check tooling
cd docker && docker compose up      # Run all services
cd terraform/environments/staging
terraform init -backend=false && terraform validate
```

## Terraform Modules

| Module | Purpose |
|--------|---------|
| `cloudflare-pages` | Pages project deployment |
| `cloudflare-worker` | Worker script + route |
| `railway-service` | Railway CLI deployment |
| `digitalocean-droplet` | Droplet + firewall |

## License

Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
