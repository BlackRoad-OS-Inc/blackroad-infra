# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
output "url" {
  description = "Pages project URL"
  value       = "https://${cloudflare_pages_project.this.name}.pages.dev"
}

output "project_id" {
  description = "Pages project ID"
  value       = cloudflare_pages_project.this.id
}
