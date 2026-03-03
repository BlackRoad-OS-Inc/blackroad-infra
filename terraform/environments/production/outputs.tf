# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
output "droplet_ip" {
  description = "Public IPv4 address of the production droplet"
  value       = module.primary_droplet.ipv4_address
}

output "droplet_name" {
  description = "Name of the production droplet"
  value       = module.primary_droplet.name
}

output "gateway_pages_url" {
  description = "Cloudflare Pages URL for the gateway"
  value       = module.gateway_pages.url
}

output "web_pages_url" {
  description = "Cloudflare Pages URL for the web frontend"
  value       = module.web_pages.url
}

output "gateway_worker_name" {
  description = "Deployed Cloudflare Worker name for the gateway"
  value       = module.gateway_worker.worker_name
}
