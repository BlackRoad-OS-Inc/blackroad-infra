# BlackRoad OS Infrastructure — Terraform
# Manages Cloudflare DNS, Worker routes, and KV namespaces

terraform {
  required_version = ">= 1.6"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    # Use Cloudflare R2 as Terraform state backend
    # Configure with: export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
    bucket   = "blackroad-tf-state"
    key      = "blackroad-os/terraform.tfstate"
    region   = "auto"
    endpoint = "https://848cf0b18d51e0170e0d1537aec3505a.r2.cloudflarestorage.com"
  }
}

# ── Variables ─────────────────────────────────────────────────────────────────

variable "cloudflare_api_token" {
  description = "Cloudflare API token — set via TF_VAR_cloudflare_api_token or CI secret"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  default     = "848cf0b18d51e0170e0d1537aec3505a"
}

variable "blackroad_zone_id" {
  description = "Zone ID for blackroad.io"
  type        = string
}

variable "blackroad_ai_zone_id" {
  description = "Zone ID for blackroad.ai"
  type        = string
}

# ── Provider ──────────────────────────────────────────────────────────────────

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ── KV Namespaces ─────────────────────────────────────────────────────────────

resource "cloudflare_workers_kv_namespace" "cache" {
  account_id = var.cloudflare_account_id
  title      = "BLACKROAD_CACHE"
}

resource "cloudflare_workers_kv_namespace" "memory" {
  account_id = var.cloudflare_account_id
  title      = "BLACKROAD_MEMORY"
}

resource "cloudflare_workers_kv_namespace" "sessions" {
  account_id = var.cloudflare_account_id
  title      = "BLACKROAD_SESSIONS"
}

# ── DNS Records ───────────────────────────────────────────────────────────────

# Gateway tunnel
resource "cloudflare_record" "gateway" {
  zone_id = var.blackroad_zone_id
  name    = "gateway"
  value   = "52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# Agents endpoint
resource "cloudflare_record" "agents" {
  zone_id = var.blackroad_zone_id
  name    = "agents"
  value   = "blackroad-agents.blackroad.workers.dev"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# API endpoint
resource "cloudflare_record" "api" {
  zone_id = var.blackroad_ai_zone_id
  name    = "api"
  value   = "blackroad-api.blackroad.workers.dev"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# ── Worker Routes ─────────────────────────────────────────────────────────────

resource "cloudflare_worker_route" "api_route" {
  zone_id     = var.blackroad_ai_zone_id
  pattern     = "api.blackroad.ai/*"
  script_name = "blackroad-api-gateway"
}

resource "cloudflare_worker_route" "agents_route" {
  zone_id     = var.blackroad_zone_id
  pattern     = "agents.blackroad.io/*"
  script_name = "agents-blackroadio"
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "kv_cache_id" {
  value = cloudflare_workers_kv_namespace.cache.id
}

output "kv_memory_id" {
  value = cloudflare_workers_kv_namespace.memory.id
}

output "kv_sessions_id" {
  value = cloudflare_workers_kv_namespace.sessions.id
}
