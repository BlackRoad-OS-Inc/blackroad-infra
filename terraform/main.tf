# BlackRoad OS — Core Infrastructure (Terraform)
terraform {
  required_version = ">= 1.6"
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 4" }
    github     = { source = "integrations/github",   version = "~> 6" }
  }
  backend "remote" {
    organization = "blackroad-os-inc"
    workspaces { name = "blackroad-core" }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "github" {
  token = var.github_token
  owner = "BlackRoad-OS-Inc"
}

# Cloudflare Zone
data "cloudflare_zone" "blackroad_ai" {
  name = "blackroad.ai"
}

# KV Namespace for agent state
resource "cloudflare_workers_kv_namespace" "agent_state" {
  account_id = var.cloudflare_account_id
  title      = "blackroad-agent-state"
}

# D1 Database for persistent memory
resource "cloudflare_d1_database" "memory" {
  account_id = var.cloudflare_account_id
  name       = "blackroad-memory"
}

# Gateway Worker
resource "cloudflare_worker_script" "gateway" {
  account_id = var.cloudflare_account_id
  name       = "blackroad-gateway"
  content    = file("${path.module}/../workers/gateway/index.js")

  kv_namespace_binding {
    name         = "AGENT_STATE"
    namespace_id = cloudflare_workers_kv_namespace.agent_state.id
  }
  
  d1_database_binding {
    name        = "MEMORY_DB"
    database_id = cloudflare_d1_database.memory.id
  }
}

# DNS: gateway.blackroad.ai → worker
resource "cloudflare_record" "gateway" {
  zone_id = data.cloudflare_zone.blackroad_ai.id
  name    = "gateway"
  type    = "CNAME"
  value   = "blackroad-gateway.workers.dev"
  proxied = true
}

variable "cloudflare_api_token" { sensitive = true }
variable "cloudflare_account_id" { default = "848cf0b18d51e0170e0d1537aec3505a" }
variable "github_token" { sensitive = true }
