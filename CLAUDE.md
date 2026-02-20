# CLAUDE.md — blackroad-infra

Infrastructure-as-Code for BlackRoad OS. Terraform modules, Docker configs, CI templates, and operational scripts.

## Stack
- Terraform (Cloudflare, DigitalOcean, Railway modules)
- Docker (multi-service compose)
- GitHub Actions (reusable workflows and composite actions)

## Key Directories
- `terraform/environments/` — Production and staging configs
- `terraform/modules/` — Reusable Terraform modules
- `docker/` — Dockerfiles and docker-compose
- `ci/` — Reusable workflow templates and composite actions
- `scripts/` — Operational shell scripts

## Copyright
All files are proprietary to BlackRoad OS, Inc.
