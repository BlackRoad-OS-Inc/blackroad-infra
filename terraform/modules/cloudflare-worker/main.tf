# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
resource "cloudflare_worker_script" "this" {
  account_id = var.account_id
  name       = var.name
  content    = file(var.script_path)
  module     = true
}

resource "cloudflare_worker_route" "this" {
  count       = var.route_pattern != "" ? 1 : 0
  zone_id     = var.zone_id
  pattern     = var.route_pattern
  script_name = cloudflare_worker_script.this.name
}
