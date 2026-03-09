# Changelog

All notable changes to **blackroad-infra** are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

---

## [Unreleased]

### Added
- `terraform/environments/production/outputs.tf` — expose droplet IP, pages URLs, worker name
- `terraform/environments/staging/outputs.tf` — expose staging droplet IP and pages URL
- `terraform/modules/digitalocean-droplet/variables.tf` — `ssh_allowed_cidr` variable to restrict SSH inbound access
- `terraform/environments/production/variables.tf` — `do_size` and `ssh_allowed_cidr` variables

### Changed
- `docker/agents/Dockerfile` — set `NODE_ENV=production` in runtime stage; add `--ignore-scripts` to `npm ci`
- `docker/operator/Dockerfile` — set `NODE_ENV=production`; add `--ignore-scripts` to `npm ci`
- `terraform/modules/digitalocean-droplet/main.tf` — enable droplet `backups` and `monitoring`; add ICMP firewall rules; restrict SSH via `ssh_allowed_cidr`; add ICMP outbound rule
- `terraform/environments/production/main.tf` — pass `ssh_allowed_cidr` and `tags` to droplet module
- `.github/workflows/terraform-apply.yml` — plan before apply (`terraform plan -out=tfplan` then `terraform apply tfplan`); add `concurrency` group; add plan summary and outputs to step summary
- `.github/workflows/terraform-plan.yml` — generate real plan output; post plan as PR comment (create or update); add `concurrency` group; add `permissions` block

---

## [0.1.0] — 2026-02-22

### Added
- Initial repository setup
- Core structure established
- LICENSE, README, CONTRIBUTING docs

---
© BlackRoad OS, Inc. All rights reserved.
