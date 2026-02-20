# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
# Railway does not have an official Terraform provider.
# We use null_resource with local-exec to deploy via the Railway CLI.
resource "null_resource" "railway_deploy" {
  triggers = {
    service_name = var.service_name
    project_id   = var.project_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      railway link ${var.project_id}
      railway up --service ${var.service_name}
    EOT

    environment = {
      RAILWAY_TOKEN = var.railway_token
    }
  }
}
