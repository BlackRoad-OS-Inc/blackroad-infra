# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
resource "cloudflare_pages_project" "this" {
  account_id        = var.account_id
  name              = var.project_name
  production_branch = "main"

  build_config {
    build_command   = var.build_command
    destination_dir = var.destination_dir
  }

  deployment_configs {
    production {
      environment_variables = var.environment_variables
    }
  }
}
