# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
output "worker_name" {
  description = "Deployed worker name"
  value       = cloudflare_worker_script.this.name
}
