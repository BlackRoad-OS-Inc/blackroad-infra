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
  description = "DigitalOcean droplet size slug"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed SSH inbound to the production droplet. Set via TF_VAR_ssh_allowed_cidr or a .tfvars file — do not leave open to the internet in production."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "do_ssh_keys" {
  description = "SSH key fingerprints for droplet access"
  type        = list(string)
  default     = []
}
