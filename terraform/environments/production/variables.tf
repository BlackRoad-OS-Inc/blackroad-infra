# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "do_size" {
  description = "DigitalOcean droplet size"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "do_ssh_keys" {
  description = "SSH key fingerprints for droplet access"
  type        = list(string)
  default     = []
}
