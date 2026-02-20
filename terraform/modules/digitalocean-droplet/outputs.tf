# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
output "id" {
  description = "Droplet ID"
  value       = digitalocean_droplet.this.id
}

output "ipv4_address" {
  description = "Public IPv4 address"
  value       = digitalocean_droplet.this.ipv4_address
}

output "name" {
  description = "Droplet name"
  value       = digitalocean_droplet.this.name
}
