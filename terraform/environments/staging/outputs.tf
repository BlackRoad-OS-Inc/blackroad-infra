# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
output "droplet_ip" {
  description = "Public IPv4 address of the staging droplet"
  value       = module.staging_droplet.ipv4_address
}

output "droplet_name" {
  description = "Name of the staging droplet"
  value       = module.staging_droplet.name
}

output "gateway_pages_url" {
  description = "Cloudflare Pages URL for the staging gateway"
  value       = module.gateway_pages.url
}
